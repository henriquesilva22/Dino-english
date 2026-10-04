import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/companion/voice/companion_voice_service.dart';
import '../core/companion/voice/piper_portuguese_voice.dart';
import '../core/companion/voice/portuguese_voice.dart';
import '../core/companion/voice/speech_recognition_service.dart';
import '../core/companion/voice/offline_speech_recognition_service.dart';
import '../core/speech/flutter_tts_speech_service.dart';
import '../core/speech/speech_service.dart';

/// Shared TTS service -- only read from navigation/tap-reachable code
/// (the Study screen's Learn step), never at app boot (see
/// `SpeechService`'s doc comment). Same pattern as
/// `adventureSoundServiceProvider`.
final speechServiceProvider = Provider<SpeechService>(
  (ref) => FlutterTtsSpeechService(),
);

/// The companion's Portuguese voice: a bundled neural Piper voice on the
/// phone ([PortugueseVoiceModel.selected]), the device TTS elsewhere or
/// if the voice can't start. Swap voices here only.
final portugueseVoiceProvider = Provider<PortugueseVoiceService>((ref) {
  final system = SystemPortugueseVoice(
    ref.watch(speechServiceProvider),
    rate: TtsCompanionVoiceService.portugueseRate,
    pitch: TtsCompanionVoiceService.dinoPitch,
  );
  final mobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  return mobile ? PiperPortugueseVoice(fallback: system) : system;
});

/// How the companion's replies are voiced: the English voice is the
/// device TTS (unchanged); Portuguese goes through [portugueseVoiceProvider].
final companionVoiceServiceProvider = Provider<CompanionVoiceService>(
  (ref) => TtsCompanionVoiceService(
    ref.watch(speechServiceProvider),
    portuguese: ref.watch(portugueseVoiceProvider),
  ),
);

/// Hands-free offline speech-to-text for the companion (Silero VAD +
/// Whisper tiny on-device).
/// Auto-disposed with the companion screen, so the model's memory is
/// freed when the child leaves it. Without the bundled model
/// (`tool/download_voice_model.sh`) it reports unavailable and the screen
/// stays text-only.
final speechRecognitionServiceProvider =
    Provider.autoDispose<SpeechRecognitionService>((ref) {
      final service = OfflineSpeechRecognitionService();
      ref.onDispose(service.dispose);
      return service;
    });
