import 'companion_response.dart';

/// Animation clips inside `assets/models/dino/Dino_Baby_v2_animado.glb`.
/// Every clip exists twice -- `A_<name>` moves the skeleton, `SK_<name>`
/// the face shape keys -- and both are played together.
enum DinoClip {
  idle('Idle'),
  talk('Falar'),
  happy('Feliz'),
  sad('Triste'),
  cry('Chorar'),
  sleep('Dormir'),
  celebrate('Comemorar'),
  correct('Acerto'),
  wrong('Erro'),
  confused('Confuso'),
  surprised('Surpreso'),
  jump('Pular'),
  walk('Andar'),
  blink('Piscar');

  const DinoClip(this.clipName);

  /// Suffix shared by `A_<clipName>` and `SK_<clipName>`.
  final String clipName;
}

/// One request to the 3D view: play [clip] (looping or once), then go
/// back to looping [rest].
class DinoClipPlan {
  const DinoClipPlan(this.clip, {required this.loop, required this.rest});

  final DinoClip clip;
  final bool loop;
  final DinoClip rest;

  @override
  bool operator ==(Object other) =>
      other is DinoClipPlan &&
      other.clip == clip &&
      other.loop == loop &&
      other.rest == rest;

  @override
  int get hashCode => Object.hash(clip, loop, rest);

  @override
  String toString() =>
      'DinoClipPlan(${clip.clipName}, loop: $loop, '
      'rest: ${rest.clipName})';
}

/// Maps the engine's [CompanionAnimation]s to the model's clips. The
/// engine stays independent of this model: another Dino (or a 2D sprite)
/// only needs another mapping.
class DinoClipMapper {
  const DinoClipMapper();

  /// [animation] is the current reaction, [rest] the pose for the pet's
  /// needs when nothing happens, [speaking] whether the voice is talking
  /// right now (the mouth moves while it does).
  DinoClipPlan plan({
    required CompanionAnimation animation,
    required CompanionAnimation rest,
    required bool speaking,
  }) {
    final restClip = _loopFor(rest, speaking: speaking);
    return switch (animation) {
      CompanionAnimation.sleeping => const DinoClipPlan(
        DinoClip.sleep,
        loop: true,
        rest: DinoClip.sleep,
      ),
      CompanionAnimation.celebrating => DinoClipPlan(
        DinoClip.celebrate,
        loop: false,
        rest: restClip,
      ),
      CompanionAnimation.playing => DinoClipPlan(
        DinoClip.jump,
        loop: false,
        rest: restClip,
      ),
      CompanionAnimation.listening => DinoClipPlan(
        DinoClip.surprised,
        loop: false,
        rest: DinoClip.idle,
      ),
      CompanionAnimation.thinking => const DinoClipPlan(
        DinoClip.confused,
        loop: true,
        rest: DinoClip.confused,
      ),
      CompanionAnimation.happy ||
      CompanionAnimation.eating ||
      CompanionAnimation.drinking => DinoClipPlan(
        DinoClip.happy,
        loop: false,
        rest: restClip,
      ),
      CompanionAnimation.idle ||
      CompanionAnimation.talking ||
      CompanionAnimation.sad ||
      CompanionAnimation.hungry ||
      CompanionAnimation.thirsty ||
      CompanionAnimation.sleepy => () {
        final clip = _loopFor(animation, speaking: speaking);
        return DinoClipPlan(clip, loop: true, rest: clip);
      }(),
    };
  }

  DinoClip _loopFor(CompanionAnimation animation, {required bool speaking}) {
    if (animation == CompanionAnimation.sleeping) return DinoClip.sleep;
    if (speaking) return DinoClip.talk;
    return switch (animation) {
      CompanionAnimation.sad ||
      CompanionAnimation.hungry ||
      CompanionAnimation.thirsty ||
      CompanionAnimation.sleepy => DinoClip.sad,
      _ => DinoClip.idle,
    };
  }
}

/// Injected into the model-viewer page. `window.dinoPlay(clip, loop,
/// rest)` plays the `A_` + `SK_` clips together (once or looping) and
/// falls back to looping `rest` when a one-shot clip finishes. Calls
/// made before the model has loaded are kept and applied on load.
const String dinoAnimatorJs = r'''
(function () {
  var mv = document.getElementById('dino');
  if (!mv) return;
  var ready = false, pending = window.__dinoPending || null, face = null;
  var current = null, currentLoop = false, rest = 'Idle';

  function start(clip, loop, restClip) {
    rest = restClip || rest;
    if (current === clip && currentLoop && loop) return;
    current = clip;
    currentLoop = loop;
    if (face) {
      try { mv.detachAnimation(face, { fade: 0.2 }); } catch (e) {}
      face = null;
    }
    mv.animationName = 'A_' + clip;
    var reps = loop ? Infinity : 1;
    // animationName is applied on the element's next update.
    requestAnimationFrame(function () {
      mv.play({ repetitions: reps });
      try {
        mv.appendAnimation('SK_' + clip, { repetitions: reps, fade: 0.2 });
        face = 'SK_' + clip;
      } catch (e) {}
    });
  }

  window.dinoPlay = function (clip, loop, restClip) {
    if (!ready) { pending = [clip, loop, restClip]; return; }
    start(clip, loop, restClip);
  };

  mv.addEventListener('load', function () {
    ready = true;
    var p = pending || ['Idle', true, 'Idle'];
    pending = null;
    start(p[0], p[1], p[2]);
  });

  mv.addEventListener('finished', function () {
    current = null;
    start(rest, true, rest);
  });
})();
''';
