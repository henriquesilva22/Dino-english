import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/database/app_database.dart';

/// A word capsule, correct or incorrect, that scrolls left across the
/// screen at one of a few height tiers (see `word_height_tier.dart`).
/// Carries either a real [Word] (correct, collecting it updates real
/// progress) or a fake label (incorrect, collecting it only costs a
/// life). Visually the two look like the same kind of object (a pill
/// with a small corner badge) in close, warm-vs-cool palettes -- not an
/// obvious green/red traffic light -- so the player has to read the word,
/// not just its color or height.
class WordComponent extends PositionComponent with CollisionCallbacks {
  WordComponent.correct({
    required Word word,
    required Vector2 position,
    required this.scrollSpeed,
  }) : word = word,
       label = word.englishTerm,
       isCorrect = true,
       super(
         position: position,
         size: Vector2(_widthFor(word.englishTerm), 40),
         anchor: Anchor.bottomLeft,
       );

  WordComponent.incorrect({
    required String label,
    required Vector2 position,
    required this.scrollSpeed,
  }) : word = null,
       label = label,
       isCorrect = false,
       super(
         position: position,
         size: Vector2(_widthFor(label), 40),
         anchor: Anchor.bottomLeft,
       );

  final Word? word;
  final String label;
  final bool isCorrect;
  final double scrollSpeed;

  double _age = 0;

  static double _widthFor(String label) =>
      (label.length * 11.0 + 24).clamp(80, 220);

  // Neon palette: cyan for correct, purple for incorrect -- close enough
  // in value/saturation (both are dark-surface pills with a glowing
  // border) that the color alone doesn't give the answer away.
  static const _correctFill = Color(0xE6111735); // NeonColors.surface
  static const _correctBorder = Color(0xFF00E5FF); // NeonColors.cyan
  static const _incorrectFill = Color(0xE6111735);
  static const _incorrectBorder = Color(0xFF8A2BE2); // NeonColors.purple
  static const _textColor = Color(0xFFEAF7FF); // NeonColors.textPrimary

  late final Paint _fillPaint = Paint()
    ..color = isCorrect ? _correctFill : _incorrectFill;
  late final Paint _borderPaint = Paint()
    ..color = isCorrect ? _correctBorder : _incorrectBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
  late final Paint _badgePaint = Paint()
    ..color = isCorrect ? _correctBorder : _incorrectBorder;
  late final TextPainter _badgeText =
      TextPainter(
          text: TextSpan(
            text: isCorrect ? '★' : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    add(
      TextComponent(
        text: label,
        anchor: Anchor.center,
        position: size / 2,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: _textColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.x -= scrollSpeed * dt;
    if (position.x + size.x < 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Purely visual idle float; never touches position/hitbox, so
    // collision stays exactly at the spawned height tier.
    final bob = sin(_age * 3 + position.x * 0.01) * 3;

    canvas.save();
    canvas.translate(0, bob);

    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      Radius.circular(size.y / 2),
    );
    canvas.drawRRect(rrect, _fillPaint);
    canvas.drawRRect(rrect, _borderPaint);

    final badgeCenter = Offset(size.x - 6, 6);
    canvas.drawCircle(badgeCenter, 8, _badgePaint);
    _badgeText.paint(
      canvas,
      badgeCenter - Offset(_badgeText.width / 2, _badgeText.height / 2),
    );

    canvas.restore();
  }
}
