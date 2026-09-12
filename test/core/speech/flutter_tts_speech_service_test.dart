import 'dart:async';

import 'package:dino_english/core/speech/flutter_tts_speech_service.dart';
import 'package:dino_english/core/speech/speech_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// `implements FlutterTts`, not `extends` -- `FlutterTts()`'s constructor
/// touches a real, static `MethodChannel` the instant it runs, and
/// `extends` always runs the superclass constructor. `implements` never
/// does, so the real channel is never touched. `noSuchMethod` lets this
/// fake skip stubbing `FlutterTts`'s full ~35-member surface -- only what
/// `FlutterTtsSpeechService` actually calls gets a real body; anything
/// else would throw `NoSuchMethodError` loudly if ever reached.
class _NeverCompletingFakeTts implements FlutterTts {
  int speakCallCount = 0;

  @override
  Future<dynamic> isLanguageAvailable(String language) async => true;

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> setPitch(double pitch) async => 1;

  @override
  Future<dynamic> setVolume(double volume) async => 1;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;

  @override
  void setCompletionHandler(VoidCallback callback) {}

  @override
  void setCancelHandler(VoidCallback callback) {}

  @override
  void setErrorHandler(ErrorHandler handler) {}

  @override
  Future<dynamic> speak(String text, {bool focus = false}) {
    speakCallCount++;
    // Never completes -- simulates a hung native completion callback
    // (the real-world flutter_tts fragility the timeout guards against).
    return Completer<dynamic>().future;
  }

  @override
  Future<dynamic> stop() async => 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'a speak() call that never completes still resolves to failed via the timeout, and clears activeUtterance',
    () async {
      final fakeTts = _NeverCompletingFakeTts();
      final service = FlutterTtsSpeechService(tts: fakeTts);

      final result = await service.speak('apple');

      expect(result, SpeechResult.failed);
      expect(service.activeUtterance.value, isNull);
      expect(fakeTts.speakCallCount, 1);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
