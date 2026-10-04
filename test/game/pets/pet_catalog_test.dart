import 'package:dino_english/core/companion/model/companion_model.dart';
import 'package:dino_english/game/pets/boss_pet_selector.dart';
import 'package:dino_english/game/pets/pet_catalog.dart';
import 'package:dino_english/providers/pet_adventure_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('has exactly 24 pets', () {
    expect(kPetCatalog, hasLength(24));
  });

  test('every id is unique', () {
    final ids = kPetCatalog.map((p) => p.id).toSet();
    expect(ids, hasLength(kPetCatalog.length));
  });

  test('every asset path is non-empty and references its own id', () {
    for (final pet in kPetCatalog) {
      expect(pet.modelAsset, isNotEmpty);
      expect(pet.previewAsset, isNotEmpty);
      expect(pet.modelAsset, contains('animal-${pet.id}'));
      expect(pet.previewAsset, contains('animal-${pet.id}'));
      expect(pet.displayName, isNotEmpty);
    }
  });

  test('the 3D Dino is playable: first in the list, its own model', () {
    expect(kPlayablePets.first, kDinoPet);
    expect(kPlayablePets, hasLength(kPetCatalog.length + 1));
    expect(kDinoPet.is3D, isTrue);
    expect(kDinoPet.companionModel, CompanionModel.dino);
    expect(kDinoPet.modelAsset, CompanionModel.dino.asset);
    expect(kDinoPet.previewAsset, isNull);
    expect(selectedPetOrFallback('dino'), kDinoPet);
    expect(kPetCatalog.every((p) => !p.is3D), isTrue);
  });

  test('the boss is never the 3D Dino', () {
    expect(pickBossPet(kDinoPet).is3D, isFalse);
  });
}
