import 'package:flutter/material.dart';

import '../../theme/neon_colors.dart';

enum WordChipVisualState { idle, placed, correct, incorrect }

/// A single tappable word token -- same color-state pattern as
/// [AnswerOptionButton] (idle/selected/correct/wrong mapped to
/// [NeonColors]), but pill-shaped and compact so many can flow in a
/// [Wrap] for the sentence word bank/answer strip.
class WordChip extends StatelessWidget {
  const WordChip({
    required this.label,
    required this.state,
    this.onTap,
    super.key,
  });

  final String label;
  final WordChipVisualState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color accent;
    Color background;
    switch (state) {
      case WordChipVisualState.idle:
        accent = NeonColors.cyan.withValues(alpha: 0.35);
        background = NeonColors.surface;
      case WordChipVisualState.placed:
        accent = NeonColors.cyan;
        background = NeonColors.cyan.withValues(alpha: 0.12);
      case WordChipVisualState.correct:
        accent = NeonColors.green;
        background = NeonColors.green.withValues(alpha: 0.14);
      case WordChipVisualState.incorrect:
        accent = NeonColors.red;
        background = NeonColors.red.withValues(alpha: 0.14);
    }

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: NeonColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
