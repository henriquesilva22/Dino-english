import 'package:drift/drift.dart';

import '../companion/companion_engine.dart';
import '../companion/companion_state.dart';
import '../database/app_database.dart';

/// Drift-backed [CompanionStateStore]: the companion's needs live in the
/// single-row `companion_state` table of the app database.
class DriftCompanionStateStore implements CompanionStateStore {
  const DriftCompanionStateStore(this._database);

  final AppDatabase _database;

  @override
  Future<CompanionState?> load() async {
    final row = await (_database.select(
      _database.companionStates,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return null;
    return CompanionState(
      hunger: row.hunger,
      thirst: row.thirst,
      energy: row.energy,
      happiness: row.happiness,
      isSleeping: row.isSleeping,
      careXpToday: row.careXpToday,
      careXpDate: row.careXpDate,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> save(CompanionState state) => _database
      .into(_database.companionStates)
      .insertOnConflictUpdate(
        CompanionStatesCompanion.insert(
          id: const Value(1),
          hunger: state.hunger,
          thirst: state.thirst,
          energy: state.energy,
          happiness: state.happiness,
          isSleeping: Value(state.isSleeping),
          careXpToday: Value(state.careXpToday),
          careXpDate: Value(state.careXpDate),
          updatedAt: state.updatedAt,
        ),
      );
}
