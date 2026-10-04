import '../../speech/speech_service.dart';

/// A bundled offline Portuguese voice (Piper/VITS, run by sherpa-onnx on
/// the device). Swapping voices only changes which model is bundled and
/// [PortugueseVoiceModel.selected]: nothing else in the companion knows
/// about it.
class PortugueseVoiceModel {
  const PortugueseVoiceModel({
    required this.id,
    required this.label,
    required this.license,
    this.lengthScale = 1.0,
  });

  final String id;
  final String label;
  final String license;

  /// > 1 speaks slower (Piper's length scale).
  final double lengthScale;

  /// `assets/models/voice_pt/<id>/` holds `model.onnx` + `tokens.txt`.
  String get assetDir => '$espeakRoot/$id';
  String get modelAsset => '$assetDir/model.onnx';
  String get tokensAsset => '$assetDir/tokens.txt';

  static const String espeakRoot = 'assets/models/voice_pt';

  /// Portuguese phoneme data shared by every Piper voice.
  static const String espeakAssetDir = '$espeakRoot/espeak-ng-data';

  /// Piper pt_BR "faber" (medium, int8), CC0, ~18 MB.
  static const faber = PortugueseVoiceModel(
    id: 'faber',
    label: 'Faber (Piper pt_BR medium)',
    license: 'CC0',
    lengthScale: 1.05,
  );

  /// "Razo" (Lucasllfs/Razo-piper-voice), conversational male, MIT,
  /// ~63 MB.
  static const razo = PortugueseVoiceModel(
    id: 'razo',
    label: 'Razo (Piper pt-BR)',
    license: 'MIT',
    lengthScale: 1.05,
  );

  static const List<PortugueseVoiceModel> all = [faber, razo];

  /// The voice to use: `--dart-define=PT_VOICE=razo` (bundle it with
  /// `PT_VOICE=razo tool/download_voice_model.sh`). Falls back to any
  /// bundled voice, then to the device's TTS.
  static PortugueseVoiceModel get selected {
    const id = String.fromEnvironment('PT_VOICE', defaultValue: 'faber');
    return all.firstWhere((v) => v.id == id, orElse: () => faber);
  }
}

/// Speaks Portuguese. The English voice is a separate path and never goes
/// through here.
abstract class PortugueseVoiceService {
  /// Speaks [text] and completes when it finished (or was stopped).
  /// Never throws.
  Future<SpeechResult> speak(String text);

  Future<void> stop();
}

/// The device's own Portuguese TTS (the old voice), used when no Piper
/// voice is bundled or it fails to start.
class SystemPortugueseVoice implements PortugueseVoiceService {
  SystemPortugueseVoice(this._speech, {this.rate = 0.5, this.pitch = 1.25});

  final SpeechService _speech;
  final double rate;
  final double pitch;

  @override
  Future<SpeechResult> speak(String text) =>
      _speech.speak(text, locale: kPortugueseLocale, rate: rate, pitch: pitch);

  @override
  Future<void> stop() => _speech.stop();
}
