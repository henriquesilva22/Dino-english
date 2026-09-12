import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_providers.dart';
import '../providers/navigation_providers.dart';
import '../theme/neon_colors.dart';
import 'neon_card.dart';

/// "PALAVRAS" secondary card, same [masteryStatsProvider] and same
/// mastered/total math as before -- now shaped as a compact game card
/// next to the Pet Adventure card. Switches to the "Estudar" tab rather
/// than pushing a route.
class MasteryProgressCard extends ConsumerWidget {
  const MasteryProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(masteryStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (stats) {
        final total = stats.totalActiveWords;
        final mastered = stats.masteredCount;
        final progress = total > 0 ? mastered / total : 0.0;

        return NeonCard(
          icon: const Text('📖', style: TextStyle(fontSize: 34)),
          title: 'PALAVRAS',
          subtitle: '$mastered/$total dominadas',
          accentColor: NeonColors.orange,
          onTap: () => ref.read(selectedTabIndexProvider.notifier).select(1),
          footer: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress.clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                color: NeonColors.orange,
                backgroundColor: NeonColors.orange.withValues(alpha: 0.15),
              ),
            ),
          ),
        );
      },
    );
  }
}
