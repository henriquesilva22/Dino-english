import 'platform.dart';

/// Resolves which platform (if any) the pet lands on this frame, given its
/// foot position before/after this frame's gravity step.
///
/// Flame's built-in collision detection checks overlap per-frame, not the
/// swept path between frames -- at the pet's fall speed that would tunnel
/// straight through a platform only ~28px thick. This pure function instead
/// checks whether the foot's vertical travel (`previousFootY` ->
/// `newFootY`) crossed a platform's `top` this frame, which is exactly the
/// same "swept" fix the single-ground clamp already relied on, generalized
/// to multiple platforms.
///
/// [ignoredPlatformId] lets the pet intentionally fall through the platform
/// it's currently standing on (the drop-through mechanic).
Platform? resolveLanding({
  required double footX,
  required double previousFootY,
  required double newFootY,
  required double velocityY,
  required List<Platform> platforms,
  String? ignoredPlatformId,
}) {
  if (velocityY < 0) return null;
  Platform? best;
  for (final platform in platforms) {
    if (platform.id == ignoredPlatformId) continue;
    if (!platform.containsX(footX)) continue;
    if (previousFootY > platform.top || newFootY < platform.top) continue;
    if (best == null || platform.top < best.top) best = platform;
  }
  return best;
}
