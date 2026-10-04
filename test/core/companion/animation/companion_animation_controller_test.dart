import 'package:dino_english/core/companion/animation/companion_animation_controller.dart';
import 'package:dino_english/core/companion/companion_response.dart';
import 'package:dino_english/core/companion/companion_state_machine.dart';
import 'package:dino_english/core/companion/model/companion_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const states = CompanionStateMachine();
  const animations = CompanionAnimationController(CompanionModel.dino);

  group('CompanionStateMachine', () {
    test('every engine animation resolves', () {
      for (final a in CompanionAnimation.values) {
        expect(() => states.resolve(engine: a), returnsNormally);
      }
    });

    test('sleeping wins; then attacking; then moving', () {
      expect(
        states.resolve(
          engine: CompanionAnimation.sleeping,
          attacking: true,
          gait: CompanionGait.run,
        ),
        CompanionActivity.sleeping,
      );
      expect(
        states.resolve(
          engine: CompanionAnimation.idle,
          attacking: true,
          gait: CompanionGait.run,
        ),
        CompanionActivity.attacking,
      );
      expect(
        states.resolve(
          engine: CompanionAnimation.happy,
          speaking: true,
          gait: CompanionGait.run,
        ),
        CompanionActivity.running,
      );
      expect(
        states.resolve(
          engine: CompanionAnimation.idle,
          gait: CompanionGait.walk,
        ),
        CompanionActivity.walking,
      );
    });

    test('reactions, talking, idle', () {
      expect(
        states.resolve(engine: CompanionAnimation.eating),
        CompanionActivity.eating,
      );
      expect(
        states.resolve(engine: CompanionAnimation.celebrating),
        CompanionActivity.happy,
      );
      expect(
        states.resolve(engine: CompanionAnimation.playing),
        CompanionActivity.playing,
      );
      expect(
        states.resolve(engine: CompanionAnimation.hungry, speaking: true),
        CompanionActivity.talking,
      );
      expect(
        states.resolve(engine: CompanionAnimation.listening),
        CompanionActivity.idle,
      );
    });
  });

  group('CompanionAnimationController', () {
    test('the four real clips', () {
      expect(animations.plan(CompanionActivity.idle).clip, 'idle');
      expect(animations.plan(CompanionActivity.walking).clip, 'walk');
      expect(animations.plan(CompanionActivity.running).clip, 'run');
      expect(animations.plan(CompanionActivity.attacking).clip, 'attack');
      expect(animations.plan(CompanionActivity.talking).clip, 'talk');
    });

    test('eating and happy have clips; sleeping falls back to idle', () {
      expect(animations.plan(CompanionActivity.eating).clip, 'eating');
      expect(animations.plan(CompanionActivity.happy).clip, 'happy');
      // No sleeping clip yet: no fake one either.
      final sleeping = animations.plan(CompanionActivity.sleeping);
      expect(sleeping.clip, 'idle');
      expect(sleeping.loop, isTrue);
    });

    test('a punch plays once, then the rest pose', () {
      final plan = animations.plan(
        CompanionActivity.playing,
        rest: CompanionActivity.talking,
        serial: 3,
      );
      expect(plan.clip, 'attack');
      expect(plan.loop, isFalse);
      expect(plan.rest, 'talk');
      expect(plan.serial, 3);
      expect(
        animations.plan(CompanionActivity.attacking, serial: 4),
        isNot(plan),
      );
    });

    test('loops carry the speed that matches the feet', () {
      final plan = animations.plan(CompanionActivity.running, timeScale: 0.8);
      expect(plan.loop, isTrue);
      expect(plan.rest, 'run');
      expect(plan.timeScale, 0.8);
    });
  });
}
