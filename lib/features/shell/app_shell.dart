/// App shell with NavigationRail for desktop navigation.
/// Provides four destinations: Generator, Library, Assistant, Settings.
library;

import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<_NavigationDestination> _destinations = [
    _NavigationDestination(
      icon: Icons.table_view,
      activeIcon: Icons.table_view,
      label: 'Generator',
    ),
    _NavigationDestination(
      icon: Icons.library_books_rounded,
      activeIcon: Icons.library_books_rounded,
      label: 'Library',
    ),
    _NavigationDestination(
      icon: Icons.auto_awesome,
      activeIcon: Icons.auto_awesome,
      label: 'Assistant',
    ),
    _NavigationDestination(
      icon: Icons.settings,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildStage() {
    switch (_selectedIndex) {
      case 0:
        return const Center(
          child: Text('Generator'),
        );
      case 1:
        return const Center(
          child: Text('Library'),
        );
      case 2:
        return const Center(
          child: Text('Assistant'),
        );
      case 3:
        return const Center(
          child: Text('Settings'),
        );
      default:
        return const Center(
          child: Text('Generator'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: 1024,
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: _destinations.map((dest) {
                return NavigationRailDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(dest.activeIcon),
                  label: Text(dest.label),
                );
              }).toList(),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
            ),
            Expanded(
              child: _buildStage(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationDestination {
  const _NavigationDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
