import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/services/wordproject_amharic_parser.dart';

// Real wordproject.org Amharic Matthew 5 page (verbatim excerpt of #textBody).
const _matthew5Html = r'''
<div class="textOptions">
<div class="textBody" id="textBody">
<h3>ማቴዎስ 5 </h3>
<!--... the Word of God:--><span class="dimver">
 </span>
<p><!--span class="verse" id="1">1  </span--> ሕዝቡንም አይቶ ወደ ተራራ ወጣ፤ በተቀመጠም ጊዜ ደቀ መዛሙርቱ ወደ እርሱ ቀረቡ፤
<br /><span class="verse" id="2">2 </span> አፉንም ከፍቶ አስተማራቸው እንዲህም አለ።
<br /><span class="verse" id="3">3 </span> በመንፈስ ድሆች የሆኑ ብፁዓን ናቸው፥ መንግሥተ ሰማያት የእነርሱ ናትና።
<br />[48] የተጨማሪ ማስታወሻ ጽሑፍ እዚህ ተጥሏል
</p>
<!--... sharper than any twoedged sword... -->
</div>
</div>
''';

void main() {
  group('parseWordProjectAmharicChapter', () {
    test('extracts verses 1..3 with the opening <p> as verse 1', () {
      final verses = parseWordProjectAmharicChapter(_matthew5Html);
      expect(verses.length, 3);
      expect(verses[0].number, 1);
      expect(verses[0].text, 'ሕዝቡንም አይቶ ወደ ተራራ ወጣ፤ በተቀመጠም ጊዜ ደቀ መዛሙርቱ ወደ እርሱ ቀረቡ፤');
      expect(verses[1].number, 2);
      expect(verses[1].text, 'አፉንም ከፍቶ አስተማራቸው እንዲህም አለ።');
      expect(verses[2].number, 3);
      expect(verses[2].text,
          'በመንፈስ ድሆች የሆኑ ብፁዓን ናቸው፥ መንግሥተ ሰማያት የእነርሱ ናትና።');
    });

    test('drops trailing bracket-style notes', () {
      final verses = parseWordProjectAmharicChapter(_matthew5Html);
      expect(verses.any((v) => v.text.contains('ማስታወሻ')), isFalse);
      expect(verses.any((v) => v.text.contains('48')), isFalse);
    });

    test('numbers are sequential', () {
      final verses = parseWordProjectAmharicChapter(_matthew5Html);
      for (var i = 0; i < verses.length; i++) {
        expect(verses[i].number, i + 1);
      }
    });

    test('returns empty when no textBody found', () {
      expect(parseWordProjectAmharicChapter('<html><body>no text</body></html>'),
          isEmpty);
    });

    test('decodes HTML entities', () {
      final html = '''
      <div class="textBody" id="textBody"><h3>መዝ 1 </h3><p>አንድ &amp; ሁለት &lt; ሦስት &gt; ነገር&nbsp;ጽሑፍ
      <br /><span class="verse" id="2">2 </span> ሁለተኛ ቁጥር</p></div>
      ''';
      final verses = parseWordProjectAmharicChapter(html);
      expect(verses[0].text, 'አንድ & ሁለት < ሦስት > ነገር ጽሑፍ');
      expect(verses[1].text, 'ሁለተኛ ቁጥር');
    });
  });
}
