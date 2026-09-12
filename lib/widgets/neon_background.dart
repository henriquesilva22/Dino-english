import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';

/// Full-bleed dark radial gradient behind every screen -- the shared
/// backdrop of the "Dino English Neon" design system.
class NeonBackground extends StatelessWidget {
  const NeonBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.4,
          colors: [Color(0xFF161C3C), NeonColors.background],
          stops: [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
