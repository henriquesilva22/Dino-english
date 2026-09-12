import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';
import 'neon_border.dart';

/// Compact boss HP bar shown by [MinigameHud] during a boss fight.
class BossHealthBar extends StatelessWidget {
  const BossHealthBar({required this.hp, required this.maxHp, super.key});

  final int hp;
  final int maxHp;

  @override
  Widget build(BuildContext context) {
    final fraction = maxHp <= 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    return NeonBorder(
      color: NeonColors.red,
      radius: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        color: NeonColors.surface.withValues(alpha: 0.75),
        child: Row(
          children: [
            Text(
              'CHEFE',
              style: const TextStyle(
                color: NeonColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: fraction),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: NeonColors.background,
                    valueColor: const AlwaysStoppedAnimation(NeonColors.red),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$hp/$maxHp',
              style: const TextStyle(
                color: NeonColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
