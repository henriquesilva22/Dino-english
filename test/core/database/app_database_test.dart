import 'package:dino_english/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('opens and creates every table with no errors', () async {
    await database.into(database.words).insert(
      WordsCompanion.insert(
        id: 'word.animals.dog',
        englishTerm: 'dog',
        portugueseTranslation: 'cachorro',
        category: 'animals',
        difficulty: 1,
        recommendedLevel: 1,
        exampleSentenceEn: 'The dog is happy.',
        exampleSentencePt: 'O cachorro está feliz.',
      ),
    );

    final words = await database.select(database.words).get();
    expect(words, hasLength(1));
    expect(words.single.englishTerm, 'dog');
  });

  test('word_progress row is independent of re-inserting the word', () async {
    const wordId = 'word.animals.cat';
    await database.into(database.words).insert(
      WordsCompanion.insert(
        id: wordId,
        englishTerm: 'cat',
        portugueseTranslation: 'gato',
        category: 'animals',
        difficulty: 1,
        recommendedLevel: 1,
        exampleSentenceEn: 'The cat sleeps.',
        exampleSentencePt: 'O gato dorme.',
      ),
    );
    await database.into(database.wordProgress).insert(
      WordProgressCompanion.insert(wordId: wordId, masteryLevel: const Value(3)),
    );

    final progress = await (database.select(
      database.wordProgress,
    )..where((tbl) => tbl.wordId.equals(wordId))).getSingle();
    expect(progress.masteryLevel, 3);
  });

  test('singleton tables (user_profile, dino_evolution_state, app_settings) accept a single row', () async {
    await database
        .into(database.userProfile)
        .insertOnConflictUpdate(
          UserProfileCompanion.insert(id: const Value(1), createdAt: DateTime(2026)),
        );
    await database
        .into(database.dinoEvolutionState)
        .insertOnConflictUpdate(DinoEvolutionStateCompanion.insert(id: const Value(1)));
    await database
        .into(database.appSettings)
        .insertOnConflictUpdate(AppSettingsCompanion.insert(id: const Value(1)));

    final profile = await database.select(database.userProfile).getSingle();
    expect(profile.totalXp, 0);
    expect(profile.currentLevel, 1);
  });
}
