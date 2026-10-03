import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/companion/voice/companion_voice_service.dart';
import '../core/companion/voice/speech_recognition_service.dart';
import '../core/companion/voice/whisper_speech_recognition_service.dart';
import '../core/speech/flutter_tts_speech_service.dart';
import '../core/speech/speech_service.dart';

/// Shared TTS service -- only read from navigation/tap-reachable code
/// (the Study screen's Learn step), never at app boot (see
/// `SpeechService`'s doc comment). Same pattern as
/// `adventureSoundServiceProvider`.
final speechServiceProvider = Provider<SpeechService>(
  (ref) => FlutterTtsSpeechService(),
);

/// How the companion's replies are voiced (device TTS today; bundled
/// audio or another offline voice later -- swap it here only).
final companionVoiceServiceProvider = Provider<CompanionVoiceService>(
  (ref) => TtsCompanionVoiceService(ref.watch(speechServiceProvider)),
);

/// Offline speech-to-text for the companion (Whisper tiny on-device).
/// Auto-disposed with the companion screen, so the model's memory is
/// freed when the child leaves it. Without the bundled model
/// (`tool/download_voice_model.sh`) it reports unavailable and the mic
/// button is hidden.
final speechRecognitionServiceProvider =
    Provider.autoDispose<SpeechRecognitionService>((ref) {
      final service = WhisperSpeechRecognitionService();
      ref.onDispose(service.dispose);
      return service;
    });
