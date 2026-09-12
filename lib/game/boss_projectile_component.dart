import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'pet_adventure_game.dart';
import 'pet_component.dart';

/// The boss's counter-attack: a straight-line shot fired leftward at
/// whatever height the boss currently is, mirroring [ProjectileComponent]
/// (the player's own shot) but flying the other way and damaging the
/// player instead of a word.
class BossProjectileComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<PetAdventureGame> {
  BossProjectileComponent({required Vector2 position, required this.speed})
    : super(position: position, size: Vector2.all(16), anchor: Anchor.center);

  /// World units per second, always moving left.
  final double speed;

  final Paint _corePaint = Paint()..color = const Color(0xFFFF375F);
  final Paint _glowPaint = Paint()
    ..color = const Color(0xFFFF375F).withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: size.x / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= speed * dt;
    if (position.x + size.x < 0) {
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
    if (other is PetComponent) {
      game.handleBossProjectileHit(this);
    }
  }
}
