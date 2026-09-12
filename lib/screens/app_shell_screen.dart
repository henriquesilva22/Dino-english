import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_providers.dart';
import '../widgets/neon_bottom_nav.dart';
import 'home_screen.dart';
import 'pet_selection_screen.dart';
import 'profile_screen.dart';
import 'study_screen.dart';

/// App-wide tab shell. Each tab is mounted lazily -- only the first time
/// it's visited -- so `StudySessionController` (fires DB queries) and the
/// pet 3D viewer (a WebView) don't get created on app boot just because
/// they exist in the tree.
class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  final Set<int> _visitedTabs = {0};

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(selectedTabIndexProvider, (previous, next) {
      if (_visitedTabs.add(next)) setState(() {});
    });
    final selected = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: selected,
        children: [
          const HomeScreen(),
          _visitedTabs.contains(1) ? const StudyScreen() : const SizedBox.shrink(),
          _visitedTabs.contains(2) ? const PetSelectionScreen() : const SizedBox.shrink(),
          _visitedTabs.contains(3) ? const ProfileScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: const NeonBottomNav(),
    );
  }
}
