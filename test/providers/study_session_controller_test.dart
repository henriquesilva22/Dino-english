import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/immersion_mode_providers.dart';
import 'package:dino_english/providers/study_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

WordsCompanion _word(String id, {required int recommendedLevel}) {
  return WordsCompanion.insert(
    id: id,
    englishTerm: id,
    portugueseTranslation: '$id (pt)',
    category: 'test',
    difficulty: 1,
    recommendedLevel: recommendedLevel,
    exampleSentenceEn: 'This is $id.',
    exampleSentencePt: 'Isto é $id.',
  );
}

Future<AppDatabase> _seededDatabase() async {
  final database = AppDatabase(NativeDatabase.memory());
  await database
      .into(database.userProfile)
      .insertOnConflictUpdate(
        UserProfileCompanion.insert(id: const Value(1), createdAt: DateTime(2026)),
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
  late ProviderSubscription<StudySessionState> subscription;

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

  /// `_loadSession()` runs fire-and-forget inside `build()`, so the state
  /// starts `isLoading: true` -- poll until it flips before asserting.
  ///
  /// `studySessionProvider` is `autoDispose`: reading it without an active
  /// listener doesn't keep it alive, so it would be disposed and rebuilt
  /// (back to `isLoading: true`) on every poll iteration, spinning
  /// forever. Establishing [subscription] here (closed in `tearDown`)
  /// pins it alive for the rest of the test, exactly like a widget's
  /// `ref.watch` would -- call this only after seeding the words a test
  /// needs, since establishing it triggers the first `build()`/
  /// `_loadSession()` read of the database.
  Future<StudySessionState> awaitLoaded() async {
    subscription = container.listen(studySessionProvider, (_, _) {});
    while (subscription.read().isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    return subscription.read();
  }

  test('a word with no word_progress row starts the Aprender step', () async {
    await database.into(database.words).insert(_word('word.a', recommendedLevel: 1));

    final state = await awaitLoaded();

    // A batch always fills to its target size (via maintenance repetition
    // once a tiny test DB runs out -- see word_selection_service_test.dart)
    // so this single seeded word repeats to fill the rest; it's still
    // deterministically first, since the initial bucketed pass always
    // picks it before any repeat filler.
    expect(state.items, isNotEmpty);
    expect(state.items.first.isNewWord, isTrue);
    expect(state.isLearningStep, isTrue);
  });

  test('a word already reviewed skips straight to Testar', () async {
    await database.into(database.words).insert(_word('word.b', recommendedLevel: 1));
    await database
        .into(database.wordProgress)
        .insert(
          WordProgressCompanion.insert(
            wordId: 'word.b',
            lastResultCorrect: const Value(false),
          ),
        );

    final state = await awaitLoaded();

    expect(state.items, isNotEmpty);
    expect(state.items.first.isNewWord, isFalse);
    expect(state.isLearningStep, isFalse);
  });

  test('finishLearningStep only clears the flag -- no XP/index/attempt change', () async {
    await database.into(database.words).insert(_word('word.c', recommendedLevel: 1));
    await awaitLoaded();
    final notifier = container.read(studySessionProvider.notifier);

    notifier.finishLearningStep();
    final state = container.read(studySessionProvider);

    expect(state.isLearningStep, isFalse);
    expect(state.currentIndex, 0);
    expect(state.sessionXpEarned, 0);
    final attempts = await database.select(database.exerciseAttempts).get();
    expect(attempts, isEmpty);
  });

  test('selectOption/submitAnswer are no-ops during the Aprender step', () async {
    await database.into(database.words).insert(_word('word.d', recommendedLevel: 1));
    await awaitLoaded();
    final notifier = container.read(studySessionProvider.notifier);

    notifier.selectOption('word.d');
    expect(container.read(studySessionProvider).selectedWordId, null);

    await notifier.submitAnswer();
    expect(container.read(studySessionProvider).isAnswered, isFalse);
    final attempts = await database.select(database.exerciseAttempts).get();
    expect(attempts, isEmpty);
  });

  test('nextQuestion recalculates isLearningStep for the next question', () async {
    await database.into(database.words).insert(_word('word.new', recommendedLevel: 1));
    await database.into(database.words).insert(_word('word.reviewed', recommendedLevel: 1));
    await database
        .into(database.wordProgress)
        .insert(
          WordProgressCompanion.insert(
            wordId: 'word.reviewed',
            lastResultCorrect: const Value(false),
          ),
        );

    final loaded = await awaitLoaded();
    // The initial bucketed pass deterministically places the new word
    // first and the reviewed word second, before any repeat filler pads
    // the rest of the batch (see word_selection_service_test.dart).
    expect(loaded.items.length, greaterThanOrEqualTo(2));
    expect(loaded.items.first.isNewWord, isTrue);
    expect(loaded.isLearningStep, isTrue);

    final notifier = container.read(studySessionProvider.notifier);
    notifier.finishLearningStep();
    notifier.selectOption(loaded.items.first.word.id);
    await notifier.submitAnswer();
    notifier.nextQuestion();

    final state = container.read(studySessionProvider);
    expect(state.currentIndex, 1);
    expect(state.items[1].isNewWord, isFalse);
    expect(state.isLearningStep, isFalse);
  });

  test(
    'Modo Imersão off (default) leaves an already-known word on Testar -- same as the existing tests above, restated explicitly as the regression baseline',
    () async {
      await database.into(database.words).insert(_word('word.known', recommendedLevel: 1));
      await database
          .into(database.wordProgress)
          .insert(
            WordProgressCompanion.insert(
              wordId: 'word.known',
              lastResultCorrect: const Value(false),
            ),
          );

      final state = await awaitLoaded();

      expect(state.immersionModeEnabled, isFalse);
      expect(state.isLearningStep, isFalse);
    },
  );

  test(
    'Modo Imersão on shows the Aprender step for an already-known word too, with translations hidden',
    () async {
      // Must be set before awaitLoaded() establishes the listener that
      // triggers the first build()/_loadSession() read.
      container.read(immersionModeEnabledProvider.notifier).set(true);
      await database.into(database.words).insert(_word('word.known', recommendedLevel: 1));
      await database
          .into(database.wordProgress)
          .insert(
            WordProgressCompanion.insert(
              wordId: 'word.known',
              lastResultCorrect: const Value(false),
            ),
          );

      final state = await awaitLoaded();

      expect(state.items.first.isNewWord, isFalse);
      expect(state.immersionModeEnabled, isTrue);
      expect(state.isLearningStep, isTrue);
      expect(state.isWordTranslationRevealed, isFalse);
      expect(state.isSentenceTranslationRevealed, isFalse);
    },
  );

  test(
    'a brand-new word still shows its translation immediately under Modo Imersão -- unchanged from normal mode',
    () async {
      container.read(immersionModeEnabledProvider.notifier).set(true);
      await database.into(database.words).insert(_word('word.new', recommendedLevel: 1));

      final state = await awaitLoaded();

      expect(state.items.first.isNewWord, isTrue);
      expect(state.isWordTranslationRevealed, isTrue);
      expect(state.isSentenceTranslationRevealed, isTrue);
    },
  );

  test(
    'revealWordTranslation/revealSentenceTranslation only flip local flags -- no DB writes',
    () async {
      container.read(immersionModeEnabledProvider.notifier).set(true);
      await database.into(database.words).insert(_word('word.known', recommendedLevel: 1));
      await database
          .into(database.wordProgress)
          .insert(
            WordProgressCompanion.insert(
              wordId: 'word.known',
              lastResultCorrect: const Value(false),
            ),
          );
      await awaitLoaded();
      final notifier = container.read(studySessionProvider.notifier);

      notifier.revealWordTranslation();
      notifier.revealSentenceTranslation();

      final state = container.read(studySessionProvider);
      expect(state.isWordTranslationRevealed, isTrue);
      expect(state.isSentenceTranslationRevealed, isTrue);
      // Neither reveal nor the Learn step itself should have touched
      // mastery/XP/history -- only a real submitAnswer() may.
      final progress = await (database.select(
        database.wordProgress,
      )..where((t) => t.wordId.equals('word.known'))).getSingle();
      expect(progress.correctCount, 0);
      expect(progress.timesShownTotal, 0);
      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, isEmpty);
    },
  );

  test(
    'submitting an answer under Modo Imersão records the same shape of attempt as the normal flow',
    () async {
      container.read(immersionModeEnabledProvider.notifier).set(true);
      await database.into(database.words).insert(_word('word.known', recommendedLevel: 1));
      await database
          .into(database.wordProgress)
          .insert(
            WordProgressCompanion.insert(
              wordId: 'word.known',
              lastResultCorrect: const Value(false),
            ),
          );
      final loaded = await awaitLoaded();
      final notifier = container.read(studySessionProvider.notifier);

      notifier.finishLearningStep();
      notifier.selectOption(loaded.items.first.word.id);
      await notifier.submitAnswer();

      final state = container.read(studySessionProvider);
      expect(state.isAnswered, isTrue);
      expect(state.sessionXpEarned, greaterThan(0));
      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, hasLength(1));
      expect(attempts.single.exerciseType, 'multiple_choice');
      expect(attempts.single.sessionKind, 'study');
      expect(attempts.single.wasCorrect, isTrue);
    },
  );

  test(
    'nextQuestion extends the session with another batch instead of ending it once the first '
    'batch is exhausted -- Estudar must never dead-end into "Sessão concluída"',
    () async {
      for (final id in ['word.x', 'word.y', 'word.z']) {
        await database.into(database.words).insert(_word(id, recommendedLevel: 1));
        await database
            .into(database.wordProgress)
            .insert(
              WordProgressCompanion.insert(
                wordId: id,
                lastResultCorrect: const Value(false),
              ),
            );
      }

      final loaded = await awaitLoaded();
      // WordSelectionService already fills a full batch via maintenance
      // repetition even though the DB only has 3 distinct words -- see
      // word_selection_service_test.dart for that guarantee in isolation.
      // This test is about what happens once THIS batch, not the word
      // bank, runs out.
      expect(loaded.items, hasLength(10));

      final notifier = container.read(studySessionProvider.notifier);
      for (var i = 0; i < 10; i++) {
        final current = container.read(studySessionProvider);
        expect(current.isComplete, isFalse);
        notifier.selectOption(current.currentQuestion.word.id);
        await notifier.submitAnswer();
        await notifier.nextQuestion();
      }

      final state = container.read(studySessionProvider);
      expect(state.currentIndex, 10);
      expect(state.items.length, greaterThan(10));
      expect(state.isComplete, isFalse);
      expect(state.currentQuestion.word.id, isNotEmpty);
    },
  );

  test(
    'a double-tap on Continuar right at a batch boundary only extends the session once, not twice',
    () async {
      for (final id in ['word.p', 'word.q']) {
        await database.into(database.words).insert(_word(id, recommendedLevel: 1));
        await database
            .into(database.wordProgress)
            .insert(
              WordProgressCompanion.insert(
                wordId: id,
                lastResultCorrect: const Value(false),
              ),
            );
      }

      final loaded = await awaitLoaded();
      expect(loaded.items, hasLength(10));

      final notifier = container.read(studySessionProvider.notifier);
      for (var i = 0; i < 9; i++) {
        final current = container.read(studySessionProvider);
        notifier.selectOption(current.currentQuestion.word.id);
        await notifier.submitAnswer();
        await notifier.nextQuestion();
      }

      final last = container.read(studySessionProvider);
      expect(last.currentIndex, 9);
      notifier.selectOption(last.currentQuestion.word.id);
      await notifier.submitAnswer();

      // Fire twice back-to-back without awaiting the first -- the second
      // call must observe the in-flight extension and no-op, not append
      // its own extra batch on top.
      final firstCall = notifier.nextQuestion();
      final secondCall = notifier.nextQuestion();
      await firstCall;
      await secondCall;

      final state = container.read(studySessionProvider);
      expect(state.currentIndex, 10);
      expect(
        state.items.length,
        20,
        reason: 'exactly one batch appended, not two',
      );
    },
  );
}
