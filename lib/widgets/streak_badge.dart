import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_providers.dart';
import '../theme/neon_colors.dart';
import 'neon_border.dart';

/// Compact "game stat" pill for the study streak. Same
/// [userProfileStreamProvider] as before -- only the visual changed.
class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final theme = Theme.of(context);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (profile) {
        final days = profile.currentStreakDays;
        return NeonBorder(
          color: NeonColors.orange,
          radius: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: NeonColors.surface.withValues(alpha: 0.85),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                TweenAnimationBuilder<int>(
                  tween: IntTween(end: days),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, _) => Text(
                    '$value',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: NeonColors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  days == 1 ? 'DIA' : 'DIAS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: NeonColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
