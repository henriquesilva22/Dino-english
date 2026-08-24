import 'package:drift/drift.dart';

import 'words_table.dart';

/// Append-only history of every answered exercise.
///
/// [exerciseType] and [sessionKind] are open string enums on purpose: a
/// new exercise type or session kind (e.g. `exam` later) is just a new
/// string value, never a migration.
@DataClassName('ExerciseAttempt')
@TableIndex(name: 'idx_exercise_attempts_word_id', columns: {#wordId})
@TableIndex(name: 'idx_exercise_attempts_attempted_at', columns: {#attemptedAt})
class ExerciseAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// Nullable on purpose: not every exercise type maps to exactly one
  /// word (e.g. a future matching/grammar-only item).
  TextColumn get wordId => text().nullable().references(Words, #id)();
  TextColumn get exerciseType => text()();
  TextColumn get sessionId => text()();
  TextColumn get sessionKind => text()();
  BoolColumn get wasCorrect => boolean()();
  TextColumn get userAnswer => text().nullable()();
  IntColumn get masteryLevelBefore => integer()();
  IntColumn get masteryLevelAfter => integer()();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  IntColumn get responseTimeMs => integer().nullable()();
  DateTimeColumn get attemptedAt => dateTime()();
}
