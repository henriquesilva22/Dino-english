import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/repositories/progress_repository.dart';
import 'repository_providers.dart';

final userProfileStreamProvider = StreamProvider<UserProfileRow>((ref) {
  return ref.watch(progressRepositoryProvider).watchUserProfile();
});

final dinoEvolutionStreamProvider = StreamProvider<DinoEvolutionStateRow>((
  ref,
) {
  return ref.watch(progressRepositoryProvider).watchDinoEvolutionState();
});

/// One-shot aggregate queries, invalidated manually right after any
/// `recordAnswer` call (see StudySessionController / MinigameController) --
/// that invalidation is what makes the Home reflect a finished session
/// immediately.
final masteryStatsProvider = FutureProvider.autoDispose<WordMasteryStats>((
  ref,
) {
  return ref.watch(progressRepositoryProvider).fetchMasteryStats();
});

final eggProgressProvider = FutureProvider.autoDispose<EggProgressInfo>((ref) {
  return ref.watch(progressRepositoryProvider).fetchEggProgress();
});
