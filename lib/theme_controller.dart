import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeController {
  ThemeController._();
  static final ThemeController I = ThemeController._();

  /// Modo actual observable por la UI
  final ValueNotifier<AppThemeMode> listenableMode =
      ValueNotifier<AppThemeMode>(AppThemeMode.system);

  /// Carga la preferencia guardada
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString('themeMode') ?? 'system';
      final m = AppThemeMode.values.firstWhere(
        (e) => e.name == s,
        orElse: () => AppThemeMode.system,
      );
      listenableMode.value = m;
    } catch (_) {}
  }

  /// Establece y persiste la preferencia
  Future<void> setMode(AppThemeMode mode) async {
    listenableMode.value = mode;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('themeMode', mode.name);
    } catch (_) {}
  }

  /// Resuelve brillo según la preferencia
  Brightness resolveBrightness(BuildContext context) {
    switch (listenableMode.value) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
      default:
        return MediaQuery.maybeOf(context)?.platformBrightness ??
            Brightness.light;
    }
  }
}
