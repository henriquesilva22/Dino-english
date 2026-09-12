import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the "Modo Imersão" toggle is on for study sessions. In-memory
/// only (not persisted to the database) -- same tradeoff already made for
/// `selectedPetIdProvider` in `pet_adventure_providers.dart`: adding this
/// to `AppSettings` would require a real Drift migration, out of scope.
/// Deliberately its own file, separate from `study_providers.dart`, so the
/// "Modo Imersão" name/concept stays easy to rename or reconfigure later.
class ImmersionModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final immersionModeEnabledProvider =
    NotifierProvider<ImmersionModeNotifier, bool>(ImmersionModeNotifier.new);

/// Whether the learner has confirmed the study setup screen and moved into
/// an actual session. Gates `StudyScreen` from ever watching
/// `studySessionProvider` (and therefore starting `_loadSession()`'s DB
/// work) until they do. Reset alongside `studySessionProvider` being
/// invalidated at the end of a session, so setup -- including the
/// Modo Imersão toggle -- is shown again for the next one.
class StudySessionStartedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void start() => state = true;
  void reset() => state = false;
}

final studySessionStartedProvider =
    NotifierProvider<StudySessionStartedNotifier, bool>(
      StudySessionStartedNotifier.new,
    );
