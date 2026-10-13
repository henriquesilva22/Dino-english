/// Where the companion is and what it is doing there. Exactly one at a
/// time: entering one closes everything that belonged to the previous one
/// (the ball, the food, the bed...).
enum PetScene {
  /// Talking and hanging out.
  home('assets/fundos/cozinha.jpg'),

  /// Eating and drinking water share the same room.
  food('assets/fundos/sala de estar.jpg'),

  /// The ball game.
  play('assets/fundos/jogos.jpg'),

  /// Bedtime: the bedroom with the bed (drawn, no picture).
  sleep(null);

  const PetScene(this.background);

  /// The room behind the Dino (null: drawn by the bedroom widget). All
  /// scene pictures live in `assets/fundos/` -- change a room here only.
  final String? background;
}
