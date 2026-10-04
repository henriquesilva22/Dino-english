import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/companion/food/food_inventory.dart';
import '../../core/companion/food/food_item.dart';
import '../../providers/food_providers.dart';
import '../../theme/neon_colors.dart';

/// "🍽️ Comidas": the foods the child can give the Dino, with their 🪙
/// coins. Tapping an unlocked food closes the panel and returns it;
/// tapping a locked one offers to buy it.
Future<FoodItem?> showFoodPanel(BuildContext context) =>
    showModalBottomSheet<FoodItem>(
      context: context,
      backgroundColor: NeonColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const FoodPanel(),
    );

class FoodPanel extends ConsumerStatefulWidget {
  const FoodPanel({super.key});

  @override
  ConsumerState<FoodPanel> createState() => _FoodPanelState();
}

class _FoodPanelState extends ConsumerState<FoodPanel> {
  /// Feedback under the grid ("Desbloqueado!", "Você precisa de...").
  String? _message;
  bool _messageGood = false;

  void _say(String message, {required bool good}) => setState(() {
    _message = message;
    _messageGood = good;
  });

  Future<void> _tap(FoodItem food, FoodInventory inventory) async {
    if (inventory.isUnlocked(food)) {
      Navigator.of(context).pop(food);
      return;
    }
    if (!inventory.canAfford(food)) {
      _say(
        'Você precisa de ${food.price} moedas. Você tem ${inventory.coins}.',
        good: false,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeonColors.background,
        title: Text(
          '${food.emoji} ${food.englishName} — ${food.name}',
          style: const TextStyle(color: NeonColors.textPrimary),
        ),
        content: Text(
          'Comprar por 🪙 ${food.price}?',
          style: const TextStyle(color: NeonColors.textSecondary, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Comprar 🪙 ${food.price}'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await buyFood(ref, food);
    if (!mounted) return;
    switch (result) {
      case Purchased():
        _say(
          'Unlocked! Desbloqueado! ${food.emoji}  🪙 -${food.price}',
          good: true,
        );
      case NotEnoughCoins(:final price, :final coins):
        _say('Você precisa de $price moedas. Você tem $coins.', good: false);
      case AlreadyUnlocked():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(foodInventoryProvider).value;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '🍽️ Comidas',
                    style: TextStyle(
                      color: NeonColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (inventory != null) _CoinChip(coins: inventory.coins),
              ],
            ),
            const SizedBox(height: 12),
            if (inventory == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
                children: [
                  for (final food in FoodCatalog.all)
                    _FoodTile(
                      food: food,
                      status: inventory.statusOf(food),
                      onTap: () => _tap(food, inventory),
                    ),
                ],
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _message == null
                  ? const SizedBox(height: 8)
                  : Padding(
                      key: ValueKey(_message),
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _messageGood
                              ? NeonColors.green
                              : NeonColors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NeonColors.orange.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeonColors.orange),
      ),
      child: Text(
        '🪙 $coins moedas',
        style: const TextStyle(
          color: NeonColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({
    required this.food,
    required this.status,
    required this.onTap,
  });

  final FoodItem food;
  final FoodStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = status == FoodStatus.locked;
    final color = locked ? NeonColors.textSecondary : NeonColors.green;
    return Material(
      color: NeonColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('food-${food.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: locked ? 0.4 : 1,
                    child: Text(
                      food.emoji,
                      style: const TextStyle(fontSize: 38),
                    ),
                  ),
                  if (locked)
                    const Positioned(
                      right: -10,
                      bottom: -4,
                      child: Text('🔒', style: TextStyle(fontSize: 18)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                food.englishName,
                style: const TextStyle(
                  color: NeonColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                locked ? '🪙 ${food.price}' : food.name,
                style: TextStyle(
                  color: locked ? NeonColors.orange : NeonColors.textSecondary,
                  fontSize: 12,
                  fontWeight: locked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
