import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/app_settings_table.dart';
import 'tables/companion_history_table.dart';
import 'tables/companion_state_table.dart';
import 'tables/daily_activity_log_table.dart';
import 'tables/dino_memories_table.dart';
import 'tables/dino_evolution_state_table.dart';
import 'tables/exercise_attempts_table.dart';
import 'tables/food_unlocks_table.dart';
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
    DinoMemories,
    CompanionStates,
    CompanionHistory,
    FoodUnlocks,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] is injectable so tests can pass `NativeDatabase.memory()`
  /// instead of the real on-device file.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'dino_english'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v2 (DinoBrain): multi-sense words + the Dino's conversation
      // memory. The seed loader re-writes `senses_json` because the
      // seed version was bumped alongside this migration.
      if (from < 2) {
        await m.addColumn(words, words.sensesJson);
        await m.createTable(dinoMemories);
      }
      // v3: the virtual companion's needs (hunger, thirst, energy...).
      if (from < 3) {
        await m.createTable(companionStates);
      }
      // v4: the companion's conversation history.
      if (from < 4) {
        await m.createTable(companionHistory);
      }
      // v5: coins + the Dino's food shop.
      if (from < 5) {
        if (await _hasTable('user_profile')) {
          await m.addColumn(userProfile, userProfile.coins);
        }
        if (await _hasTable('app_settings')) {
          await m.addColumn(appSettings, appSettings.foodHintSeen);
        }
        await m.createTable(foodUnlocks);
      }
    },
  );

  Future<bool> _hasTable(String name) async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(name)],
    ).get();
    return rows.isNotEmpty;
  }
}
