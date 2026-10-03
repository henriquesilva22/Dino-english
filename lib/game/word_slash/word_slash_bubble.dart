import 'dart:ui' show Offset;

/// One floating word bubble. Immutable -- every per-frame update (movement)
/// or gameplay event produces a new instance via [copyWith], mirroring the
/// rest of this codebase's pure state models (`MinigameRoundState`,
/// `StudySessionState`). A bubble only exists in
/// `WordSlashSessionState.bubbles` while active -- there is no separate
/// "removed" status to track, since pair resolution is a single synchronous
/// state transition (see `WordSlashSessionState.endSwipe`), so nothing can
/// ever observe a bubble mid-removal the way Flame's multi-frame collision
/// callbacks can.
class WordSlashBubble {
  const WordSlashBubble({
    required this.id,
    required this.pairId,
    required this.text,
    required this.isPortuguese,
    required this.position,
    required this.velocity,
    required this.radius,
  });

  /// Unique per spawn -- two bubbles of the same pair share [pairId] but
  /// never [id].
  final String id;

  /// The `Word.id` this bubble represents -- the Portuguese and English
  /// bubbles of one pair always share this, which is what makes pairing a
  /// simple equality check instead of a lookup.
  final String pairId;

  final String text;
  final bool isPortuguese;
  final Offset position;
  final Offset velocity;
  final double radius;

  /// Hit-test for one swipe segment (the straight line between two
  /// consecutive pan-update points) against this bubble's hit-circle,
  /// padded larger than [radius] so mobile touch doesn't need pixel
  /// precision. Closest-point-on-segment-to-center via clamped projection --
  /// no dependency on rendering/animation state, so it's directly
  /// unit-testable.
  bool intersectsSegment(Offset a, Offset b, {required double padding}) {
    final hitRadius = radius + padding;
    final ab = b - a;
    final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSquared == 0) {
      return (a - position).distance <= hitRadius;
    }
    final t =
        (((position - a).dx * ab.dx) + ((position - a).dy * ab.dy)) /
        lengthSquared;
    final clampedT = t < 0 ? 0.0 : (t > 1 ? 1.0 : t);
    final closest = a + ab * clampedT;
    return (closest - position).distance <= hitRadius;
  }

  WordSlashBubble copyWith({Offset? position, Offset? velocity}) {
    return WordSlashBubble(
      id: id,
      pairId: pairId,
      text: text,
      isPortuguese: isPortuguese,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      radius: radius,
    );
  }
}
