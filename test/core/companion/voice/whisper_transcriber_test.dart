import 'dart:typed_data';

import 'package:dino_english/core/companion/voice/whisper_transcriber.dart';
import 'package:flutter_test/flutter_test.dart';

// Only the pure helpers: the native model itself runs on the device
// (on this Windows machine a conflicting onnxruntime.dll lives in System32).
void main() {
  group('clean', () {
    test('trims and keeps normal sentences', () {
      expect(WhisperTranscriber.clean('  Vamos brincar.  '), 'Vamos brincar.');
    });

    test('Whisper loops are collapsed ("Apple Apple Apple")', () {
      expect(
        WhisperTranscriber.clean('Apple Apple Apple Apple Apple.'),
        'Apple',
      );
    });

    test('known mishearings become what the Dino understands', () {
      expect(
        WhisperTranscriber.clean('Você está conforme?'),
        'Você está com fome?',
      );
      expect(WhisperTranscriber.clean('Tá conforme?'), 'Tá com fome?');
    });

    test('noise tags and subtitle credits are nothing', () {
      expect(WhisperTranscriber.clean('[Música]'), isNull);
      expect(WhisperTranscriber.clean(' (risos) '), isNull);
      expect(
        WhisperTranscriber.clean('Legendas pela comunidade Amara.org'),
        isNull,
      );
    });

    test('things children really say are kept', () {
      expect(WhisperTranscriber.clean('Obrigado!'), 'Obrigado!');
      expect(WhisperTranscriber.clean('Thank you.'), 'Thank you.');
      expect(WhisperTranscriber.clean('Tchau'), 'Tchau');
    });
  });

  group('audio', () {
    test('silence or a short tap is not speech', () {
      expect(WhisperTranscriber.hasSpeech(Float32List(16000)), isFalse);
      final tap = Float32List(1600)..fillRange(0, 1600, 0.5);
      expect(WhisperTranscriber.hasSpeech(tap), isFalse);
    });

    test('a loud enough second of audio is speech', () {
      final voice = Float32List(16000);
      for (var i = 0; i < voice.length; i++) {
        voice[i] = i.isEven ? 0.1 : -0.1;
      }
      expect(WhisperTranscriber.hasSpeech(voice), isTrue);
    });

    test('PCM16 little-endian -> -1..1', () {
      final bytes = Uint8List.fromList([0x00, 0x40, 0x00, 0xC0, 0xFF, 0x7F]);
      final samples = WhisperTranscriber.pcm16ToFloat(bytes);
      expect(samples, hasLength(3));
      expect(samples[0], closeTo(0.5, 1e-6));
      expect(samples[1], closeTo(-0.5, 1e-6));
      expect(samples[2], closeTo(1.0, 1e-4));
    });
  });
}
