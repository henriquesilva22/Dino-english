import 'package:flutter/material.dart';

import '../../theme/neon_colors.dart';
import '../pet_model_viewer.dart';
import 'egg_idle_pulse.dart';

const String _kDinoBabyAsset = 'assets/models/dino/Dino_Baby_v2_animado.glb';

/// The Home's centerpiece: the baby Dino, front and center from level 1 --
/// no egg gating. [EggIdlePulse] is reused as-is (it's already
/// content-agnostic via `child`) rather than duplicated; it's now shared
/// between this and [EggShowcase]/`egg_showcase.dart` (kept intact,
/// unused by the Home, for future evolution stages).
class DinoShowcase extends StatelessWidget {
  const DinoShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: 220,
              height: 238,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 154,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            NeonColors.green.withValues(alpha: 0.4),
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
                            NeonColors.green.withValues(alpha: 0.28),
                            NeonColors.cyan.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  EggIdlePulse(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NeonColors.surface.withValues(alpha: 0.55),
                        boxShadow: [
                          BoxShadow(
                            color: NeonColors.green.withValues(alpha: 0.30),
                            blurRadius: 34,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: NeonColors.cyan.withValues(alpha: 0.22),
                            blurRadius: 50,
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: PetModelViewer(
                          modelAsset: _kDinoBabyAsset,
                          label: 'Dino bebê',
                          height: 190,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Seu Dino está crescendo com você! 🦖',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: NeonColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
