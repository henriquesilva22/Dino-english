import 'dart:math' as math;

/// Pure XP/level curve for levels 1-100.
///
/// The cumulative-XP threshold table is precomputed once per instance
/// (not recalculated on every lookup), so [levelForTotalXp] is a cheap
/// binary search rather than a repeated `pow()` evaluation.
class LevelCurve {
  LevelCurve({double base = 40, double growth = 1.45})
    : _cumulativeXpForLevel = _buildTable(base, growth);

  static const int maxLevel = 100;

  /// `_cumulativeXpForLevel[i]` = total XP required to reach level `i + 2`
  /// (level 1 always costs 0, so it isn't stored).
  final List<int> _cumulativeXpForLevel;

  static List<int> _buildTable(double base, double growth) {
    final table = <int>[];
    var cumulative = 0;
    for (var level = 1; level < maxLevel; level++) {
      cumulative += (base * math.pow(level, growth)).round();
      table.add(cumulative);
    }
    return List.unmodifiable(table);
  }

  /// XP required to go from [level] to `level + 1`. Zero at the level cap.
  int xpToNextLevel(int level) {
    if (level >= maxLevel) return 0;
    final previous = xpForLevel(level);
    return xpForLevel(level + 1) - previous;
  }

  /// Total cumulative XP required to reach [level] (level 1 = 0 XP).
  int xpForLevel(int level) {
    final clamped = level.clamp(1, maxLevel);
    if (clamped <= 1) return 0;
    return _cumulativeXpForLevel[clamped - 2];
  }

  /// The level reached with [totalXp] accumulated so far.
  int levelForTotalXp(int totalXp) {
    if (totalXp <= 0) return 1;
    var low = 1;
    var high = maxLevel;
    while (low < high) {
      final mid = low + (high - low + 1) ~/ 2;
      if (xpForLevel(mid) <= totalXp) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// XP accrued since reaching the current level (0 right at a level-up).
  int xpIntoCurrentLevel(int totalXp) {
    return totalXp - xpForLevel(levelForTotalXp(totalXp));
  }
}
