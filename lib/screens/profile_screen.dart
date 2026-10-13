import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/level_curve.dart';
import '../core/services/word_review_selector.dart';
import '../providers/home_providers.dart';
import '../providers/navigation_providers.dart';
import '../providers/word_review_providers.dart';
import '../theme/neon_colors.dart';
import '../widgets/home/egg_stage_copy.dart';
import '../widgets/neon_background.dart';
import '../widgets/neon_panel.dart';

/// Read-only profile/stats screen -- consumes providers that already
/// existed since Bloco 3 (`userProfileStreamProvider`,
/// `masteryStatsProvider`, `dinoEvolutionStreamProvider`,
/// `eggProgressProvider`) with no consumer of their own until now. Zero
/// new business logic, only presentation.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileStreamProvider);
    final statsAsync = ref.watch(masteryStatsProvider);
    final dinoStateAsync = ref.watch(dinoEvolutionStreamProvider);
    final eggProgressAsync = ref.watch(eggProgressProvider);

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'PERFIL',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: NeonColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (profile) {
                  final curve = LevelCurve();
                  final xpIntoLevel = curve.xpIntoCurrentLevel(profile.totalXp);
                  final xpNeeded = curve.xpToNextLevel(profile.currentLevel);
                  return NeonPanel(
                    accentColor: NeonColors.purple,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nível ${profile.currentLevel}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: NeonColors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${profile.totalXp} XP total'
                          '${xpNeeded > 0 ? ' · $xpIntoLevel/$xpNeeded para o próximo nível' : ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: NeonColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _StatChip(
                              icon: '🔥',
                              label: 'Streak atual',
                              value: '${profile.currentStreakDays} dias',
                              color: NeonColors.orange,
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              icon: '🏆',
                              label: 'Recorde',
                              value: '${profile.longestStreakDays} dias',
                              color: NeonColors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // The current balance (earned minus spent), the
                            // same number the shop uses.
                            _StatChip(
                              key: const ValueKey('profile-coins'),
                              icon: '🪙',
                              label: 'Moedas',
                              value: '${profile.coins}',
                              color: NeonColors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
                data: (stats) => NeonPanel(
                  accentColor: NeonColors.cyan,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Palavras dominadas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: NeonColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${stats.masteredCount}/${stats.totalActiveWords}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: NeonColors.cyan,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var level = 0; level <= 5; level++)
                            _MasteryLevelBar(
                              level: level,
                              count: stats.distribution[level] ?? 0,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const WordReviewSection(),
              const SizedBox(height: 16),
              eggProgressAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
                data: (info) => NeonPanel(
                  accentColor: NeonColors.green,
                  child: Row(
                    children: [
                      const Text('🥚', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              describeEggStage(info),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: NeonColors.textPrimary,
                              ),
                            ),
                            dinoStateAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (err, stack) => const SizedBox.shrink(),
                              data: (state) => Text(
                                state.hatchedAt != null
                                    ? 'Eclodiu em ${state.hatchedAt!.day.toString().padLeft(2, '0')}/${state.hatchedAt!.month.toString().padLeft(2, '0')}'
                                    : 'Ainda não eclodiu',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: NeonColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon, label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$icon $label',
              style: theme.textTheme.labelSmall?.copyWith(
                color: NeonColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryLevelBar extends StatelessWidget {
  const _MasteryLevelBar({required this.level, required this.count});

  final int level;
  final int count;

  @override
  Widget build(BuildContext context) {
    final height = 8.0 + (count.clamp(0, 30) * 2.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: const TextStyle(color: NeonColors.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Container(
          width: 20,
          height: height,
          decoration: BoxDecoration(
            color: NeonColors.cyan.withValues(alpha: 0.2 + level * 0.14),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$level',
          style: const TextStyle(color: NeonColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

/// "Revisão de palavras": a few English words and their meaning from the
/// word bank -- the ones the child got wrong or met lately first. The
/// same set while the profile is open; a new one with 🔄 or when the
/// profile is opened again.
class WordReviewSection extends ConsumerWidget {
  const WordReviewSection({super.key});

  /// The profile's tab in the app shell.
  static const int profileTab = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(selectedTabIndexProvider, (previous, next) {
      if (next == profileTab && previous != profileTab) {
        ref.read(wordReviewRoundProvider.notifier).next();
      }
    });
    final theme = Theme.of(context);
    final review = ref.watch(wordReviewProvider);
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: NeonColors.textSecondary,
    );
    return NeonPanel(
      accentColor: NeonColors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Revisão de palavras',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: NeonColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('word-review-refresh'),
                tooltip: 'Outras palavras',
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    ref.read(wordReviewRoundProvider.notifier).next(),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: NeonColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          review.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'Não foi possível carregar as palavras agora.',
              style: hint,
            ),
            data: (words) => words.isEmpty
                ? Text(
                    'Estude algumas palavras para revisá-las aqui!',
                    style: hint,
                  )
                : Column(
                    children: [for (final w in words) _ReviewRow(word: w)],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.word});

  final ReviewCandidate word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey('review-${word.wordId}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              word.english,
              style: theme.textTheme.titleSmall?.copyWith(
                color: NeonColors.orange,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text('→', style: TextStyle(color: NeonColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              word.portuguese,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: NeonColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
