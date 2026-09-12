import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';

/// A single icon/label/value row, shared by [MinigameGameOverOverlay] and
/// [MinigameVictoryOverlay].
class MinigameStatRow extends StatelessWidget {
  const MinigameStatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final String icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: NeonColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? NeonColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
