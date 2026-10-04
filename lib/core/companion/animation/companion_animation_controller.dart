import '../companion_state_machine.dart';
import '../model/companion_model.dart';

/// One request to the 3D view: play [clip] (looping or once), then loop
/// [rest]. [timeScale] speeds the clip up/down so the feet match the
/// ground speed. A new [serial] restarts a one-shot that is already
/// playing (two punches in a row).
class CompanionClipPlan {
  const CompanionClipPlan(
    this.clip, {
    required this.loop,
    required this.rest,
    this.timeScale = 1,
    this.serial = 0,
  });

  final String clip;
  final bool loop;
  final String rest;
  final double timeScale;
  final int serial;

  @override
  bool operator ==(Object other) =>
      other is CompanionClipPlan &&
      other.clip == clip &&
      other.loop == loop &&
      other.rest == rest &&
      other.timeScale == timeScale &&
      other.serial == serial;

  @override
  int get hashCode => Object.hash(clip, loop, rest, timeScale, serial);

  @override
  String toString() =>
      'CompanionClipPlan($clip, loop: $loop, rest: $rest, '
      'timeScale: $timeScale, serial: $serial)';
}

/// The single place that turns what the companion does
/// ([CompanionActivity]) into clips of the current [CompanionModel]. The
/// UI never names a clip: changing the model means changing
/// [CompanionModel], not the screens.
///
/// A model without a clip for an activity shows idle instead (this model
/// has no eating, sleeping or happy clips yet -- no fake ones are made).
/// Transitions are crossfaded by the 3D view.
class CompanionAnimationController {
  const CompanionAnimationController(this.model);

  final CompanionModel model;

  /// Crossfade between clips (quick, so a punch still feels snappy).
  static const Duration crossfade = Duration(milliseconds: 250);

  /// The clip actually shown for [anim]: itself, or the closest fallback.
  CompanionClip clipFor(CompanionAnim anim) {
    final own = model.clip(anim);
    if (own != null) return own;
    final fallback = switch (anim) {
      CompanionAnim.run => model.clip(CompanionAnim.walk),
      _ => null,
    };
    return fallback ?? model.clip(CompanionAnim.idle)!;
  }

  bool has(CompanionAnim anim) => model.clip(anim) != null;

  /// [activity] now; [rest] is what to go back to after a one-shot.
  CompanionClipPlan plan(
    CompanionActivity activity, {
    CompanionActivity rest = CompanionActivity.idle,
    double timeScale = 1,
    int serial = 0,
  }) {
    final restClip = clipFor(rest.oneShot ? CompanionAnim.idle : rest.anim);
    final clip = clipFor(activity.anim);
    final oneShot = activity.oneShot && has(activity.anim);
    return CompanionClipPlan(
      clip.name,
      loop: !oneShot,
      rest: oneShot ? restClip.name : clip.name,
      timeScale: timeScale,
      serial: serial,
    );
  }
}
