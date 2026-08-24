import 'package:drift/drift.dart';

/// Single-row table (id is always 1) holding XP, level and streak.
///
/// [totalXp] is the source of truth; [currentLevel] is a denormalized
/// cache recomputed and written in the same transaction as [totalXp] so
/// the home screen can read it cheaply via a reactive stream.
@DataClassName('UserProfileRow')
class UserProfile extends Table {
  IntColumn get id => integer()();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get currentLevel => integer().withDefault(const Constant(1))();
  IntColumn get currentStreakDays => integer().withDefault(const Constant(0))();
  IntColumn get longestStreakDays => integer().withDefault(const Constant(0))();
  /// Local calendar date (`YYYY-MM-DD`) of the last study day, stored as
  /// text to avoid timezone-boundary bugs when comparing "same day".
  TextColumn get lastStudyDate => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
