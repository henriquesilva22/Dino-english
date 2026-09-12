/// Pet Adventure sound events, mapped to the real Kenney `.ogg` files
/// already bundled under `assets/sprites/map/Sounds/`.
enum AdventureSfx {
  jump,
  correct,
  incorrect,
  select,
  roundEnd,
  shoot,
  wordPop,
  bossHit,
  bossShoot,
}

extension AdventureSfxFile on AdventureSfx {
  String get fileName => switch (this) {
    AdventureSfx.jump => 'sfx_jump.ogg',
    AdventureSfx.correct => 'sfx_coin.ogg',
    AdventureSfx.incorrect => 'sfx_hurt.ogg',
    AdventureSfx.select => 'sfx_select.ogg',
    AdventureSfx.roundEnd => 'sfx_magic.ogg',
    AdventureSfx.shoot => 'sfx_throw.ogg',
    AdventureSfx.wordPop => 'sfx_disappear.ogg',
    AdventureSfx.bossHit => 'sfx_bump.ogg',
    AdventureSfx.bossShoot => 'sfx_gem.ogg',
  };
}
