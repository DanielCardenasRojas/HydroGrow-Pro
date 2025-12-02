// lib/main.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Tus pantallas
import 'pages/login_page.dart';
import 'pages/home_page.dart';
// Asistente
import 'pages/assistant_page.dart';
// Página de recordatorios
import 'pages/reminders_page.dart';

// Tema
import 'theme_controller.dart';

// 👉 Servicio MQTT
import 'services/mqtt_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Carga variables de entorno (.env en la raíz)
  await dotenv.load(fileName: ".env");

  // 2) Inicializa Firebase
  await Firebase.initializeApp();

  // 3) Español para correos/flows de Firebase Auth
  FirebaseAuth.instance.setLanguageCode('es');

  // 4) Carga preferencia de tema antes de construir la app
  await ThemeController.I.load();

  // 5) (Opcional) Preparar MQTT (NO conecta aún, solo inicializa el singleton)
  MqttService.I;

  runApp(const HydroApp());
}

class HydroApp extends StatelessWidget {
  const HydroApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Reacciona cuando cambie el modo (Auto/Claro/Oscuro)
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeController.I.listenableMode,
      builder: (_, __, ___) {
        return Builder(
          builder: (ctx) {
            final brightness = ThemeController.I.resolveBrightness(ctx);
            return CupertinoApp(
              debugShowCheckedModeBanner: false,
              theme: CupertinoThemeData(
                brightness: brightness,
                primaryColor: CupertinoColors.activeGreen,
                scaffoldBackgroundColor:
                    CupertinoColors.systemGroupedBackground,
                barBackgroundColor: CupertinoColors.systemGrey6,
              ),
              onGenerateRoute: _onGenerateRoute,
              initialRoute: '/login',
            );
          },
        );
      },
    );
  }
}

Route<dynamic> _onGenerateRoute(RouteSettings s) {
  switch (s.name) {
    case '/login':
      return CupertinoPageRoute(builder: (_) => const LoginPage());
    case '/home':
      return CupertinoPageRoute(builder: (_) => const HomePage());
    // Asistente
    case '/assistant':
      return CupertinoPageRoute(builder: (_) => const AssistantPage());
    // Recordatorios
    case '/reminders':
      return CupertinoPageRoute(builder: (_) => const RemindersEntryPage());
    default:
      return CupertinoPageRoute(builder: (_) => const LoginPage());
  }
}

/// Widget de entrada que:
/// - Pide permisos de notificación
/// - Obtiene el deviceToken de FCM
/// - Lo pasa a RemindersPage
class RemindersEntryPage extends StatefulWidget {
  const RemindersEntryPage({super.key});

  @override
  State<RemindersEntryPage> createState() => _RemindersEntryPageState();
}

class _RemindersEntryPageState extends State<RemindersEntryPage> {
  String? _deviceToken;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initMessaging();
  }

  Future<void> _initMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Pide permisos (sobre todo iOS)
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();

      setState(() {
        _deviceToken = token;
        _loading = false;
      });
    } catch (e) {
      // Si falla, solo dejamos de "cargar" y mostramos mensaje genérico
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Recordatorios')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_deviceToken == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Recordatorios'),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: const Text(
              'No se pudo obtener el token de notificaciones.\n\n'
              'Revisa los permisos de la app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );
    }

    // Aquí ya tenemos token ✅
    return RemindersPage(deviceToken: _deviceToken!);
  }
}
