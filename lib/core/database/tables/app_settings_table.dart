import 'package:drift/drift.dart';

/// Single-row table (id is always 1) for user-editable preferences.
@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer()();
  BoolColumn get soundEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get dailyGoalExercises =>
      integer().withDefault(const Constant(10))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
