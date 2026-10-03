import '../brain/model/dino_enums.dart';
import '../brain/model/dino_status.dart';

/// The virtual pet's body and mood, persisted in `companion_state`.
///
/// Every need is a 0..100 "satisfied" level, like a Tamagotchi bar:
/// 100 = full/rested/happy, 0 = urgent. So [hunger] 80 means "not
/// hungry" -- feeding *raises* it. Doubles, not ints, so slow decay
/// (a few points per hour) survives frequent saves.
class CompanionState {
  const CompanionState({
    required this.hunger,
    required this.thirst,
    required this.energy,
    required this.happiness,
    required this.updatedAt,
    this.isSleeping = false,
    this.careXpToday = 0,
    this.careXpDate,
  });

  /// First meeting: a little hungry and thirsty, so the very first
  /// "are you hungry?" already has something to say.
  factory CompanionState.initial(DateTime now) => CompanionState(
    hunger: 60,
    thirst: 60,
    energy: 80,
    happiness: 80,
    updatedAt: now,
  );

  static const double max = 100;

  final double hunger;
  final double thirst;
  final double energy;
  final double happiness;
  final bool isSleeping;

  /// Last time decay was applied (see `CompanionNeedsService.decay`).
  final DateTime updatedAt;

  /// Care XP already granted on [careXpDate] (`YYYY-MM-DD`), for the
  /// daily cap -- caring for the Dino helps, but it isn't the lesson.
  final int careXpToday;
  final String? careXpDate;

  double valueOf(DinoNeed need) => switch (need) {
    DinoNeed.hunger => hunger,
    DinoNeed.thirst => thirst,
    DinoNeed.energy => energy,
    DinoNeed.happiness => happiness,
    // Not simulated yet: always clean.
    DinoNeed.hygiene => max,
  };

  /// The brain's view of this state (0..1 per need).
  DinoStatus toStatus({required int totalXp, required int level}) => DinoStatus(
    needs: {
      DinoNeed.hunger: hunger / max,
      DinoNeed.thirst: thirst / max,
      DinoNeed.energy: energy / max,
      DinoNeed.happiness: happiness / max,
    },
    totalXp: totalXp,
    level: level,
    isSleeping: isSleeping,
  );

  bool isUrgent(DinoNeed need) =>
      valueOf(need) < DinoStatus.urgentThreshold * max;

  /// The lowest urgent need, or null when the Dino is fine.
  DinoNeed? get mostUrgentNeed {
    DinoNeed? worst;
    for (final need in DinoNeed.values) {
      if (!isUrgent(need)) continue;
      if (worst == null || valueOf(need) < valueOf(worst)) worst = need;
    }
    return worst;
  }

  CompanionState copyWith({
    double? hunger,
    double? thirst,
    double? energy,
    double? happiness,
    bool? isSleeping,
    DateTime? updatedAt,
    int? careXpToday,
    String? careXpDate,
  }) {
    return CompanionState(
      hunger: _clamp(hunger ?? this.hunger),
      thirst: _clamp(thirst ?? this.thirst),
      energy: _clamp(energy ?? this.energy),
      happiness: _clamp(happiness ?? this.happiness),
      isSleeping: isSleeping ?? this.isSleeping,
      updatedAt: updatedAt ?? this.updatedAt,
      careXpToday: careXpToday ?? this.careXpToday,
      careXpDate: careXpDate ?? this.careXpDate,
    );
  }

  /// Moves one need by [delta] points (clamped). Hygiene is ignored.
  CompanionState adjust(DinoNeed need, double delta) => switch (need) {
    DinoNeed.hunger => copyWith(hunger: hunger + delta),
    DinoNeed.thirst => copyWith(thirst: thirst + delta),
    DinoNeed.energy => copyWith(energy: energy + delta),
    DinoNeed.happiness => copyWith(happiness: happiness + delta),
    DinoNeed.hygiene => this,
  };

  static double _clamp(double v) => v.clamp(0.0, max);

  @override
  String toString() =>
      'CompanionState(hunger: ${hunger.round()}, thirst: ${thirst.round()}, '
      'energy: ${energy.round()}, happiness: ${happiness.round()}, '
      'sleeping: $isSleeping)';
}
