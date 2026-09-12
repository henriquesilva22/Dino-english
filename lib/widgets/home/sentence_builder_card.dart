import 'package:flutter/material.dart';

import '../../theme/neon_colors.dart';
import '../neon_card.dart';

/// "MONTAR FRASES" secondary Home card. `onTap` is a placeholder until
/// Fase 2 wires it to `SentenceBuilderScreen`.
class SentenceBuilderCard extends StatelessWidget {
  const SentenceBuilderCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      icon: const Text('🧩', style: TextStyle(fontSize: 34)),
      title: 'MONTAR FRASES',
      subtitle: 'Construa frases em inglês',
      accentColor: NeonColors.purple,
      onTap:
          onTap ??
          () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Em breve! 🚧'))),
    );
  }
}
