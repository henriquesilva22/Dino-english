import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/study_providers.dart';
import '../../theme/neon_colors.dart';
import '../glow_button.dart';
import '../neon_panel.dart';
import '../speech_button.dart';
import '../streak_badge.dart';
import '../xp_level_card.dart';

/// "Aprender" step: word + translation + example sentence, each speakable,
/// using only real data already on [StudyQuestion.word] (no invented
/// content). Never speaks on its own; the learner has to tap a
/// [SpeechButton]. Shown for a brand-new word (translation/sentence
/// visible immediately -- nothing to "try to recall" for a word never seen
/// before), or for an already-known word under Modo Imersão (translation/
/// sentence hidden behind a reveal button, encouraging recall first).
class LearnWordCard extends ConsumerWidget {
  const LearnWordCard({required this.session, super.key});

  final StudySessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(studySessionProvider.notifier);
    final question = session.currentQuestion;
    final word = question.word;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [StreakBadge(), XpLevelCard()],
          ),
          const SizedBox(height: 16),
          Text(
            question.isNewWord ? 'PALAVRA NOVA' : 'MODO IMERSÃO',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: NeonColors.purple,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: NeonPanel(
                  accentColor: NeonColors.cyan,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              word.englishTerm,
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: NeonColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SpeechButton(text: word.englishTerm),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (session.isWordTranslationRevealed)
                        Text(
                          word.portugueseTranslation,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: NeonColors.textSecondary,
                          ),
                        )
                      else
                        _RevealButton(
                          label: 'Ver tradução',
                          onTap: controller.revealWordTranslation,
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              word.exampleSentenceEn,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: NeonColors.textPrimary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SpeechButton(text: word.exampleSentenceEn),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (session.isSentenceTranslationRevealed)
                        Text(
                          word.exampleSentencePt,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: NeonColors.textSecondary,
                          ),
                        )
                      else
                        _RevealButton(
                          label: 'Ver tradução da frase',
                          onTap: controller.revealSentenceTranslation,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: 'CONTINUAR',
            color: NeonColors.cyan,
            onTap: controller.finishLearningStep,
          ),
        ],
      ),
    );
  }
}

/// Small, textual, contextual reveal action -- deliberately not a full
/// [GlowButton]: this is meant to nudge the learner to try recalling the
/// translation first, not compete visually with the word itself.
class _RevealButton extends StatelessWidget {
  const _RevealButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.visibility, size: 18, color: NeonColors.cyan),
      label: Text(
        label,
        style: const TextStyle(
          color: NeonColors.cyan,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
