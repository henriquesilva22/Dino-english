import 'package:flutter/material.dart';

import '../../theme/neon_colors.dart';
import '../neon_card.dart';

/// "CONVERSAR COM O DINO" secondary Home card -- disabled/"coming soon"
/// for now. Conversation/voice recognition is explicitly future work
/// (the end of the PALAVRA -> ... -> CONVERSAR COM O DINO roadmap); this
/// only gives the access point the Home is meant to show.
class DinoChatCard extends StatelessWidget {
  const DinoChatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      icon: const Text('💬', style: TextStyle(fontSize: 34)),
      title: 'CONVERSAR COM O DINO',
      subtitle: 'Em breve',
      accentColor: NeonColors.cyan,
      enabled: false,
      onTap: () {},
    );
  }
}
