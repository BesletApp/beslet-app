class WordProjectAmharicVerse {
  final int number;
  final String text;
  const WordProjectAmharicVerse({required this.number, required this.text});
}

/// Parses the chapter text out of a wordproject.org Amharic Bible page.
///
/// The pages render verse text inline in `#textBody`: verse 1 is the opening
/// text of the chapter `<p>`, and every following verse is a
/// `<span class="verse" id="N">N </span>` block separated by `<br />`. Trailing
/// bracket-style notes (e.g. `[52]`) and any non-span fragments after the last
/// verse are dropped. Verse numbers are sequential (1..N), matching the
/// numbering convention used for the rest of the Amharic bundle.
List<WordProjectAmharicVerse> parseWordProjectAmharicChapter(String html) {
  final textBody = RegExp(
    r'id="textBody">(.*?)</div>',
    dotAll: true,
  ).firstMatch(html);
  if (textBody == null) return const [];

  var body = textBody.group(1)!;
  body = body.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

  final p = RegExp(r'<p>(.*?)</p>', dotAll: true).firstMatch(body);
  if (p == null) return const [];

  final chunks = p.group(1)!.split(RegExp(r'<br\s*/?>'));

  final verses = <WordProjectAmharicVerse>[];
  for (var i = 0; i < chunks.length; i++) {
    final chunk = chunks[i];
    final span = RegExp(
      r'<span class="verse" id="(\d+)">(.*?)</span>(.*)',
      dotAll: true,
    ).firstMatch(chunk);

    String text;
    if (span != null) {
      text = span.group(3) ?? '';
    } else if (i == 0) {
      text = chunk;
    } else {
      continue;
    }

    final cleaned = _clean(text);
    verses.add(WordProjectAmharicVerse(number: i + 1, text: cleaned));
  }
  return verses;
}

String _clean(String raw) {
  var s = raw.replaceAll(RegExp(r'<[^>]+>'), '');
  const entities = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
  };
  entities.forEach((k, v) => s = s.replaceAll(k, v));
  return s.trim();
}
