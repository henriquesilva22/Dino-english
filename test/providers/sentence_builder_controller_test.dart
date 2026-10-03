import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/sentence_builder_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

WordsCompanion _word(String id, {int difficulty = 1}) {
  return WordsCompanion.insert(
    id: id,
    englishTerm: id,
    portugueseTranslation: '$id (pt)',
    category: 'test',
    difficulty: difficulty,
    recommendedLevel: 1,
    exampleSentenceEn: 'The $id is very happy.',
    exampleSentencePt: 'O $id está muito feliz.',
  );
}

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
  return database;
}

void main() {
  late AppDatabase database;
  late ProviderContainer container;
  late ProviderSubscription<SentenceBuilderState> subscription;

  setUp(() async {
    database = await _seededDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    subscription.close();
    container.dispose();
    await database.close();
  });

  /// Same `autoDispose`-pinning technique as
  /// `study_session_controller_test.dart`: a bare `container.read()` with
  /// no active listener lets the provider get disposed/rebuilt on every
  /// poll iteration, spinning forever.
  Future<SentenceBuilderState> awaitLoaded() async {
    subscription = container.listen(sentenceBuilderProvider, (_, _) {});
    while (subscription.read().isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    return subscription.read();
  }

  test('loads a session with a real challenge from the word pool', () async {
    await database.into(database.words).insert(_word('dog'));

    final state = await awaitLoaded();

    // WordSelectionService always fills a batch to its target size (here
    // count: 8), repeating the one seeded word via maintenance cycling --
    // see word_selection_service_test.dart -- so the deterministic first
    // challenge is what this test cares about, not the batch length.
    expect(state.challenges, isNotEmpty);
    expect(state.challenges.first.word.id, 'dog');
    expect(state.challenges.first.displayTokens, [
      'The',
      'dog',
      'is',
      'very',
      'happy.',
    ]);
  });

  test(
    'tapBankToken/tapPlacedToken/clearPlaced move tokens between bank and answer',
    () async {
      await database.into(database.words).insert(_word('dog'));
      await awaitLoaded();
      final notifier = container.read(sentenceBuilderProvider.notifier);

      notifier.tapBankToken('w0');
      expect(container.read(sentenceBuilderProvider).placedTokenIds, ['w0']);

      notifier.tapBankToken('w0'); // already placed -- no duplicate
      expect(container.read(sentenceBuilderProvider).placedTokenIds, ['w0']);

      notifier.tapPlacedToken('w0');
      expect(container.read(sentenceBuilderProvider).placedTokenIds, isEmpty);

      notifier.tapBankToken('w0');
      notifier.tapBankToken('w1');
      notifier.clearPlaced();
      expect(container.read(sentenceBuilderProvider).placedTokenIds, isEmpty);
    },
  );

  test(
    'submit() with the correct order records a correct sentence_builder attempt',
    () async {
      await database.into(database.words).insert(_word('dog'));
      final loaded = await awaitLoaded();
      final notifier = container.read(sentenceBuilderProvider.notifier);
      final tokenCount = loaded.challenges.first.displayTokens.length;

      for (var i = 0; i < tokenCount; i++) {
        notifier.tapBankToken('w$i');
      }
      await notifier.submit();

      final state = container.read(sentenceBuilderProvider);
      expect(state.isSubmitted, isTrue);
      expect(state.isCorrect, isTrue);
      expect(state.sessionCorrectCount, 1);
      expect(state.streakThisSession, 1);
      expect(state.sessionXpEarned, greaterThan(0));

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, hasLength(1));
      expect(attempts.single.exerciseType, 'sentence_builder');
      expect(attempts.single.wasCorrect, isTrue);
      expect(attempts.single.userAnswer, 'The dog is very happy.');
    },
  );

  test(
    'submit() with the wrong order records an incorrect attempt and resets the streak',
    () async {
      await database.into(database.words).insert(_word('dog'));
      final loaded = await awaitLoaded();
      final notifier = container.read(sentenceBuilderProvider.notifier);
      final tokenCount = loaded.challenges.first.displayTokens.length;

      for (var i = tokenCount - 1; i >= 0; i--) {
        notifier.tapBankToken('w$i');
      }
      await notifier.submit();

      final state = container.read(sentenceBuilderProvider);
      expect(state.isCorrect, isFalse);
      expect(state.sessionCorrectCount, 0);
      expect(state.streakThisSession, 0);

      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts.single.wasCorrect, isFalse);
    },
  );

  test(
    'next() advances past a completed challenge without marking the session complete',
    () async {
      await database.into(database.words).insert(_word('dog'));
      final loaded = await awaitLoaded();
      final notifier = container.read(sentenceBuilderProvider.notifier);
      for (var i = 0; i < loaded.challenges.first.displayTokens.length; i++) {
        notifier.tapBankToken('w$i');
      }
      await notifier.submit();

      notifier.next();

      final state = container.read(sentenceBuilderProvider);
      // WordSelectionService now always fills a batch to its target size
      // (count: 8), repeating the one seeded word via maintenance cycling --
      // see word_selection_service_test.dart -- so one completed challenge
      // out of a full batch does not complete the round.
      expect(state.currentIndex, 1);
      expect(state.isComplete, isFalse);
      expect(state.isSubmitted, isFalse);
      expect(state.placedTokenIds, isEmpty);
    },
  );
}
