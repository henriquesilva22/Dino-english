import 'package:dino_english/core/companion/companion_state.dart';
import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/repositories/companion_state_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1 -> v2 keeps existing words and adds senses + dino memory', () async {
    // A v1 install: the `words` table as it was before DinoBrain, with a
    // user row in it, and user_version = 1.
    final executor = NativeDatabase.memory(
      setup: (db) {
        db.execute('''
          CREATE TABLE words (
            id TEXT NOT NULL PRIMARY KEY,
            english_term TEXT NOT NULL,
            portuguese_translation TEXT NOT NULL,
            category TEXT NOT NULL,
            difficulty INTEGER NOT NULL,
            recommended_level INTEGER NOT NULL,
            example_sentence_en TEXT NOT NULL,
            example_sentence_pt TEXT NOT NULL,
            pronunciation_audio_asset TEXT NULL,
            image_asset TEXT NULL,
            is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
          );
        ''');
        db.execute(
          "INSERT INTO words (id, english_term, portuguese_translation, category, "
          "difficulty, recommended_level, example_sentence_en, example_sentence_pt) "
          "VALUES ('word.animals.dog', 'dog', 'cachorro', 'animals', 1, 1, "
          "'The dog is happy.', 'O cachorro está feliz.')",
        );
        db.execute('PRAGMA user_version = 1;');
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final dog = await database.select(database.words).getSingle();
    expect(dog.englishTerm, 'dog');
    expect(dog.sensesJson, isNull);

    await database
        .into(database.dinoMemories)
        .insert(
          DinoMemoriesCompanion.insert(
            kind: 'preference',
            memoryKey: 'food',
            value: 'apple',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    final memories = await database.select(database.dinoMemories).get();
    expect(memories.single.value, 'apple');
    expect(memories.single.confidence, 1.0);
  });

  test('v2 -> v3 adds the companion state table', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        db.execute('''
          CREATE TABLE user_profile (
            id INTEGER NOT NULL PRIMARY KEY,
            total_xp INTEGER NOT NULL DEFAULT 0,
            current_level INTEGER NOT NULL DEFAULT 1,
            current_streak_days INTEGER NOT NULL DEFAULT 0,
            longest_streak_days INTEGER NOT NULL DEFAULT 0,
            last_study_date TEXT NULL,
            created_at INTEGER NOT NULL
          );
        ''');
        db.execute(
          'INSERT INTO user_profile (id, total_xp, current_level, created_at) '
          'VALUES (1, 120, 3, 0)',
        );
        db.execute('PRAGMA user_version = 2;');
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final profile = await database.select(database.userProfile).getSingle();
    expect(profile.totalXp, 120);

    final store = DriftCompanionStateStore(database);
    expect(await store.load(), isNull);
    final state = CompanionState.initial(DateTime(2026, 10, 3));
    await store.save(state.copyWith(hunger: 42.5, isSleeping: true));
    final loaded = await store.load();
    expect(loaded!.hunger, 42.5);
    expect(loaded.isSleeping, isTrue);
    expect(loaded.updatedAt, DateTime(2026, 10, 3));
  });
}
