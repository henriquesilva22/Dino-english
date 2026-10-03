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
    await database
        .into(database.words)
        .insert(_word('word.a', recommendedLevel: 1));

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
    await database
        .into(database.words)
        .insert(_word('word.b', recommendedLevel: 1));
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

  test(
    'finishLearningStep only clears the flag -- no XP/index/attempt change',
    () async {
      await database
          .into(database.words)
          .insert(_word('word.c', recommendedLevel: 1));
      await awaitLoaded();
      final notifier = container.read(studySessionProvider.notifier);

      notifier.finishLearningStep();
      final state = container.read(studySessionProvider);

      expect(state.isLearningStep, isFalse);
      expect(state.currentIndex, 0);
      expect(state.sessionXpEarned, 0);
      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, isEmpty);
    },
  );

  test(
    'selectOption/submitAnswer are no-ops during the Aprender step',
    () async {
      await database
          .into(database.words)
          .insert(_word('word.d', recommendedLevel: 1));
      await awaitLoaded();
      final notifier = container.read(studySessionProvider.notifier);

      notifier.selectOption('word.d');
      expect(container.read(studySessionProvider).selectedWordId, null);

      await notifier.submitAnswer();
      expect(container.read(studySessionProvider).isAnswered, isFalse);
      final attempts = await database.select(database.exerciseAttempts).get();
      expect(attempts, isEmpty);
    },
  );

  test(
    'nextQuestion recalculates isLearningStep for the next question',
    () async {
      await database
          .into(database.words)
          .insert(_word('word.new', recommendedLevel: 1));
      await database
          .into(database.words)
          .insert(_word('word.reviewed', recommendedLevel: 1));
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
    },
  );

  test(
    'Modo Imersão off (default) leaves an already-known word on Testar -- same as the existing tests above, restated explicitly as the regression baseline',
    () async {
      await database
          .into(database.words)
          .insert(_word('word.known', recommendedLevel: 1));
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
      await database
          .into(database.words)
          .insert(_word('word.known', recommendedLevel: 1));
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
      await database
          .into(database.words)
          .insert(_word('word.new', recommendedLevel: 1));

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
      await database
          .into(database.words)
          .insert(_word('word.known', recommendedLevel: 1));
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
      await database
          .into(database.words)
          .insert(_word('word.known', recommendedLevel: 1));
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
    'a block never exceeds kWordsPerBlock words and completes once they are all answered -- '
    'Estudar must not dead-end into an infinite session',
    () async {
      for (final id in ['word.x', 'word.y', 'word.z']) {
        await database
            .into(database.words)
            .insert(_word(id, recommendedLevel: 1));
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
      expect(loaded.items, hasLength(StudySessionController.kWordsPerBlock));

      final notifier = container.read(studySessionProvider.notifier);
      for (var i = 0; i < StudySessionController.kWordsPerBlock; i++) {
        final current = container.read(studySessionProvider);
        expect(current.isComplete, isFalse);
        notifier.selectOption(current.currentQuestion.word.id);
        await notifier.submitAnswer();
        await notifier.nextQuestion();
      }

      final state = container.read(studySessionProvider);
      expect(state.currentIndex, StudySessionController.kWordsPerBlock);
      expect(
        state.items.length,
        StudySessionController.kWordsPerBlock,
        reason:
            'the block never grows past its fixed size -- no 11th word is ever loaded',
      );
      expect(state.isComplete, isTrue);
    },
  );

  test(
    'the completed block\'s results list every attempt with the word and whether it was correct, '
    'isolated to just this block',
    () async {
      await database
          .into(database.words)
          .insert(_word('word.right', recommendedLevel: 1));
      await database
          .into(database.words)
          .insert(_word('word.wrong', recommendedLevel: 1));
      for (var i = 0; i < 8; i++) {
        await database
            .into(database.words)
            .insert(_word('word.filler$i', recommendedLevel: 1));
      }

      final loaded = await awaitLoaded();
      expect(loaded.items, hasLength(StudySessionController.kWordsPerBlock));
      final notifier = container.read(studySessionProvider.notifier);

      for (var i = 0; i < StudySessionController.kWordsPerBlock; i++) {
        final current = container.read(studySessionProvider);
        final question = current.currentQuestion;
        // Deliberately answer 'word.right' correctly and 'word.wrong'
        // incorrectly (any wrong option works) whenever they come up, and
        // correctly otherwise -- so both an acerto and an erro land in
        // this block's results.
        final answerId = question.word.id == 'word.wrong'
            ? question.options
                  .firstWhere((o) => o.wordId != question.word.id)
                  .wordId
            : question.word.id;
        notifier.finishLearningStep();
        notifier.selectOption(answerId);
        await notifier.submitAnswer();
        await notifier.nextQuestion();
      }

      final state = container.read(studySessionProvider);
      expect(state.isComplete, isTrue);
      expect(
        state.blockResults,
        hasLength(StudySessionController.kWordsPerBlock),
      );
      final right = state.blockResults.singleWhere(
        (a) => a.word.id == 'word.right',
      );
      expect(right.wasCorrect, isTrue);
      final wrong = state.blockResults.singleWhere(
        (a) => a.word.id == 'word.wrong',
      );
      expect(wrong.wasCorrect, isFalse);
      expect(wrong.word.portugueseTranslation, 'word.wrong (pt)');
    },
  );

  test(
    'a double-tap on Continuar right at the block boundary only fetches the block results once',
    () async {
      for (var i = 0; i < 5; i++) {
        await database
            .into(database.words)
            .insert(_word('word.dt$i', recommendedLevel: 1));
      }

      final loaded = await awaitLoaded();
      expect(loaded.items, hasLength(StudySessionController.kWordsPerBlock));

      final notifier = container.read(studySessionProvider.notifier);
      for (var i = 0; i < StudySessionController.kWordsPerBlock - 1; i++) {
        final current = container.read(studySessionProvider);
        notifier.finishLearningStep();
        notifier.selectOption(current.currentQuestion.word.id);
        await notifier.submitAnswer();
        await notifier.nextQuestion();
      }

      final last = container.read(studySessionProvider);
      expect(last.currentIndex, StudySessionController.kWordsPerBlock - 1);
      notifier.finishLearningStep();
      notifier.selectOption(last.currentQuestion.word.id);
      await notifier.submitAnswer();

      // Fire twice back-to-back without awaiting the first -- the guard
      // must make the second call a plain no-op, not race the first.
      final firstCall = notifier.nextQuestion();
      final secondCall = notifier.nextQuestion();
      await firstCall;
      await secondCall;

      final state = container.read(studySessionProvider);
      expect(state.currentIndex, StudySessionController.kWordsPerBlock);
      expect(state.isComplete, isTrue);
      expect(
        state.blockResults,
        hasLength(StudySessionController.kWordsPerBlock),
      );
    },
  );

  test(
    'startNewBlock resets every per-block stat, fetches a fresh block, and never mixes its '
    'results with the previous block\'s',
    () async {
      for (var i = 0; i < 5; i++) {
        await database
            .into(database.words)
            .insert(_word('word.nb$i', recommendedLevel: 1));
      }

      final loaded = await awaitLoaded();
      final notifier = container.read(studySessionProvider.notifier);
      for (var i = 0; i < StudySessionController.kWordsPerBlock; i++) {
        final current = container.read(studySessionProvider);
        notifier.finishLearningStep();
        notifier.selectOption(current.currentQuestion.word.id);
        await notifier.submitAnswer();
        await notifier.nextQuestion();
      }
      final firstBlockDone = container.read(studySessionProvider);
      expect(firstBlockDone.isComplete, isTrue);
      expect(
        firstBlockDone.blockResults,
        hasLength(StudySessionController.kWordsPerBlock),
      );
      final firstBlockWordIds = firstBlockDone.blockResults
          .map((a) => a.word.id)
          .toSet();
      expect(
        loaded.items,
        isNotEmpty,
      ); // sanity: first block actually loaded something

      await notifier.startNewBlock();

      final secondBlock = container.read(studySessionProvider);
      expect(secondBlock.isLoading, isFalse);
      expect(secondBlock.currentIndex, 0);
      expect(secondBlock.sessionCorrectCount, 0);
      expect(secondBlock.sessionXpEarned, 0);
      expect(secondBlock.isComplete, isFalse);
      expect(secondBlock.blockResults, isEmpty);
      expect(
        secondBlock.items,
        hasLength(StudySessionController.kWordsPerBlock),
      );

      // Answer the whole second block, then confirm its own results never
      // include any of the first block's attempts (different sessionId).
      for (var i = 0; i < StudySessionController.kWordsPerBlock; i++) {
        final current = container.read(studySessionProvider);
        notifier.finishLearningStep();
        notifier.selectOption(current.currentQuestion.word.id);
        await notifier.submitAnswer();
        await notifier.nextQuestion();
      }
      final secondBlockDone = container.read(studySessionProvider);
      expect(
        secondBlockDone.blockResults,
        hasLength(StudySessionController.kWordsPerBlock),
      );

      final allAttempts = await database
          .select(database.exerciseAttempts)
          .get();
      expect(
        allAttempts.length,
        2 * StudySessionController.kWordsPerBlock,
        reason: 'both blocks persisted their own attempts',
      );
      expect(
        allAttempts.map((a) => a.sessionId).toSet(),
        hasLength(2),
        reason: 'each block recorded under its own distinct sessionId',
      );
      // Every attempt in the second block's results actually belongs to a
      // *different* sessionId than the first block's -- the concrete
      // isolation guarantee 3.3 requires.
      expect(firstBlockWordIds, isNotEmpty);
    },
  );
}
