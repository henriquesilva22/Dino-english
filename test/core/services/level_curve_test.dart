import 'package:dino_english/core/services/level_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LevelCurve curve;

  setUp(() {
    curve = LevelCurve();
  });

  test('xpForLevel is strictly increasing across every level', () {
    var previous = curve.xpForLevel(1);
    expect(previous, 0);
    for (var level = 2; level <= LevelCurve.maxLevel; level++) {
      final xp = curve.xpForLevel(level);
      expect(xp, greaterThan(previous));
      previous = xp;
    }
  });

  test('xpToNextLevel is always positive below the cap, zero at the cap', () {
    for (var level = 1; level < LevelCurve.maxLevel; level++) {
      expect(curve.xpToNextLevel(level), greaterThan(0));
    }
    expect(curve.xpToNextLevel(LevelCurve.maxLevel), 0);
  });

  test('levelForTotalXp boundary: exactly at threshold reaches the level', () {
    final thresholdForLevel10 = curve.xpForLevel(10);
    expect(curve.levelForTotalXp(thresholdForLevel10), 10);
  });

  test('levelForTotalXp boundary: one XP below threshold stays at the previous level', () {
    final thresholdForLevel10 = curve.xpForLevel(10);
    expect(curve.levelForTotalXp(thresholdForLevel10 - 1), 9);
  });

  test('levelForTotalXp boundary: one XP above threshold does not skip ahead', () {
    final thresholdForLevel10 = curve.xpForLevel(10);
    expect(curve.levelForTotalXp(thresholdForLevel10 + 1), 10);
  });

  test('level 1 for zero or negative XP', () {
    expect(curve.levelForTotalXp(0), 1);
    expect(curve.levelForTotalXp(-100), 1);
  });

  test('clamps at level 100 no matter how much XP is granted', () {
    final hugeAmount = curve.xpForLevel(LevelCurve.maxLevel) * 10;
    expect(curve.levelForTotalXp(hugeAmount), LevelCurve.maxLevel);
  });

  test('xpIntoCurrentLevel is zero right at a level threshold', () {
    final thresholdForLevel5 = curve.xpForLevel(5);
    expect(curve.xpIntoCurrentLevel(thresholdForLevel5), 0);
  });

  test('xpIntoCurrentLevel accrues correctly mid-level', () {
    final thresholdForLevel5 = curve.xpForLevel(5);
    expect(curve.xpIntoCurrentLevel(thresholdForLevel5 + 7), 7);
  });
}
