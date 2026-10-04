import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'speech_service.dart';

const _kEnglishLocale = kEnglishLocale;

/// A bit under the platform default (~0.5): easier to follow while still
/// learning.
const double _kDefaultRate = 0.4;

/// `flutter_tts`-backed [SpeechService] using the device's native TTS
/// engine (Android's `TextToSpeech`) -- fully offline whenever an English
/// voice is installed, no network calls, no API keys. Configured once for
/// `en-US` at a rate a bit slower than the platform default, suited to
/// students still learning pronunciation.
class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    unawaited(_configure());
    _tts.setCompletionHandler(() => _clearIfCurrent());
    _tts.setCancelHandler(() => _clearIfCurrent());
    _tts.setErrorHandler((_) => _clearIfCurrent());
  }

  final FlutterTts _tts;
  final ValueNotifier<Object?> _activeUtterance = ValueNotifier(null);

  /// Worst-case recovery budget, not a normal-latency guard -- deliberately
  /// generous (real utterances in this app's word bank finish in a couple
  /// of seconds) so a slow-but-working device is never falsely told
  /// "Não foi possível falar agora." A hung native completion callback (a
  /// real, OEM-dependent flutter_tts fragility -- see this plugin's own
  /// changelog re: TTS reconnection bugs) would otherwise leave `speak()`
  /// waiting forever and, with it, this specific button's local
  /// "is speaking" guard permanently stuck -- since this timeout is a
  /// purely local `Timer`, it recovers even in the worst case where no
  /// native signal ever arrives at all.
  static const _speakTimeout = Duration(seconds: 15);

  @override
  ValueListenable<Object?> get activeUtterance => _activeUtterance;

  Future<void> _configure() async {
    await _tts.setLanguage(_kEnglishLocale);
    // 0.0 (slowest) .. 1.0 (fastest); the platform default lands around
    // 0.5 -- a bit under that is easier to follow while still learning.
    await _tts.setSpeechRate(_kDefaultRate);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  void _clearIfCurrent([Object? token]) {
    if (token == null || _activeUtterance.value == token) {
      _activeUtterance.value = null;
    }
  }

  /// Locales whose offline voice was already looked up.
  final Set<String> _voiceChosen = {};

  /// Picks an installed (offline) voice for [locale] when the engine has
  /// one, so speech never depends on the network. Best effort: on any
  /// error the engine's default voice for the language is kept.
  Future<void> _preferOfflineVoice(String locale) async {
    if (!_voiceChosen.add(locale)) return;
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      final wanted = locale.toLowerCase();
      for (final v in voices) {
        if (v is! Map) continue;
        final voiceLocale = '${v['locale']}'.toLowerCase().replaceAll('_', '-');
        if (voiceLocale == wanted && '${v['network_required']}' != '1') {
          await _tts.setVoice({
            'name': '${v['name']}',
            'locale': '${v['locale']}',
          });
          return;
        }
      }
    } catch (_) {}
  }

  @override
  Future<SpeechResult> speak(
    String text, {
    String locale = _kEnglishLocale,
    double? rate,
    double? pitch,
  }) async {
    final unavailable = locale == _kEnglishLocale
        ? SpeechResult.noEnglishVoice
        : SpeechResult.noVoice;
    final bool available;
    try {
      final result = await _tts.isLanguageAvailable(locale);
      available = result == true || result == 1;
    } catch (_) {
      return unavailable;
    }
    if (!available) return unavailable;

    await stop();
    final token = Object();
    _activeUtterance.value = token;
    try {
      // Re-asserted before every utterance, not just once in the
      // constructor: flutter_tts can transparently rebind to a fresh
      // native TextToSpeech instance after the OS kills the bound
      // service, resetting its language to the device default rather
      // than English. This reduces the window rather than eliminating it
      // -- if a reconnect happens during this very call, this specific
      // utterance can still land on the device default (the next call
      // runs against the now-stable instance and is correct again).
      await _tts.setLanguage(locale);
      await _preferOfflineVoice(locale);
      await _tts.setSpeechRate(rate ?? _kDefaultRate);
      await _tts.setPitch(pitch ?? 1.0);
      // focus: true requests audio focus so playback isn't silently
      // muted/routed behind whatever else may hold it -- omitted before,
      // so it was never requested.
      await _tts.speak(text, focus: true).timeout(_speakTimeout);
    } catch (_) {
      _clearIfCurrent(token);
      return SpeechResult.failed;
    }
    _clearIfCurrent(token);
    return SpeechResult.spoken;
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _activeUtterance.value = null;
  }
}
