import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'boss_component.dart';
import 'pet_adventure_game.dart';
import 'word_component.dart';

/// A simple straight-line shot the player fires to knock out an
/// incorrect word before it gets close -- an alternative to jumping over
/// it. Never affects correct words (they're still only collected by
/// jumping into them); a shot that reaches a correct word just passes
/// through and keeps flying. In a boss fight, a shot landing on
/// [BossComponent] instead damages its HP -- a second way to fight it
/// besides collecting words.
class ProjectileComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<PetAdventureGame> {
  ProjectileComponent({required Vector2 position, required this.speed})
    : super(position: position, size: Vector2.all(14), anchor: Anchor.center);

  /// World units per second, always moving right.
  final double speed;

  final Paint _corePaint = Paint()..color = const Color(0xFF00E5FF);
  final Paint _glowPaint = Paint()
    ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: size.x / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += speed * dt;
    if (position.x - size.x > game.size.x) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2 + 4, _glowPaint);
    canvas.drawCircle(center, size.x / 2, _corePaint);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is WordComponent && !other.isCorrect) {
      game.handleWordShot(other, this);
    } else if (other is BossComponent) {
      game.handleBossShot(this);
    }
  }
}
