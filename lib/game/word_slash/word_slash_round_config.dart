/// Tunable pacing for one of Word Slash's 10 rounds ("FASE N" in the UI). A
/// single place to adjust balancing without touching gameplay logic --
/// mirrors `DifficultyConfig` (Pet Adventure)'s role exactly. How many
/// words are on screen is deliberately NOT here: it's the fixed
/// [pairsOnScreen] constant for every round, per spec -- only
/// movement/timing/tolerance scale with round difficulty, never word count.
class WordSlashRoundConfig {
  const WordSlashRoundConfig({
    required this.roundNumber,
    required this.duration,
    required this.minSpeed,
    required this.maxSpeed,
    required this.hitPadding,
  });

  /// 1-based, matches the "FASE N" label shown in the UI.
  final int roundNumber;

  final Duration duration;

  /// Bubble speed range, in logical pixels/second.
  final double minSpeed;
  final double maxSpeed;

  /// Extra hit-test radius added on top of a bubble's visual [bubbleRadius]
  /// -- shrinks round over round for "menor tolerância de erro".
  final double hitPadding;

  static const int totalRounds = 10;

  /// Fixed for every round -- difficulty never comes from crowding more
  /// words on screen, only from movement/timing (see class doc).
  static const int pairsOnScreen = 3;

  static const double bubbleRadius = 46;

  static const int basePointsPerPair = 100;
  static const int comboCap = 10;
  static const int xpPerPair = 5;

  static const List<WordSlashRoundConfig> all = [
    WordSlashRoundConfig(
      roundNumber: 1,
      duration: Duration(seconds: 30),
      minSpeed: 40,
      maxSpeed: 70,
      hitPadding: 28,
    ),
    WordSlashRoundConfig(
      roundNumber: 2,
      duration: Duration(seconds: 28),
      minSpeed: 55,
      maxSpeed: 90,
      hitPadding: 26,
    ),
    WordSlashRoundConfig(
      roundNumber: 3,
      duration: Duration(seconds: 26),
      minSpeed: 70,
      maxSpeed: 110,
      hitPadding: 24,
    ),
    WordSlashRoundConfig(
      roundNumber: 4,
      duration: Duration(seconds: 24),
      minSpeed: 85,
      maxSpeed: 130,
      hitPadding: 22,
    ),
    WordSlashRoundConfig(
      roundNumber: 5,
      duration: Duration(seconds: 22),
      minSpeed: 100,
      maxSpeed: 150,
      hitPadding: 20,
    ),
    WordSlashRoundConfig(
      roundNumber: 6,
      duration: Duration(seconds: 20),
      minSpeed: 115,
      maxSpeed: 170,
      hitPadding: 18,
    ),
    WordSlashRoundConfig(
      roundNumber: 7,
      duration: Duration(seconds: 19),
      minSpeed: 130,
      maxSpeed: 190,
      hitPadding: 16,
    ),
    WordSlashRoundConfig(
      roundNumber: 8,
      duration: Duration(seconds: 18),
      minSpeed: 145,
      maxSpeed: 210,
      hitPadding: 15,
    ),
    WordSlashRoundConfig(
      roundNumber: 9,
      duration: Duration(seconds: 17),
      minSpeed: 160,
      maxSpeed: 230,
      hitPadding: 14,
    ),
    WordSlashRoundConfig(
      roundNumber: 10,
      duration: Duration(seconds: 16),
      minSpeed: 180,
      maxSpeed: 260,
      hitPadding: 12,
    ),
  ];

  static WordSlashRoundConfig forRound(int roundNumber) =>
      all[(roundNumber - 1).clamp(0, all.length - 1)];
}
