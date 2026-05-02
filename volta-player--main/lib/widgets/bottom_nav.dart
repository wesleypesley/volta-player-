import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNav extends StatelessWidget {
  final String currentRoute;

  const CustomBottomNav({super.key, required this.currentRoute});

  int _getSelectedIndex() {
    if (currentRoute.startsWith('/player')) return 0;
    if (currentRoute.startsWith('/downloads')) return 1;
    if (currentRoute.startsWith('/search')) return 2;
    if (currentRoute.startsWith('/library')) return 3;
    if (currentRoute.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/player');
        break;
      case 1:
        context.go('/downloads');
        break;
      case 2:
        context.go('/search');
        break;
      case 3:
        context.go('/library');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getSelectedIndex(),
      onTap: (index) => _onItemTapped(index, context),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_outline),
          activeIcon: Icon(Icons.play_circle_filled),
          label: 'Player',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.download_outlined),
          activeIcon: Icon(Icons.download),
          label: 'Downloads',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search_rounded),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music_outlined),
          activeIcon: Icon(Icons.library_music),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
