import 'package:dino_english/game/pets/boss_pet_selector.dart';
import 'package:dino_english/game/pets/pet_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'boss pet is never the same as the player pet, for every catalog pet',
    () {
      for (final playerPet in kPetCatalog) {
        final boss = pickBossPet(playerPet);
        expect(boss.id, isNot(playerPet.id));
      }
    },
  );

  test('prefers one of the fierce-reading animals when available', () {
    final dog = kPetCatalog.firstWhere((p) => p.id == 'dog');

    final boss = pickBossPet(dog);

    expect(['tiger', 'lion', 'polar', 'hog'], contains(boss.id));
  });

  test(
    'falls back to any other pet if the player picked every preferred boss id',
    () {
      final tiger = kPetCatalog.firstWhere((p) => p.id == 'tiger');

      final boss = pickBossPet(tiger);

      expect(boss.id, isNot('tiger'));
    },
  );
}
