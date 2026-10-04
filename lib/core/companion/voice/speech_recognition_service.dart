/// Which language the child is expected to speak. The recognizer detects
/// the language by itself, but on a one-word clip ("apple") it guesses
/// badly, so when the Dino waits for an English word the caller says so.
enum SpeechLanguageHint { auto, english, portuguese }

/// What the voice input is doing, as shown on the companion screen.
enum VoiceState {
  /// Not listening right now (screen in background, paused by the child).
  idle,

  /// The microphone is open and waiting for the child to talk.
  listening,

  /// A sentence was heard and is being turned into text.
  processing,

  /// Something went wrong; it retries by itself or on a tap.
  error,

  /// Voice can't be used (permission denied, no model): text only.
  disabled,
}

enum MicPermission {
  granted,
  denied,

  /// "Don't ask again": only the system settings can change it.
  permanentlyDenied,
}

/// Something the always-on recognizer noticed.
sealed class SpeechEvent {
  const SpeechEvent();
}

/// The child started talking.
class SpeechStarted extends SpeechEvent {
  const SpeechStarted();
}

/// The child stopped talking; the sentence is being transcribed.
class SpeechProcessing extends SpeechEvent {
  const SpeechProcessing();
}

/// A sentence turned into text.
class SpeechRecognized extends SpeechEvent {
  const SpeechRecognized(this.text);

  final String text;
}

/// Something that sounded like speech, but no usable words (noise).
class SpeechNothingHeard extends SpeechEvent {
  const SpeechNothingHeard();
}

/// The microphone or the model failed.
class SpeechFailed extends SpeechEvent {
  const SpeechFailed(this.reason);

  final String reason;
}

/// Hands-free voice input for the companion screen: once [start]ed it
/// listens continuously, detects when the child talks and emits each
/// sentence as text on [events] -- no button to hold.
///
/// Implementations must be *offline* (on-device models): the child's
/// voice never leaves the device. The app uses
/// `OfflineSpeechRecognitionService` (Silero VAD + Whisper tiny via
/// sherpa-onnx); [UnavailableSpeechRecognitionService] when the models
/// aren't bundled. The UI never sees the underlying libraries.
abstract class SpeechRecognitionService {
  /// Whether the on-device models are bundled.
  Future<bool> isAvailable();

  Future<MicPermission> checkPermission();

  /// Shows the system permission dialog (only if still allowed to ask).
  Future<MicPermission> requestPermission();

  /// Opens the app's system settings (after "don't ask again").
  Future<void> openSettings();

  /// Opens the microphone and starts listening. False when it can't
  /// (no permission, no model, mic busy). Safe to call when running.
  Future<bool> start();

  /// Closes the microphone. Safe to call when stopped.
  Future<void> stop();

  bool get isRunning;

  /// While muted the microphone stays open but audio is discarded -- so
  /// the Dino never "hears" its own voice while it talks.
  void setMuted(bool muted);

  /// Language expected in the next sentences.
  set languageHint(SpeechLanguageHint hint);

  Stream<SpeechEvent> get events;

  /// Closes the microphone and frees the models.
  Future<void> dispose();
}

class UnavailableSpeechRecognitionService implements SpeechRecognitionService {
  const UnavailableSpeechRecognitionService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<MicPermission> checkPermission() async => MicPermission.denied;

  @override
  Future<MicPermission> requestPermission() async => MicPermission.denied;

  @override
  Future<void> openSettings() async {}

  @override
  Future<bool> start() async => false;

  @override
  Future<void> stop() async {}

  @override
  bool get isRunning => false;

  @override
  void setMuted(bool muted) {}

  @override
  set languageHint(SpeechLanguageHint hint) {}

  @override
  Stream<SpeechEvent> get events => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
