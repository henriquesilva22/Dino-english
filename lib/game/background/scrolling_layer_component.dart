import 'dart:ui';

import 'package:flame/components.dart';

import '../pet_adventure_game.dart';

/// Base for a decorative background layer that loops infinitely as it
/// scrolls left, at some fraction ([parallaxFactor]) of the ground's
/// scroll speed -- distant layers (clouds) move slower than near ones
/// (trees), giving a simple parallax depth cue with no image assets.
///
/// Technique: a single "tile" the width of the screen is generated once
/// per resize ([regeneratePattern]) and painted twice per frame, offset
/// by the current scroll and by one tile width, so the pattern always
/// covers the screen with no gap -- no components are ever added/removed
/// to scroll.
abstract class ScrollingLayerComponent extends PositionComponent
    with HasGameReference<PetAdventureGame> {
  ScrollingLayerComponent({required this.parallaxFactor})
    : super(anchor: Anchor.topLeft);

  final double parallaxFactor;

  double _scrollOffset = 0;
  double _patternWidth = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
    _patternWidth = size.x;
    regeneratePattern(size);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_patternWidth <= 0) return;
    _scrollOffset =
        (_scrollOffset + game.difficulty.scrollSpeed * parallaxFactor * dt) %
        _patternWidth;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(-_scrollOffset, 0);
    paintPattern(canvas);
    canvas.translate(_patternWidth, 0);
    paintPattern(canvas);
    canvas.restore();
  }

  /// Called once per resize; use it to precompute random shape positions
  /// for [paintPattern] (e.g. with a fixed-seed [Random] for stability).
  void regeneratePattern(Vector2 size);

  /// Paints one tile of the pattern, in local coordinates `0..size.x`.
  void paintPattern(Canvas canvas);
}
