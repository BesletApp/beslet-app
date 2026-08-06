import 'package:flutter/material.dart';

/// The verse rendered quietly, with the key words gently emphasized. The
/// emphasis is a light heuristic (longer, meaningful words in English get a
/// bolder weight) — enough to draw the eye, never so much as to be loud.
class EmphasizedVerseText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final bool emphasize;

  const EmphasizedVerseText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    this.emphasize = true,
  });

  static const Set<String> _stopWords = {
    'the', 'and', 'for', 'you', 'your', 'i', 'a', 'an', 'of', 'to', 'in',
    'is', 'it', 'that', 'he', 'his', 'her', 'we', 'our', 'their', 'they',
    'all', 'this', 'with', 'as', 'on', 'at', 'be', 'by', 'from', 'who',
    'not', 'but', 'have', 'has', 'are', 'was', 'were', 'me', 'my', 'so',
    'or', 'if', 'when', 'what', 'which', 'there', 'these', 'those', 'do',
    'does', 'did', 'shall', 'can', 'will', 'would', 'should', 'unto',
  };

  static String _core(String w) => w.replaceAll(RegExp(r'[^a-zA-Z]'), '');

  @override
  Widget build(BuildContext context) {
    final base = style;
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    if (!emphasize) return Text(text, style: base, textAlign: textAlign);

    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final spans = <TextSpan>[];
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final core = _core(w).toLowerCase();
      final isKey = core.length > 3 && !_stopWords.contains(core);
      spans.add(TextSpan(text: w, style: isKey ? bold : null));
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: textAlign,
    );
  }
}
