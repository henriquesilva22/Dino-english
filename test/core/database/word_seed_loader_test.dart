import 'dart:convert';

import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/database/seed/word_seed_loader.dart';
import 'package:drift/drift.dart' hide isNull;
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
    expect(words, hasLength(267));

    final versionRow = await (database.select(
      database.seedMetadata,
    )..where((tbl) => tbl.key.equals('seed_word_bank_version'))).getSingle();
    expect(versionRow.value, isNotEmpty);
  });

  test('running twice does not duplicate rows or error', () async {
    await loader.seedIfNeeded();
    await loader.seedIfNeeded();

    final words = await database.select(database.words).get();
    expect(words, hasLength(267));
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

  test('every english term is unique across the 267 words', () async {
    await loader.seedIfNeeded();

    final words = await database.select(database.words).get();
    final terms = words.map((w) => w.englishTerm.toLowerCase()).toList();
    expect(terms.toSet(), hasLength(terms.length));
  });

  test('stores every sense of a multi-meaning word', () async {
    await loader.seedIfNeeded();

    final light = await (database.select(
      database.words,
    )..where((tbl) => tbl.id.equals('word.objects.light'))).getSingle();
    expect(light.portugueseTranslation, 'luz');
    final senses = (jsonDecode(light.sensesJson!) as List)
        .map((s) => (s as Map<String, dynamic>)['pt'])
        .toList();
    expect(senses, ['luz', 'leve']);

    final dog = await (database.select(
      database.words,
    )..where((tbl) => tbl.id.equals('word.animals.dog'))).getSingle();
    expect(dog.sensesJson, isNull);
  });

  test('the first sense is always the primary translation', () async {
    await loader.seedIfNeeded();

    final words = await database.select(database.words).get();
    for (final word in words.where((w) => w.sensesJson != null)) {
      final first = (jsonDecode(word.sensesJson!) as List).first as Map;
      expect(
        first['pt'],
        startsWith(word.portugueseTranslation),
        reason: word.id,
      );
    }
  });
}
