import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/speech/speech_service.dart';
import '../providers/speech_providers.dart';
import '../theme/neon_colors.dart';
import 'home/tap_scale.dart';
import 'neon_border.dart';

/// Reusable 🔊 button: speaks [text] in English through [speechServiceProvider]
/// on tap -- never automatically. Shows a glow while speaking, ignores
/// repeat taps until that finishes (tapping a *different* SpeechButton
/// still interrupts it -- see [SpeechService.speak]), and shows a short
/// friendly caption instead of failing silently when there's no English
/// voice installed.
class SpeechButton extends ConsumerStatefulWidget {
  const SpeechButton({required this.text, this.size = 40, super.key});

  final String text;
  final double size;

  @override
  ConsumerState<SpeechButton> createState() => _SpeechButtonState();
}

class _SpeechButtonState extends ConsumerState<SpeechButton> {
  bool _isSpeaking = false;
  SpeechResult? _lastResult;
  // Cached rather than re-read via `ref` in dispose(): Riverpod treats
  // ref.read() as unsafe once the widget is unmounting.
  late final SpeechService _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(speechServiceProvider);
    _service.activeUtterance.addListener(_onActiveUtteranceChanged);
  }

  @override
  void dispose() {
    _service.activeUtterance.removeListener(_onActiveUtteranceChanged);
    super.dispose();
  }

  // Safety net: if this button's own speak() Future never resolves after
  // being interrupted by another SpeechButton (a known flutter_tts/Android
  // rough edge -- see SpeechService.activeUtterance's doc comment), the
  // shared activeUtterance going back to null is what actually clears the
  // "speaking" state here.
  void _onActiveUtteranceChanged() {
    if (!mounted) return;
    if (_service.activeUtterance.value == null && _isSpeaking) {
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _handleTap() async {
    if (_isSpeaking) return;
    setState(() {
      _isSpeaking = true;
      _lastResult = null;
    });
    final result = await _service.speak(widget.text);
    if (!mounted) return;
    setState(() {
      _isSpeaking = false;
      _lastResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color =
        _lastResult == SpeechResult.noEnglishVoice ||
            _lastResult == SpeechResult.failed
        ? NeonColors.red
        : NeonColors.cyan;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TapScale(
          onTap: _handleTap,
          child: NeonBorder(
            color: color,
            radius: widget.size / 2,
            glow: _isSpeaking,
            child: Container(
              width: widget.size,
              height: widget.size,
              color: NeonColors.surface.withValues(alpha: 0.75),
              alignment: Alignment.center,
              child: Text('🔊', style: TextStyle(fontSize: widget.size * 0.5)),
            ),
          ),
        ),
        if (_lastResult == SpeechResult.noEnglishVoice)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 120,
              child: Text(
                'Instale uma voz em inglês nas configurações do aparelho.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: NeonColors.textSecondary),
              ),
            ),
          )
        else if (_lastResult == SpeechResult.failed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Não foi possível falar agora.',
              style: TextStyle(fontSize: 10, color: NeonColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
