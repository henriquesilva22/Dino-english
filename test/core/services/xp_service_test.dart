import 'package:dino_english/core/services/level_curve.dart';
import 'package:dino_english/core/services/xp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LevelCurve curve;
  late XpService service;

  setUp(() {
    curve = LevelCurve();
    service = XpService(curve);
  });

  test('granting XP within the current level does not level up', () {
    final result = service.grantXp(currentTotalXp: 0, xpToAdd: 1);
    expect(result.leveledUp, isFalse);
    expect(result.previousLevel, 1);
    expect(result.newLevel, 1);
    expect(result.newTotalXp, 1);
  });

  test('a single grant that crosses exactly one threshold levels up once', () {
    final thresholdForLevel2 = curve.xpForLevel(2);
    final result = service.grantXp(
      currentTotalXp: thresholdForLevel2 - 1,
      xpToAdd: 1,
    );
    expect(result.leveledUp, isTrue);
    expect(result.levelsGained, 1);
    expect(result.newLevel, 2);
  });

  test('a single large grant can cross multiple thresholds at once', () {
    final thresholdForLevel10 = curve.xpForLevel(10);
    final result = service.grantXp(currentTotalXp: 0, xpToAdd: thresholdForLevel10);
    expect(result.newLevel, 10);
    expect(result.levelsGained, 9);
  });

  test('new total XP is always previous total plus the grant', () {
    final result = service.grantXp(currentTotalXp: 250, xpToAdd: 40);
    expect(result.newTotalXp, 290);
  });

  test('rejects a negative XP grant', () {
    expect(
      () => service.grantXp(currentTotalXp: 100, xpToAdd: -1),
      throwsA(isA<AssertionError>()),
    );
  });
}
