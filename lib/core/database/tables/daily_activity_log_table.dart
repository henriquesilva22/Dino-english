import 'package:drift/drift.dart';

/// One row per local calendar day with any activity. Backbone for both
/// the study streak and the egg-hatching activity-day count (deliberate
/// reuse) — a day is either active or not, regardless of how many
/// sessions happened in it.
@DataClassName('DailyActivityLogRow')
class DailyActivityLog extends Table {
  /// Local calendar date, `YYYY-MM-DD`. Text, not a DateTime column, so
  /// "same day" comparisons don't depend on time-of-day/timezone.
  TextColumn get studyDate => text()();
  IntColumn get exercisesCompleted => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  /// Flips to true once [exercisesCompleted] crosses the active-day
  /// threshold for that date; recomputed on each write within the day.
  BoolColumn get countsAsActiveDay => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {studyDate};
}
