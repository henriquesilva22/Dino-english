/// Word Slash sound events, mapped to the real Kenney `.ogg` files already
/// bundled under `assets/sprites/map/Sounds/` (same pack Pet Adventure
/// uses) -- no new assets needed. Deliberately minimal for v1 ("não
/// exagere inicialmente. A prioridade é a mecânica"): just enough to
/// confirm a correct/wrong pair without building out a whole new sound
/// catalog.
enum WordSlashSfx { correctPair, wrongPair, roundEnd }

extension WordSlashSfxFile on WordSlashSfx {
  String get fileName => switch (this) {
    WordSlashSfx.correctPair => 'sfx_coin.ogg',
    WordSlashSfx.wrongPair => 'sfx_hurt.ogg',
    WordSlashSfx.roundEnd => 'sfx_magic.ogg',
  };
}
