import 'package:drift/drift.dart';

/// The conversation with the companion, kept across visits (the history
/// sheet). One row per exchange: what the child said and the Dino's
/// answer in both languages. Added in schema v4.
@DataClassName('CompanionHistoryRow')
class CompanionHistory extends Table {
  @override
  String get tableName => 'companion_history';

  IntColumn get id => integer().autoIncrement()();

  /// What the child said or typed (null for the Dino's own lines, like the
  /// greeting or an activity).
  TextColumn get childText => text().nullable()();
  BoolColumn get viaVoice => boolean().withDefault(const Constant(false))();
  TextColumn get englishText => text()();
  TextColumn get portugueseText => text().nullable()();

  /// `CompanionIntent.name` (open vocabulary: no migration for new ones).
  TextColumn get intent => text().nullable()();

  /// English word detected/taught in the exchange.
  TextColumn get word => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
