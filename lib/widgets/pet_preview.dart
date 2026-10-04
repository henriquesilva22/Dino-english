import 'package:flutter/material.dart';

import '../game/pets/pet_catalog.dart';

/// A pet's 2D picture, or its emoji when it has none (the 3D Dino).
class PetPreview extends StatelessWidget {
  const PetPreview({
    required this.pet,
    this.height,
    this.fit = BoxFit.contain,
    super.key,
  });

  final PetDefinition pet;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = pet.previewAsset;
    if (asset != null) return Image.asset(asset, height: height, fit: fit);
    return SizedBox(
      height: height,
      child: FittedBox(
        fit: fit,
        child: Text(pet.emoji, style: const TextStyle(fontSize: 64)),
      ),
    );
  }
}
