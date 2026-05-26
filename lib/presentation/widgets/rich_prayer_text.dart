import 'package:flutter/material.dart';

/// Parses a prayer text string containing `<b>...</b>` runs and returns the
/// equivalent list of [TextSpan]s, with bold spans wearing
/// [FontWeight.bold]. Used to render the day-of-Omer highlights that
/// [OmerPostProcessor] injects into Lamenatzeach + Ana BeKoach.
///
/// Top-level helper (no Flutter dependency on widget context) so it is
/// trivially unit-testable.
List<TextSpan> parseBoldSpans(String text, {TextStyle? baseStyle}) {
  if (text.isEmpty) return const [];
  // Greedy match: `<b>...</b>` with the closing tag required (we never emit
  // unclosed tags from the assembler, so a missing closer is treated as
  // literal text).
  final regex = RegExp(r'<b>(.*?)</b>', dotAll: true);
  final spans = <TextSpan>[];
  var cursor = 0;
  for (final m in regex.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start), style: baseStyle));
    }
    spans.add(TextSpan(
      text: m.group(1),
      style: (baseStyle ?? const TextStyle())
          .merge(const TextStyle(fontWeight: FontWeight.bold)),
    ));
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return spans;
}

/// Renders [text] right-to-left with `<b>...</b>` runs styled bold.
class RichPrayerText extends StatelessWidget {
  const RichPrayerText({
    super.key,
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: parseBoldSpans(text, baseStyle: style)),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
  }
}
