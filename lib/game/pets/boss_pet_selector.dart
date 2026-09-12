import 'pet_catalog.dart';

/// Preferred boss looks -- bigger/fiercer-reading animals from the same
/// catalog the player picks their own pet from, reused as the enemy
/// visual per the user's explicit go-ahead rather than new boss art.
const List<String> _bossPreferredIds = ['tiger', 'lion', 'polar', 'hog'];

/// Picks a boss pet distinct from the player's own choice. Kept separate
/// from `pet_catalog.dart` (pure data by design) since this is a
/// selection rule, not data.
PetDefinition pickBossPet(PetDefinition playerPet) {
  return kPetCatalog.firstWhere(
    (p) => p.id != playerPet.id && _bossPreferredIds.contains(p.id),
    orElse: () => kPetCatalog.firstWhere((p) => p.id != playerPet.id),
  );
}
