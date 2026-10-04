import 'dart:ui' show Offset, Size;

import 'package:dino_english/core/companion/model/companion_model.dart';
import 'package:dino_english/core/companion/play/floor_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const model = CompanionModel.dino;

  FloorProjection fit(Size arena) =>
      FloorProjection.fit(arena: arena, dinoBox: 240, model: model);

  test('screen -> floor -> screen round trip', () {
    final p = fit(const Size(360, 420));
    for (final s in const [
      Offset(180, 300),
      Offset(40, 200),
      Offset(330, 400),
    ]) {
      final back = p.toScreen(p.toWorld(s));
      expect(back.dx, closeTo(s.dx, 0.01));
      expect(back.dy, closeTo(s.dy, 0.01));
    }
  });

  test('far is up and smaller; the floor fits the arena', () {
    final p = fit(const Size(360, 420));
    final b = p.bounds;
    expect(
      p.toScreen(Offset(0, b.minZ)).dy,
      lessThan(p.toScreen(Offset(0, b.maxZ)).dy),
    );
    expect(p.scaleAt(b.minZ), lessThan(p.scaleAt(b.maxZ)));
    for (final corner in [
      Offset(b.minX, b.minZ),
      Offset(b.maxX, b.maxZ),
      Offset(b.minX, b.maxZ),
    ]) {
      final s = p.toScreen(corner);
      expect(s.dx, inInclusiveRange(0, 360));
      expect(s.dy, inInclusiveRange(0, 420));
    }
  });

  test('metres keep their size: a wider screen shows more floor', () {
    final small = fit(const Size(360, 420));
    final wide = fit(const Size(800, 420));
    expect(wide.ppmNear, small.ppmNear);
    expect(wide.bounds.width, greaterThan(small.bounds.width));
  });

  test('a swipe up the screen goes away from the child', () {
    final p = fit(const Size(360, 420));
    final d = p.directionToWorld(const Offset(0, -100), 0);
    expect(d.dy, closeTo(-1, 1e-9));
  });
}
