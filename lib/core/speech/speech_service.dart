import 'package:flutter/foundation.dart';

/// Outcome of a [SpeechService.speak] call -- never throws, so callers can
/// always show a clear result instead of catching an exception.
enum SpeechResult {
  /// Spoke successfully (or was cut short by a newer [SpeechService.speak]
  /// call -- from the caller's perspective this still isn't a failure).
  spoken,

  /// No English voice is installed on the device. No online fallback is
  /// attempted -- callers should show a friendly message asking the user
  /// to install one in the device's settings.
  noEnglishVoice,

  /// The platform TTS engine reported an error.
  failed,
}

/// Offline text-to-speech, reusable across screens (Study now, minigame/
/// review later). Only ever called from navigation/tap-reachable code --
/// never from boot-time widgets -- so `test/widget_test.dart` (which has
/// no real platform TTS plugin) never touches it. See
/// `FlutterTtsSpeechService`'s doc comment for the concrete implementation
/// and `lib/game/sound/adventure_sound_service.dart` for the established
/// pattern this mirrors.
abstract class SpeechService {
  /// Speaks [text] in English. Never throws: always resolves to a
  /// [SpeechResult] describing what happened. Interrupts (does not queue
  /// behind) any speech already in progress.
  Future<SpeechResult> speak(String text);

  /// Stops any speech in progress.
  Future<void> stop();

  /// Non-null (an opaque token) while a [speak] call is actively
  /// producing audio; null once it completes, is cancelled, or errors.
  /// Widgets watch this to show "speaking" feedback without depending on
  /// `speak()`'s Future alone -- some platforms don't reliably resolve
  /// that Future after a `stop()` cuts an utterance short.
  ValueListenable<Object?> get activeUtterance;
}
