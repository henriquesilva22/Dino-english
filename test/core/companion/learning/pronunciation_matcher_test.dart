import 'package:dino_english/core/companion/learning/pronunciation_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const matcher = PronunciationMatcher();

  RepetitionMatch walk(String heard) => matcher.match(
    'walk',
    heard,
    aliases: const ['wok', 'woke'],
    otherWords: const {'walk', 'work', 'rock', 'run', 'banana'},
  );

  test('the word itself, any case or punctuation, inside a sentence', () {
    for (final heard in ['walk', 'Walk!', 'walk.', ' WALK ', 'ué, walk']) {
      expect(walk(heard), RepetitionMatch.correct, reason: heard);
    }
  });

  test('what a recognizer writes for it', () {
    for (final heard in ['wok', 'walkk', 'waalk', 'Wolk']) {
      expect(walk(heard), RepetitionMatch.correct, reason: heard);
    }
  });

  test('near but not it: "almost"; something else: miss', () {
    expect(walk('rock'), RepetitionMatch.almost);
    expect(walk('banana'), RepetitionMatch.miss);
    expect(walk(''), RepetitionMatch.miss);
    expect(walk('eu gosto de pizza'), RepetitionMatch.miss);
  });

  test('another word the Dino teaches is not accepted as a typo', () {
    expect(walk('work'), isNot(RepetitionMatch.correct));
  });

  test('two-word targets', () {
    expect(matcher.match('thank you', 'Thank you!'), RepetitionMatch.correct);
    expect(
      matcher.match('thank you', 'thankyou', aliases: const ['thankyou']),
      RepetitionMatch.correct,
    );
  });

  test('sound keys', () {
    expect(
      PronunciationMatcher.soundKey('walk'),
      PronunciationMatcher.soundKey('wok'),
    );
    expect(
      PronunciationMatcher.soundKey('eat'),
      PronunciationMatcher.soundKey('eet'),
    );
    expect(
      PronunciationMatcher.soundKey('phone'),
      PronunciationMatcher.soundKey('fone'),
    );
  });
}
