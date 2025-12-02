// lib/pages/assistant_page.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Para LinearProgressIndicator y Colors
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/gemini_service.dart';

// ================== MODELO DE MENSAJE ==================
class Message {
  final String text;
  final bool isUser;
  final String? imagePath;
  final String? videoQuery;
  final bool isVoice; // <- para diferenciar notas de voz

  Message(
    this.text,
    this.isUser, {
    this.imagePath,
    this.videoQuery,
    bool? isVoice,
  }) : isVoice = isVoice ?? false; // nunca null
}

// Helper para parsear respuesta
class ParsedResponse {
  final String text;
  final String? videoQuery;
  ParsedResponse(this.text, this.videoQuery);
}

// ================== PANTALLA ASISTENTE ==================
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  // Servicio de Gemini (HydroGrowBot)
  final InvernaderoChatService _chatService = InvernaderoChatService();

  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  // 🔊 TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsEnabled = true;

  // 🎤 STT
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // ================== CICLO DE VIDA ==================
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('es-MX'); // o 'es-ES'
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
    } catch (_) {
      // Si algo falla con TTS, simplemente no hablamos
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (!_ttsEnabled) return;
    if (text.trim().isEmpty) return;

    final cleaned = text
        .replaceAll('```', '')
        .replaceAll('*', '')
        .replaceAll('#', '');

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(cleaned);
    } catch (_) {
      // Ignoramos errores de TTS para no crashear la app
    }
  }

  // 🎤 ESCUCHAR VOZ Y ENVIAR AL CHATBOT (SIN MOSTRAR TEXTO)
  Future<void> _toggleListening() async {
    if (_isLoading) return;

    if (!_isListening) {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );

      if (!available) {
        // Opcional: mostrar un diálogo si no hay permisos / no disponible
        return;
      }

      if (!mounted) return;
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        localeId: 'es-MX',
        onResult: (result) {
          if (!mounted) return;

          if (result.finalResult) {
            setState(() => _isListening = false);
            _speech.stop();

            final recognizedText = result.recognizedWords.trim();
            if (recognizedText.isNotEmpty) {
              _handleVoiceSend(recognizedText); // 👈 se envía sin mostrar texto
            }
          }
        },
      );
    } else {
      _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  // ================== ENVIAR MENSAJE DE VOZ (usa texto internamente) ==================
  Future<void> _handleVoiceSend(String recognizedText) async {
    if (_isLoading) return;
    final textForBot = recognizedText.trim();
    if (textForBot.isEmpty) return;

    setState(() {
      // En UI solo se ve que fue una nota de voz, NO el texto
      _messages.add(Message('Mensaje de voz', true, isVoice: true));
      _isLoading = true;
    });

    String rawResponse;
    try {
      rawResponse = await _chatService.sendMessage(textForBot);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(
          Message(
            'Ocurrió un error al contactar a HydroGrowBot. Intenta de nuevo.\n\n$e',
            false,
          ),
        );
      });
      return;
    }

    final parsed = _parseResponse(rawResponse);
    final botText = parsed.text;
    final videoQuery = parsed.videoQuery;

    if (!mounted) return;
    setState(() {
      _messages.add(Message(botText, false, videoQuery: videoQuery));
      _isLoading = false;
    });

    await _speak(botText);
  }

  // ================== PARSEAR RESPUESTA (VIDEO) ==================
  ParsedResponse _parseResponse(String rawResponse) {
    const marker = '---VIDEO SUGERIDO---';
    if (rawResponse.contains(marker)) {
      final parts = rawResponse.split(marker);
      final text = parts[0].trim();
      final videoQuery = parts.length > 1 ? parts[1].trim() : null;
      return ParsedResponse(text, videoQuery);
    }
    return ParsedResponse(rawResponse, null);
  }

  // ================== ENVIAR MENSAJE TEXTO / IMAGEN ==================
  void _handleSend({
    String? imagePath,
    String? prompt,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    if (_isLoading) return;

    final text = prompt ?? _controller.text.trim();
    if (text.isEmpty && imagePath == null) return;

    setState(() {
      _messages.add(Message(text, true, imagePath: imagePath));
      _isLoading = true;
    });
    _controller.clear();

    String rawResponse;
    try {
      if (imagePath != null && imageBytes != null && mimeType != null) {
        rawResponse = await _chatService.sendMultimodalMessage(
          text,
          imageBytes,
          mimeType,
        );
      } else {
        rawResponse = await _chatService.sendMessage(text);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(
          Message(
            'Ocurrió un error al contactar a HydroGrowBot. Intenta de nuevo.\n\n$e',
            false,
          ),
        );
      });
      return;
    }

    final parsed = _parseResponse(rawResponse);
    final botText = parsed.text;
    final videoQuery = parsed.videoQuery;

    if (!mounted) return;
    setState(() {
      _messages.add(Message(botText, false, videoQuery: videoQuery));
      _isLoading = false;
    });

    await _speak(botText);
  }

  // ================== ABRIR YOUTUBE ==================
  Future<void> _launchYouTubeSearch(String query) async {
    final url = Uri.https('www.youtube.com', '/results', {
      'search_query': query,
    });

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        await showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('No se pudo abrir YouTube'),
            content: const Text(
              '\nNo se pudo abrir el navegador o la app de YouTube en este dispositivo.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Error al abrir YouTube'),
          content: Text('\nOcurrió un error al intentar abrir YouTube:\n$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  // ================== TOMAR FOTO CON CÁMARA ==================
  Future<void> _handleCameraCapture() async {
    if (_isLoading) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final imageFile = File(image.path);
    final imageBytes = await imageFile.readAsBytes();
    final mimeType = image.mimeType ?? 'image/jpeg';

    const prompt =
        'Analiza esta imagen e identifica la plaga, enfermedad o necesidad de esta planta de invernadero. '
        'Dame un diagnóstico y plan de acción claro y práctico.';

    _handleSend(
      imagePath: image.path,
      prompt: prompt,
      imageBytes: imageBytes.buffer.asUint8List(),
      mimeType: mimeType,
    );
  }

  // ================== SELECCIONAR IMAGEN DESDE GALERÍA ==================
  Future<void> _handleImagePicker() async {
    if (_isLoading) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final imageFile = File(image.path);
    final imageBytes = await imageFile.readAsBytes();
    final mimeType = image.mimeType ?? 'image/jpeg';

    const prompt =
        'Analiza esta imagen e identifica la plaga, enfermedad o necesidad de esta planta de invernadero. '
        'Dame un diagnóstico y plan de acción claro y práctico.';

    _handleSend(
      imagePath: image.path,
      prompt: prompt,
      imageBytes: imageBytes.buffer.asUint8List(),
      mimeType: mimeType,
    );
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final isDark = cupertinoTheme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('HydroGrowBot'),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.9),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            setState(() {
              _ttsEnabled = !_ttsEnabled;
            });
            if (!_ttsEnabled) {
              _flutterTts.stop();
            }
          },
          child: Icon(
            _ttsEnabled
                ? CupertinoIcons.speaker_2_fill
                : CupertinoIcons.speaker_slash_fill,
            size: 22,
            color: CupertinoColors.activeGreen,
          ),
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            color: cupertinoTheme.scaffoldBackgroundColor,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyStateScrollable()
                      : CupertinoScrollbar(
                          child: ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message =
                                  _messages[_messages.length - 1 - index];
                              return _buildMessageBubble(message);
                            },
                          ),
                        ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: LinearProgressIndicator(
                      color: CupertinoColors.activeGreen,
                      minHeight: 2,
                    ),
                  ),
                const SizedBox(height: 4),
                _buildInputBar(isDark: isDark, theme: cupertinoTheme),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================== HEADER / EMPTY ==================
  Widget _buildHeader() {
    final cupertinoTheme = CupertinoTheme.of(context);
    final isDark = cupertinoTheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF00B0FF)],
              ),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.leaf_arrow_circlepath,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HydroGrowBot 🤖',
                  style: cupertinoTheme.textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Haz preguntas sobre plagas, riego, nutrientes o envía una foto de tus plantas.',
                  style: cupertinoTheme.textTheme.textStyle.copyWith(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Empty state scrollable
  Widget _buildEmptyStateScrollable() {
    final cupertinoTheme = CupertinoTheme.of(context);
    final isDark = cupertinoTheme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF00B0FF)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.leaf_arrow_circlepath,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hola, soy HydroGrowBot 🌱',
                      textAlign: TextAlign.center,
                      style: cupertinoTheme.textTheme.textStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pregúntame sobre cuidados del invernadero, plagas, riego, fertilización o envíame una foto para analizarla.',
                      textAlign: TextAlign.center,
                      style: cupertinoTheme.textTheme.textStyle.copyWith(
                        fontSize: 13,
                        color: isDark
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: const [
                        _SuggestionChip(
                          text: '¿Qué cultivo es ideal para mi invernadero?',
                        ),
                        _SuggestionChip(
                          text: 'Tengo manchas en las hojas, ¿qué puede ser?',
                        ),
                        _SuggestionChip(text: 'Recomiéndame un plan de riego.'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================== INPUT BAR ==================
  Widget _buildInputBar({
    required bool isDark,
    required CupertinoThemeData theme,
  }) {
    final inputBgColor = isDark
        ? CupertinoColors.darkBackgroundGray.withOpacity(0.9)
        : CupertinoColors.secondarySystemBackground;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          // 📷 Botón cámara
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _handleCameraCapture,
            child: Icon(
              CupertinoIcons.camera_fill,
              size: 26,
              color: _isLoading
                  ? CupertinoColors.inactiveGray
                  : CupertinoColors.systemGreen,
            ),
          ),
          // 🖼️ Botón galería
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _handleImagePicker,
            child: Icon(
              CupertinoIcons.photo_fill_on_rectangle_fill,
              size: 26,
              color: _isLoading
                  ? CupertinoColors.inactiveGray
                  : CupertinoColors.systemBlue,
            ),
          ),
          // 🎤 Botón micrófono (nota de voz al bot)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _toggleListening,
            child: Icon(
              _isListening
                  ? CupertinoIcons.mic_circle_fill
                  : CupertinoIcons.mic_circle,
              size: 28,
              color: _isLoading
                  ? CupertinoColors.inactiveGray
                  : CupertinoColors.systemRed,
            ),
          ),
          const SizedBox(width: 4),
          // Campo de texto (para escribir normal)
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 110, // aprox. 4 líneas
              ),
              child: CupertinoTextField(
                controller: _controller,
                placeholder: 'Escribe aquí sobre tu invernadero...',
                onSubmitted: (_) => _handleSend(),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                style: theme.textTheme.textStyle.copyWith(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                placeholderStyle: theme.textTheme.textStyle.copyWith(
                  fontSize: 14,
                  color: isDark
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.systemGrey,
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón enviar texto
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _handleSend,
            child: Icon(
              CupertinoIcons.arrow_up_circle_fill,
              size: 30,
              color: _isLoading
                  ? CupertinoColors.inactiveGray
                  : CupertinoColors.activeGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ================== BURBUJA DE MENSAJE ==================
  Widget _buildMessageBubble(Message message) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final isDark = cupertinoTheme.brightness == Brightness.dark;
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.75;

    final Color bubbleColor;
    final Color textColor;

    if (isUser) {
      // 🧑‍💬 Usuario: verde pastel más intenso (#BFFF8A)
      bubbleColor = const Color(0xFFBFFF8A);
      textColor = CupertinoColors.black;
    } else {
      // 🤖 Bot: también con la paleta
      if (isDark) {
        bubbleColor = const Color(0xFFDBFF95); // un poco más fuerte
      } else {
        bubbleColor = const Color(0xFFEEFFCD); // muy suave
      }
      textColor = CupertinoColors.black;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 6, top: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00B0FF)],
                ),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.leaf_arrow_circlepath,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        File(message.imagePath!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (isUser)
                    // Usuario
                    (message.isVoice
                        // 🎤 Nota de voz: NO mostramos el texto
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                CupertinoIcons.mic_fill,
                                size: 18,
                                color: CupertinoColors.black,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Mensaje de voz',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.black,
                                ),
                              ),
                            ],
                          )
                        // Mensaje escrito normal
                        : Text(
                            message.text,
                            style: TextStyle(color: textColor, fontSize: 14),
                          ))
                  else
                    // Bot
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 14, color: textColor),
                      ),
                    ),
                  if (!isUser && message.videoQuery != null) ...[
                    const SizedBox(height: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: CupertinoColors.systemRed,
                      borderRadius: BorderRadius.circular(18),
                      onPressed: () =>
                          _launchYouTubeSearch(message.videoQuery!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.play_circle_fill,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              message.videoQuery!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

// ================== CHIPS DE SUGERENCIA ==================
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AssistantPageState>();
    final isLoading = state?._isLoading ?? false;
    final cupertinoTheme = CupertinoTheme.of(context);
    final isDark = cupertinoTheme.brightness == Brightness.dark;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isDark
          ? CupertinoColors.darkBackgroundGray
          : CupertinoColors.systemGrey6,
      borderRadius: BorderRadius.circular(20),
      onPressed: isLoading
          ? null
          : () {
              if (state == null) return;
              state._controller.text = text;
              state._handleSend();
            },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
      ),
    );
  }
}
