// lib/pages/dashboard_page.dart

import 'dart:ui'; // 👈 para BackdropFilter (efecto glass)
import 'package:flutter/cupertino.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/mqtt_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // MQTT
  final _mqtt = MqttService.I;

  bool _vent1 = false;
  bool _vent2 = false;
  bool _tiraLed = false;

  // Reconocimiento de voz
  late final stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();

    // Conecta a HiveMQ
    _mqtt.connect();

    // Inicializar STT
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  // ================== VOZ ==================

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (_) {},
      onError: (_) {},
    );
    if (mounted) setState(() {});
  }

  /// Inicia escucha por voz (es-MX)
  Future<void> _startListening() async {
    if (!_speechAvailable) return;

    await _speech.listen(
      localeId: 'es_MX',
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        _handleVoiceCommand(text);
      },
    );
    setState(() => _isListening = true);
  }

  /// Detiene escucha
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  /// Interpreta lo que dijo el usuario y manda comandos MQTT
  void _handleVoiceCommand(String text) {
    // ---- Ventiladores ----
    if (text.contains('ventilador') || text.contains('ventiladores')) {
      final encender =
          text.contains('enciende') ||
          text.contains('prende') ||
          text.contains('prénd');
      final apagar = text.contains('apaga') || text.contains('apagar');

      if (encender || apagar) {
        final turnOn = encender;

        if (text.contains('uno') || text.contains('1')) {
          _setVentilador(1, turnOn);
        } else if (text.contains('dos') || text.contains('2')) {
          _setVentilador(2, turnOn);
        } else {
          // si no dijo cuál, aplicamos a ambos
          _setVentilador(1, turnOn);
          _setVentilador(2, turnOn);
        }
      }
    }

    // ---- Tira LED / luces ----
    if (text.contains('tira led') ||
        (text.contains('tira') && text.contains('led')) ||
        text.contains('luces') ||
        text.contains('luz')) {
      final encender =
          text.contains('enciende') ||
          text.contains('prende') ||
          text.contains('prénd');
      final apagar = text.contains('apaga') || text.contains('apagar');

      if (encender || apagar) {
        final turnOn = encender;
        _setTiraLed(turnOn);
      }
    }
  }

  // ================== COMANDOS MQTT ==================

  void _setVentilador(int index, bool on) {
    setState(() {
      if (index == 1) {
        _vent1 = on;
      } else if (index == 2) {
        _vent2 = on;
      }
    });
    _mqtt.setVentilador(index, on);
  }

  void _setTiraLed(bool on) {
    setState(() => _tiraLed = on);
    _mqtt.setLuz(on);
  }

  // ================== UI FLUTTER ==================

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: isDark
                ? const Color.fromARGB(255, 0, 0, 0)
                : CupertinoColors.black,
          ),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ===== Ambiente (DHT22) =====
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: const Text(
                      'Ambiente (DHT22)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<double?>(
                            valueListenable: _mqtt.temperatura,
                            builder: (_, value, __) {
                              return _GaugeCard(
                                title: 'Temperatura (°C)',
                                value: value,
                                min: 0,
                                max: 60,
                                unit: '°C',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ValueListenableBuilder<double?>(
                            valueListenable: _mqtt.humedad,
                            builder: (_, value, __) {
                              return _GaugeCard(
                                title: 'Humedad (%)',
                                value: value,
                                min: 0,
                                max: 100,
                                unit: '%',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== Ventiladores =====
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: const Text(
                      'Ventiladores',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SwitchCard(
                            label: 'Ventilador 1',
                            value: _vent1,
                            onChanged: (v) => _setVentilador(1, v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SwitchCard(
                            label: 'Ventilador 2',
                            value: _vent2,
                            onChanged: (v) => _setVentilador(2, v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== Luz LED =====
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: const Text(
                      'Luz LED',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: _SwitchCard(
                      label: 'Tira LED',
                      value: _tiraLed,
                      onChanged: _setTiraLed,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),

            // Botón flotante de voz (glass, transparentoso)
            Positioned(
              right: 20,
              bottom: 28,
              child: _VoiceButton(
                isListening: _isListening,
                onTap: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con esquinas iOS
class _Card extends StatelessWidget {
  final double? height;
  final Widget child;

  const _Card({this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Gauge semicircular nativo (sin Material)
class _GaugeCard extends StatelessWidget {
  final String title;
  final double min;
  final double max;
  final double? value;
  final String unit;

  const _GaugeCard({
    required this.title,
    required this.min,
    required this.max,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final v = value ?? min;
    final pct = ((v - min) / (max - min)).clamp(0.0, 1.0);

    return _Card(
      height: 190,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: CustomPaint(
                  size: const Size(140, 80),
                  painter: _GaugePainter(
                    percentage: pct,
                    color: CupertinoColors.activeGreen,
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                value == null
                    ? '-- $unit'
                    : '${value!.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    final bgPaint = Paint()
      ..color = CupertinoColors.systemGrey4
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Fondo
    canvas.drawArc(rect, 3.14, 3.14, false, bgPaint);
    // Progreso
    canvas.drawArc(rect, 3.14, 3.14 * percentage, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Tarjeta para un switch tipo iOS
class _SwitchCard extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
            CupertinoSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Botón flotante circular para el micrófono (glass, transparentoso)
class _VoiceButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _VoiceButton({required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color accent = isListening
        ? CupertinoColors.systemRed
        : CupertinoColors.activeGreen;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withOpacity(0.30),
                  CupertinoColors.systemGrey6.withOpacity(0.08),
                ],
              ),
              border: Border.all(color: accent.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isListening ? CupertinoIcons.mic_fill : CupertinoIcons.mic,
              color: accent,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
