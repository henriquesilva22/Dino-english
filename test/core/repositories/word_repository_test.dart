import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/repositories/word_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _insertWord(
  AppDatabase database, {
  required String id,
  bool isActive = true,
  String category = 'animals',
}) {
  return database
      .into(database.words)
      .insert(
        WordsCompanion.insert(
          id: id,
          englishTerm: id,
          portugueseTranslation: '$id-pt',
          category: category,
          difficulty: 1,
          recommendedLevel: 1,
          exampleSentenceEn: 'Example $id.',
          exampleSentencePt: 'Exemplo $id.',
          isActive: Value(isActive),
        ),
      );
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'fetchCandidatePool marks a word with no progress row as not introduced',
    () async {
      await _insertWord(database, id: 'word.a');
      final repository = WordRepository(database);

      final pool = await repository.fetchCandidatePool();

      expect(pool, hasLength(1));
      expect(pool.single.hasBeenIntroduced, isFalse);
      expect(pool.single.masteryLevel, 0);
    },
  );

  test('fetchCandidatePool reflects an existing word_progress row', () async {
    await _insertWord(database, id: 'word.b');
    await database
        .into(database.wordProgress)
        .insert(
          WordProgressCompanion.insert(
            wordId: 'word.b',
            masteryLevel: const Value(3),
          ),
        );
    final repository = WordRepository(database);

    final pool = await repository.fetchCandidatePool();

    expect(pool.single.hasBeenIntroduced, isTrue);
    expect(pool.single.masteryLevel, 3);
  });

  test('fetchActiveWords excludes inactive words', () async {
    await _insertWord(database, id: 'word.active', isActive: true);
    await _insertWord(database, id: 'word.inactive', isActive: false);
    final repository = WordRepository(database);

    final active = await repository.fetchActiveWords();

    expect(active.map((w) => w.id), ['word.active']);
  });

  test(
    'fetchDistractorPool and fetchCandidatePool also exclude inactive words',
    () async {
      await _insertWord(database, id: 'word.active', isActive: true);
      await _insertWord(database, id: 'word.inactive', isActive: false);
      final repository = WordRepository(database);

      final pool = await repository.fetchCandidatePool();
      final distractors = await repository.fetchDistractorPool();

      expect(pool.map((c) => c.wordId), ['word.active']);
      expect(distractors.map((d) => d.wordId), ['word.active']);
    },
  );
}
