import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_bootstrap.dart';
import '../core/database/app_database.dart';
import '../core/database/seed/word_seed_loader.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// Seeds the word bank and ensures the singleton rows exist. `main.dart`
/// waits on this before showing any screen that reads from the database.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(databaseProvider);
  await WordSeedLoader(database).seedIfNeeded();
  await AppBootstrapper(database).ensureSingletonRows();
});
