/// Pure text for the Dino's in-exercise reaction -- first instance of
/// this "Dino reacts" pattern in the project, kept as a standalone
/// function so it's trivially testable and reusable outside
/// SentenceBuilderScreen later (Estudar, Provas, etc).
String dinoReactionMessage({
  required bool isCorrect,
  required int streakThisSession,
}) {
  if (!isCorrect) return '🦖🤔 Almost! Try again!';
  if (streakThisSession >= 3) return "🦖🤩 You're getting better!";
  return '🦖😄 Perfect!';
}
