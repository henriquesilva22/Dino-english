import 'package:dino_english/game/pet_adventure_game.dart';
import 'package:dino_english/game/pets/pet_catalog.dart';
import 'package:dino_english/game/sound/adventure_sfx.dart';
import 'package:dino_english/game/sound/adventure_sound_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdventureSoundService implements AdventureSoundService {
  int stopMusicCallCount = 0;
  int playMusicCallCount = 0;

  @override
  Future<void> preload() async {}

  @override
  void play(AdventureSfx sfx) {}

  @override
  void playMusic({double volume = 0.35}) {
    playMusicCallCount++;
  }

  @override
  Future<void> stopMusic() async {
    stopMusicCallCount++;
  }
}

/// Doesn't need onLoad() to have run at all: PetAdventureGame's
/// constructor is lightweight (field assignment + a debug log line), and
/// endSession()/onRemove()'s phase guards work from `starting` just as
/// well as from `running` -- exactly the property this test relies on to
/// stay a plain, fast unit test instead of needing the full GameWidget/
/// asset-loading machinery.
PetAdventureGame _buildGame(AdventureSoundService sound) {
  return PetAdventureGame(
    pet: kPetCatalog.first,
    correctWordPool: const [],
    sound: sound,
    onCollectCorrect: (_) {},
    onCollectIncorrect: () {},
  );
}

void main() {
  test(
    'onRemove() does not stop music again once endSession() already did',
    () async {
      final sound = _FakeAdventureSoundService();
      final game = _buildGame(sound);

      await game.endSession();
      expect(sound.stopMusicCallCount, 1);
      expect(game.phase, GameSessionPhase.ending);

      // Simulates the old instance's deferred dispose (fires ~300ms
      // after pop, once the route's exit transition finishes) landing
      // late. Regression coverage for exactly what a design review
      // caught before this shipped: without this guard, onRemove()'s
      // unconditional stopMusic() could land after a *new* "JOGAR
      // NOVAMENTE" instance already started its own music -- both share
      // one app-lifetime Bgm, so an unconditional second stop would kill
      // the new one's freshly-started track.
      game.onRemove();

      expect(game.phase, GameSessionPhase.disposed);
      expect(sound.stopMusicCallCount, 1);
    },
  );

  test(
    'onRemove() still stops music when endSession() was never called -- the safety net for an uncovered exit path',
    () async {
      final sound = _FakeAdventureSoundService();
      final game = _buildGame(sound);

      expect(game.phase, GameSessionPhase.starting);
      game.onRemove();

      expect(game.phase, GameSessionPhase.disposed);
      expect(sound.stopMusicCallCount, 1);
    },
  );

  test(
    'endSession() is idempotent -- calling it twice only stops music once',
    () async {
      final sound = _FakeAdventureSoundService();
      final game = _buildGame(sound);

      await game.endSession();
      await game.endSession();

      expect(sound.stopMusicCallCount, 1);
    },
  );
}
