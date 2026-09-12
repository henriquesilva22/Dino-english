import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/exam_session_providers.dart';
import '../theme/neon_colors.dart';
import '../widgets/answer_option_button.dart';
import '../widgets/exit_top_bar.dart';
import '../widgets/glow_button.dart';
import '../widgets/neon_background.dart';
import '../widgets/neon_panel.dart';
import '../widgets/streak_badge.dart';
import '../widgets/xp_level_card.dart';

/// "Provas": review-only multiple choice (no new words -- see
/// `ExamSessionController`'s `SessionKind.review` word mix), a genuinely
/// separate screen/controller from Estudar per the project's per-mode
/// convention. Composition here deliberately mirrors `study_screen.dart`'s
/// `_QuestionView`/`_FeedbackBanner`/`_SessionSummary` (small, honest
/// duplication of screen wiring rather than forcing a shared generic over
/// two different state types) -- reusing the same underlying widgets
/// (`AnswerOptionButton`, `NeonPanel`, `GlowButton`).
class ExamScreen extends ConsumerWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(examSessionProvider);

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExitTopBar(
                title: 'Provas',
                onExit: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: session.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : session.items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhuma palavra pronta para revisão agora. Estude mais e volte!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: NeonColors.textPrimary),
                          ),
                        ),
                      )
                    : session.isComplete
                    ? const _ExamSummary()
                    : const _ExamQuestionView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamQuestionView extends ConsumerWidget {
  const _ExamQuestionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(examSessionProvider);
    final controller = ref.read(examSessionProvider.notifier);
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
              color: NeonColors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pergunta ${session.currentIndex + 1} de ${session.items.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: NeonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          NeonPanel(
            accentColor: NeonColors.red,
            child: Column(
              children: [
                Text(
                  'QUAL O SIGNIFICADO DE:',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: NeonColors.red,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.word.englishTerm,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: NeonColors.textPrimary,
                  ),
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
            _ExamFeedbackBanner(session: session),
            const SizedBox(height: 12),
          ],
          GlowButton(
            label: session.isAnswered ? 'Continuar' : 'Confirmar',
            color: NeonColors.red,
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

class _ExamFeedbackBanner extends StatelessWidget {
  const _ExamFeedbackBanner({required this.session});

  final ExamSessionState session;

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

class _ExamSummary extends ConsumerWidget {
  const _ExamSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(examSessionProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📝🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Prova concluída!',
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
              '+${session.sessionXpEarned} XP nesta sessão',
              style: theme.textTheme.titleMedium?.copyWith(
                color: NeonColors.purple,
              ),
            ),
            const SizedBox(height: 24),
            GlowButton(
              label: 'Voltar para a Home',
              color: NeonColors.red,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
