import 'package:flutter/foundation.dart';

import '../../speech/speech_service.dart';
import '../companion_response.dart';

/// How the companion's replies are voiced. The `CompanionEngine` never
/// touches audio: swapping the implementation (device TTS today, bundled
/// audio clips or another offline voice later) needs no engine change.
abstract class CompanionVoiceService {
  /// Voices [response] (its English text only -- subtitles are never
  /// spoken). Never throws.
  Future<void> say(CompanionResponse response);

  Future<void> stop();

  /// Non-null while the Dino is talking -- the 3D model moves its mouth.
  ValueListenable<Object?> get speaking;
}

/// Default voice: the app's existing offline [SpeechService] (device TTS,
/// no online fallback).
class TtsCompanionVoiceService implements CompanionVoiceService {
  const TtsCompanionVoiceService(this._speech);

  final SpeechService _speech;

  /// Emoji and symbols the TTS would read out loud ("red apple").
  static final RegExp _nonSpeakable = RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}*]',
    unicode: true,
  );

  static String speakable(String text) =>
      text.replaceAll(_nonSpeakable, '').replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  Future<void> say(CompanionResponse response) async {
    final text = speakable(response.text);
    if (text.isEmpty) return;
    await _speech.speak(text);
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  ValueListenable<Object?> get speaking => _speech.activeUtterance;
}
