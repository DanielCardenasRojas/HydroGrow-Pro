// lib/pages/assistant_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Solo para SnackBar y MaterialType (necesario a veces)
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir YouTube
import 'dart:io';
import 'dart:typed_data';
import '../services/gemini_service.dart';

// Clase para representar un mensaje
class Message {
  final String text;
  final bool isUser;
  final String? imagePath;
  final String? videoQuery;

  Message(this.text, this.isUser, {this.imagePath, this.videoQuery});
}

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  // Instanciación del servicio
  final InvernaderoChatService _chatService = InvernaderoChatService();
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // --- Lógica de Manejo de Respuestas ---
  // Extrae el texto y la consulta de video basada en el marcador
  (String, String?) _parseResponse(String rawResponse) {
    const marker = '---VIDEO SUGERIDO---';
    if (rawResponse.contains(marker)) {
      final parts = rawResponse.split(marker);
      final text = parts[0].trim();
      final videoQuery = parts[1].trim();
      return (text, videoQuery);
    }
    return (rawResponse, null);
  }

  // Envía el mensaje (puede ser texto o multimodal)
  void _handleSend({
    String? imagePath,
    String? prompt,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    if (_isLoading) return;

    final text = prompt ?? _controller.text.trim();
    if (text.isEmpty && imagePath == null) return;

    // 1. Mostrar mensaje del usuario
    setState(() {
      _messages.add(Message(text, true, imagePath: imagePath));
      _isLoading = true;
    });
    _controller.clear();

    String rawResponse;
    if (imagePath != null && imageBytes != null && mimeType != null) {
      // Multimodal: Envía imagen y prompt
      rawResponse = await _chatService.sendMultimodalMessage(
        text,
        imageBytes,
        mimeType,
      );
    } else {
      // Solo texto
      rawResponse = await _chatService.sendMessage(text);
    }

    // 2. Parsear respuesta (extraer videoQuery)
    final (botText, videoQuery) = _parseResponse(rawResponse);

    // 3. Mostrar respuesta del bot
    setState(() {
      _messages.add(Message(botText, false, videoQuery: videoQuery));
      _isLoading = false;
    });
  }

  // --- Lógica para Abrir YouTube ---
  Future<void> _launchYouTubeSearch(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://www.youtube.com/results?search_query=$encodedQuery',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // ⭐ CORRECCIÓN: Usar mounted para evitar el error de contexto asíncrono
      if (!mounted) return;

      // Mostrar notificación de error (usando Material SnackBar por simplicidad)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir YouTube.')),
      );
    }
  }

  // --- Lógica para Seleccionar Imagen ---
  Future<void> _handleImagePicker() async {
    if (_isLoading) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final imageFile = File(image.path);
      final imageBytes = await imageFile.readAsBytes();
      final mimeType = image.mimeType ?? 'image/jpeg';

      const prompt =
          "Analiza esta imagen e identifica la plaga, enfermedad o necesidad de esta planta de invernadero. Dame un diagnóstico y plan de acción.";

      _handleSend(
        imagePath: image.path,
        prompt: prompt,
        imageBytes: imageBytes.buffer.asUint8List(),
        mimeType: mimeType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // Barra de navegación estilo Cupertino
      navigationBar: CupertinoNavigationBar(
        middle: const Text('HydroGrowBot'),
        backgroundColor: CupertinoColors.activeGreen.withOpacity(0.95),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Área de mensajes
            Expanded(
              child: CupertinoScrollbar(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.only(top: 8.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - 1 - index];
                    return _buildMessageContainer(message);
                  },
                ),
              ),
            ),

            // Indicador de carga
            if (_isLoading)
              const LinearProgressIndicator(color: CupertinoColors.activeGreen),

            // Campo de entrada (CupertinoTextField)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CupertinoTextField(
                        controller: _controller,
                        placeholder: 'Pregunta sobre tu invernadero...',
                        onSubmitted: (value) => _handleSend(),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.extraLightBackgroundGray,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  // Botón para Imagen (Detección de Plagas)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isLoading ? null : _handleImagePicker,
                    child: Icon(
                      CupertinoIcons.camera,
                      color: _isLoading
                          ? CupertinoColors.inactiveGray
                          : CupertinoColors.systemGreen,
                    ),
                  ),
                  // Botón para Enviar Texto
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isLoading ? null : _handleSend,
                    child: Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      color: _isLoading
                          ? CupertinoColors.inactiveGray
                          : CupertinoColors.activeGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContainer(Message message) {
    final align = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser
        ? CupertinoColors.activeGreen.withOpacity(0.15)
        : CupertinoColors.systemGrey5;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenido de la burbuja (Imagen o Texto del Usuario/Bot)
            if (message.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.file(
                  File(message.imagePath!),
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.text,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
              const Divider(height: 12),
            ] else if (message.isUser) ...[
              Text(
                message.text,
                style: const TextStyle(color: CupertinoColors.black),
              ),
            ],

            // Respuesta del Bot (si no es un mensaje de usuario simple)
            if (!message.isUser || message.imagePath != null) ...[
              MarkdownBody(data: message.text),
            ],

            // ⭐ Botón de YouTube
            if (message.videoQuery != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                color: CupertinoColors.systemRed,
                onPressed: () => _launchYouTubeSearch(message.videoQuery!),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.play_circle_fill, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      message.videoQuery!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
