import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/sentence_challenge.dart';
import '../providers/sentence_builder_providers.dart';
import '../providers/speech_providers.dart';
import '../theme/neon_colors.dart';
import '../widgets/dino/dino_reaction_banner.dart';
import '../widgets/exit_top_bar.dart';
import '../widgets/glow_button.dart';
import '../widgets/neon_background.dart';
import '../widgets/neon_panel.dart';
import '../widgets/sentence_builder/sentence_prompt_copy.dart';
import '../widgets/sentence_builder/word_chip.dart';
import '../widgets/speech_button.dart';
import '../widgets/streak_badge.dart';
import '../widgets/xp_level_card.dart';

class SentenceBuilderScreen extends ConsumerWidget {
  const SentenceBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sentenceBuilderProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Covers the button below *and* the Android back button/gesture
        // with the same cleanup -- SpeechButton only removes its own
        // listener on dispose, it never stops playback itself.
        if (didPop) unawaited(ref.read(speechServiceProvider).stop());
      },
      child: Scaffold(
        body: NeonBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExitTopBar(
                  title: 'Montar Frase',
                  onExit: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: session.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : session.challenges.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Nenhuma frase disponível agora. Estude mais palavras e volte!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: NeonColors.textPrimary),
                            ),
                          ),
                        )
                      : session.isComplete
                      ? const _SentenceSessionSummary()
                      : const _ChallengeView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeView extends ConsumerWidget {
  const _ChallengeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sentenceBuilderProvider);
    final controller = ref.read(sentenceBuilderProvider.notifier);
    final challenge = session.currentChallenge;

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
            'Frase ${session.currentIndex + 1} de ${session.challenges.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: NeonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: NeonPanel(
                accentColor: NeonColors.purple,
                child: Column(
                  children: [
                    _PromptHeader(challenge: challenge),
                    const SizedBox(height: 20),
                    if (challenge.style.isAssemble)
                      _AssembleBody(session: session, controller: controller)
                    else
                      _FillBlankBody(session: session, controller: controller),
                    if (session.isSubmitted) ...[
                      const SizedBox(height: 20),
                      DinoReactionBanner(
                        isCorrect: session.isCorrect,
                        streakThisSession: session.streakThisSession,
                      ),
                      const SizedBox(height: 12),
                      if (session.isCorrect)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SpeechButton(text: challenge.correctSentenceText),
                          ],
                        )
                      else
                        Text(
                          '💡 Ordem correta: ${challenge.correctSentenceText}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: NeonColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!session.isSubmitted)
            Row(
              children: [
                Expanded(
                  child: GlowButton(
                    label: 'LIMPAR',
                    color: NeonColors.textSecondary,
                    filled: false,
                    onTap: challenge.style.isAssemble
                        ? controller.clearPlaced
                        : () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlowButton(
                    label: 'VERIFICAR',
                    color: NeonColors.cyan,
                    onTap: _canSubmit(challenge, session)
                        ? controller.submit
                        : () {},
                  ),
                ),
              ],
            )
          else
            GlowButton(
              label: 'CONTINUAR',
              color: NeonColors.cyan,
              onTap: controller.next,
            ),
        ],
      ),
    );
  }

  bool _canSubmit(SentenceChallenge challenge, SentenceBuilderState session) {
    if (challenge.style.isAssemble) {
      return session.placedTokenIds.length == challenge.displayTokens.length;
    }
    return challenge.blanks.every(
      (b) => session.selectedBlankAnswers.containsKey(b.tokenIndex),
    );
  }
}

class _PromptHeader extends StatelessWidget {
  const _PromptHeader({required this.challenge});

  final SentenceChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = challenge.word;

    return Column(
      children: [
        Text(
          switch (challenge.style) {
            SentenceExerciseStyle.translationHint => 'TRADUZA A FRASE:',
            SentenceExerciseStyle.situationHint => 'SITUAÇÃO:',
            SentenceExerciseStyle.fillBlank => 'COMPLETE A FRASE:',
            SentenceExerciseStyle.emojiHint => 'MONTE UMA FRASE:',
          },
          style: theme.textTheme.labelLarge?.copyWith(
            color: NeonColors.purple,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        switch (challenge.style) {
          SentenceExerciseStyle.translationHint => Text(
            word.exampleSentencePt,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: NeonColors.textPrimary,
            ),
          ),
          SentenceExerciseStyle.situationHint => Text(
            situationFor(word.category),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: NeonColors.textPrimary,
            ),
          ),
          SentenceExerciseStyle.emojiHint => Text(
            emojiFor(word.category),
            style: const TextStyle(fontSize: 56),
          ),
          SentenceExerciseStyle.fillBlank => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _AssembleBody extends StatelessWidget {
  const _AssembleBody({required this.session, required this.controller});

  final SentenceBuilderState session;
  final SentenceBuilderController controller;

  @override
  Widget build(BuildContext context) {
    final challenge = session.currentChallenge;
    final bankById = {for (final t in challenge.wordBank) t.id: t};

    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: NeonColors.background.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: NeonColors.cyan.withValues(alpha: 0.25),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < session.placedTokenIds.length; i++)
                _placedChip(context, session.placedTokenIds[i], i, bankById),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final token in challenge.wordBank)
              if (!session.placedTokenIds.contains(token.id))
                WordChip(
                  label: token.text,
                  state: WordChipVisualState.idle,
                  onTap: session.isSubmitted
                      ? null
                      : () => controller.tapBankToken(token.id),
                ),
          ],
        ),
      ],
    );
  }

  Widget _placedChip(
    BuildContext context,
    String id,
    int position,
    Map<String, BankToken> bankById,
  ) {
    final challenge = session.currentChallenge;
    final text = bankById[id]!.text;
    var state = WordChipVisualState.placed;
    if (session.isSubmitted) {
      final correctText = position < challenge.displayTokens.length
          ? challenge.displayTokens[position]
          : null;
      state = text == correctText
          ? WordChipVisualState.correct
          : WordChipVisualState.incorrect;
    }
    return WordChip(
      label: text,
      state: state,
      onTap: session.isSubmitted ? null : () => controller.tapPlacedToken(id),
    );
  }
}

class _FillBlankBody extends StatelessWidget {
  const _FillBlankBody({required this.session, required this.controller});

  final SentenceBuilderState session;
  final SentenceBuilderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final challenge = session.currentChallenge;
    final blanksByIndex = {for (final b in challenge.blanks) b.tokenIndex: b};

    return Column(
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < challenge.displayTokens.length; i++)
              if (blanksByIndex.containsKey(i))
                Text(
                  session.selectedBlankAnswers[i] ?? '_____',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: NeonColors.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  challenge.displayTokens[i],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: NeonColors.textPrimary,
                  ),
                ),
          ],
        ),
        const SizedBox(height: 24),
        for (final blank in challenge.blanks) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final option in blank.options)
                _blankOptionChip(blank, option),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _blankOptionChip(SentenceBlank blank, String option) {
    final selected = session.selectedBlankAnswers[blank.tokenIndex] == option;
    var state = selected ? WordChipVisualState.placed : WordChipVisualState.idle;
    if (session.isSubmitted && selected) {
      state = option == blank.correctText
          ? WordChipVisualState.correct
          : WordChipVisualState.incorrect;
    }
    return WordChip(
      label: option,
      state: state,
      onTap: session.isSubmitted
          ? null
          : () => controller.selectBlankOption(blank.tokenIndex, option),
    );
  }
}

class _SentenceSessionSummary extends ConsumerWidget {
  const _SentenceSessionSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sentenceBuilderProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧩🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Sessão concluída!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: NeonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${session.sessionCorrectCount} de ${session.challenges.length} certas',
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
              color: NeonColors.cyan,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
