import 'package:flutter/material.dart';

import '../../theme/neon_colors.dart';
import '../neon_card.dart';

/// "BRINCAR COM O DINO" Home card -- opens the offline virtual companion
/// (`DinoChatScreen`): talk, feed, play and learn English with the Dino.
/// Same shape as `WordSlashCard`/`ExamCard`.
class DinoChatCard extends StatelessWidget {
  const DinoChatCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      icon: const Text('🦖', style: TextStyle(fontSize: 34)),
      title: 'BRINCAR COM O DINO',
      subtitle: 'Converse, cuide e aprenda',
      accentColor: NeonColors.cyan,
      onTap: onTap,
    );
  }
}
