import 'package:drift/drift.dart';

/// Content table, seeded from `assets/seed/words_seed.json`.
///
/// [id] is a stable slug (e.g. `word.animals.dog`), not an autoincrement
/// int, so re-seeding on app updates is a safe upsert-by-key that never
/// disturbs a user's [WordProgress] row for that word.
@DataClassName('Word')
class Words extends Table {
  TextColumn get id => text()();
  TextColumn get englishTerm => text()();
  TextColumn get portugueseTranslation => text()();
  TextColumn get category => text()();
  IntColumn get difficulty => integer()();
  IntColumn get recommendedLevel => integer()();
  TextColumn get exampleSentenceEn => text()();
  TextColumn get exampleSentencePt => text()();

  /// Optional JSON list of every sense of the word (`light` -> luz /
  /// leve), each `{pt, pos, example_en, example_pt}`. The first entry is
  /// the primary sense and always matches [portugueseTranslation], which
  /// stays the single answer quizzes grade against. Null for words with
  /// only one sense. Added in schema v2.
  TextColumn get sensesJson => text().nullable()();
  TextColumn get pronunciationAudioAsset => text().nullable()();
  TextColumn get imageAsset => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
