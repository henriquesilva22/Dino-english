import 'package:flutter/material.dart';

import '../../game/word_slash/word_slash_bubble.dart';
import '../../theme/neon_colors.dart';

/// Renders one floating word bubble. Purely presentational -- the caller
/// wraps this in a `Positioned` using [bubble]'s position/radius; this
/// widget only draws the fixed-size circle itself. Wrapped in
/// [IgnorePointer] because cut detection is geometric (segment-vs-circle,
/// in `WordSlashBubble.intersectsSegment`), not Flutter's own widget
/// hit-testing -- the swipe `GestureDetector` lives on the play area,
/// above every bubble, and must see the whole continuous drag regardless
/// of what's visually underneath it.
class WordSlashBubbleWidget extends StatelessWidget {
  const WordSlashBubbleWidget({required this.bubble, this.isHit = false, super.key});

  final WordSlashBubble bubble;

  /// True while the in-flight swipe gesture has already crossed this
  /// bubble (`state.swipeHitBubbleIds`) -- gives the player immediate
  /// visual feedback that the cut registered, before `onPanEnd` resolves
  /// the whole gesture.
  final bool isHit;

  @override
  Widget build(BuildContext context) {
    final color = isHit
        ? NeonColors.red
        : (bubble.isPortuguese ? NeonColors.orange : NeonColors.cyan);
    final diameter = bubble.radius * 2;
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHit
              ? NeonColors.red.withValues(alpha: 0.35)
              : NeonColors.surface.withValues(alpha: 0.92),
          border: Border.all(color: color, width: isHit ? 3.5 : 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isHit ? 0.85 : 0.55),
              blurRadius: isHit ? 20 : 14,
              spreadRadius: isHit ? 3 : 1,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          bubble.text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: NeonColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: bubble.text.length > 7 ? 13 : 16,
          ),
        ),
      ),
    );
  }
}
