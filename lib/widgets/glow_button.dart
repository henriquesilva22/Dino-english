import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';
import 'home/tap_scale.dart';
import 'neon_border.dart';

/// The design system's primary call-to-action button: a big glowing
/// pill/rounded rect with press feedback, an optional leading icon
/// (emoji or [IconData]) and an optional subtitle line. `filled` picks
/// between a solid gradient fill (primary actions) and a ghost/outline
/// style (secondary actions).
class GlowButton extends StatelessWidget {
  const GlowButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.filled = true,
    this.color = NeonColors.cyan,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? icon;
  final String? subtitle;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 14)],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: subtitle == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: filled ? NeonColors.background : color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: filled
                        ? NeonColors.background.withValues(alpha: 0.75)
                        : NeonColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    final body = filled
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: content,
          )
        : NeonBorder(
            color: color,
            radius: 24,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: NeonColors.surface.withValues(alpha: 0.6),
              child: content,
            ),
          );

    return TapScale(onTap: onTap, child: body);
  }
}
