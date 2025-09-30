import 'package:flutter/cupertino.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const HydroApp());
}

class HydroApp extends StatelessWidget {
  const HydroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeGreen,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        barBackgroundColor: CupertinoColors.systemGrey6,
      ),
      onGenerateRoute: _onGenerateRoute,
      initialRoute: '/login',
    );
  }
}

Route<dynamic> _onGenerateRoute(RouteSettings s) {
  switch (s.name) {
    case '/login':
      return CupertinoPageRoute(builder: (_) => const LoginPage());
    case '/home':
      return CupertinoPageRoute(builder: (_) => const HomePage());
    default:
      return CupertinoPageRoute(builder: (_) => const LoginPage());
  }
}
