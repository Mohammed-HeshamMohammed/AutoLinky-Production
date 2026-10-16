import 'package:intl/intl.dart' show Bidi;
import 'package:material_ui/material_ui.dart';

/// The direction a piece of text reads in, from its first strong letter: an English job title is left to right
/// even inside the Arabic app. Null when it has no letters (numbers, symbols): the page's direction then.
TextDirection? directionOf(String text) {
  if (Bidi.startsWithRtl(text)) return TextDirection.rtl;
  if (Bidi.startsWithLtr(text)) return TextDirection.ltr;
  return null;
}

/// Text from the data (job titles, companies, places) that may be in either language: shaped in its own direction
/// (so "...Senior Network Engineer" is cut at the right end), aligned with the page (right in Arabic).
class BidiText extends StatelessWidget {
  const BidiText(this.text, {super.key, this.style, this.maxLines, this.overflow = TextOverflow.ellipsis});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final page = Directionality.of(context);
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: directionOf(text) ?? page,
      textAlign: page == TextDirection.rtl ? TextAlign.right : TextAlign.left,
    );
  }
}
