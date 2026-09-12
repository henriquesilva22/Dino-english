import 'package:flutter/material.dart';

import '../../theme/neon_colors.dart';
import '../neon_card.dart';

/// "PROVAS" secondary Home card. `onTap` is a placeholder until Fase 3
/// wires it to `ExamScreen`.
class ExamCard extends StatelessWidget {
  const ExamCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      icon: const Text('📝', style: TextStyle(fontSize: 34)),
      title: 'PROVAS',
      subtitle: 'Teste o que você já sabe',
      accentColor: NeonColors.red,
      onTap:
          onTap ??
          () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Em breve! 🚧'))),
    );
  }
}
