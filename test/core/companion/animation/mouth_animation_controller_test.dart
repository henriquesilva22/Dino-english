import 'package:dino_english/core/companion/animation/mouth_animation_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const open = MouthState.mouthOpen;
  const half = MouthState.mouthSlightlyOpen;
  const closed = MouthState.mouthClosed;

  group('frames', () {
    test('vowels open (with their shape), consonants half, spaces close', () {
      final frames = MouthAnimationController.framesFor('Hi you');
      expect(frames.map((f) => f.state), [
        half,
        open,
        closed,
        open,
        open,
        open,
      ]);
      expect(frames[1].vowel, 'i');
      expect(frames.map((f) => f.vowel).whereType<String>(), [
        'i',
        'i',
        'o',
        'u',
      ]);
    });

    test('accents count as vowels; emoji make no sound', () {
      final frames = MouthAnimationController.framesFor('Maçã! 🍎');
      expect(frames.map((f) => f.state), [half, open, half, open]);
      expect(frames.last.vowel, 'a');
    });

    test('long runs never freeze the mouth', () {
      final frames = MouthAnimationController.framesFor('Hmmmmmmm');
      expect(frames.length, lessThanOrEqualTo(3));
    });

    test('nothing to say -> no frames', () {
      expect(MouthAnimationController.framesFor('🍎 !!'), isEmpty);
    });
  });

  test('alternates while talking and closes when the voice ends', () {
    fakeAsync((async) {
      final mouth = MouthAnimationController(
        step: const Duration(milliseconds: 100),
      );
      final seen = <MouthState>{};
      mouth.shape.addListener(() => seen.add(mouth.shape.value.state));

      mouth.talk('I love apples!');
      expect(mouth.isTalking, isTrue);
      async.elapse(const Duration(milliseconds: 1500));
      expect(seen, containsAll([open, half, closed]));

      mouth.stop();
      expect(mouth.isTalking, isFalse);
      expect(mouth.shape.value, MouthShape.closed);
      final before = seen.length;
      async.elapse(const Duration(seconds: 1));
      expect(seen.length, before);
      mouth.dispose();
    });
  });

  test('keeps moving if the audio outlasts the text', () {
    fakeAsync((async) {
      final mouth = MouthAnimationController(
        step: const Duration(milliseconds: 100),
      );
      mouth.talk('Hi');
      var changes = 0;
      mouth.shape.addListener(() => changes++);
      async.elapse(const Duration(seconds: 2));
      expect(changes, greaterThan(5));
      mouth.dispose();
    });
  });
}
