import 'package:drift/drift.dart';

import 'app_database.dart';

/// Ensures the single-row tables ([UserProfile], [DinoEvolutionState],
/// [AppSettings]) have their id=1 row before anything reads from them.
/// Only inserts a default row when one doesn't already exist yet -- never
/// overwrites existing progress on a subsequent app start.
class AppBootstrapper {
  const AppBootstrapper(this._database);

  final AppDatabase _database;

  Future<void> ensureSingletonRows() async {
    await _database.transaction(() async {
      final profile = await (_database.select(
        _database.userProfile,
      )..where((t) => t.id.equals(1))).getSingleOrNull();
      if (profile == null) {
        await _database
            .into(_database.userProfile)
            .insert(
              UserProfileCompanion.insert(
                id: const Value(1),
                createdAt: DateTime.now(),
              ),
            );
      }

      final dinoState = await (_database.select(
        _database.dinoEvolutionState,
      )..where((t) => t.id.equals(1))).getSingleOrNull();
      if (dinoState == null) {
        await _database
            .into(_database.dinoEvolutionState)
            .insert(DinoEvolutionStateCompanion.insert(id: const Value(1)));
      }

      final settings = await (_database.select(
        _database.appSettings,
      )..where((t) => t.id.equals(1))).getSingleOrNull();
      if (settings == null) {
        await _database
            .into(_database.appSettings)
            .insert(AppSettingsCompanion.insert(id: const Value(1)));
      }
    });
  }
}
