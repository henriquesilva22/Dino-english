import 'package:flutter/material.dart';

import '../neon_card.dart';

/// Thin compatibility wrapper: `SecondaryActionCard` is now just
/// [NeonCard] under its Bloco 3 name/contract, so existing callers
/// (`DinoGameCard`/`PetAdventureCard`, `MasteryProgressCard`) don't need
/// to change their constructor calls.
class SecondaryActionCard extends StatelessWidget {
  const SecondaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.footer,
    this.accentColor,
    super.key,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? footer;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      footer: footer,
      accentColor: accentColor ?? Theme.of(context).colorScheme.primary,
    );
  }
}
