import 'package:dino_english/game/level/platform.dart';
import 'package:dino_english/game/level/platform_landing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ground = Platform(id: 'ground', left: 0, right: 800, top: 500);
  const mid = Platform(id: 'mid', left: 50, right: 750, top: 415);
  const high = Platform(id: 'high', left: 50, right: 750, top: 335);
  const platforms = [high, mid, ground];

  test('lands on the ground when falling with nothing above', () {
    final landing = resolveLanding(
      footX: 100,
      previousFootY: 490,
      newFootY: 510,
      velocityY: 300,
      platforms: platforms,
    );

    expect(landing, ground);
  });

  test(
    'picks the highest platform crossed this frame, not the ground beyond it',
    () {
      // Falling from well above `high`, past `mid` and `high`'s tops in one
      // frame (a fast tick) -- the pet should land on the first (highest)
      // surface it crosses, not tunnel through to a lower one.
      final landing = resolveLanding(
        footX: 100,
        previousFootY: 300,
        newFootY: 520,
        velocityY: 900,
        platforms: platforms,
      );

      expect(landing, high);
    },
  );

  test('never lands while moving upward (mid-jump)', () {
    final landing = resolveLanding(
      footX: 100,
      previousFootY: 500,
      newFootY: 480,
      velocityY: -600,
      platforms: platforms,
    );

    expect(landing, isNull);
  });

  test('ignoredPlatformId excludes the current platform (drop-through)', () {
    final landing = resolveLanding(
      footX: 100,
      previousFootY: 410,
      newFootY: 420,
      velocityY: 300,
      platforms: platforms,
      ignoredPlatformId: 'mid',
    );

    expect(landing, isNull);
  });

  test('drop-through eventually lands on the platform below once cleared', () {
    final landing = resolveLanding(
      footX: 100,
      previousFootY: 490,
      newFootY: 505,
      velocityY: 300,
      platforms: platforms,
      ignoredPlatformId: 'mid',
    );

    expect(landing, ground);
  });

  test('outside the platform\'s X range never lands on it', () {
    final landing = resolveLanding(
      footX: 10, // left of mid/high's `left: 50`
      previousFootY: 300,
      newFootY: 520,
      velocityY: 900,
      platforms: platforms,
    );

    expect(landing, ground);
  });

  test('edge case: previousFootY exactly at the platform top still lands', () {
    final landing = resolveLanding(
      footX: 100,
      previousFootY: 415, // == mid.top
      newFootY: 420,
      velocityY: 200,
      platforms: platforms,
    );

    expect(landing, mid);
  });
}
