import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../brain/nlp/normalizer.dart';

enum MouthState { mouthClosed, mouthSlightlyOpen, mouthOpen }

/// What the mouth looks like at one moment: how open, and (when open)
/// which vowel shape -- the model has `V_A`..`V_U` visemes.
@immutable
class MouthShape {
  const MouthShape(this.state, [this.vowel]);

  static const closed = MouthShape(MouthState.mouthClosed);

  final MouthState state;

  /// `a`, `e`, `i`, `o` or `u` while [MouthState.mouthOpen].
  final String? vowel;

  @override
  bool operator ==(Object other) =>
      other is MouthShape && other.state == state && other.vowel == vowel;

  @override
  int get hashCode => Object.hash(state, vowel);

  @override
  String toString() =>
      'MouthShape(${state.name}${vowel == null ? '' : ', $vowel'})';
}

/// Moves the Dino's mouth while it talks. TTS engines don't report
/// phonemes, so it walks through the spoken text at speech speed: vowels
/// open the mouth (with that vowel's shape), consonants half-open it,
/// spaces and punctuation close it -- which reads as real talking. The
/// text loops until [stop] (the voice tells when the audio really ends).
class MouthAnimationController {
  MouthAnimationController({this.step = const Duration(milliseconds: 85)});

  /// Time per character (~12 characters per second, like the slow TTS).
  final Duration step;

  final ValueNotifier<MouthShape> _shape = ValueNotifier(MouthShape.closed);
  Timer? _timer;
  List<MouthShape> _frames = const [];
  int _index = 0;

  ValueListenable<MouthShape> get shape => _shape;

  bool get isTalking => _timer != null;

  /// Starts (or switches to) talking [text].
  void talk(String text) {
    _frames = framesFor(text);
    _index = 0;
    _timer?.cancel();
    if (_frames.isEmpty) {
      _timer = null;
      _shape.value = MouthShape.closed;
      return;
    }
    _advance();
    _timer = Timer.periodic(step, (_) => _advance());
  }

  /// The voice finished: close the mouth.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _shape.value = MouthShape.closed;
  }

  void dispose() {
    _timer?.cancel();
    _shape.dispose();
  }

  void _advance() {
    _shape.value = _frames[_index];
    _index = (_index + 1) % _frames.length;
  }

  /// One shape per character, with runs of the same shape merged into a
  /// single longer frame so the mouth never flickers faster than a
  /// syllable.
  static List<MouthShape> framesFor(String text) {
    final frames = <MouthShape>[];
    for (final rune in Normalizer.fold(text).runes) {
      final c = String.fromCharCode(rune);
      final MouthShape shape;
      if ('aeiouy'.contains(c)) {
        shape = MouthShape(MouthState.mouthOpen, c == 'y' ? 'i' : c);
      } else if (RegExp(r'[a-z0-9]').hasMatch(c)) {
        shape = const MouthShape(MouthState.mouthSlightlyOpen);
      } else if (c == ' ' || RegExp(r'[.,!?;:…-]').hasMatch(c)) {
        shape = MouthShape.closed;
      } else {
        continue; // emoji and symbols: no sound
      }
      // Two identical shapes in a row stay as two frames (longer hold),
      // but a third one is dropped -- "Hmmmm" doesn't freeze the mouth.
      if (frames.length >= 2 &&
          frames[frames.length - 1] == shape &&
          frames[frames.length - 2] == shape) {
        continue;
      }
      frames.add(shape);
    }
    // Trailing silence would hold the mouth closed while still talking.
    while (frames.isNotEmpty && frames.last == MouthShape.closed) {
      frames.removeLast();
    }
    return frames;
  }
}
