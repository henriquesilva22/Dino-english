import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';

/// A border with a soft light sweeping smoothly around it -- the signature
/// "neon" touch, used sparingly (selected states, emphasis) rather than
/// everywhere.
class AnimatedGlow extends StatefulWidget {
  const AnimatedGlow({
    required this.child,
    this.color = NeonColors.cyan,
    this.borderRadius = 20,
    this.strokeWidth = 2.5,
    this.duration = const Duration(milliseconds: 2600),
    super.key,
  });

  final Widget child;
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final Duration duration;

  @override
  State<AnimatedGlow> createState() => _AnimatedGlowState();
}

class _AnimatedGlowState extends State<AnimatedGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _AnimatedGlowPainter(
        progress: _controller,
        color: widget.color,
        radius: widget.borderRadius,
        strokeWidth: widget.strokeWidth,
      ),
      child: widget.child,
    );
  }
}

class _AnimatedGlowPainter extends CustomPainter {
  _AnimatedGlowPainter({
    required this.progress,
    required this.color,
    required this.radius,
    required this.strokeWidth,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final sweep = SweepGradient(
      transform: GradientRotation(progress.value * 2 * math.pi),
      colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
      stops: const [0.0, 0.12, 0.28],
    );

    final paint = Paint()
      ..shader = sweep.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawRRect(rrect.deflate(strokeWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedGlowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
