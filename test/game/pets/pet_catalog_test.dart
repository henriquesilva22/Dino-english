import 'package:dino_english/game/pets/pet_catalog.dart';
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
}
