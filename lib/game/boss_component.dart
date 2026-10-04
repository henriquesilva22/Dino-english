import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'boss_fight_state.dart';
import 'boss_projectile_component.dart';
import 'pet_adventure_game.dart';
import 'pets/pet_catalog.dart';
import 'sound/adventure_sfx.dart';

/// The boss fight's enemy visual and combatant: a larger rendering of one
/// of the catalog's pets, patrolling up and down near the right edge of
/// the level and firing back at the player -- while itself vulnerable to
/// the player's own shots (see [PetAdventureGame.handleBossShot]) besides
/// the usual correct-word damage. No pathing/targeting AI beyond the
/// vertical patrol and a fixed-cadence straight shot -- intentionally
/// simple per the spec's "doesn't need to be complex yet".
class BossComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<PetAdventureGame> {
  BossComponent({required this.pet})
    : super(size: Vector2(110, 110), anchor: Anchor.bottomLeft);

  final PetDefinition pet;

  // Bosses are always 2D animals (see pickBossPet).
  late final Sprite _sprite = Sprite(Flame.images.fromCache(pet.previewAsset!));

  /// How far above the ground the boss patrols, in world units -- roughly
  /// up to the `high` platform's height, so it moves through the same
  /// vertical space the player does.
  static const double _verticalRange = 190;
  static const double _patrolSpeed = 0.9;
  double _patrolPhase = 0;
  double _groundY = 0;

  static const double _projectileSpeed = 300;
  double _attackCooldownRemaining = 1.5;

  /// Ramps up with [BossFightState.band] -- same "desperate boss" feel as
  /// `DifficultyConfig.bossBand`'s word-spawn pacing, kept local here
  /// since attack cadence is boss-specific, not a word-spawn concern.
  double get _attackCooldownDuration => switch (game.bossState?.band) {
    BossHpBand.full => 2.4,
    BossHpBand.wounded => 1.9,
    BossHpBand.critical => 1.5,
    BossHpBand.desperate => 1.1,
    null => 2.4,
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _groundY = game.levelLayout.ground.top;
    position = Vector2(size.x * 0.82, _groundY - _verticalOffset);
  }

  double get _verticalOffset => ((sin(_patrolPhase) + 1) / 2) * _verticalRange;

  @override
  void update(double dt) {
    super.update(dt);
    _patrolPhase += dt * _patrolSpeed;
    position.y = _groundY - _verticalOffset;

    _attackCooldownRemaining -= dt;
    if (_attackCooldownRemaining <= 0 && game.bossState?.isFinished != true) {
      _attackCooldownRemaining = _attackCooldownDuration;
      _shoot();
    }
  }

  void _shoot() {
    // Same belt-and-suspenders as WordSpawner._spawn().
    if (game.phase != GameSessionPhase.running) return;
    game.sound.play(AdventureSfx.bossShoot);
    game.world.add(
      BossProjectileComponent(
        position: Vector2(position.x, position.y - size.y / 2),
        speed: _projectileSpeed,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    _sprite.render(canvas, size: size);
  }
}
