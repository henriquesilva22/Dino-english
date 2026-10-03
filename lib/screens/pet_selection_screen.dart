import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/single_navigation_guard.dart';
import '../game/pets/pet_catalog.dart';
import '../game/sound/adventure_sfx.dart';
import '../providers/minigame_providers.dart';
import '../providers/pet_adventure_providers.dart';
import '../theme/neon_colors.dart';
import '../widgets/glow_button.dart';
import '../widgets/neon_background.dart';
import '../widgets/pet_catalog_tile.dart';
import '../widgets/pet_model_viewer.dart';
import 'pet_adventure_game_screen.dart';

/// "ESCOLHA SEU PET" -- the Aventura tab's entry point. Grid of the 24
/// Kenney animals (2D preview thumbnails), a 3D showcase of whichever is
/// currently selected, and the button that starts the platformer.
class PetSelectionScreen extends ConsumerWidget {
  const PetSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedId = ref.watch(selectedPetIdProvider);
    final selectedPet = selectedPetOrFallback(selectedId);

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'ESCOLHA SEU PET',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: NeonColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              PetModelViewer(
                modelAsset: selectedPet.modelAsset,
                label: selectedPet.displayName,
                height: 200,
              ),
              Text(
                selectedPet.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: NeonColors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: kPetCatalog.length,
                  itemBuilder: (context, index) {
                    final pet = kPetCatalog[index];
                    return PetCatalogTile(
                      pet: pet,
                      selected: pet.id == selectedId,
                      onTap: () {
                        ref.read(selectedPetIdProvider.notifier).select(pet.id);
                        ref
                            .read(adventureSoundServiceProvider)
                            .play(AdventureSfx.select);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    GlowButton(
                      label: 'COMEÇAR AVENTURA',
                      color: NeonColors.green,
                      onTap: () => SingleNavigationGuard.run(() {
                        resetMinigameState(ref, isBossFight: false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PetAdventureGameScreen(
                              isBossFight: false,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    GlowButton(
                      label: 'DESAFIAR O CHEFE',
                      color: NeonColors.red,
                      onTap: () => SingleNavigationGuard.run(() {
                        resetMinigameState(ref, isBossFight: true);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const PetAdventureGameScreen(isBossFight: true),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
