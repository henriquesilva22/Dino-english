import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repositories/progress_repository.dart';
import '../core/repositories/word_repository.dart';
import 'database_providers.dart';

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return WordRepository(ref.watch(databaseProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(databaseProvider));
});
