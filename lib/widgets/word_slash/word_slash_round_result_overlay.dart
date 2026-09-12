import 'package:flutter/material.dart';

import '../../game/word_slash/word_slash_session_state.dart';
import '../../theme/neon_colors.dart';
import '../glow_button.dart';
import '../minigame_stat_row.dart';
import '../neon_panel.dart';

/// Shown when a round's timer hits zero -- mirrors
/// `MinigameVictoryOverlay`'s structure (panel + stat rows + two buttons),
/// with Word Slash's own stat shape (pares/acertos/erros/precisão/combo).
class WordSlashRoundResultOverlay extends StatelessWidget {
  const WordSlashRoundResultOverlay({
    required this.state,
    required this.onContinue,
    required this.onExit,
    super.key,
  });

  final WordSlashSessionState state;

  /// "PRÓXIMA FASE" or "JOGAR NOVAMENTE" depending on [WordSlashSessionState
  /// .isFinalRound] -- both are in-place resets of the same controller (see
  /// `WordSlashSessionState.startRound`'s doc comment), so the caller can
  /// wire a single callback regardless of which label is shown.
  final VoidCallback onContinue;

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunComplete = state.isFinalRound;

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: NeonPanel(
                accentColor: NeonColors.cyan,
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isRunComplete
                          ? 'TODAS AS FASES CONCLUÍDAS!'
                          : 'FASE ${state.roundNumber} CONCLUÍDA!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: NeonColors.cyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    MinigameStatRow(
                      icon: '⭐',
                      label: 'Pontuação',
                      value: '${state.score}',
                    ),
                    const SizedBox(height: 8),
                    MinigameStatRow(
                      icon: '🔗',
                      label: 'Pares',
                      value: '${state.pairsMatched}',
                    ),
                    const SizedBox(height: 8),
                    MinigameStatRow(
                      icon: '✅',
                      label: 'Acertos',
                      value: '${state.correctCount}',
                      valueColor: NeonColors.green,
                    ),
                    const SizedBox(height: 8),
                    MinigameStatRow(
                      icon: '❌',
                      label: 'Erros',
                      value: '${state.wrongCount}',
                      valueColor: NeonColors.red,
                    ),
                    const SizedBox(height: 8),
                    MinigameStatRow(
                      icon: '🎯',
                      label: 'Precisão',
                      value: '${(state.accuracy * 100).round()}%',
                    ),
                    const SizedBox(height: 8),
                    MinigameStatRow(
                      icon: '🔥',
                      label: 'Combo máximo',
                      value: 'x${state.maxCombo}',
                      valueColor: NeonColors.purple,
                    ),
                    const SizedBox(height: 24),
                    GlowButton(
                      label: isRunComplete ? 'JOGAR NOVAMENTE' : 'PRÓXIMA FASE',
                      color: NeonColors.green,
                      onTap: onContinue,
                    ),
                    const SizedBox(height: 10),
                    GlowButton(
                      label: 'SAIR',
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
