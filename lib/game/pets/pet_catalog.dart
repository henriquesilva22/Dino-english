import '../../core/companion/model/companion_model.dart';

/// Static catalog of the Pet Adventure companions: the player's own 3D Dino
/// ([kDinoPet]) plus the 24 Kenney 3D animals ([kPetCatalog]). Purely
/// local data -- no persistence, no business rule.
class PetDefinition {
  const PetDefinition({
    required this.id,
    required this.displayName,
    required this.modelAsset,
    this.previewAsset,
    this.companionModel,
    this.emoji = '🐾',
  });

  final String id;
  final String displayName;
  final String modelAsset;

  /// 2D picture (the animals' Kenney previews); null for the 3D Dino.
  final String? previewAsset;

  /// Set for a pet played as its animated 3D model (the Dino), drawn over
  /// the game instead of a 2D sprite.
  final CompanionModel? companionModel;

  /// Stands in for [previewAsset] where there is no picture.
  final String emoji;

  bool get is3D => companionModel != null;
}

/// The companion Dino -- the same animated 3D model as "Brincar com o
/// Dino" -- as a playable Pet Adventure character.
const PetDefinition kDinoPet = PetDefinition(
  id: 'dino',
  displayName: 'Dino',
  modelAsset: 'assets/models/dino/dino_companion.glb',
  companionModel: CompanionModel.dino,
  emoji: '🦖',
);

/// Everything the player can pick: the Dino first, then the animals.
const List<PetDefinition> kPlayablePets = [kDinoPet, ...kPetCatalog];

/// The 24 Kenney animals (2D previews + 3D models).
const List<PetDefinition> kPetCatalog = [
  PetDefinition(
    id: 'beaver',
    displayName: 'Castor',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-beaver.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-beaver.png',
  ),
  PetDefinition(
    id: 'bee',
    displayName: 'Abelha',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-bee.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-bee.png',
  ),
  PetDefinition(
    id: 'bunny',
    displayName: 'Coelho',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-bunny.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-bunny.png',
  ),
  PetDefinition(
    id: 'cat',
    displayName: 'Gato',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-cat.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-cat.png',
  ),
  PetDefinition(
    id: 'caterpillar',
    displayName: 'Lagarta',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-caterpillar.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-caterpillar.png',
  ),
  PetDefinition(
    id: 'chick',
    displayName: 'Pintinho',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-chick.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-chick.png',
  ),
  PetDefinition(
    id: 'cow',
    displayName: 'Vaca',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-cow.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-cow.png',
  ),
  PetDefinition(
    id: 'crab',
    displayName: 'Caranguejo',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-crab.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-crab.png',
  ),
  PetDefinition(
    id: 'deer',
    displayName: 'Cervo',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-deer.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-deer.png',
  ),
  PetDefinition(
    id: 'dog',
    displayName: 'Cachorro',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-dog.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-dog.png',
  ),
  PetDefinition(
    id: 'elephant',
    displayName: 'Elefante',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-elephant.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-elephant.png',
  ),
  PetDefinition(
    id: 'fish',
    displayName: 'Peixe',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-fish.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-fish.png',
  ),
  PetDefinition(
    id: 'fox',
    displayName: 'Raposa',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-fox.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-fox.png',
  ),
  PetDefinition(
    id: 'giraffe',
    displayName: 'Girafa',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-giraffe.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-giraffe.png',
  ),
  PetDefinition(
    id: 'hog',
    displayName: 'Javali',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-hog.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-hog.png',
  ),
  PetDefinition(
    id: 'koala',
    displayName: 'Coala',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-koala.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-koala.png',
  ),
  PetDefinition(
    id: 'lion',
    displayName: 'Leão',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-lion.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-lion.png',
  ),
  PetDefinition(
    id: 'monkey',
    displayName: 'Macaco',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-monkey.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-monkey.png',
  ),
  PetDefinition(
    id: 'panda',
    displayName: 'Panda',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-panda.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-panda.png',
  ),
  PetDefinition(
    id: 'parrot',
    displayName: 'Papagaio',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-parrot.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-parrot.png',
  ),
  PetDefinition(
    id: 'penguin',
    displayName: 'Pinguim',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-penguin.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-penguin.png',
  ),
  PetDefinition(
    id: 'pig',
    displayName: 'Porco',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-pig.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-pig.png',
  ),
  PetDefinition(
    id: 'polar',
    displayName: 'Urso Polar',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-polar.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-polar.png',
  ),
  PetDefinition(
    id: 'tiger',
    displayName: 'Tigre',
    modelAsset: "assets/sprites/characters/Models/GLB/animal-tiger.glb",
    previewAsset: 'assets/sprites/characters/Previews/animal-tiger.png',
  ),
];
