import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/level_curve.dart';
import '../providers/home_providers.dart';
import '../theme/neon_colors.dart';
import 'neon_border.dart';

/// Compact "game stat" pill showing level + XP + a thin animated progress
/// line to the next level. Reads the same [userProfileStreamProvider] and
/// the same pure [LevelCurve] math as before -- only the visual changed.
class XpLevelCard extends ConsumerWidget {
  const XpLevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final theme = Theme.of(context);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (profile) {
        final curve = LevelCurve();
        final xpIntoLevel = curve.xpIntoCurrentLevel(profile.totalXp);
        final xpNeeded = curve.xpToNextLevel(profile.currentLevel);
        final progress = xpNeeded > 0 ? xpIntoLevel / xpNeeded : 1.0;

        return NeonBorder(
          color: NeonColors.purple,
          radius: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: NeonColors.surface.withValues(alpha: 0.85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.totalXp} XP',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: NeonColors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· Nível ${profile.currentLevel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NeonColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 120,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: progress.clamp(0, 1).toDouble()),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: NeonColors.purple.withValues(
                          alpha: 0.15,
                        ),
                        color: NeonColors.purple,
                      ),
                    ),
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
