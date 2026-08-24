import 'package:drift/drift.dart';

/// Single-row table (id is always 1) tracking the egg/dino lifecycle.
///
/// [stage] is a cache, always recomputed as a pure function of
/// (current level, hatching-active-day count, hatchedAt) and rewritten
/// transactionally — never hand-set elsewhere. [hatchedAt] is the one
/// genuinely one-way fact worth persisting: once the egg hatches, it
/// never goes back to being an egg.
@DataClassName('DinoEvolutionStateRow')
class DinoEvolutionState extends Table {
  IntColumn get id => integer()();
  TextColumn get stage => text().withDefault(const Constant('eggDormant'))();
  DateTimeColumn get hatchingStartedAt => dateTime().nullable()();
  DateTimeColumn get hatchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
