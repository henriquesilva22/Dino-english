import 'level_curve.dart';

class XpGrantResult {
  const XpGrantResult({
    required this.newTotalXp,
    required this.previousLevel,
    required this.newLevel,
  });

  final int newTotalXp;
  final int previousLevel;
  final int newLevel;

  bool get leveledUp => newLevel > previousLevel;
  int get levelsGained => newLevel - previousLevel;
}

/// Grants XP and derives the resulting level directly from the new total
/// (never `level += 1`), so a single grant that crosses several
/// thresholds at once is handled correctly.
class XpService {
  const XpService(this._levelCurve);

  final LevelCurve _levelCurve;

  XpGrantResult grantXp({required int currentTotalXp, required int xpToAdd}) {
    assert(xpToAdd >= 0, 'xpToAdd must not be negative');
    final newTotalXp = currentTotalXp + xpToAdd;
    return XpGrantResult(
      newTotalXp: newTotalXp,
      previousLevel: _levelCurve.levelForTotalXp(currentTotalXp),
      newLevel: _levelCurve.levelForTotalXp(newTotalXp),
    );
  }
}
