// lib/main.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Tus pantallas y controlador de tema
import 'pages/login_page.dart';
import 'pages/home_page.dart';
// ⭐ IMPORTAR LA PÁGINA DEL ASISTENTE ⭐
import 'pages/assistant_page.dart';
import 'theme_controller.dart';

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
                // Si tu versión lo sopporta, mantenla; si no, elimínala:
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
    // ⭐ NUEVA RUTA PARA EL ASISTENTE ⭐
    case '/assistant':
      return CupertinoPageRoute(builder: (_) => const AssistantPage());
    default:
      return CupertinoPageRoute(builder: (_) => const LoginPage());
  }
}
