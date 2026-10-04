import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

/// The Pet Adventure scenery: sky, clouds, mountains, trees, the fence,
/// the little house and the path -- one picture, no characters, no
/// platforms, no HUD.
const String kSceneryAsset = 'assets/sprites/map/fundo do jogo.jpg';

/// Where the painted path is, as a fraction of the picture's height (the
/// picture always fills the screen height): the ground lane stands on it.
const double kSceneryPathTop = 0.84;

/// Draws [kSceneryAsset] filling the screen height and repeating sideways,
/// every other copy mirrored so the edges meet without a seam. It scrolls
/// at [parallax] x the words' speed: the far scenery drifts by slower than
/// what the pet runs into, which gives depth.
///
/// One image, decoded once and drawn twice or three times a frame: cheap
/// on a phone.
class SceneryBackgroundComponent extends PositionComponent {
  SceneryBackgroundComponent({this.scrollSpeed = 0, this.parallax = 0.5})
    : super(anchor: Anchor.topLeft);

  /// The words' speed (world units/second).
  double scrollSpeed;
  final double parallax;

  late final ui.Image _image = Flame.images.fromCache(kSceneryAsset);
  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;
  double _offset = 0;

  double get _tileWidth => _image.width * size.y / _image.height;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (scrollSpeed <= 0 || size.y <= 0) return;
    // A mirrored pair is the repeating unit.
    _offset = (_offset + scrollSpeed * parallax * dt) % (_tileWidth * 2);
  }

  @override
  void render(Canvas canvas) {
    if (size.y <= 0) return;
    final w = _tileWidth;
    final src = Rect.fromLTWH(
      0,
      0,
      _image.width.toDouble(),
      _image.height.toDouble(),
    );
    var i = 0;
    for (var x = -_offset; x < size.x; x += w, i++) {
      final dst = Rect.fromLTWH(x, 0, w, size.y);
      if (i.isOdd) {
        canvas.save();
        canvas.translate(x * 2 + w, 0);
        canvas.scale(-1, 1);
        canvas.drawImageRect(_image, src, dst, _paint);
        canvas.restore();
      } else {
        canvas.drawImageRect(_image, src, dst, _paint);
      }
    }
  }
}
