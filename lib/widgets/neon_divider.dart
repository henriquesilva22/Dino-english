import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';

/// A soft glowing horizontal rule -- fades in from transparent, peaks at
/// [color], fades back out.
class NeonDivider extends StatelessWidget {
  const NeonDivider({this.color = NeonColors.cyan, this.height = 2, super.key});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
