// lib/pages/plants_page.dart

import 'dart:ui'; // para BackdropFilter (efecto glass)
import 'package:flutter/cupertino.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/mqtt_service.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  final _mqtt = MqttService.I;

  bool _bomba1 = false;
  bool _bomba2 = false;

  // 🎤 Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Reutilizamos la misma conexión MQTT
    _mqtt.connect();

    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  // ================== COMANDOS MQTT ==================

  void _setBomba(int index, bool on) {
    setState(() {
      if (index == 1) {
        _bomba1 = on;
      } else if (index == 2) {
        _bomba2 = on;
      }
    });
    _mqtt.setBomba(index, on);
  }

  void _setBombasAll(bool on) {
    // Actualiza UI
    setState(() {
      _bomba1 = on;
      _bomba2 = on;
    });
    // Publica a las 2 bombas
    _mqtt.setBombasAll(on);
  }

  // ================== VOZ: ESCUCHAR Y PARSEAR COMANDOS ==================

  Future<void> _toggleListening() async {
    if (_isListening) {
      _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

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

    if (!available || !mounted) return;

    setState(() => _isListening = true);

    _speech.listen(
      localeId: 'es-MX',
      onResult: (result) {
        if (!mounted) return;

        if (result.finalResult) {
          setState(() => _isListening = false);
          _speech.stop();

          final command = result.recognizedWords.trim();
          if (command.isNotEmpty) {
            _handleVoiceCommand(command);
          }
        }
      },
    );
  }

  void _handleVoiceCommand(String raw) {
    final text = raw.toLowerCase();

    int? bombaIndex;
    bool? turnOn;

    // ------------ ENCENDER / APAGAR ------------
    // Encender
    if (text.contains('prende') ||
        text.contains('enciende') ||
        text.contains('encender') ||
        text.contains('activar') ||
        text.contains('activa')) {
      turnOn = true;
    }

    // Apagar
    if (text.contains('apaga') ||
        text.contains('apagar') ||
        text.contains('desactiva') ||
        text.contains('desactivar')) {
      turnOn = false;
    }

    // Si ni siquiera sabemos si es prender/apagar, salimos
    if (turnOn == null) return;

    // ------------ ¿TODAS LAS BOMBAS? ------------
    final hasAllWord =
        text.contains('todas') ||
        text.contains('ambas') ||
        text.contains('las dos') ||
        text.contains('las 2');

    final mentionsBombas =
        text.contains('bomba') ||
        text.contains('bombas') ||
        text.contains('suelo') ||
        text.contains('suelos');

    final isAll = hasAllWord && mentionsBombas;

    if (isAll) {
      // "apaga todas las bombas", "prende ambas bombas", etc.
      _setBombasAll(turnOn);
      return;
    }

    // ------------ UNA SOLA BOMBA / SUELO ------------

    // Identificar bomba / suelo individual
    if (text.contains('bomba 1') ||
        text.contains('bomba uno') ||
        text.contains('suelo 1') ||
        text.contains('suelo uno')) {
      bombaIndex = 1;
    } else if (text.contains('bomba 2') ||
        text.contains('bomba dos') ||
        text.contains('suelo 2') ||
        text.contains('suelo dos')) {
      bombaIndex = 2;
    }

    if (bombaIndex != null) {
      _setBomba(bombaIndex, turnOn);
    }
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Plantas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
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
            // ===== CONTENIDO SCROLLABLE (SUELOS / BOMBAS) =====
            CustomScrollView(
              slivers: [
                // ===== Suelo 1 =====
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Suelo 1',
                      style: const TextStyle(
                        fontSize: 18,
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
                      vertical: 4,
                    ),
                    child: ValueListenableBuilder<double?>(
                      valueListenable: _mqtt.suelo1,
                      builder: (_, value, __) {
                        return _SoilCard(
                          title: 'Suelo 1 (%)',
                          value: value,
                          bombaLabel: 'Bomba 1',
                          bombaValue: _bomba1,
                          onBombaChanged: (v) => _setBomba(1, v),
                        );
                      },
                    ),
                  ),
                ),

                // ===== Suelo 2 =====
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Suelo 2',
                      style: const TextStyle(
                        fontSize: 18,
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
                      vertical: 4,
                    ),
                    child: ValueListenableBuilder<double?>(
                      valueListenable: _mqtt.suelo2,
                      builder: (_, value, __) {
                        return _SoilCard(
                          title: 'Suelo 2 (%)',
                          value: value,
                          bombaLabel: 'Bomba 2',
                          bombaValue: _bomba2,
                          onBombaChanged: (v) => _setBomba(2, v),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),

            // ===== MICRÓFONO FLOTANTE GLASS (MISMO ESTILO QUE DASHBOARD) =====
            Positioned(
              right: 20,
              bottom: 28,
              child: _VoiceButton(
                isListening: _isListening,
                onTap: _toggleListening,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de suelo: gauge + switch de bomba
class _SoilCard extends StatelessWidget {
  final String title;
  final double? value;
  final String bombaLabel;
  final bool bombaValue;
  final ValueChanged<bool> onBombaChanged;

  const _SoilCard({
    required this.title,
    required this.value,
    required this.bombaLabel,
    required this.bombaValue,
    required this.onBombaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final v = value ?? 0;
    final pct = v.clamp(0, 100);

    // Color tipo Node-RED: verde si hay humedad, gris si está en 0
    final Color gaugeColor = pct > 0
        ? CupertinoColors.activeGreen
        : CupertinoColors.systemGrey4;

    return _Card(
      height: 210,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título arriba centrado
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Gauge
            Expanded(
              child: Center(
                child: _Gauge(
                  value: pct.toDouble(),
                  min: 0,
                  max: 100,
                  color: gaugeColor,
                ),
              ),
            ),

            // Valor grande en el centro (debajo del gauge)
            Center(
              child: Text(
                value == null ? '-- %' : '${pct.toInt()} %',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Bomba + switch
            Row(
              children: [
                Text(bombaLabel, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                const Spacer(),
                CupertinoSwitch(value: bombaValue, onChanged: onBombaChanged),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta genérica
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Gauge semicircular
class _Gauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final Color color;

  const _Gauge({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return CustomPaint(
      size: const Size(140, 80),
      painter: _GaugePainter(percentage: pct, color: color),
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
