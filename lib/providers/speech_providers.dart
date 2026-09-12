import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/speech/flutter_tts_speech_service.dart';
import '../core/speech/speech_service.dart';

/// Shared TTS service -- only read from navigation/tap-reachable code
/// (the Study screen's Learn step), never at app boot (see
/// `SpeechService`'s doc comment). Same pattern as
/// `adventureSoundServiceProvider`.
final speechServiceProvider = Provider<SpeechService>(
  (ref) => FlutterTtsSpeechService(),
);
