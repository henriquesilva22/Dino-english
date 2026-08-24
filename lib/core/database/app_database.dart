import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/app_settings_table.dart';
import 'tables/daily_activity_log_table.dart';
import 'tables/dino_evolution_state_table.dart';
import 'tables/exercise_attempts_table.dart';
import 'tables/seed_metadata_table.dart';
import 'tables/user_profile_table.dart';
import 'tables/word_progress_table.dart';
import 'tables/words_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Words,
    WordProgress,
    UserProfile,
    DailyActivityLog,
    ExerciseAttempts,
    DinoEvolutionState,
    AppSettings,
    SeedMetadata,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] is injectable so tests can pass `NativeDatabase.memory()`
  /// instead of the real on-device file.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'dino_english'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
  );
}
