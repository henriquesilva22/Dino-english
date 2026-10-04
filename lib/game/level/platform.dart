/// A single standing surface in the level: the main ground or one of the
/// elevated platforms. Pure data, no Flame/Flutter dependency -- X grows
/// right, Y grows down (screen convention), `top` is the walkable surface.
class Platform {
  const Platform({
    required this.id,
    required this.left,
    required this.right,
    required this.top,
  });

  /// 'ground' (the painted path) | 'mid' | 'high'.
  final String id;
  final double left;
  final double right;
  final double top;

  bool containsX(double x) => x >= left && x <= right;
}
