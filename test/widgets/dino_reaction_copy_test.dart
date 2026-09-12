import 'package:dino_english/widgets/dino/dino_reaction_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incorrect answer always shows the "almost" message, regardless of streak', () {
    expect(
      dinoReactionMessage(isCorrect: false, streakThisSession: 0),
      contains('Almost'),
    );
    expect(
      dinoReactionMessage(isCorrect: false, streakThisSession: 5),
      contains('Almost'),
    );
  });

  test('correct answer below streak threshold shows "Perfect"', () {
    expect(
      dinoReactionMessage(isCorrect: true, streakThisSession: 1),
      contains('Perfect'),
    );
  });

  test('correct answer at or above a 3-streak shows the encouragement message', () {
    expect(
      dinoReactionMessage(isCorrect: true, streakThisSession: 3),
      contains("getting better"),
    );
    expect(
      dinoReactionMessage(isCorrect: true, streakThisSession: 4),
      contains("getting better"),
    );
  });
}
