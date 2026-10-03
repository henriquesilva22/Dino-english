/// Which language the child is expected to speak. The recognizer detects
/// the language by itself, but on a one-word clip ("apple") it guesses
/// badly, so when the Dino waits for an English word the caller says so.
enum SpeechLanguageHint { auto, english, portuguese }

/// Microphone -> text, for talking to the companion by voice
/// (push-to-talk: hold the button, speak, release):
///
/// `microphone -> SpeechRecognitionService -> text -> CompanionEngine`
///
/// Implementations must be *offline* (on-device model): the app never
/// sends the child's voice anywhere. The app uses
/// `WhisperSpeechRecognitionService` (sherpa-onnx + Whisper tiny);
/// [UnavailableSpeechRecognitionService] when no model is bundled.
abstract class SpeechRecognitionService {
  /// Whether recognition can work on this device (model bundled...). The
  /// mic button is only shown when true.
  Future<bool> isAvailable();

  /// Loads the model in the background so the first answer is fast.
  /// Safe to call many times; never throws.
  Future<void> prepare();

  /// Starts capturing the microphone. False when it can't (permission
  /// denied, no model, mic busy).
  Future<bool> startListening();

  /// Stops capturing and transcribes what was said. Null when nothing
  /// usable was heard. Never throws.
  Future<String?> stopListening({
    SpeechLanguageHint hint = SpeechLanguageHint.auto,
  });

  /// Stops capturing and discards the audio.
  Future<void> cancel();

  /// Frees the model and the microphone.
  Future<void> dispose();
}

class UnavailableSpeechRecognitionService implements SpeechRecognitionService {
  const UnavailableSpeechRecognitionService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> prepare() async {}

  @override
  Future<bool> startListening() async => false;

  @override
  Future<String?> stopListening({
    SpeechLanguageHint hint = SpeechLanguageHint.auto,
  }) async => null;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}
