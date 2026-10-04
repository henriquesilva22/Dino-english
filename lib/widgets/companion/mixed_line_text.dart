import 'package:flutter/material.dart';

import '../../core/companion/companion_response.dart';
import '../../theme/neon_colors.dart';

/// One of the Dino's lines. In a Portuguese line with English inside
/// ("Eu vou WALK amanhã.") the English word stands out and can be
/// tapped ([onWord]) to see what it means.
class MixedLineText extends StatelessWidget {
  const MixedLineText({
    super.key,
    required this.text,
    this.english = const [],
    required this.style,
    this.onWord,
  });

  final String text;
  final List<String> english;
  final TextStyle style;
  final ValueChanged<String>? onWord;

  /// The look of a taught English word.
  static const Color wordColor = NeonColors.orange;

  @override
  Widget build(BuildContext context) {
    // Only the taught words (in capitals) are highlighted: "Great job!"
    // is English but not a word to learn.
    final words = [
      for (final w in english)
        if (w == w.toUpperCase()) w,
    ];
    if (words.isEmpty) return Text(text, style: style);
    final segments = CompanionLine.mixed(text, english: words).displaySegments;
    final wordStyle = style.copyWith(
      color: wordColor,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: wordColor,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final segment in segments)
            if (!segment.isEnglish)
              TextSpan(text: segment.text)
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  key: ValueKey('word-${segment.text.toLowerCase()}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onWord == null
                      ? null
                      : () => onWord!(segment.text.toLowerCase()),
                  child: Text(segment.text, style: wordStyle),
                ),
              ),
        ],
      ),
    );
  }
}
