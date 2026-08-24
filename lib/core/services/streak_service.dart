/// Study-streak logic built on distinct local-calendar active days.
///
/// Shares its notion of "active day" with the egg-hatching progress
/// ([HatchingService]) by design -- both read the same
/// `daily_activity_log` rows, just aggregated differently.
class StreakService {
  const StreakService({this.activeDayThreshold = 5});

  /// Exercises needed in one day for it to count as an active day.
  final int activeDayThreshold;

  bool countsAsActiveDay(int exercisesCompletedToday) =>
      exercisesCompletedToday >= activeDayThreshold;

  /// Current streak as of [today]: consecutive active days ending today
  /// or yesterday. Ending "yesterday" is allowed so a streak isn't
  /// considered broken while today simply hasn't been studied yet.
  ///
  /// [activeDates] should contain only dates that already count as
  /// active (time-of-day is ignored/stripped).
  int currentStreak({
    required Set<DateTime> activeDates,
    required DateTime today,
  }) {
    final dates = activeDates.map(_stripTime).toSet();
    final normalizedToday = _stripTime(today);

    var cursor = dates.contains(normalizedToday)
        ? normalizedToday
        : normalizedToday.subtract(const Duration(days: 1));

    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
