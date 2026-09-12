import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Short-lived particle burst for collecting a word: golden sparkles on a
/// correct catch, a duller reddish/grey puff on an incorrect one.
/// [ParticleSystemComponent] removes itself once the particle's lifespan
/// ends, so no manual cleanup is needed.
class CollectBurstComponent extends ParticleSystemComponent {
  CollectBurstComponent.sparkle({required Vector2 position, Random? random})
    : super(
        position: position,
        priority: 5,
        particle: _burst(
          random ?? Random(),
          count: 10,
          colors: const [Color(0xFFFFD54F), Color(0xFFFFF176)],
          speedMin: 60,
          speedMax: 120,
          gravity: 140,
          radius: 2.5,
          lifespan: 0.5,
        ),
      );

  CollectBurstComponent.impact({required Vector2 position, Random? random})
    : super(
        position: position,
        priority: 5,
        particle: _burst(
          random ?? Random(),
          count: 8,
          colors: const [Color(0xFFFF7043), Color(0xFFBDBDBD)],
          speedMin: 40,
          speedMax: 90,
          gravity: 220,
          radius: 3,
          lifespan: 0.4,
        ),
      );

  static Particle _burst(
    Random random, {
    required int count,
    required List<Color> colors,
    required double speedMin,
    required double speedMax,
    required double gravity,
    required double radius,
    required double lifespan,
  }) {
    return Particle.generate(
      count: count,
      lifespan: lifespan,
      generator: (i) {
        final angle = random.nextDouble() * 2 * pi;
        final speed = speedMin + random.nextDouble() * (speedMax - speedMin);
        return AcceleratedParticle(
          acceleration: Vector2(0, gravity),
          speed: Vector2(cos(angle), sin(angle)) * speed,
          child: CircleParticle(
            radius: radius,
            paint: Paint()..color = colors[i % colors.length],
          ),
        );
      },
    );
  }
}
