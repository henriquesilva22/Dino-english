import 'package:flutter/material.dart';

import '../game/pets/pet_catalog.dart';
import '../theme/neon_colors.dart';
import 'animated_glow.dart';
import 'home/tap_scale.dart';
import 'neon_border.dart';

/// One grid cell in the pet selection screen: preview image + name,
/// glowing when selected.
class PetCatalogTile extends StatelessWidget {
  const PetCatalogTile({
    required this.pet,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final PetDefinition pet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? NeonColors.cyan : NeonColors.cyan.withValues(alpha: 0.25);

    final tile = NeonBorder(
      color: color,
      radius: 18,
      borderWidth: selected ? 2 : 1,
      child: Container(
        color: NeonColors.surface.withValues(alpha: 0.85),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.asset(pet.previewAsset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 4),
            Text(
              pet.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: NeonColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    return TapScale(
      onTap: onTap,
      child: selected
          ? AnimatedGlow(color: NeonColors.cyan, borderRadius: 18, child: tile)
          : tile,
    );
  }
}
