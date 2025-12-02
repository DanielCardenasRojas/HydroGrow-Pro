// lib/pages/home_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dashboard_page.dart';
import 'plants_page.dart';
import 'assistant_page.dart';
import 'profile_page.dart';
import 'reminders_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _deviceToken;
  bool _loadingToken = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceToken();
  }

  Future<void> _loadDeviceToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // iOS: pedir permiso (en Android no pasa nada malo)
      await messaging.requestPermission();

      // Token REAL del dispositivo
      final token = await messaging.getToken();

      if (!mounted) return; // 👈 importante

      setState(() {
        _deviceToken = token;
        _loadingToken = false;
      });
    } catch (e) {
      if (!mounted) return; // 👈 también aquí

      setState(() {
        _deviceToken = null;
        _loadingToken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.speedometer),
            label: 'Panel',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: 'Plantas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'Asistente',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bell),
            label: 'Recordatorios',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle),
            label: 'Perfil',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (_) => const DashboardPage());
          case 1:
            return CupertinoTabView(builder: (_) => const PlantsPage());
          case 2:
            return CupertinoTabView(builder: (_) => const AssistantPage());
          case 3:
            // Pestaña Recordatorios
            return CupertinoTabView(
              builder: (_) {
                if (_loadingToken) {
                  return const CupertinoPageScaffold(
                    child: Center(child: CupertinoActivityIndicator()),
                  );
                }

                if (_deviceToken == null) {
                  return const CupertinoPageScaffold(
                    navigationBar: CupertinoNavigationBar(
                      middle: Text('Recordatorios'),
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No se pudo obtener el token de notificaciones.\n'
                          'Revisa la configuración de Firebase Messaging.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }

                return RemindersPage(deviceToken: _deviceToken!);
              },
            );
          default:
            return CupertinoTabView(builder: (_) => const ProfilePage());
        }
      },
    );
  }
}
