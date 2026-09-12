import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';
import 'home/tap_scale.dart';
import 'neon_border.dart';

/// Tappable "game card" -- icon, title, subtitle, optional footer (e.g. a
/// progress bar), glowing border, press feedback. Successor to the
/// Bloco 3 `SecondaryActionCard`, kept as the single implementation both
/// `secondary_action_card.dart` and new Pet Adventure widgets build on.
class NeonCard extends StatelessWidget {
  const NeonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.footer,
    this.accentColor = NeonColors.cyan,
    this.enabled = true,
    super.key,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? footer;
  final Color accentColor;

  /// When false, renders dimmed with an "EM BREVE" badge and taps show a
  /// short "coming soon" message instead of calling [onTap].
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled ? accentColor : NeonColors.textSecondary;

    return TapScale(
      onTap: enabled
          ? onTap
          : () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Em breve! 🚧')),
            ),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.55,
        child: NeonBorder(
          color: color,
          radius: 24,
          borderWidth: 1.2,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: NeonColors.surface.withValues(alpha: 0.85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    icon,
                    if (!enabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: NeonColors.textSecondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'EM BREVE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: NeonColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: NeonColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: NeonColors.textSecondary,
                  ),
                ),
                if (footer != null) ...[const SizedBox(height: 10), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
