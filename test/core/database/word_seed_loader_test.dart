import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/database/seed/word_seed_loader.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late WordSeedLoader loader;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    loader = WordSeedLoader(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds every word from the bundled JSON on first run', () async {
    await loader.seedIfNeeded();

    final words = await database.select(database.words).get();
    expect(words, hasLength(120));

    final versionRow = await (database.select(
      database.seedMetadata,
    )..where((tbl) => tbl.key.equals('seed_word_bank_version'))).getSingle();
    expect(versionRow.value, isNotEmpty);
  });

  test('running twice does not duplicate rows or error', () async {
    await loader.seedIfNeeded();
    await loader.seedIfNeeded();

    final words = await database.select(database.words).get();
    expect(words, hasLength(120));
  });

  test('re-seeding never touches an existing word_progress row', () async {
    await loader.seedIfNeeded();

    const wordId = 'word.animals.dog';
    await database
        .into(database.wordProgress)
        .insert(
          WordProgressCompanion.insert(
            wordId: wordId,
            masteryLevel: const Value(4),
          ),
        );

    await loader.seedIfNeeded();

    final progress = await (database.select(
      database.wordProgress,
    )..where((tbl) => tbl.wordId.equals(wordId))).getSingle();
    expect(progress.masteryLevel, 4);
  });
}
