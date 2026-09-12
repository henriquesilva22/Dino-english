import 'package:dino_english/game/boss_fight_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state: 100 HP, fighting', () {
    const state = BossFightState();

    expect(state.hp, 100);
    expect(state.status, BossFightStatus.fighting);
    expect(state.isFinished, isFalse);
  });

  test('hit() with the default damage reduces HP and stays fighting', () {
    const state = BossFightState();

    final next = state.hit();

    expect(next.hp, 100 - BossFightState.normalWordDamage);
    expect(next.status, BossFightStatus.fighting);
  });

  test('hit() accepts a custom damage amount', () {
    const state = BossFightState();

    final next = state.hit(damage: BossFightState.hardWordDamage);

    expect(next.hp, 100 - BossFightState.hardWordDamage);
  });

  test('HP clamps at zero, never goes negative', () {
    const state = BossFightState(hp: 5);

    final next = state.hit(damage: 50);

    expect(next.hp, 0);
  });

  test('HP reaching zero ends the fight in victory', () {
    var state = const BossFightState();

    while (state.hp > 0) {
      state = state.hit();
    }

    expect(state.status, BossFightStatus.victory);
    expect(state.isFinished, isTrue);
  });

  test('calls after victory are no-ops', () {
    var state = const BossFightState();
    while (!state.isFinished) {
      state = state.hit();
    }
    final finished = state;

    expect(finished.hit(), same(finished));
  });

  test('band reflects the correct HP threshold', () {
    expect(const BossFightState(hp: 100).band, BossHpBand.full);
    expect(const BossFightState(hp: 76).band, BossHpBand.full);
    expect(const BossFightState(hp: 75).band, BossHpBand.wounded);
    expect(const BossFightState(hp: 51).band, BossHpBand.wounded);
    expect(const BossFightState(hp: 50).band, BossHpBand.critical);
    expect(const BossFightState(hp: 26).band, BossHpBand.critical);
    expect(const BossFightState(hp: 25).band, BossHpBand.desperate);
    expect(const BossFightState(hp: 0).band, BossHpBand.desperate);
  });

  test('damageForWordDifficulty returns normal damage for easy/medium words', () {
    expect(BossFightState.damageForWordDifficulty(1), BossFightState.normalWordDamage);
    expect(BossFightState.damageForWordDifficulty(2), BossFightState.normalWordDamage);
  });

  test('damageForWordDifficulty returns hard damage at the threshold and above', () {
    expect(BossFightState.damageForWordDifficulty(3), BossFightState.hardWordDamage);
    expect(BossFightState.damageForWordDifficulty(4), BossFightState.hardWordDamage);
  });
}
