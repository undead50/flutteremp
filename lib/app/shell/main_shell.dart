import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/shell/relay_bottom_nav.dart';
import 'package:relay/core/theme/app_palette.dart';

/// Hosts the four tab branches. Each branch keeps its own navigation stack and
/// scroll position (IndexedStack), so switching tabs never reloads a screen.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: RelayBottomNav(
        currentIndex: navigationShell.currentIndex,
        // Tapping the active tab returns it to its root.
        onSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
      ),
    );
  }
}
