import 'package:dino_english/game/minigame_round_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state: 4 lives, zero score/XP, playing', () {
    const state = MinigameRoundState();

    expect(state.lives, 4);
    expect(state.score, 0);
    expect(state.xpEarned, 0);
    expect(state.correctWordsCollected, isEmpty);
    expect(state.status, MinigameStatus.playing);
    expect(state.isGameOver, isFalse);
  });

  test('collectCorrect adds points, XP and the word, keeps playing', () {
    const state = MinigameRoundState();

    final next = state.collectCorrect('apple');

    expect(next.score, MinigameRoundState.pointsPerCorrectWord);
    expect(next.xpEarned, MinigameRoundState.xpPerCorrectWord);
    expect(next.correctWordsCollected, ['apple']);
    expect(next.lives, 4);
    expect(next.status, MinigameStatus.playing);
  });

  test('collectIncorrect removes exactly one life, no score/XP change', () {
    const state = MinigameRoundState();

    final next = state.collectIncorrect();

    expect(next.lives, 3);
    expect(next.score, 0);
    expect(next.xpEarned, 0);
    expect(next.status, MinigameStatus.playing);
  });

  test('losing the 4th life ends the round as game over', () {
    var state = const MinigameRoundState();

    for (var i = 0; i < 3; i++) {
      state = state.collectIncorrect();
      expect(state.status, MinigameStatus.playing);
    }
    state = state.collectIncorrect();

    expect(state.lives, 0);
    expect(state.status, MinigameStatus.gameOver);
    expect(state.isGameOver, isTrue);
  });

  test('calls after game over are no-ops', () {
    var state = const MinigameRoundState();
    for (var i = 0; i < 4; i++) {
      state = state.collectIncorrect();
    }
    final gameOverState = state;

    final afterCorrect = gameOverState.collectCorrect('apple');
    final afterIncorrect = gameOverState.collectIncorrect();

    expect(afterCorrect, same(gameOverState));
    expect(afterIncorrect, same(gameOverState));
  });

  test(
    'reaching maxCorrectWordsPerRound correct words also ends the round',
    () {
      var state = const MinigameRoundState();

      for (var i = 0; i < MinigameRoundState.maxCorrectWordsPerRound; i++) {
        state = state.collectCorrect('word$i');
      }

      expect(
        state.correctWordsCollected,
        hasLength(MinigameRoundState.maxCorrectWordsPerRound),
      );
      expect(state.status, MinigameStatus.gameOver);
      expect(state.lives, 4); // never lost a life in this scenario
    },
  );
}
