import 'package:drift/drift.dart';

import 'words_table.dart';

/// Spaced-repetition state for one word. A row is created lazily on first
/// exposure, not pre-populated for every seeded word, so re-seeding
/// [Words] never touches this table.
@DataClassName('WordProgressRow')
class WordProgress extends Table {
  TextColumn get wordId => text().references(Words, #id)();
  IntColumn get masteryLevel => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get incorrectCount => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  BoolColumn get lastResultCorrect => boolean().nullable()();
  IntColumn get timesShownTotal => integer().withDefault(const Constant(0))();
  DateTimeColumn get introducedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {wordId};
}
