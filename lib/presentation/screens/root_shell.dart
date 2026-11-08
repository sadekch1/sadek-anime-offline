import 'package:flutter/material.dart';

import '../../core/strings.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: const [
        HomeScreen(),
        SearchScreen(),
        SettingsScreen(),
        LibraryScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: s.home),
          NavigationDestination(
              icon: const Icon(Icons.search_rounded), label: s.search),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: s.settings),
          NavigationDestination(
              icon: const Icon(Icons.bookmark_outlined),
              selectedIcon: const Icon(Icons.bookmark_rounded),
              label: s.library),
        ],
      ),
    );
  }
}
