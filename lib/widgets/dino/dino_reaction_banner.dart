import 'package:flutter/material.dart';

import '../../theme/neon_colors.dart';
import 'dino_reaction_copy.dart';

/// Shows the Dino's reaction after a "Montar Frase" submission -- same
/// bordered-box feedback style as `study_screen.dart`'s `_FeedbackBanner`.
class DinoReactionBanner extends StatelessWidget {
  const DinoReactionBanner({
    required this.isCorrect,
    required this.streakThisSession,
    super.key,
  });

  final bool isCorrect;
  final int streakThisSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect ? NeonColors.green : NeonColors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        dinoReactionMessage(
          isCorrect: isCorrect,
          streakThisSession: streakThisSession,
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: NeonColors.textPrimary,
        ),
      ),
    );
  }
}
