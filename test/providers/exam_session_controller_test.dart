import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/exam_session_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

WordsCompanion _word(String id) {
  return WordsCompanion.insert(
    id: id,
    englishTerm: id,
    portugueseTranslation: '$id (pt)',
    category: 'test',
    difficulty: 1,
    recommendedLevel: 1,
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
  late ProviderSubscription<ExamSessionState> subscription;

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

  Future<ExamSessionState> awaitLoaded() async {
    subscription = container.listen(examSessionProvider, (_, _) {});
    while (subscription.read().isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    return subscription.read();
  }

  test('review mix excludes a brand-new word when enough weak words already fill the session', () async {
    // 10 already-seen, weak words -- enough to fill count=10 on their own
    // -- plus 1 word with no progress row at all (a genuinely "new" word,
    // which Estudar would readily include but Provas should not, since
    // SessionKind.review's mix targets 0% new).
    for (var i = 0; i < 10; i++) {
      final id = 'weak$i';
      await database.into(database.words).insert(_word(id));
      await database
          .into(database.wordProgress)
          .insert(
            WordProgressCompanion.insert(
              wordId: id,
              lastResultCorrect: const Value(false),
            ),
          );
    }
    await database.into(database.words).insert(_word('brand_new'));

    final state = await awaitLoaded();

    expect(state.items.map((q) => q.word.id), isNot(contains('brand_new')));
  });

  test('submitAnswer records exam_multiple_choice/exam exercise attempts', () async {
    await database.into(database.words).insert(_word('weak0'));
    await database
        .into(database.wordProgress)
        .insert(
          WordProgressCompanion.insert(
            wordId: 'weak0',
            lastResultCorrect: const Value(false),
          ),
        );

    final loaded = await awaitLoaded();
    expect(loaded.items, isNotEmpty);
    final notifier = container.read(examSessionProvider.notifier);
    final correctWordId = loaded.items.first.word.id;

    notifier.selectOption(correctWordId);
    await notifier.submitAnswer();

    final state = container.read(examSessionProvider);
    expect(state.isAnswered, isTrue);
    expect(state.sessionCorrectCount, 1);
    expect(state.sessionXpEarned, greaterThan(0));

    final attempts = await database.select(database.exerciseAttempts).get();
    expect(attempts, hasLength(1));
    expect(attempts.single.exerciseType, 'exam_multiple_choice');
    expect(attempts.single.sessionKind, 'exam');
    expect(attempts.single.wasCorrect, isTrue);
  });

  test('nextQuestion advances only after the current question is answered', () async {
    await database.into(database.words).insert(_word('weak0'));
    await database
        .into(database.wordProgress)
        .insert(
          WordProgressCompanion.insert(
            wordId: 'weak0',
            lastResultCorrect: const Value(false),
          ),
        );
    await awaitLoaded();
    final notifier = container.read(examSessionProvider.notifier);

    notifier.nextQuestion(); // not answered yet -- no-op
    expect(container.read(examSessionProvider).currentIndex, 0);

    notifier.selectOption(container.read(examSessionProvider).currentQuestion.word.id);
    await notifier.submitAnswer();
    notifier.nextQuestion();

    expect(container.read(examSessionProvider).currentIndex, 1);
    // WordSelectionService now always fills a batch to its target size
    // (repeating the one seeded word via maintenance cycling -- see
    // word_selection_service_test.dart), so one answered question out of
    // a full batch does not complete the round.
    expect(container.read(examSessionProvider).isComplete, isFalse);
  });
}
