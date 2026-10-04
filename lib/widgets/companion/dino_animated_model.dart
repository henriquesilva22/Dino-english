import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/companion/animation/companion_animation_controller.dart';
import '../../core/companion/animation/mouth_animation_controller.dart';
import '../../core/companion/model/companion_model.dart';
import '../pet_model_viewer.dart';

/// The companion's 3D body (any [CompanionModel]), driven without
/// reloading the model (all through [companionAnimatorJs]):
///
/// * [plan] -- which clip plays, at which speed (crossfaded);
/// * [yaw] -- the way it faces (degrees, 0 = the child), turned smoothly;
/// * [playing] -- the ball game: fixed camera (the stage places the feet
///   on the floor), no finger orbiting;
/// * [talking] + [mouth], [chewToken], [gaping] -- the mouth, when the
///   model has mouth blend shapes (this Dino has none: no-ops);
/// * [lookToken] -- each change turns the camera back to the front.
///
/// The view is square ([size]) so the camera framing is known.
/// Desktop (no WebView) shows [PetModelViewer]'s static fallback.
class DinoAnimatedModel extends StatefulWidget {
  const DinoAnimatedModel({
    required this.model,
    required this.plan,
    this.yaw = 0,
    this.playing = false,
    this.talking = false,
    this.mouth,
    this.lookToken = 0,
    this.chewToken = 0,
    this.gaping = false,
    this.size = 240,
    super.key,
  });

  final CompanionModel model;
  final CompanionClipPlan plan;
  final double yaw;
  final bool playing;
  final bool talking;
  final ValueListenable<MouthShape>? mouth;
  final int lookToken;

  /// Each change plays the chewing/gulping mouth (eating, drinking).
  final int chewToken;

  /// Mouth wide open, waiting for the food held near it.
  final bool gaping;
  final double size;

  static bool get isSupportedPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  State<DinoAnimatedModel> createState() => _DinoAnimatedModelState();
}

class _DinoAnimatedModelState extends State<DinoAnimatedModel> {
  WebViewController? _controller;
  double? _sentYaw;
  DateTime _yawSentAt = DateTime(0);

  @override
  void initState() {
    super.initState();
    widget.mouth?.addListener(_sendMouth);
  }

  @override
  void didUpdateWidget(DinoAnimatedModel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mouth != widget.mouth) {
      oldWidget.mouth?.removeListener(_sendMouth);
      widget.mouth?.addListener(_sendMouth);
    }
    if (oldWidget.playing != widget.playing) _sendPlaying();
    // Talking first, so the next clip knows the mouth is taken.
    if (oldWidget.talking != widget.talking) _sendTalking();
    if (oldWidget.plan != widget.plan) _sendPlan();
    if (oldWidget.yaw != widget.yaw) _sendYaw();
    if (oldWidget.lookToken != widget.lookToken) {
      _run('window.dinoLook && dinoLook()');
    }
    if (oldWidget.chewToken != widget.chewToken) {
      _run('window.dinoChew && dinoChew(1400)');
    } else if (oldWidget.gaping != widget.gaping) {
      _run('window.dinoGape && dinoGape(${widget.gaping})');
    }
  }

  @override
  void dispose() {
    widget.mouth?.removeListener(_sendMouth);
    super.dispose();
  }

  void _run(String js) =>
      _controller?.runJavaScript(js).catchError((Object _) {});

  void _sendPlan() {
    final p = widget.plan;
    final args =
        "'${p.clip}', ${p.loop}, '${p.rest}', "
        '${p.timeScale.toStringAsFixed(2)}, ${p.serial}';
    // Before the page script exists, park the call where the script picks
    // it up on start.
    _run(
      '(window.dinoPlay || function () '
      '{ window.__dinoPending = Array.prototype.slice.call(arguments); })'
      '($args)',
    );
  }

  /// The heading changes every frame while it runs around: send it at most
  /// ~30 times a second (the page smooths in between).
  void _sendYaw({bool force = false}) {
    final yaw = widget.yaw;
    final now = DateTime.now();
    if (!force && _sentYaw != null) {
      if ((yaw - _sentYaw!).abs() < 1.5 &&
          now.difference(_yawSentAt).inMilliseconds < 200) {
        return;
      }
      if (now.difference(_yawSentAt).inMilliseconds < 33) return;
    }
    _sentYaw = yaw;
    _yawSentAt = now;
    // Before the page script exists, park it where the script picks it up.
    _run(
      '(window.dinoFace || function (y) { window.__dinoYaw = y; })'
      '(${yaw.toStringAsFixed(1)})',
    );
  }

  void _sendPlaying() => _run(
    '(window.dinoPlaying || function (on) { window.__dinoPlaying = on; })'
    '(${widget.playing})',
  );

  void _sendTalking() => _run('window.dinoTalk && dinoTalk(${widget.talking})');

  void _sendMouth() {
    if (!widget.talking) return;
    final shape = widget.mouth?.value ?? MouthShape.closed;
    final vowel = shape.vowel == null ? 'null' : "'${shape.vowel}'";
    _run("window.dinoMouth && dinoMouth('${shape.state.name}', $vowel)");
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    if (!DinoAnimatedModel.isSupportedPlatform) {
      return PetModelViewer(
        modelAsset: model.asset,
        label: 'Dino',
        height: widget.size,
      );
    }
    final camera = model.camera;
    return SizedBox.square(
      dimension: widget.size,
      child: ModelViewer(
        key: ValueKey(model.asset),
        id: 'dino',
        src: model.asset,
        alt: 'Dino',
        backgroundColor: Colors.transparent,
        animationName: model.clip(CompanionAnim.idle)?.name,
        autoPlay: true,
        cameraControls: true,
        disableZoom: true,
        disablePan: true,
        cameraOrbit: camera.orbit,
        cameraTarget: camera.target,
        fieldOfView: camera.fov,
        interactionPrompt: InteractionPrompt.none,
        // A soft contact shadow under the feet: it sits on the floor.
        shadowIntensity: 1,
        shadowSoftness: 0.8,
        relatedJs: companionAnimatorJs(model),
        debugLogging: false,
        onWebViewCreated: (controller) {
          _controller = controller;
          _sendPlaying();
          _sendTalking();
          _sendYaw(force: true);
          _sendPlan();
        },
      ),
    );
  }
}

/// Injected into the model-viewer page (`<model-viewer id="dino">`):
///
/// * `dinoPlay(clip, loop, rest, timeScale, serial)` -- plays [clip] once or
///   looping, crossfaded; a one-shot falls back to looping [rest]; a new
///   serial restarts a one-shot already playing. Calls made before the
///   model loads are applied on load (also those parked in
///   `window.__dinoPending`).
/// * `dinoFace(yaw)` -- turns the model (degrees, 0 = the child), smoothly
///   and the short way round.
/// * `dinoPlaying(on)` -- the ball game: fixed camera, no orbiting.
/// * `dinoTalk(on)` / `dinoMouth(state, vowel)` / `dinoChew(ms)` /
///   `dinoGape(on)` -- mouth blend shapes, only when the model has them.
/// * `dinoLook()` -- the camera back to the front.
/// * `dinoDebug()` -- state snapshot, for tests.
String companionAnimatorJs(CompanionModel model) {
  final config = jsonEncode({
    'orbit': model.camera.orbit,
    'target': model.camera.target,
    'fov': model.camera.fov,
    'idle': model.clip(CompanionAnim.idle)?.name,
    'crossfadeMs': CompanionAnimationController.crossfade.inMilliseconds,
    'mouth': model.mouthShapes == null
        ? null
        : {'open': model.mouthShapes!.open, 'close': model.mouthShapes!.close},
  });
  return '(function (config) {$_animatorBody})($config);';
}

const String _animatorBody = r'''
  var mv = document.getElementById('dino');
  if (!mv) return;
  mv.animationCrossfadeDuration = config.crossfadeMs;
  var ready = false, pending = window.__dinoPending || null;
  var current = null, currentLoop = false, serial = -1, rest = config.idle;
  var talking = false, chewing = false, gaping = false;

  // ---- clips -----------------------------------------------------------------
  function start(clip, loop, restClip, timeScale, nextSerial) {
    rest = restClip || rest;
    if (timeScale && mv.timeScale !== timeScale) mv.timeScale = timeScale;
    var again = nextSerial !== undefined && nextSerial !== serial;
    if (nextSerial !== undefined) serial = nextSerial;
    if (current === clip && currentLoop === loop && (loop || !again)) return;
    var restart = current === clip;
    current = clip;
    currentLoop = loop;
    mv.animationName = clip;
    // animationName is applied on the element's next update.
    requestAnimationFrame(function () {
      if (restart) mv.currentTime = 0;
      mv.play({ repetitions: loop ? Infinity : 1 });
    });
  }

  window.dinoPlay = function (clip, loop, restClip, timeScale, nextSerial) {
    if (!ready) { pending = [clip, loop, restClip, timeScale, nextSerial]; return; }
    start(clip, loop, restClip, timeScale, nextSerial);
  };

  mv.addEventListener('load', function () {
    ready = true;
    // Already facing the right way when it appears.
    yaw = yawTarget;
    mv.orientation = '0deg 0deg ' + yaw.toFixed(1) + 'deg';
    findMouth();
    var p = pending || [config.idle, true, config.idle, 1, 0];
    pending = null;
    start(p[0], p[1], p[2], p[3], p[4]);
  });

  mv.addEventListener('finished', function () {
    if (currentLoop) return;
    current = null;
    start(rest, true, rest, 1);
  });

  // ---- facing ------------------------------------------------------------------
  // Facing/camera sent before this script ran were parked on window.
  var yaw = 0, yawTarget = window.__dinoYaw || 0;
  window.dinoFace = function (deg) { yawTarget = deg; };
  function turn() {
    var d = ((yawTarget - yaw) % 360 + 540) % 360 - 180; // short way round
    if (ready && Math.abs(d) > 0.3) {
      yaw += d * 0.35;
      mv.orientation = '0deg 0deg ' + yaw.toFixed(1) + 'deg';
    }
    requestAnimationFrame(turn);
  }
  requestAnimationFrame(turn);

  // ---- camera --------------------------------------------------------------------
  function frontCamera() {
    mv.cameraOrbit = config.orbit;
    mv.cameraTarget = config.target;
    mv.fieldOfView = config.fov;
  }
  window.dinoPlaying = function (on) {
    mv.cameraControls = !on;
    if (on) { frontCamera(); mv.jumpCameraToGoal && mv.jumpCameraToGoal(); }
  };
  window.dinoLook = frontCamera;
  if (window.__dinoPlaying) window.dinoPlaying(true);

  // ---- mouth (only with blend shapes) --------------------------------------------
  var mouths = [], mouth = config.mouth, open = 0, openTarget = 0;
  function findMouth() {
    mouths = [];
    if (!mouth) return;
    var sym = Object.getOwnPropertySymbols(mv).find(function (s) {
      return s.description === 'scene';
    });
    var scene = sym ? mv[sym] : null;
    if (!scene || !scene.traverse) return;
    scene.traverse(function (o) {
      if (o.morphTargetDictionary &&
          o.morphTargetDictionary[mouth.open] !== undefined) {
        mouths.push(o);
      }
    });
  }
  function setMouth(o) {
    mouths.forEach(function (m) {
      var i = m.morphTargetDictionary[mouth.open];
      var c = m.morphTargetDictionary[mouth.close];
      if (i !== undefined) m.morphTargetInfluences[i] = o;
      if (c !== undefined) m.morphTargetInfluences[c] = 1 - o;
    });
  }
  (function tick() {
    if (mouths.length && (talking || chewing || gaping || open > 0.01)) {
      open += (openTarget - open) * 0.4;
      setMouth(open);
    }
    requestAnimationFrame(tick);
  })();

  window.dinoMouth = function (state, vowel) {
    openTarget = state === 'mouthOpen' ? 0.8
      : state === 'mouthSlightlyOpen' ? 0.4 : 0;
  };
  window.dinoTalk = function (on) {
    talking = on;
    if (!on) openTarget = 0;
  };
  window.dinoChew = function (ms) {
    if (talking || !mouths.length) return;
    gaping = false;
    chewing = true;
    var end = Date.now() + (ms || 1400);
    (function step(o) {
      if (Date.now() > end) { chewing = false; openTarget = 0; return; }
      openTarget = o ? 0.5 : 0;
      setTimeout(function () { step(!o); }, 160);
    })(true);
  };
  window.dinoGape = function (on) {
    if (talking) return;
    gaping = on;
    openTarget = on ? 1 : 0;
  };

  window.dinoDebug = function () {
    return JSON.stringify({
      ready: ready, current: current, rest: rest, loop: currentLoop,
      serial: serial, timeScale: mv.timeScale, yaw: yaw,
      talking: talking, mouths: mouths.length,
      animation: mv.animationName, orbit: mv.cameraOrbit,
      controls: mv.cameraControls
    });
  };
''';
