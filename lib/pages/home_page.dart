import 'package:flutter/cupertino.dart';
import 'dashboard_page.dart';
import 'plants_page.dart';
import 'assistant_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.speedometer),
            label: 'Panel prueba',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.star_lefthalf_fill),
            label: 'Plantas',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_text),
            label: 'Asistentee',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (_) => DashboardPage());
          case 1:
            return CupertinoTabView(builder: (_) => PlantsPage());
          default:
            return CupertinoTabView(builder: (_) => AssistantPage());
        }
      },
    );
  }
}
