import 'dart:ui';

import 'package:flame/components.dart';

/// Static sky gradient + a soft neon glow near the horizon. Doesn't
/// scroll -- the sky never moves, only what's in front of it does.
/// Dark-neon palette matching `NeonColors` (kept as literal Color values
/// here since this file has no Flutter widget dependency).
class SkyComponent extends PositionComponent {
  SkyComponent() : super(anchor: Anchor.topLeft);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final gradientPaint = Paint()
      ..shader = Gradient.linear(
        Offset(0, 0),
        Offset(0, rect.height),
        const [
          Color(0xFF0B1020), // NeonColors.background
          Color(0xFF1B1440), // deep purple midtone
          Color(0xFF13294A), // cyan-tinted horizon
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(rect, gradientPaint);

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(
      Offset(size.x * 0.78, size.y * 0.55),
      size.x * 0.22,
      glowPaint,
    );
  }
}
