import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/immersion_mode_providers.dart';
import '../../theme/neon_colors.dart';
import '../glow_button.dart';
import '../neon_panel.dart';

/// Shown before a study session starts (gated by
/// `studySessionStartedProvider` in `StudyScreen`) -- lets the learner
/// turn Modo Imersão on/off before COMEÇAR triggers the actual session
/// load. Deliberately small: no word-count picker (not part of what was
/// asked for, and `WordSelectionService`'s count is a target, not a
/// guarantee, so this screen doesn't promise an exact number).
class StudySetupView extends ConsumerWidget {
  const StudySetupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final immersionEnabled = ref.watch(immersionModeEnabledProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ESTUDAR',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: NeonColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Como você quer estudar?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: NeonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          NeonPanel(
            accentColor: NeonColors.purple,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo Imersão',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: NeonColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Veja exemplos, traduções e ouça as palavras enquanto estuda.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: NeonColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: immersionEnabled,
                  activeThumbColor: NeonColors.cyan,
                  onChanged: (value) => ref
                      .read(immersionModeEnabledProvider.notifier)
                      .set(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Uma seleção de palavras para o seu nível.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: NeonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GlowButton(
            label: 'COMEÇAR',
            color: NeonColors.cyan,
            onTap: () => ref.read(studySessionStartedProvider.notifier).start(),
          ),
        ],
      ),
    );
  }
}
