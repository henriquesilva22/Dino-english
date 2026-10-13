import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/game/boss_projectile_component.dart';
import 'package:dino_english/game/pet_adventure_game.dart';
import 'package:dino_english/game/pets/pet_catalog.dart';
import 'package:dino_english/game/sound/adventure_sfx.dart';
import 'package:dino_english/game/sound/adventure_sound_service.dart';
import 'package:dino_english/game/word_catch.dart';
import 'package:dino_english/game/word_component.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SilentSound implements AdventureSoundService {
  @override
  Future<void> preload() async {}

  @override
  void play(AdventureSfx sfx) {}

  @override
  void playMusic({double volume = 0.35}) {}

  @override
  Future<void> stopMusic() async {}
}

const _bread = Word(
  id: 'word.food.bread',
  englishTerm: 'bread',
  portugueseTranslation: 'pão',
  category: 'food',
  difficulty: 1,
  recommendedLevel: 1,
  exampleSentenceEn: 'I eat bread.',
  exampleSentencePt: 'Eu como pão.',
  isActive: true,
);

void main() {
  late List<WordCatch> catches;
  late int lostLives;
  late PetAdventureGame game;

  setUp(() {
    // As in main(): asset paths are full paths.
    Flame.images.prefix = '';
  });

  Future<void> start(WidgetTester tester, {bool boss = false}) async {
    catches = [];
    lostLives = 0;
    game = PetAdventureGame(
      pet: kPetCatalog.first,
      correctWordPool: const [_bread],
      sound: _SilentSound(),
      isBossFight: boss,
      onCollectCorrect: (_) {},
      onCollectIncorrect: () => lostLives++,
      onWordCatch: catches.add,
    );
    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pumpWidget(GameWidget(game: game));
    for (var i = 0; i < 40 && game.phase != GameSessionPhase.running; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.phase, GameSessionPhase.running);
  }

  WordComponent word({bool correct = true}) {
    final w = correct
        ? WordComponent.correct(
            word: _bread,
            position: Vector2(300, 200),
            scrollSpeed: 0,
          )
        : WordComponent.incorrect(
            label: 'brede',
            position: Vector2(300, 200),
            scrollSpeed: 0,
          );
    game.world.add(w);
    return w;
  }

  testWidgets('a correct word caught: the Dino says it ("bread"), once', (
    tester,
  ) async {
    await start(tester);
    final caught = word();
    await tester.pump();
    game.handleWordCollected(caught);
    // The same capsule touching twice in one frame is one catch.
    game.handleWordCollected(caught);
    expect(catches, hasLength(1));
    expect(catches.single, isA<CorrectWordCaught>());
    expect((catches.single as CorrectWordCaught).english, 'bread');
    await game.endSession();
  });

  testWidgets('a wrong word caught: "Errou!" (WrongWordCaught)', (
    tester,
  ) async {
    await start(tester);
    final caught = word(correct: false);
    await tester.pump();
    game.handleWordCollected(caught);
    expect(catches.single, isA<WrongWordCaught>());
    expect(lostLives, 1);
    await game.endSession();
  });

  testWidgets('the boss hitting the pet costs a life but is never a word', (
    tester,
  ) async {
    await start(tester, boss: true);
    final shot = BossProjectileComponent(position: Vector2(200, 200), speed: 0);
    game.world.add(shot);
    await tester.pump();
    game.handleBossProjectileHit(shot);
    expect(lostLives, 1);
    expect(catches, isEmpty);
    await game.endSession();
  });
}
