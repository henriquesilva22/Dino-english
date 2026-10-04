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

  /// No voice for a non-English [SpeechService.speak] locale (e.g. no
  /// Portuguese voice installed). Callers just keep showing the text.
  noVoice,

  /// The platform TTS engine reported an error.
  failed,
}

/// Locales the app speaks.
const String kEnglishLocale = 'en-US';
const String kPortugueseLocale = 'pt-BR';

/// Offline text-to-speech, reusable across screens (Study now, minigame/
/// review later). Only ever called from navigation/tap-reachable code --
/// never from boot-time widgets -- so `test/widget_test.dart` (which has
/// no real platform TTS plugin) never touches it. See
/// `FlutterTtsSpeechService`'s doc comment for the concrete implementation
/// and `lib/game/sound/adventure_sound_service.dart` for the established
/// pattern this mirrors.
abstract class SpeechService {
  /// Speaks [text] -- in English unless [locale] says otherwise (the
  /// companion also speaks `pt-BR` subtitles). [rate] (0..1) and [pitch]
  /// default to the study screens' settings. Never throws: always
  /// resolves to a [SpeechResult] describing what happened. Interrupts
  /// (does not queue behind) any speech already in progress.
  Future<SpeechResult> speak(
    String text, {
    String locale = kEnglishLocale,
    double? rate,
    double? pitch,
  });

  /// Stops any speech in progress.
  Future<void> stop();

  /// Non-null (an opaque token) while a [speak] call is actively
  /// producing audio; null once it completes, is cancelled, or errors.
  /// Widgets watch this to show "speaking" feedback without depending on
  /// `speak()`'s Future alone -- some platforms don't reliably resolve
  /// that Future after a `stop()` cuts an utterance short.
  ValueListenable<Object?> get activeUtterance;
}
