import 'dino_enums.dart';

/// Snapshot of the Dino's body/mood and the child's progress, read by the
/// brain to answer "How are you?", "Are you hungry?" or "How much XP do I
/// have?". Today the needs are static defaults; the future needs system
/// (hunger, thirst, energy, hygiene, happiness) only has to push a new
/// snapshot via `DinoBrain.updateStatus`.
class DinoStatus {
  const DinoStatus({
    this.name = 'Dino',
    this.needs = const {},
    this.totalXp = 0,
    this.level = 1,
    this.isSleeping = false,
  });

  final String name;

  /// 0..1 per need, 1 = satisfied. Missing needs count as satisfied.
  final Map<DinoNeed, double> needs;
  final int totalXp;
  final int level;
  final bool isSleeping;

  /// Below this a need is "urgent" and colours the Dino's answers.
  static const double urgentThreshold = 0.35;

  double levelOf(DinoNeed need) => needs[need] ?? 1.0;

  bool isUrgent(DinoNeed need) => levelOf(need) < urgentThreshold;

  /// Below this (but not urgent) the Dino is "a little" hungry/tired...
  static const double mildThreshold = 0.7;

  bool isMild(DinoNeed need) =>
      !isUrgent(need) && levelOf(need) < mildThreshold;

  /// How simple the Dino's English should be for this child.
  EnglishTier get tier => EnglishTier.forLevel(level);

  /// The lowest urgent need, or null when the Dino is fine.
  DinoNeed? get mostUrgentNeed {
    DinoNeed? worst;
    for (final need in DinoNeed.values) {
      if (!isUrgent(need)) continue;
      if (worst == null || levelOf(need) < levelOf(worst)) worst = need;
    }
    return worst;
  }

  DinoStatus copyWith({
    String? name,
    Map<DinoNeed, double>? needs,
    int? totalXp,
    int? level,
    bool? isSleeping,
  }) {
    return DinoStatus(
      name: name ?? this.name,
      needs: needs ?? this.needs,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      isSleeping: isSleeping ?? this.isSleeping,
    );
  }

  /// Returns a copy with [need] moved by [delta], clamped to 0..1.
  DinoStatus adjustNeed(DinoNeed need, double delta) {
    final next = (levelOf(need) + delta).clamp(0.0, 1.0);
    return copyWith(needs: {...needs, need: next});
  }
}
