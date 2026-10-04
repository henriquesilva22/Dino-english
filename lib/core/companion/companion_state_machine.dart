import 'companion_response.dart';
import 'model/companion_model.dart';

/// What the companion is doing right now, from everything that drives it:
/// the engine's reaction, the voice, and its body in the world (walking,
/// chasing the ball...). Each activity shows one [CompanionAnim].
enum CompanionActivity {
  idle(CompanionAnim.idle),
  walking(CompanionAnim.walk),
  running(CompanionAnim.run),

  /// A physical play move outside the ball game (the ball dropped on it):
  /// one hit, then back to rest.
  playing(CompanionAnim.attack),
  attacking(CompanionAnim.attack),

  /// A hop (Pet Adventure: changing lanes).
  jumping(CompanionAnim.jump),
  talking(CompanionAnim.talking),
  eating(CompanionAnim.eating),
  sleeping(CompanionAnim.sleeping),
  happy(CompanionAnim.happy);

  const CompanionActivity(this.anim);

  final CompanionAnim anim;

  /// Played once, then the companion goes back to rest.
  bool get oneShot => this == playing || this == attacking || this == jumping;
}

/// How the body moves through the world (set by the movement controller).
enum CompanionGait { still, walk, run }

/// Resolves the [CompanionActivity] -- pure and model-independent, so the
/// companion's logic keeps working with any model.
///
/// Priority: sleeping > attacking > moving (run/walk) > the engine's
/// reaction (eating, happy, playing) > talking > idle. Talking never stops
/// the body: the Dino keeps running after the ball while it speaks.
class CompanionStateMachine {
  const CompanionStateMachine();

  CompanionActivity resolve({
    required CompanionAnimation engine,
    bool speaking = false,
    CompanionGait gait = CompanionGait.still,
    bool attacking = false,
  }) {
    if (engine == CompanionAnimation.sleeping) {
      return CompanionActivity.sleeping;
    }
    if (attacking) return CompanionActivity.attacking;
    switch (gait) {
      case CompanionGait.run:
        return CompanionActivity.running;
      case CompanionGait.walk:
        return CompanionActivity.walking;
      case CompanionGait.still:
        break;
    }
    final reaction = switch (engine) {
      CompanionAnimation.walking => CompanionActivity.walking,
      CompanionAnimation.eating ||
      CompanionAnimation.drinking => CompanionActivity.eating,
      CompanionAnimation.happy ||
      CompanionAnimation.celebrating => CompanionActivity.happy,
      CompanionAnimation.playing => CompanionActivity.playing,
      _ => null,
    };
    if (reaction != null) return reaction;
    if (speaking || engine == CompanionAnimation.talking) {
      return CompanionActivity.talking;
    }
    return CompanionActivity.idle;
  }
}
