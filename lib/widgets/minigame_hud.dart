import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/boss_fight_state.dart';
import '../game/minigame_round_state.dart';
import '../providers/minigame_providers.dart';
import '../theme/neon_colors.dart';
import 'boss_health_bar.dart';
import 'neon_border.dart';

class MinigameHud extends ConsumerStatefulWidget {
  const MinigameHud({required this.onExit, this.isBossFight = false, super.key});

  final bool isBossFight;
  final VoidCallback onExit;

  @override
  ConsumerState<MinigameHud> createState() => _MinigameHudState();
}

class _MinigameHudState extends ConsumerState<MinigameHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MinigameRoundState>(minigameControllerProvider, (
      previous,
      next,
    ) {
      if (previous != null && next.lives < previous.lives) {
        _shakeController.forward(from: 0);
      }
    });
    final state = ref.watch(minigameControllerProvider);
    final bossHp = widget.isBossFight
        ? ref.watch(bossFightControllerProvider.select((s) => s.hp))
        : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Row(
              children: [
                _ExitButton(onTap: widget.onExit),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          final t = _shakeController.value;
                          final dx = sin(t * pi * 6) * (1 - t) * 6;
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: child,
                          );
                        },
                        child: Row(
                          children: List.generate(
                            MinigameRoundState.startingLives,
                            (i) {
                              final filled = i < state.lives;
                              return Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: AnimatedScale(
                                  scale: filled ? 1.0 : 0.85,
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    filled ? '❤️' : '🤍',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      NeonBorder(
                        color: NeonColors.cyan,
                        radius: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          color: NeonColors.surface.withValues(alpha: 0.75),
                          child: TweenAnimationBuilder<int>(
                            tween: IntTween(end: state.score),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, _) => Text(
                              '$value pts',
                              style: const TextStyle(
                                color: NeonColors.cyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (bossHp != null) ...[
              const SizedBox(height: 6),
              BossHealthBar(hp: bossHp, maxHp: BossFightState.startingHp),
            ],
          ],
        ),
      ),
    );
  }
}

/// Always-visible way to leave the round mid-play -- until this existed,
/// the only exit was the post-round overlay, and `SystemUiMode
/// .immersiveSticky` (used while this screen is active) makes the Android
/// system back gesture less discoverable/reliable than normal.
class _ExitButton extends StatelessWidget {
  const _ExitButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeonBorder(
        color: NeonColors.textSecondary,
        radius: 16,
        child: Container(
          width: 32,
          height: 32,
          color: NeonColors.surface.withValues(alpha: 0.75),
          alignment: Alignment.center,
          child: const Text(
            '✕',
            style: TextStyle(
              color: NeonColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
