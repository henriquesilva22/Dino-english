import '../brain/model/dino_enums.dart';
import '../utils/date_key.dart';
import 'companion_state.dart';
import 'food/food_item.dart';

enum CareResult {
  /// The care was applied.
  applied,

  /// Nothing to do ("I'm full!"): state unchanged, no XP.
  notNeeded,

  /// Too tired to play: state unchanged, no XP.
  tooTired,

  /// The Dino is sleeping: only sleep/wake do anything.
  asleep,
}

class CareOutcome {
  const CareOutcome({
    required this.state,
    required this.result,
    required this.xp,
    required this.wasUrgent,
  });

  final CompanionState state;
  final CareResult result;

  /// XP earned (already capped by the daily care limit).
  final int xp;

  /// The cared-for need was urgent before -- lets the copy say "I'm
  /// happy now!".
  final bool wasUrgent;

  bool get applied => result == CareResult.applied;
}

/// Pure rules of the pet simulation: how needs decay over time and what
/// each care does. No clock, database or Flutter -- the
/// `CompanionEngine` passes "now" in.
class CompanionNeedsService {
  const CompanionNeedsService();

  // Decay in points per hour while awake.
  static const double hungerPerHour = 5;
  static const double thirstPerHour = 7;
  static const double energyPerHour = 4;
  static const double happinessPerHour = 3;

  /// Energy recovered per hour of sleep; hunger/thirst decay at half
  /// speed meanwhile.
  static const double sleepEnergyPerHour = 25;

  /// Put to bed already full of energy, it naps this long.
  static const double fullNapHours = 1;

  /// Long absences are capped: coming back after a week finds a hungry
  /// Dino, not a ruined one.
  static const Duration maxCatchUp = Duration(hours: 36);

  /// Needs never decay below this on their own -- only the child's care
  /// (or lack of it in a session) moves them lower. Keeps it gentle.
  static const double decayFloor = 10;

  /// Care XP is only granted when the need really needed care.
  static const double needsCareBelow = 80;
  static const int dailyCareXpCap = 30;

  static const int feedXp = 5;
  static const int waterXp = 5;
  static const int playXp = 10;
  static const int sleepXp = 5;

  CompanionState decay(CompanionState state, DateTime now) {
    var elapsed = now.difference(state.updatedAt);
    if (elapsed.isNegative) return state.copyWith(updatedAt: now);
    if (elapsed > maxCatchUp) elapsed = maxCatchUp;
    final hours = elapsed.inSeconds / 3600;
    if (hours <= 0) return state;

    double down(double value, double perHour) {
      if (value <= decayFloor) return value;
      final next = value - perHour * hours;
      return next < decayFloor ? decayFloor : next;
    }

    if (state.isSleeping) {
      final energy = state.energy + sleepEnergyPerHour * hours;
      // Wakes up by itself when sleep fills its energy -- or after a long
      // nap if it went to bed already full (otherwise it would wake up
      // the very next second).
      final filledNow =
          state.energy < CompanionState.max && energy >= CompanionState.max;
      final restedLongNap =
          state.energy >= CompanionState.max && hours >= fullNapHours;
      return state.copyWith(
        hunger: down(state.hunger, hungerPerHour / 2),
        thirst: down(state.thirst, thirstPerHour / 2),
        energy: energy,
        isSleeping: !(filledNow || restedLongNap),
        updatedAt: now,
      );
    }
    return state.copyWith(
      hunger: down(state.hunger, hungerPerHour),
      thirst: down(state.thirst, thirstPerHour),
      energy: down(state.energy, energyPerHour),
      happiness: down(state.happiness, happinessPerHour),
      updatedAt: now,
    );
  }

  /// Applies [care] to an already-decayed [state]. A [food] given by
  /// dragging sets how much it feeds, cheers and pays (default meal
  /// otherwise).
  CareOutcome applyCare(
    CompanionState state,
    DinoCare care,
    DateTime now, {
    FoodItem? food,
  }) {
    if (state.isSleeping && care != DinoCare.sleep) {
      return CareOutcome(
        state: state,
        result: CareResult.asleep,
        xp: 0,
        wasUrgent: false,
      );
    }

    final (need, before) = switch (care) {
      DinoCare.feed => (DinoNeed.hunger, state.hunger),
      DinoCare.water => (DinoNeed.thirst, state.thirst),
      DinoCare.play => (DinoNeed.happiness, state.happiness),
      DinoCare.sleep => (DinoNeed.energy, state.energy),
    };
    final wasUrgent = state.isUrgent(need);

    CareOutcome unchanged(CareResult result) =>
        CareOutcome(state: state, result: result, xp: 0, wasUrgent: wasUrgent);

    final CompanionState next;
    final int baseXp;
    switch (care) {
      case DinoCare.feed:
        if (state.hunger >= 95) return unchanged(CareResult.notNeeded);
        next = state.copyWith(
          hunger: state.hunger + (food?.hungerRestore ?? 20),
          happiness: state.happiness + (food?.happinessReward ?? 5),
        );
        baseXp = food?.xpReward ?? feedXp;
      case DinoCare.water:
        if (state.thirst >= 95) return unchanged(CareResult.notNeeded);
        next = state.copyWith(
          thirst: state.thirst + 25,
          happiness: state.happiness + 5,
        );
        baseXp = waterXp;
      case DinoCare.play:
        if (state.energy < 15) return unchanged(CareResult.tooTired);
        next = state.copyWith(
          happiness: state.happiness + 15,
          energy: state.energy - 10,
          hunger: state.hunger - 3,
          thirst: state.thirst - 3,
        );
        baseXp = playXp;
      case DinoCare.sleep:
        if (state.isSleeping) return unchanged(CareResult.notNeeded);
        next = state.copyWith(energy: state.energy + 30, isSleeping: true);
        baseXp = sleepXp;
    }

    final xp = before < needsCareBelow ? _capXp(state, baseXp, now) : 0;
    return CareOutcome(
      state: _recordXp(next, xp, now),
      result: CareResult.applied,
      xp: xp,
      wasUrgent: wasUrgent,
    );
  }

  CompanionState wakeUp(CompanionState state) =>
      state.copyWith(isSleeping: false);

  int _capXp(CompanionState state, int xp, DateTime now) {
    final today = dateKeyFor(now);
    final used = state.careXpDate == today ? state.careXpToday : 0;
    final left = dailyCareXpCap - used;
    return xp.clamp(0, left < 0 ? 0 : left);
  }

  CompanionState _recordXp(CompanionState state, int xp, DateTime now) {
    final today = dateKeyFor(now);
    final used = state.careXpDate == today ? state.careXpToday : 0;
    return state.copyWith(careXpToday: used + xp, careXpDate: today);
  }
}
