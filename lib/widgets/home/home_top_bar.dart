import 'package:flutter/material.dart';

import '../../theme/neon_colors.dart';
import '../streak_badge.dart';
import '../xp_level_card.dart';

/// Top row of the Home: short title + the streak and XP "game stat"
/// pills. Wraps so it never overflows on narrow phones.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            '🦖 Dino English',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: NeonColors.cyan,
              shadows: [
                Shadow(color: NeonColors.cyan.withValues(alpha: 0.6), blurRadius: 12),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: const [StreakBadge(), XpLevelCard()],
        ),
      ],
    );
  }
}
