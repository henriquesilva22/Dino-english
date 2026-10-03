import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_providers.dart';
import '../theme/neon_colors.dart';
import 'animated_glow.dart';

class _NavDestination {
  const _NavDestination({
    required this.key,
    required this.icon,
    required this.label,
  });
  final String key;
  final String icon;
  final String label;
}

const _destinations = [
  _NavDestination(key: 'nav.home', icon: '🏠', label: 'HOME'),
  _NavDestination(key: 'nav.estudar', icon: '📚', label: 'ESTUDAR'),
  _NavDestination(key: 'nav.aventura', icon: '🐾', label: 'AVENTURA'),
  _NavDestination(key: 'nav.perfil', icon: '👤', label: 'PERFIL'),
];

/// Custom bottom navigation for the "Dino English Neon" design system --
/// deliberately not `BottomNavigationBar`/`NavigationBar` (the design
/// brief explicitly rules out stock Flutter buttons). The active item
/// gets an [AnimatedGlow] ring.
class NeonBottomNav extends ConsumerWidget {
  const NeonBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabIndexProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: NeonColors.surface,
        border: Border(
          top: BorderSide(color: NeonColors.cyan.withValues(alpha: 0.25)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _destinations.length; i++)
                _NavItem(
                  key: Key(_destinations[i].key),
                  destination: _destinations[i],
                  active: i == selected,
                  onTap: () =>
                      ref.read(selectedTabIndexProvider.notifier).select(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required super.key,
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? NeonColors.cyan : NeonColors.textSecondary;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(destination.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            destination.label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: active
          ? AnimatedGlow(
              color: NeonColors.cyan,
              borderRadius: 16,
              strokeWidth: 1.5,
              child: content,
            )
          : content,
    );
  }
}
