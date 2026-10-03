import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';
import 'animated_glow.dart';

enum AnswerOptionVisualState { idle, selected, correct, wrongSelected }

class AnswerOptionButton extends StatelessWidget {
  const AnswerOptionButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final AnswerOptionVisualState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color accent;
    Color background;
    switch (state) {
      case AnswerOptionVisualState.idle:
        accent = NeonColors.cyan.withValues(alpha: 0.35);
        background = NeonColors.surface;
      case AnswerOptionVisualState.selected:
        accent = NeonColors.cyan;
        background = NeonColors.cyan.withValues(alpha: 0.12);
      case AnswerOptionVisualState.correct:
        accent = NeonColors.green;
        background = NeonColors.green.withValues(alpha: 0.14);
      case AnswerOptionVisualState.wrongSelected:
        accent = NeonColors.red;
        background = NeonColors.red.withValues(alpha: 0.14);
    }

    final button = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: NeonColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    if (state == AnswerOptionVisualState.selected) {
      return AnimatedGlow(
        color: NeonColors.cyan,
        borderRadius: 16,
        child: button,
      );
    }
    return button;
  }
}
