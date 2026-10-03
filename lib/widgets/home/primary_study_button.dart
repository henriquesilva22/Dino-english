import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/home_providers.dart';
import '../../providers/navigation_providers.dart';
import '../../theme/neon_colors.dart';
import '../glow_button.dart';

/// The Home's most important call to action: big, glowing, with tap
/// feedback and a subtitle that reacts to the current streak. Switches
/// to the "Estudar" tab rather than pushing a route -- Study is now a
/// bottom-nav destination.
class PrimaryStudyButton extends ConsumerWidget {
  const PrimaryStudyButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final streakDays = profileAsync.value?.currentStreakDays ?? 0;

    final subtitle = streakDays > 0
        ? 'Continue sua sequência de $streakDays dias'
        : 'Comece sua jornada de hoje';

    return GlowButton(
      label: 'ESTUDAR',
      subtitle: subtitle,
      color: NeonColors.cyan,
      icon: const Text('📚', style: TextStyle(fontSize: 30)),
      onTap: () => ref.read(selectedTabIndexProvider.notifier).select(1),
    );
  }
}
