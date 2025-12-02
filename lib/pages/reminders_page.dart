// lib/pages/reminders_page.dart

import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// ===================== UTILS =====================

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Modelo simple para lo que entendimos del comando de voz
class ParsedReminder {
  final String title;
  final DateTime dateTime;

  ParsedReminder(this.title, this.dateTime);
}

/// Parser MUY sencillo de frases en español.
///
/// Ejemplos que debería entender "más o menos":
/// - "pon un recordatorio hoy a las 3 pm que riegue las plantas"
/// - "recuérdame mañana a las 9 revisar nutrientes"
/// - "establece un recordatorio pasado mañana en la tarde que fertilice"
ParsedReminder parseSpanishReminder(String text) {
  final now = DateTime.now();
  var lower = text.toLowerCase().trim();

  // ---------- Día ----------
  DateTime baseDate = DateTime(now.year, now.month, now.day);

  // Diferenciar "mañana" (día siguiente) de "de la mañana / en la mañana / por la mañana"
  final hasPasadoManana = lower.contains('pasado mañana');

  final hasMananaSolo =
      RegExp(r'\bmañana\b').hasMatch(lower) &&
      !lower.contains('de la mañana') &&
      !lower.contains('en la mañana') &&
      !lower.contains('por la mañana');

  if (hasPasadoManana) {
    baseDate = baseDate.add(const Duration(days: 2));
  } else if (hasMananaSolo) {
    // "mañana" como día siguiente
    baseDate = baseDate.add(const Duration(days: 1));
  } else if (lower.contains('hoy')) {
    // ya es hoy
  }

  // Fecha explícita dd/mm o dd-mm
  final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})');
  final dateMatch = dateRegex.firstMatch(lower);
  if (dateMatch != null) {
    final d = int.parse(dateMatch.group(1)!);
    final m = int.parse(dateMatch.group(2)!);
    baseDate = DateTime(now.year, m, d);
  }

  // ---------- Hora ----------
  int hour = now.hour + 1; // fallback si no encontramos nada
  int minute = 0;

  // Patrón de am/pm con o sin espacios y puntos: am, pm, a.m., a. m., etc.
  const ampmPattern = r'(am|pm|a\.?\s?m\.?|p\.?\s?m\.?)';

  // 1) Intentar con "a las"/"a la"
  final timeRegexConALas = RegExp(
    r'(?:a las|a la)\s+(\d{1,2})'
    r'(?:(?:[:\.]\s*(\d{1,2}))|\s+(\d{1,2}))?'
    '\\s*$ampmPattern?',
  );

  // 2) Si no lo encuentra, buscar cualquier hora tipo "1:10 am" o "1 10 am"
  final timeRegexGeneral = RegExp(
    r'\b(\d{1,2})'
    r'(?:(?:[:\.]\s*(\d{1,2}))|\s+(\d{1,2}))?'
    '\\s*$ampmPattern',
  );

  RegExpMatch? tMatch = timeRegexConALas.firstMatch(lower);

  if (tMatch == null) {
    tMatch = timeRegexGeneral.firstMatch(lower);
  }

  if (tMatch != null) {
    // group(1) = hora
    // group(2) o group(3) = minutos
    // algún grupo más adelante = am/pm
    hour = int.parse(tMatch.group(1)!);
    final minuteStr = tMatch.group(2) ?? tMatch.group(3);
    if (minuteStr != null) {
      minute = int.parse(minuteStr);
    }

    String? ampm;
    for (int i = 4; i <= tMatch.groupCount; i++) {
      final g = tMatch.group(i);
      if (g != null) ampm = g;
    }

    if (ampm != null) {
      ampm = ampm.replaceAll(' ', ''); // "a.m." / "a. m." -> "a.m."
      final isPm = ampm.contains('p');
      final isAm = ampm.contains('a');

      if (isPm && hour < 12) {
        hour += 12; // 3 pm -> 15
      }
      if (isAm && hour == 12) {
        hour = 0; // 12 am -> 00
      }
    }
  } else {
    // Si no encontramos formato de hora explícito,
    // usamos heurísticas tipo "por la tarde / noche / mañana"
    if (lower.contains('en la tarde') || lower.contains('por la tarde')) {
      hour = 18;
    } else if (lower.contains('en la noche') ||
        lower.contains('por la noche')) {
      hour = 21;
    } else if (lower.contains('en la mañana') ||
        lower.contains('por la mañana') ||
        lower.contains('de la mañana')) {
      hour = 9;
    }
  }

  final dateTime = DateTime(
    baseDate.year,
    baseDate.month,
    baseDate.day,
    hour,
    minute,
  );

  // ---------- Título ----------
  String title = lower;

  // quitar frases típicas del inicio
  for (final prefix in [
    'pon un recordatorio para',
    'pon un recordatorio',
    'establece un recordatorio para',
    'establece un recordatorio',
    'establecer un recordatorio',
    'recuérdame',
    'recuerdame',
    'quiero un recordatorio de',
  ]) {
    if (title.startsWith(prefix)) {
      title = title.substring(prefix.length).trim();
      break;
    }
  }

  // si contiene "que ..." usamos lo que viene después
  final idxQue = title.indexOf('que ');
  if (idxQue != -1) {
    title = title.substring(idxQue + 4).trim();
  }

  if (title.isEmpty) {
    title = 'Recordatorio';
  }

  // Capitalizar primera letra
  final prettyTitle = title[0].toUpperCase() + title.substring(1);

  return ParsedReminder(prettyTitle, dateTime);
}

/// ===================== SERVICE: n8n / PUSH =====================

class ReminderService {
  final Dio _dio = Dio();

  // 👇 Production URL de tu webhook en n8n (SIN -test)
  static const String _webhookUrl =
      'https://danielarr08.app.n8n.cloud/webhook/nuevo-recordatorio';

  Future<void> crearRecordatorio({
    required String title,
    required String body,
    required DateTime dateTime,
    required String deviceToken,
  }) async {
    final payload = {
      'title': title,
      'body': body,
      'datetime': dateTime.toUtc().toIso8601String(),
      'deviceToken': deviceToken,
    };

    await _dio.post(_webhookUrl, data: payload);
  }
}

/// ===================== MODEL =====================

class Reminder {
  final String title;
  final DateTime dateTime;
  final bool fromVoice;

  Reminder({
    required this.title,
    required this.dateTime,
    this.fromVoice = false,
  });
}

/// ===================== PANTALLA PRINCIPAL =====================
/// Muestra la lista y botones para crear manual o por voz

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.deviceToken});

  /// Token real de FCM de este dispositivo
  final String deviceToken;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final List<Reminder> _reminders = [];

  void _addReminder(Reminder reminder) {
    setState(() {
      _reminders.add(reminder);
      _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  Future<void> _openManualReminder() async {
    final reminder = await Navigator.of(context).push<Reminder>(
      CupertinoPageRoute(
        builder: (_) => ManualReminderPage(deviceToken: widget.deviceToken),
      ),
    );

    if (reminder != null && mounted) {
      _addReminder(reminder);
    }
  }

  Future<void> _openVoiceReminder() async {
    final reminder = await Navigator.of(context).push<Reminder>(
      CupertinoPageRoute(
        builder: (_) => VoiceReminderPage(deviceToken: widget.deviceToken),
      ),
    );

    if (reminder != null && mounted) {
      _addReminder(reminder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Recordatorios'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openVoiceReminder,
              child: const Icon(CupertinoIcons.mic_fill, size: 24),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openManualReminder,
              child: const Icon(CupertinoIcons.add_circled_solid, size: 26),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: _reminders.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  return _buildReminderTile(reminder);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.bell_solid,
              size: 60,
              color: CupertinoColors.activeGreen,
            ),
            const SizedBox(height: 12),
            const Text(
              'Aún no tienes recordatorios',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea un recordatorio manualmente o usando tu voz, '
              'y se programará una notificación push.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _openManualReminder,
              child: const Text('Añadir recordatorio'),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              onPressed: _openVoiceReminder,
              child: const Text('Crear con voz'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTile(Reminder reminder) {
    final date = reminder.dateTime;
    final formatted =
        '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}  '
        '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            reminder.fromVoice
                ? CupertinoIcons.mic_fill
                : CupertinoIcons.pencil,
            size: 22,
            color: CupertinoColors.activeGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatted,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: CupertinoColors.activeGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Programado',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.activeGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================== PÁGINA: RECORDATORIO MANUAL =====================

class ManualReminderPage extends StatefulWidget {
  const ManualReminderPage({super.key, required this.deviceToken});

  final String deviceToken;

  @override
  State<ManualReminderPage> createState() => _ManualReminderPageState();
}

class _ManualReminderPageState extends State<ManualReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isSaving = false;

  final ReminderService _service = ReminderService();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => _CupertinoBottomSheet(
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _selectedDateTime,
          minimumDate: DateTime.now(),
          onDateTimeChanged: (value) {
            _selectedDateTime = DateTime(
              value.year,
              value.month,
              value.day,
              _selectedDateTime.hour,
              _selectedDateTime.minute,
            );
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => _CupertinoBottomSheet(
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: _selectedDateTime,
          onDateTimeChanged: (value) {
            _selectedDateTime = DateTime(
              _selectedDateTime.year,
              _selectedDateTime.month,
              _selectedDateTime.day,
              value.hour,
              value.minute,
            );
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _saveReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await _service.crearRecordatorio(
        title: title,
        body: 'Recordatorio de HydroGrowPro',
        dateTime: _selectedDateTime,
        deviceToken: widget.deviceToken,
      );

      final reminder = Reminder(
        title: title,
        dateTime: _selectedDateTime,
        fromVoice: false,
      );

      if (!mounted) return;
      Navigator.of(context).pop(reminder);
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('No se pudo crear el recordatorio:\n$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha =
        '${_twoDigits(_selectedDateTime.day)}/${_twoDigits(_selectedDateTime.month)}/${_selectedDateTime.year}';
    final hora =
        '${_twoDigits(_selectedDateTime.hour)}:${_twoDigits(_selectedDateTime.minute)}';

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Nuevo recordatorio'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Título', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _titleController,
                placeholder: 'Ej. Revisar riego del invernadero',
              ),
              const SizedBox(height: 20),
              const Text('Fecha', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                onPressed: _pickDate,
                color: CupertinoColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.calendar,
                      size: 20,
                      color: CupertinoColors.activeGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(fecha, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Hora', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                onPressed: _pickTime,
                color: CupertinoColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.time,
                      size: 20,
                      color: CupertinoColors.activeGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(hora, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const Spacer(),
              CupertinoButton.filled(
                onPressed: _isSaving ? null : _saveReminder,
                child: _isSaving
                    ? const CupertinoActivityIndicator()
                    : const Text('Guardar recordatorio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===================== PÁGINA: RECORDATORIO POR VOZ (TODO VOZ) =====================

class VoiceReminderPage extends StatefulWidget {
  const VoiceReminderPage({super.key, required this.deviceToken});

  final String deviceToken;

  @override
  State<VoiceReminderPage> createState() => _VoiceReminderPageState();
}

class _VoiceReminderPageState extends State<VoiceReminderPage> {
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isSaving = false;

  String _rawText = '';
  ParsedReminder? _parsed;

  final ReminderService _service = ReminderService();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
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

      if (available) {
        if (!mounted) return;
        setState(() {
          _isListening = true;
          _rawText = '';
          _parsed = null;
        });

        _speech.listen(
          localeId: 'es-MX',
          onResult: (result) {
            if (!mounted) return;

            setState(() {
              _rawText = result.recognizedWords;
            });

            if (result.finalResult) {
              final parsed = parseSpanishReminder(result.recognizedWords);

              if (!mounted) return;
              setState(() {
                _parsed = parsed;
                _isListening = false;
              });

              if (!mounted) return;
              _confirmAndSave(parsed);
            }
          },
        );
      }
    } else {
      _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _confirmAndSave(ParsedReminder parsed) async {
    if (!mounted) return;

    final fecha =
        '${_twoDigits(parsed.dateTime.day)}/${_twoDigits(parsed.dateTime.month)}/${parsed.dateTime.year}';
    final hora =
        '${_twoDigits(parsed.dateTime.hour)}:${_twoDigits(parsed.dateTime.minute)}';

    await showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('¿Guardar este recordatorio?'),
        content: Text('"${parsed.title}"\n\n$fecha  $hora'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Guardar'),
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // cierra el diálogo
              if (!mounted) return;
              await _saveReminder(parsed);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveReminder(ParsedReminder parsed) async {
    if (_isSaving || !mounted) return;
    setState(() => _isSaving = true);

    try {
      await _service.crearRecordatorio(
        title: parsed.title,
        body: 'Recordatorio de HydroGrowBot',
        dateTime: parsed.dateTime,
        deviceToken: widget.deviceToken,
      );

      final reminder = Reminder(
        title: parsed.title,
        dateTime: parsed.dateTime,
        fromVoice: true,
      );

      if (!mounted) return;
      Navigator.of(context).pop(reminder);
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('No se pudo crear el recordatorio:\n$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final micColor = _isListening
        ? CupertinoColors.systemRed
        : CupertinoColors.activeGreen;

    final parsedText = _parsed == null
        ? ''
        : 'Entendido:\n"${_parsed!.title}"\n'
              'para el ${_twoDigits(_parsed!.dateTime.day)}/'
              '${_twoDigits(_parsed!.dateTime.month)}/'
              '${_parsed!.dateTime.year} '
              '${_twoDigits(_parsed!.dateTime.hour)}:'
              '${_twoDigits(_parsed!.dateTime.minute)}';

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Recordatorio por voz'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Dile algo como:\n'
                '"Establece un recordatorio hoy a las 3 pm y recuérdame que riegue las plantas"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (_rawText.isNotEmpty)
                Text(
                  'Escuchado:\n$_rawText',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 12),
              if (parsedText.isNotEmpty)
                Text(
                  parsedText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: micColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? CupertinoIcons.mic_fill : CupertinoIcons.mic,
                    size: 60,
                    color: micColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isListening
                    ? 'Escuchando...'
                    : 'Toca el micrófono para hablar',
              ),
              if (_isSaving) ...[
                const SizedBox(height: 16),
                const CupertinoActivityIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ===================== WIDGET REUSABLE: Sheet para pickers =====================

class _CupertinoBottomSheet extends StatelessWidget {
  const _CupertinoBottomSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      color: CupertinoColors.systemBackground,
      child: Column(
        children: [
          Expanded(child: child),
          CupertinoButton(
            child: const Text('Listo'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
