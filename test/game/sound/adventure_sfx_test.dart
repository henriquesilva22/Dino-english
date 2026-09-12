import 'package:dino_english/game/sound/adventure_sfx.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real `.ogg` files confirmed to exist under
/// `assets/sprites/map/Sounds/`.
const _availableSoundFiles = {
  'sfx_jump.ogg',
  'sfx_jump-high.ogg',
  'sfx_coin.ogg',
  'sfx_gem.ogg',
  'sfx_disappear.ogg',
  'sfx_hurt.ogg',
  'sfx_bump.ogg',
  'sfx_magic.ogg',
  'sfx_select.ogg',
  'sfx_throw.ogg',
};

void main() {
  test('every AdventureSfx maps to a real bundled sound file', () {
    for (final sfx in AdventureSfx.values) {
      expect(_availableSoundFiles, contains(sfx.fileName));
    }
  });

  test('every AdventureSfx has a distinct file', () {
    final files = AdventureSfx.values.map((s) => s.fileName).toSet();
    expect(files, hasLength(AdventureSfx.values.length));
  });
}
