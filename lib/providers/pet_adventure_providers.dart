import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/pets/pet_catalog.dart';
import '../game/sound/adventure_sound_service.dart';

PetDefinition selectedPetOrFallback(String id) =>
    kPetCatalog.firstWhere((p) => p.id == id, orElse: () => kPetCatalog.first);

class SelectedPetIdNotifier extends Notifier<String> {
  @override
  String build() => kPetCatalog.first.id;

  void select(String id) => state = id;
}

/// Which pet the player picked for the current session. In-memory only
/// (not persisted to the database) -- see plan decision #3: adding this
/// to `AppSettings` would require a schema migration, out of scope.
final selectedPetIdProvider =
    NotifierProvider<SelectedPetIdNotifier, String>(SelectedPetIdNotifier.new);

/// Shared sound service for Pet Adventure -- only read from
/// navigation/tap-reachable code, never at app boot (see
/// `AdventureSoundService`'s doc comment).
final adventureSoundServiceProvider = Provider<AdventureSoundService>(
  (ref) => FlameAdventureSoundService(),
);
