/// App shell with adaptive navigation for phones and desktop.
/// Uses NavigationBar on narrow screens (< 600dp) and NavigationRail on wide screens.
/// Provides three destinations: Library, Assistant, Settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_lesson_planner/core/providers.dart';
import 'package:ai_lesson_planner/features/library/library_screen.dart';
import 'package:ai_lesson_planner/features/assistant/assistant_screen.dart';
import 'package:ai_lesson_planner/features/settings/settings_screen.dart';
import 'package:ai_lesson_planner/features/plan_view/plan_workspace.dart';

/// Width threshold for switching between navigation styles.
/// Below 600dp uses bottom NavigationBar, above uses side NavigationRail.
const double _navBreakpoint = 600.0;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraftRestore());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Flush as soon as we leave the foreground; Android may kill us next.
    if (state != AppLifecycleState.resumed) {
      ref.read(planEditorProvider.notifier).flushDraft();
    }
  }

  Future<void> _offerDraftRestore() async {
    if (ref.read(planEditorProvider) != null) return;
    final store = ref.read(draftStoreProvider);
    final draft = await store.read();
    if (draft == null || !mounted) return;

    final restore = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Recover unsaved plan?'),
        content: Text('An unsaved plan from your last session was found: '
            '"${draft.plan.sharedSubTheme}".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Discard')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Recover')),
        ],
      ),
    );
    if (!mounted) return;

    if (restore == true) {
      ref
          .read(planEditorProvider.notifier)
          .load(draft.plan, savedId: draft.savedId, dirty: true);
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const PlanWorkspace()));
    } else {
      await store.clear();
    }
  }

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
