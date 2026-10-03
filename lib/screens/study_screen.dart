import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repositories/progress_repository.dart';
import '../core/services/level_curve.dart';
import '../providers/home_providers.dart';
import '../providers/immersion_mode_providers.dart';
import '../providers/navigation_providers.dart';
import '../providers/study_providers.dart';
import '../theme/neon_colors.dart';
import '../widgets/answer_option_button.dart';
import '../widgets/glow_button.dart';
import '../widgets/neon_background.dart';
import '../widgets/neon_panel.dart';
import '../widgets/speech_button.dart';
import '../widgets/streak_badge.dart';
import '../widgets/study/learn_word_card.dart';
import '../widgets/study/study_setup_view.dart';
import '../widgets/xp_level_card.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final started = ref.watch(studySessionStartedProvider);

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: started
              ? const _StudySessionContent()
              : const StudySetupView(),
        ),
      ),
    );
  }
}

/// The session itself, unchanged from before Modo Imersão except that it
/// no longer starts loading until `StudyScreen` decides to build it (once
/// `studySessionStartedProvider` is true) -- `studySessionProvider` is
/// lazy by default, so simply not watching it yet is enough to defer
/// `_loadSession()`'s DB work until COMEÇAR is tapped.
class _StudySessionContent extends ConsumerWidget {
  const _StudySessionContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(studySessionProvider);

    return session.isLoading
        ? const Center(child: CircularProgressIndicator())
        : session.items.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhuma palavra disponível para estudar agora. Volte mais tarde!',
                textAlign: TextAlign.center,
                style: TextStyle(color: NeonColors.textPrimary),
              ),
            ),
          )
        : session.isComplete
        ? _SessionSummary(session: session)
        : session.isLearningStep
        ? LearnWordCard(session: session)
        : _QuestionView(session: session);
  }
}

class _QuestionView extends ConsumerWidget {
  const _QuestionView({required this.session});

  final StudySessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(studySessionProvider.notifier);
    final question = session.currentQuestion;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (session.currentIndex + 1) / session.items.length,
              minHeight: 6,
              backgroundColor: NeonColors.surface,
              color: NeonColors.cyan,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Palavra ${session.currentIndex + 1} de ${session.items.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: NeonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          NeonPanel(
            accentColor: NeonColors.purple,
            child: Column(
              children: [
                Text(
                  'QUAL O SIGNIFICADO DE:',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: NeonColors.purple,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        question.word.englishTerm,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NeonColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SpeechButton(text: question.word.englishTerm),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = question.options[index];
                final isCorrectOption = option.wordId == question.word.id;
                final isSelected = option.wordId == session.selectedWordId;

                AnswerOptionVisualState state;
                if (!session.isAnswered) {
                  state = isSelected
                      ? AnswerOptionVisualState.selected
                      : AnswerOptionVisualState.idle;
                } else if (isCorrectOption) {
                  state = AnswerOptionVisualState.correct;
                } else if (isSelected) {
                  state = AnswerOptionVisualState.wrongSelected;
                } else {
                  state = AnswerOptionVisualState.idle;
                }

                return AnswerOptionButton(
                  label: option.answerText,
                  state: state,
                  onTap: session.isAnswered
                      ? null
                      : () => controller.selectOption(option.wordId),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (session.isAnswered) ...[
            _FeedbackBanner(session: session),
            const SizedBox(height: 12),
          ],
          GlowButton(
            label: session.isAnswered ? 'Continuar' : 'Confirmar',
            color: NeonColors.cyan,
            onTap: !session.isAnswered
                ? (session.selectedWordId == null
                      ? () {}
                      : controller.submitAnswer)
                : controller.nextQuestion,
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.session});

  final StudySessionState session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = session.lastResult;
    final wasCorrect =
        session.selectedWordId == session.currentQuestion.word.id;
    final color = wasCorrect ? NeonColors.green : NeonColors.red;

    final messages = <String>[
      wasCorrect ? 'Certinho! 🎉' : 'Quase! A resposta certa está em verde.',
    ];
    if (result != null) {
      if (result.xpAwarded > 0) messages.add('+${result.xpAwarded} XP');
      if (result.leveledUp) {
        messages.add('Subiu para o nível ${result.newLevel}!');
      }
      if (result.hatchedJustNow) messages.add('O ovo eclodiu! 🥚');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        messages.join('  •  '),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: NeonColors.textPrimary,
        ),
      ),
    );
  }
}

class _SessionSummary extends ConsumerWidget {
  const _SessionSummary({required this.session});

  final StudySessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileStreamProvider);
    final correct = session.blockResults.where((a) => a.wasCorrect).toList();
    final wrong = session.blockResults.where((a) => !a.wasCorrect).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Bloco concluído!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: NeonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${session.sessionCorrectCount} de ${session.items.length} certas',
            style: theme.textTheme.titleMedium?.copyWith(
              color: NeonColors.textPrimary,
            ),
          ),
          Text(
            '+${session.sessionXpEarned} XP neste bloco',
            style: theme.textTheme.titleMedium?.copyWith(
              color: NeonColors.purple,
            ),
          ),
          const SizedBox(height: 20),
          if (correct.isNotEmpty)
            _ResultList(
              title: '✅ Acertos',
              color: NeonColors.green,
              attempts: correct,
            ),
          if (wrong.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ResultList(
              title: '❌ Erros',
              color: NeonColors.red,
              attempts: wrong,
            ),
          ],
          const SizedBox(height: 20),
          profileAsync.when(
            data: (profile) => _LevelStatus(currentLevel: profile.currentLevel),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          GlowButton(
            label: 'Continuar',
            color: NeonColors.green,
            onTap: () =>
                ref.read(studySessionProvider.notifier).startNewBlock(),
          ),
          const SizedBox(height: 10),
          GlowButton(
            label: 'Voltar para a Home',
            color: NeonColors.cyan,
            filled: false,
            onTap: () {
              ref.invalidate(studySessionProvider);
              ref.read(studySessionStartedProvider.notifier).reset();
              ref.read(selectedTabIndexProvider.notifier).select(0);
            },
          ),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.title,
    required this.color,
    required this.attempts,
  });

  final String title;
  final Color color;
  final List<StudyBlockAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          for (final attempt in attempts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${attempt.word.englishTerm} → ${attempt.word.portugueseTranslation}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: NeonColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelStatus extends StatelessWidget {
  const _LevelStatus({required this.currentLevel});

  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atMaxLevel = currentLevel >= LevelCurve.maxLevel;
    return Text(
      atMaxLevel
          ? 'Nível $currentLevel — você já está no nível máximo! 🏆'
          : 'Nível $currentLevel — próximo nível: ${currentLevel + 1}',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: NeonColors.textSecondary,
      ),
    );
  }
}
