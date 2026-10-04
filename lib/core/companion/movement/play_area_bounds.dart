import 'dart:math' as math;
import 'dart:ui' show Offset;

/// A rectangle of floor, in world metres: `Offset.dx` is x (screen right
/// +), `Offset.dy` is z (towards the child +). Nothing that plays inside
/// it may leave it -- the companion stops at the edge, the ball bounces.
class PlayAreaBounds {
  const PlayAreaBounds({
    required this.minX,
    required this.maxX,
    required this.minZ,
    required this.maxZ,
  });

  final double minX;
  final double maxX;
  final double minZ;
  final double maxZ;

  double get width => maxX - minX;
  double get depth => maxZ - minZ;
  Offset get center => Offset((minX + maxX) / 2, (minZ + maxZ) / 2);

  /// Smaller by [x] at the sides and [z] front and back (never inverted).
  PlayAreaBounds deflate(double x, [double? z]) {
    final dz = z ?? x;
    final cx = (minX + maxX) / 2, cz = (minZ + maxZ) / 2;
    return PlayAreaBounds(
      minX: math.min(minX + x, cx),
      maxX: math.max(maxX - x, cx),
      minZ: math.min(minZ + dz, cz),
      maxZ: math.max(maxZ - dz, cz),
    );
  }

  bool contains(Offset p) =>
      p.dx >= minX && p.dx <= maxX && p.dy >= minZ && p.dy <= maxZ;

  Offset clamp(Offset p) =>
      Offset(p.dx.clamp(minX, maxX), p.dy.clamp(minZ, maxZ));

  @override
  String toString() =>
      'PlayAreaBounds(x: ${minX.toStringAsFixed(2)}..${maxX.toStringAsFixed(2)}, '
      'z: ${minZ.toStringAsFixed(2)}..${maxZ.toStringAsFixed(2)})';
}
