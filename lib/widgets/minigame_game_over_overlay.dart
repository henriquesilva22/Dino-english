import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/single_navigation_guard.dart';
import '../game/pet_adventure_game.dart';
import '../providers/minigame_providers.dart';
import '../providers/pet_adventure_providers.dart';
import '../screens/pet_adventure_game_screen.dart';
import '../theme/neon_colors.dart';
import 'glow_button.dart';
import 'minigame_stat_row.dart';
import 'neon_panel.dart';

/// Result modal shown when the round ends in a loss (0 lives) -- a
/// rounded neon card over a dark backdrop. Shown for both the normal
/// round and a boss fight ended by running out of lives (a boss fight
/// ended by defeating the boss instead shows [MinigameVictoryOverlay]).
class MinigameGameOverOverlay extends ConsumerWidget {
  const MinigameGameOverOverlay({
    required this.game,
    required this.onExit,
    this.isBossFight = false,
    super.key,
  });

  /// The round's game instance -- "JOGAR NOVAMENTE" ends its session
  /// before replacing the screen (see the button below).
  final PetAdventureGame game;

  /// "VOLTAR PARA HOME" -- the same centralized exit path
  /// `_PetAdventurePlayAreaState._exitGame` uses everywhere else, so this
  /// button doesn't do its own, different thing.
  final VoidCallback onExit;

  final bool isBossFight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(minigameControllerProvider);
    final theme = Theme.of(context);
    final pet = selectedPetOrFallback(ref.watch(selectedPetIdProvider));

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: NeonPanel(
                accentColor: NeonColors.purple,
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1.0),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Image.asset(pet.previewAsset, height: 88),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FIM DE JOGO',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: NeonColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Aventura de ${pet.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NeonColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    MinigameStatRow(
                      icon: '📘',
                      label: 'Você coletou',
                      value: '${state.correctWordsCollected.length} palavras',
                    ),
                    const SizedBox(height: 8),
                    MinigameStatRow(
                      icon: '⭐',
                      label: 'Pontuação',
                      value: '${state.score}',
                    ),
                    const SizedBox(height: 8),
                    MinigameStatRow(
                      icon: '✨',
                      label: 'XP ganho',
                      value: '+${state.xpEarned}',
                      valueColor: NeonColors.cyan,
                    ),
                    const SizedBox(height: 24),
                    GlowButton(
                      label: 'JOGAR NOVAMENTE',
                      color: NeonColors.green,
                      onTap: () => SingleNavigationGuard.run(() async {
                        // Awaited: the old session's music must actually
                        // be stopped before the new screen's onLoad()
                        // starts its own, not just "eventually" via a
                        // dispose() that fires ~300ms later.
                        await game.endSession();
                        if (!context.mounted) return;
                        resetMinigameState(ref, isBossFight: isBossFight);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => PetAdventureGameScreen(
                              isBossFight: isBossFight,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    GlowButton(
                      label: 'VOLTAR PARA HOME',
                      color: NeonColors.cyan,
                      filled: false,
                      onTap: onExit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
