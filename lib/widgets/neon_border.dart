import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';

/// Static glowing border: a solid stroke plus a layered box-shadow glow.
/// No [CustomPainter] needed -- same technique already used by
/// `PrimaryStudyButton`/`EggShowcase` in the Home screen.
class NeonBorder extends StatelessWidget {
  const NeonBorder({
    required this.child,
    this.color = NeonColors.cyan,
    this.radius = 20,
    this.borderWidth = 1.5,
    this.glow = true,
    super.key,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double borderWidth;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.8), width: borderWidth),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - borderWidth),
        child: child,
      ),
    );
  }
}
