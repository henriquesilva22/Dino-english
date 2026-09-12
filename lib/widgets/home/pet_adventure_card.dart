import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/navigation_providers.dart';
import '../../theme/neon_colors.dart';
import '../neon_card.dart';

/// Secondary Home action leading to the "Aventura" tab (pet selection ->
/// platformer). Switches tabs rather than pushing a route.
class PetAdventureCard extends ConsumerWidget {
  const PetAdventureCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NeonCard(
      icon: const Text('🐾', style: TextStyle(fontSize: 34)),
      title: 'PET ADVENTURE',
      subtitle: 'Jogue e ganhe XP',
      accentColor: NeonColors.green,
      onTap: () => ref.read(selectedTabIndexProvider.notifier).select(2),
    );
  }
}
