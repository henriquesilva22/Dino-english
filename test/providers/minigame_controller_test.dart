import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/minigame_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _seededDatabase() async {
  final database = AppDatabase(NativeDatabase.memory());
  await database
      .into(database.userProfile)
      .insertOnConflictUpdate(
        UserProfileCompanion.insert(
          id: const Value(1),
          createdAt: DateTime(2026),
        ),
      );
  await database
      .into(database.dinoEvolutionState)
      .insertOnConflictUpdate(
        DinoEvolutionStateCompanion.insert(id: const Value(1)),
      );
  await database
      .into(database.words)
      .insert(
        WordsCompanion.insert(
          id: 'word.apple',
          englishTerm: 'apple',
          portugueseTranslation: 'maçã',
          category: 'food',
          difficulty: 1,
          recommendedLevel: 1,
          exampleSentenceEn: 'I eat an apple.',
          exampleSentencePt: 'Eu como uma maçã.',
        ),
      );
  return database;
}

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    database = await _seededDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test(
    'collectCorrectWord records a minigame_collect/review exercise attempt',
    () async {
      final word = await (database.select(
        database.words,
      )..where((t) => t.id.equals('word.apple'))).getSingle();

      await container
          .read(minigameControllerProvider.notifier)
          .collectCorrectWord(word);

      final state = container.read(minigameControllerProvider);
      expect(state.score, greaterThan(0));
      expect(state.correctWordsCollected, ['apple']);

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, hasLength(1));
      expect(attempts.single.exerciseType, 'minigame_collect');
      expect(attempts.single.sessionKind, 'review');
      expect(attempts.single.wasCorrect, isTrue);
    },
  );

  test(
    'four collectIncorrectWord calls end the round with 4 null-wordId attempts',
    () async {
      final notifier = container.read(minigameControllerProvider.notifier);

      for (var i = 0; i < 4; i++) {
        await notifier.collectIncorrectWord();
      }

      final state = container.read(minigameControllerProvider);
      expect(state.isGameOver, isTrue);
      expect(state.lives, 0);

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, hasLength(4));
      expect(attempts.every((a) => a.wordId == null), isTrue);
      expect(attempts.every((a) => a.xpAwarded == 0), isTrue);
    },
  );
}
