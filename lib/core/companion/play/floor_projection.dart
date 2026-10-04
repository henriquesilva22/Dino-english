import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../model/companion_model.dart';
import '../movement/play_area_bounds.dart';

/// Maps the play floor (world metres) to the arena (pixels) and back, with
/// a little perspective: far away (small z, up the screen) things are
/// smaller. The scale comes from the companion's own size -- [dinoBox]
/// pixels show [CompanionCamera.viewWidthAtFeet] metres -- so the ball,
/// the speeds and the distances look the same on any screen; only how
/// much floor fits changes.
class FloorProjection {
  FloorProjection._({
    required this.arena,
    required this.dinoBox,
    required this.ppmNear,
    required this.yFar,
    required this.yNear,
    required this.bounds,
  });

  /// [arena]: the play area in pixels. [dinoBox]: size (px) of the square
  /// 3D view at the front of the floor. [top]: pixels kept free above the
  /// floor (HUD).
  factory FloorProjection.fit({
    required Size arena,
    required double dinoBox,
    required CompanionModel model,
    double margin = 12,
    double top = 48,
  }) {
    final ppmNear = dinoBox / model.camera.viewWidthAtFeet;
    final yNear = arena.height - margin;
    // Far line low enough for the (smaller) Dino's head to fit below the HUD.
    final headroom = model.camera.feetFraction * dinoBox * farScale;
    final yFar = math.min(
      math.max(arena.height * 0.3, top + headroom * 0.85),
      yNear - 40,
    );
    final halfWidth = math.max(0.5, (arena.width / 2 - margin) / ppmNear);
    // Seen from above at an angle: a metre of depth looks shorter.
    final ppmMid = ppmNear * (1 + farScale) / 2;
    final depth = math.max(0.8, (yNear - yFar) / (ppmMid * 0.55));
    return FloorProjection._(
      arena: arena,
      dinoBox: dinoBox,
      ppmNear: ppmNear,
      yFar: yFar,
      yNear: yNear,
      bounds: PlayAreaBounds(
        minX: -halfWidth,
        maxX: halfWidth,
        minZ: -depth / 2,
        maxZ: depth / 2,
      ),
    );
  }

  /// Size at the far edge compared to the front.
  static const double farScale = 0.72;

  final Size arena;
  final double dinoBox;

  /// Pixels per metre at the front edge.
  final double ppmNear;
  final double yFar;
  final double yNear;

  /// The whole floor visible in the arena.
  final PlayAreaBounds bounds;

  /// 0 at the far edge, 1 at the front.
  double _t(double z) => ((z - bounds.minZ) / bounds.depth).clamp(0.0, 1.0);

  /// How big things are at depth [z] (1 = at the front).
  double scaleAt(double z) => farScale + (1 - farScale) * _t(z);

  double ppmAt(double z) => ppmNear * scaleAt(z);

  /// Pixels per metre of depth (up/down the screen).
  double get ppmDepth => (yNear - yFar) / bounds.depth;

  /// The floor point [world] on screen.
  Offset toScreen(Offset world) => Offset(
    arena.width / 2 + world.dx * ppmAt(world.dy),
    yFar + _t(world.dy) * (yNear - yFar),
  );

  /// The floor point under the screen point [screen].
  Offset toWorld(Offset screen) {
    final t = ((screen.dy - yFar) / (yNear - yFar)).clamp(0.0, 1.0);
    final z = bounds.minZ + t * bounds.depth;
    return Offset((screen.dx - arena.width / 2) / ppmAt(z), z);
  }

  /// A screen direction (a swipe, "away from the finger") on the floor at
  /// depth [z], as a unit vector.
  Offset directionToWorld(Offset screenDirection, double z) {
    final d = Offset(
      screenDirection.dx / ppmAt(z),
      screenDirection.dy / ppmDepth,
    );
    final l = d.distance;
    return l < 1e-9 ? Offset.zero : d / l;
  }
}
