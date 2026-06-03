import 'package:flutter/material.dart';

import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';

/// Parses prayer text that may contain markup tags and returns a list of
/// [TextSpan]s styled accordingly.
///
/// Supported tags:
///   `<b>...</b>`      — bold, in the prayer body font (Omer highlights).
///   `<label>...</label>` — section / aliyah marker: system font,
///                          AppColors.primary, ~80 % body size.
///   `<rubric>...</rubric>` — instruction / rubric: system font,
///                            muted grey, ~65 % body size.
///
/// `parseBoldSpans` is kept as a thin alias so existing tests continue to pass.
List<TextSpan> parseBoldSpans(String text, {TextStyle? baseStyle}) =>
    parsePrayerText(text, bodyStyle: baseStyle);

List<TextSpan> parsePrayerText(
  String text, {
  TextStyle? bodyStyle,
  TextStyle? labelStyle,
  TextStyle? rubricStyle,
}) {
  if (text.isEmpty) return const [];

  final regex = RegExp(r'<(b|label|rubric)>(.*?)<\/\1>', dotAll: true);
  final spans = <TextSpan>[];
  var cursor = 0;

  for (final m in regex.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(
        text: text.substring(cursor, m.start),
        style: bodyStyle,
      ));
    }
    final tag = m.group(1)!;
    final content = m.group(2)!;
    switch (tag) {
      case 'b':
        spans.add(TextSpan(
          text: content,
          style: (bodyStyle ?? const TextStyle())
              .merge(const TextStyle(fontWeight: FontWeight.bold)),
        ));
      case 'label':
        spans.add(TextSpan(text: content, style: labelStyle ?? _fallbackLabel(bodyStyle)));
      case 'rubric':
        spans.add(TextSpan(text: content, style: rubricStyle ?? _fallbackRubric(bodyStyle)));
    }
    cursor = m.end;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: bodyStyle));
  }
  return spans;
}

TextStyle _fallbackLabel(TextStyle? base) => TextStyle(
      fontSize: (base?.fontSize ?? 22) * (14.0 / 22.0),
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      height: (base?.height ?? 1.5),
    );

TextStyle _fallbackRubric(TextStyle? base) => TextStyle(
      fontSize: (base?.fontSize ?? 22) * 0.65,
      color: Colors.black54,
      height: (base?.height ?? 1.5),
    );

/// Renders [text] right-to-left, parsing all markup tags into styled spans.
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
    final labelStyle = TextStyle(
      fontSize: style.fontSize != null ? style.fontSize! * (14.0 / 22.0) : 14,
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      height: style.height,
    );
    final rubricStyle = TextStyle(
      fontSize: style.fontSize != null ? style.fontSize! * 0.65 : 14,
      color: Colors.black54,
      height: style.height,
    );
    return Text.rich(
      TextSpan(
        children: parsePrayerText(
          text,
          bodyStyle: style,
          labelStyle: labelStyle,
          rubricStyle: rubricStyle,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
  }
}
