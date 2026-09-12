import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/dino_evolution_stage.dart';
import '../../core/repositories/progress_repository.dart';
import '../../core/services/hatching_service.dart';
import '../../providers/home_providers.dart';
import '../../theme/neon_colors.dart';
import '../egg_model_viewer.dart';
import 'egg_idle_pulse.dart';
import 'egg_stage_copy.dart';

/// Percentage towards the next egg stage, purely derived from
/// [EggProgressInfo] (already computed by [HatchingService]) -- display
/// formatting only, not a new rule.
double? _hatchingPercent(EggProgressInfo info) {
  if (info.stage == DinoEvolutionStage.hatchedBabyPlaceholder) return 1.0;
  if (info.daysRemaining == null) return null;
  const requiredDays = HatchingService();
  final total = requiredDays.requiredActiveDays;
  if (total <= 0) return 1.0;
  return (1 - info.daysRemaining! / total).clamp(0.0, 1.0);
}

/// The Home's centerpiece: a dedicated, large stage for the egg with a
/// soft glow, idle "breathing" motion, and an animated progress ring
/// showing how close it is to the next evolution stage. Reads exactly
/// [eggProgressProvider] -- no new data, only presentation.
class EggShowcase extends ConsumerWidget {
  const EggShowcase({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(eggProgressProvider);
    final theme = Theme.of(context);

    return progressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(
        child: Text('Não foi possível carregar o ovo'),
      ),
      data: (info) {
        final percent = _hatchingPercent(info);

        return LayoutBuilder(
          builder: (context, constraints) {
            final eggSize = constraints.maxHeight.clamp(180, 300).toDouble();

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: eggSize,
                      height: eggSize * 1.08,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pedestal: soft elliptical glow at the base.
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: eggSize * 0.7,
                              height: eggSize * 0.14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    NeonColors.purple.withValues(alpha: 0.45),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.9,
                            heightFactor: 0.9,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    NeonColors.purple.withValues(alpha: 0.30),
                                    NeonColors.cyan.withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (percent != null)
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(end: percent),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) =>
                                      CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 6,
                                        backgroundColor: NeonColors.surface,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              NeonColors.cyan,
                                            ),
                                      ),
                                ),
                              ),
                            ),
                          EggIdlePulse(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: NeonColors.surface.withValues(
                                  alpha: 0.55,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: NeonColors.cyan.withValues(
                                      alpha: 0.30,
                                    ),
                                    blurRadius: 34,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: NeonColors.purple.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 50,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: EggModelViewer(height: eggSize - 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    key: ValueKey(info.stage),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      describeEggStage(info),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: NeonColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (percent != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${(percent * 100).round()}% para a próxima fase',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NeonColors.cyan,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
