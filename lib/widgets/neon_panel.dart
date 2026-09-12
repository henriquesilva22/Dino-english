import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';

/// Shared decorated surface used by [NeonCard]/[NeonPanel]: a dark
/// translucent panel with a glowing border.
class _NeonSurface extends StatelessWidget {
  const _NeonSurface({
    required this.child,
    required this.padding,
    required this.borderRadius,
    required this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NeonColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A larger content panel (e.g. the study question, a full-width section)
/// -- same visual language as [NeonCard] but meant for bigger blocks of
/// content rather than a tappable action.
class NeonPanel extends StatelessWidget {
  const NeonPanel({
    required this.child,
    this.accentColor = NeonColors.cyan,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    super.key,
  });

  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return _NeonSurface(
      padding: padding,
      borderRadius: borderRadius,
      accentColor: accentColor,
      child: child,
    );
  }
}
