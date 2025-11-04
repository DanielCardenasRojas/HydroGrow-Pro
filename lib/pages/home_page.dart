import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // <- para Icons.eco y Icons.smart_toy
import 'dashboard_page.dart';
import 'plants_page.dart';
import 'assistant_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.speedometer),
            label: 'Panel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco), // 🌿 plantita (Material)
            label: 'Plantas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy), // 🤖 robotcito (Material)
            label: 'Asistente',
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
          default:
            return CupertinoTabView(builder: (_) => const ProfilePage());
        }
      },
    );
  }
}
