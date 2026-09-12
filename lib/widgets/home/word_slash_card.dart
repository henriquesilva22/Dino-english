import 'package:flutter/material.dart';

import '../../theme/neon_colors.dart';
import '../neon_card.dart';

/// "WORD SLASH" Home card -- mirrors `SentenceBuilderCard`/`ExamCard`'s
/// shape exactly (icon/title/subtitle/onTap).
class WordSlashCard extends StatelessWidget {
  const WordSlashCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      icon: const Text('🥷', style: TextStyle(fontSize: 34)),
      title: 'WORD SLASH',
      subtitle: 'Corte os pares certos',
      accentColor: NeonColors.orange,
      onTap:
          onTap ??
          () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Em breve! 🚧'))),
    );
  }
}
