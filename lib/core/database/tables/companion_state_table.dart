import 'package:drift/drift.dart';

/// Single-row table (id is always 1): the virtual companion's needs
/// (`CompanionState`). Each need is a 0..100 "satisfied" level; decay is
/// computed from [updatedAt] when the app opens, so nothing has to run
/// in the background. Added in schema v3.
@DataClassName('CompanionStateRow')
class CompanionStates extends Table {
  @override
  String get tableName => 'companion_state';

  IntColumn get id => integer()();
  RealColumn get hunger => real()();
  RealColumn get thirst => real()();
  RealColumn get energy => real()();
  RealColumn get happiness => real()();
  BoolColumn get isSleeping => boolean().withDefault(const Constant(false))();

  /// Care XP granted on [careXpDate] (`YYYY-MM-DD`), for the daily cap.
  IntColumn get careXpToday => integer().withDefault(const Constant(0))();
  TextColumn get careXpDate => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
