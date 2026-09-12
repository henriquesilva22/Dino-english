import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// A short-lived text popup (e.g. "+5 XP") that rises and fades out, then
/// removes itself.
class FloatingTextComponent extends TextComponent {
  FloatingTextComponent({
    required super.text,
    required Vector2 position,
    Color color = Colors.white,
  }) : super(
         position: position,
         anchor: Anchor.bottomCenter,
         priority: 6,
         textRenderer: TextPaint(
           style: TextStyle(
             color: color,
             fontSize: 18,
             fontWeight: FontWeight.bold,
             shadows: const [Shadow(blurRadius: 2, color: Colors.black45)],
           ),
         ),
       ) {
    add(
      MoveByEffect(Vector2(0, -40), EffectController(duration: 0.7, curve: Curves.easeOut)),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.7, curve: Curves.easeIn),
        onComplete: removeFromParent,
      ),
    );
  }
}
