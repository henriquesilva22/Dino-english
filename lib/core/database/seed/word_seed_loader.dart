import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../app_database.dart';

const _seedVersionKey = 'seed_word_bank_version';
const _defaultAssetPath = 'assets/seed/words_seed.json';

/// Loads the bundled word bank JSON into [AppDatabase.words].
///
/// Safe to call on every app start: it compares the JSON's `seed_version`
/// against [SeedMetadata] and only writes when they differ. Because
/// [WordProgress] rows are created lazily on first exposure (see that
/// table's docs), re-seeding on an app update never disturbs a user's
/// existing SRS progress, even if wording/examples change.
class WordSeedLoader {
  WordSeedLoader(
    this._database, {
    AssetBundle? assetBundle,
    this._assetPath = _defaultAssetPath,
  }) : _assetBundle = assetBundle ?? rootBundle;

  final AppDatabase _database;
  final AssetBundle _assetBundle;
  final String _assetPath;

  Future<void> seedIfNeeded() async {
    final raw = await _assetBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final seedVersion = json['seed_version'] as String;
    final wordsJson = (json['words'] as List).cast<Map<String, dynamic>>();

    if (await _readSeedVersion() == seedVersion) {
      return;
    }

    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.words,
        wordsJson.map(_wordFromJson).toList(),
      );
    });

    await _database
        .into(_database.seedMetadata)
        .insertOnConflictUpdate(
          SeedMetadataCompanion.insert(
            key: _seedVersionKey,
            value: seedVersion,
          ),
        );
  }

  Future<String?> _readSeedVersion() async {
    final row = await (_database.select(
      _database.seedMetadata,
    )..where((tbl) => tbl.key.equals(_seedVersionKey))).getSingleOrNull();
    return row?.value;
  }

  WordsCompanion _wordFromJson(Map<String, dynamic> json) {
    return WordsCompanion.insert(
      id: json['id'] as String,
      englishTerm: json['english_term'] as String,
      portugueseTranslation: json['portuguese_translation'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as int,
      recommendedLevel: json['recommended_level'] as int,
      exampleSentenceEn: json['example_sentence_en'] as String,
      exampleSentencePt: json['example_sentence_pt'] as String,
    );
  }
}
