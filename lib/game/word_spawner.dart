import 'dart:math';

import 'package:flame/components.dart';

import '../core/database/app_database.dart';
import 'minigame_fake_words.dart';
import 'pet_adventure_game.dart';
import 'word_component.dart';
import 'word_height_tier.dart';

/// Periodically spawns words off the right edge of the screen, correct
/// and incorrect alike, each in an independently-picked lane -- the
/// player has to read every capsule and decide whether to move to its
/// lane or out of it, rather than inferring the answer from
/// its position. Timing and mix are driven entirely by [DifficultyConfig],
/// so a harder preset later only needs new numbers, not new spawner logic.
class WordSpawner extends Component with HasGameReference<PetAdventureGame> {
  WordSpawner({required this.random});

  final Random random;

  double _timeUntilNextSpawn = 0;
  List<Word> _wordQueue = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _scheduleNext();
  }

  void _scheduleNext() {
    final difficulty = game.activeDifficulty;
    final span = difficulty.maxSpawnInterval - difficulty.minSpawnInterval;
    _timeUntilNextSpawn =
        difficulty.minSpawnInterval + random.nextDouble() * span;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timeUntilNextSpawn -= dt;
    if (_timeUntilNextSpawn <= 0) {
      _spawn();
      _scheduleNext();
    }
  }

  void _spawn() {
    // Belt-and-suspenders alongside pauseEngine() (which already stops
    // update(dt) from firing at all once paused): explicit per the
    // requirement that nothing should spawn once the session isn't
    // actively running.
    if (game.phase != GameSessionPhase.running) return;
    final difficulty = game.activeDifficulty;
    final spawnX = game.size.x + 40;
    final isCorrect = random.nextDouble() < difficulty.correctWordProbability;
    final tier = pickWordHeightTier(random, difficulty.heightTierWeights);
    // On the lane's surface: the pet catches it by being on that lane.
    final spawnY = game.levelLayout.laneSurface(tier.lane).top;

    if (isCorrect && game.correctWordPool.isNotEmpty) {
      game.world.add(
        WordComponent.correct(
          word: _nextCorrectWord(),
          position: Vector2(spawnX, spawnY),
          scrollSpeed: difficulty.scrollSpeed,
        ),
      );
    } else {
      final label =
          kMinigameFakeWords[random.nextInt(kMinigameFakeWords.length)];
      game.world.add(
        WordComponent.incorrect(
          label: label,
          position: Vector2(spawnX, spawnY),
          scrollSpeed: difficulty.scrollSpeed,
        ),
      );
    }
  }

  /// Cycles through a shuffled copy of the pool so every word is seen once
  /// before any repeat, reshuffling once exhausted.
  Word _nextCorrectWord() {
    if (_wordQueue.isEmpty) {
      _wordQueue = List.of(game.correctWordPool)..shuffle(random);
    }
    return _wordQueue.removeAt(0);
  }
}
