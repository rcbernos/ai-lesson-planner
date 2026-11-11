/// App shell with adaptive navigation for phones and desktop.
/// Uses NavigationBar on narrow screens (< 600dp) and NavigationRail on wide screens.
/// Provides three destinations: Library, Assistant, Settings.
library;

import 'package:flutter/material.dart';

import 'package:ai_lesson_planner/features/library/library_screen.dart';
import 'package:ai_lesson_planner/features/assistant/assistant_screen.dart';
import 'package:ai_lesson_planner/features/settings/settings_screen.dart';

/// Width threshold for switching between navigation styles.
/// Below 600dp uses bottom NavigationBar, above uses side NavigationRail.
const double _navBreakpoint = 600.0;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildStage() {
    switch (_selectedIndex) {
      case 0:
        return const LibraryScreen();
      case 1:
        return const AssistantScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const LibraryScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _navBreakpoint;

    if (isWide) {
      return _buildWideScaffold();
    } else {
      return _buildNarrowScaffold();
    }
  }

  /// Build for wide screens (>= 600dp) using NavigationRail on the left.
  Widget _buildWideScaffold() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            minExtendedWidth: 80,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.library_books_rounded),
                selectedIcon: Icon(Icons.library_books_rounded),
                label: Text('Library'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_awesome),
                selectedIcon: Icon(Icons.auto_awesome),
                label: Text('Assistant'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
          ),
          Expanded(child: _buildStage()),
        ],
      ),
    );
  }

  /// Build for narrow screens (< 600dp) using bottom NavigationBar.
  Widget _buildNarrowScaffold() {
    return Scaffold(
      body: _buildStage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        indicatorColor:
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        backgroundColor:
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_rounded),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
