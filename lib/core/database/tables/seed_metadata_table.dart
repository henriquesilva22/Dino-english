import 'package:drift/drift.dart';

/// Small key/value table for content-versioning (e.g. which seed word
/// bank version is currently loaded). Kept separate from [AppSettings]
/// since this is content bookkeeping, not a user preference.
@DataClassName('SeedMetadataRow')
class SeedMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
