/// Something the player *caught* in Pet Adventure -- the only game events
/// that make the Dino speak. Shots, the boss's attacks and projectiles,
/// bursts and other effects are never word catches.
sealed class WordCatch {
  const WordCatch();
}

/// A real word was caught: the Dino says it in English ("Bread!").
final class CorrectWordCaught extends WordCatch {
  const CorrectWordCaught(this.english);

  final String english;

  @override
  String toString() => 'CorrectWordCaught($english)';
}

/// A fake word was caught: "Errou!".
final class WrongWordCaught extends WordCatch {
  const WrongWordCaught(this.label);

  final String label;

  @override
  String toString() => 'WrongWordCaught($label)';
}
