/// Local calendar date as `YYYY-MM-DD`, zero-padded. The single date
/// formatter used across the project, matching the text format stored in
/// `daily_activity_log.studyDate` and `user_profile.lastStudyDate`.
String dateKeyFor(DateTime dt) {
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
