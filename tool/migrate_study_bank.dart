import 'dart:convert';
import 'dart:io';

/// Migrates `assets/data/study.json` from the v2 phased bank (seven legacy
/// sections) to the v3 full workbook: eight sections with the canonical order,
/// a verseByVerse section split from the old whatTextSays prose, and a memory
/// anchor per entry.
///
/// Run from the repo root:
///   dart tool/migrate_study_bank.dart
///
/// The migration is conservative: every existing string is reused verbatim
/// (including the Amharic), nothing is rewritten, and the tool refuses to
/// write when the transformation would lose or alter any text.

/// Verse ranges used to split the old `whatTextSays` prose into observations.
/// Single-verse passages and passages whose prose is one continuous statement
/// keep a single observation over the whole passage.
const Map<String, List<Map<String, int>>> _observationRanges = {
  'psalm23': [
    {'start': 1, 'end': 1},
    {'start': 2, 'end': 3},
    {'start': 4, 'end': 4},
    {'start': 5, 'end': 5},
    {'start': 6, 'end': 6},
  ],
  'john316': [
    {'start': 16, 'end': 16},
  ],
  'romans828': [
    {'start': 28, 'end': 28},
  ],
  'philippians413': [
    {'start': 13, 'end': 13},
  ],
  'matthew633': [
    {'start': 33, 'end': 33},
  ],
  'isaiah4031': [
    {'start': 31, 'end': 31},
  ],
  'ephesians28': [
    {'start': 8, 'end': 9},
  ],
  'corinthians13': [
    {'start': 4, 'end': 7},
  ],
};

/// Short memory anchors derived from the passage: a concrete image, a key
/// word, and a one-sentence central statement, in both languages.
const Map<String, Map<String, String>> _anchors = {
  'psalm23': {
    'imageEn': 'the shepherd who walks the valley with his sheep',
    'imageAm': 'ከበጎቹ ጋር ሸለቆውን የሚሻገር እረኛ',
    'keywordEn': 'the LORD is my shepherd',
    'keywordAm': 'እግዚአብሔር እረኛዬ ነው',
    'sentenceEn':
        'The shepherd provides, restores, stays near, and finally hosts forever.',
    'sentenceAm':
        'እረኛው ያቀርባል፣ ያድሳል፣ አብሮ ይኖራል፣ በመጨረሻ ለዘላለም ያስተናግዳል።',
  },
  'john316': {
    'imageEn': 'God giving His one and only Son to the world',
    'imageAm': 'እግዚአብሔር አንድያ ልጁን ለዓለም ሲሰጥ',
    'keywordEn': 'whoever believes has eternal life',
    'keywordAm': 'የሚያምን ሁሉ ዘላለማዊ ሕይወት አለው',
    'sentenceEn': 'Love gives first; faith receives; life follows.',
    'sentenceAm':
        'ፍቅር ይሰጣል፤ እምነት ይቀበላል፤ ሕይወት ይከተላል።',
  },
  'romans828': {
    'imageEn': 'all things woven together toward good',
    'imageAm': 'ሁሉ ወደ በጎነት የተሳሰረ',
    'keywordEn': 'called according to His purpose',
    'keywordAm': 'እንደ ዓላማው የተጠሩ',
    'sentenceEn': "Nothing in the groaning escapes God's loving work.",
    'sentenceAm':
        'ከእግዚአብሔር ፍቅራዊ ሥራ የሚያመልጥ አቆስቆስ የለም።',
  },
  'philippians413': {
    'imageEn': 'strength in every circumstance through Christ',
    'imageAm': 'በክርስቶስ በማንኛውም ሁኔታ ኃይል',
    'keywordEn': 'I can do all things through Christ',
    'keywordAm': 'በክርስቶስ ሁሉን እችላለሁ',
    'sentenceEn': 'Contentment is learned; strength is received.',
    'sentenceAm': 'እርካታ የሚማር ነው፤ ኃይል የሚቀበል ነው።',
  },
  'matthew633': {
    'imageEn': "birds and lilies under the Father's care",
    'imageAm': 'በአባት እንክብካቤ ሥር ወፎችና አበቦች',
    'keywordEn': 'seek first the kingdom of God',
    'keywordAm': 'መጀመሪያ የእግዚአብሔርን መንግሥት ፈልጉ',
    'sentenceEn': 'The Father who knows the need also supplies it.',
    'sentenceAm': 'ፍላጎቱን የሚያውቀው አባት ያቀርበዋል።',
  },
  'isaiah4031': {
    'imageEn': 'wings like an eagle on a long road',
    'imageAm': 'በረጅም መንገድ ላይ እንደ ንስር ክንፍ',
    'keywordEn': 'they who wait on the LORD renew strength',
    'keywordAm': 'እግዚአብሔርን የሚጠባበቁ ኃይልን ያድሳሉ',
    'sentenceEn': "Waiting, not ceasing, renews the walker's strength.",
    'sentenceAm': 'መጠባበቅ እንጂ ማቆም የተራመደውን ኃይል ያድሳል።',
  },
  'ephesians28': {
    'imageEn': 'salvation as a gift, not a wage',
    'imageAm': 'ደመወዝ ሳይሆን ስጦታ የሆነ መዳን',
    'keywordEn': 'by grace through faith',
    'keywordAm': 'በጸጋ በእምነት',
    'sentenceEn': 'The gift closes every door on human boasting.',
    'sentenceAm': 'ስጦታው የሰውን መመካት በር ሁሉ ይዘጋል።',
  },
  'corinthians13': {
    'imageEn': 'love shown in patient, kind action',
    'imageAm': 'በታጋሽና ቸር ተግባር የሚታይ ፍቅር',
    'keywordEn': 'love bears, believes, hopes, endures all things',
    'keywordAm':
        'ፍቅር ሁሉን ይታገሣል፣ ያምናል፣ ተስፋ ያደርጋል፣ ይጸናል',
    'sentenceEn': 'Love is measured by what it keeps giving.',
    'sentenceAm': 'ፍቅር በመስጠት በሚቀጥለው ይለካል።',
  },
};

const List<String> _canonicalKinds = [
  'passageOverview',
  'historicalBackground',
  'literaryContext',
  'verseByVerse',
  'originalLanguage',
  'scriptureInterconnections',
  'explicitTeachings',
  'questionsToCarry',
];

List<Map<String, dynamic>> _sectionsFor(Map<String, dynamic> entry) {
  final legacy = <String, Map<String, dynamic>>{};
  for (final s in entry['sections'] as List) {
    legacy[s['kind'] as String] = s as Map<String, dynamic>;
  }

  final setting = legacy['setting']!;
  final context = legacy['context']!;
  final whatTextSays = legacy['whatTextSays']!;
  final meaning = legacy['meaningBackground']!;
  final connections = legacy['biblicalConnections']!;
  final understood = legacy['whatCanBeUnderstood']!;
  final reflection = legacy['reflection']!;

  final observations = _buildObservations(
    entry['id'] as String,
    whatTextSays['en'] as String,
    whatTextSays['am'] as String,
    entry['startVerse'] as int,
    entry['endVerse'] as int,
  );

  return [
    _prose('passageOverview', setting),
    _prose('historicalBackground', context),
    {
      'kind': 'literaryContext',
      'en': context['enSub'] as String,
      'am': context['amSub'] as String,
      'sourceIds': context['sourceIds'],
    },
    {
      'kind': 'verseByVerse',
      'verseObservations': observations,
      'sourceIds': whatTextSays['sourceIds'],
    },
    _prose('originalLanguage', meaning),
    {
      'kind': 'scriptureInterconnections',
      'references': connections['references'],
      'sourceIds': connections['sourceIds'],
    },
    {
      'kind': 'explicitTeachings',
      'blocks': understood['blocks'],
      'sourceIds': understood['sourceIds'],
    },
    {
      'kind': 'questionsToCarry',
      'en': reflection['en'],
      'am': reflection['am'],
      'enSub': reflection['takeawayEn'],
      'amSub': reflection['takeawayAm'],
      'sourceIds': reflection['sourceIds'],
    },
  ];
}

Map<String, dynamic> _prose(String kind, Map<String, dynamic> legacy) {
  return {
    'kind': kind,
    'en': legacy['en'],
    'am': legacy['am'],
    if (legacy['terms'] is List && (legacy['terms'] as List).isNotEmpty)
      'terms': legacy['terms'],
    'sourceIds': legacy['sourceIds'],
  };
}

/// Splits the old whatTextSays prose into verse observations.
///
/// When an entry defines multiple observation ranges, the prose is split at
/// sentence boundaries (English periods / Ethiopic full stops) and the tool
/// verifies the English and Amharic sentence counts both match the range count
/// before assigning them — otherwise it refuses to write. When an entry has a
/// single range (including multi-verse passages whose prose is one continuous
/// statement), the whole prose becomes that one observation.
List<Map<String, dynamic>> _buildObservations(
    String id, String en, String am, int startVerse, int endVerse) {
  final ranges = _observationRanges[id]!;

  if (ranges.length == 1) {
    return [
      {
        'startVerse': ranges.single['start'],
        'endVerse': ranges.single['end'],
        'en': en,
        'am': am,
      },
    ];
  }

  final enParts = en.split('. ');
  final amParts = am.split('። ');
  if (enParts.length != ranges.length) {
    throw 'entry $id: expected ${ranges.length} English sentences, found ${enParts.length}';
  }
  if (amParts.length != ranges.length) {
    throw 'entry $id: expected ${ranges.length} Amharic sentences, found ${amParts.length}';
  }

  final observations = <Map<String, Object>>[];
  for (var i = 0; i < ranges.length; i++) {
    final isLast = i == ranges.length - 1;
    final enText = isLast ? enParts[i] : '${enParts[i]}. ';
    final amText = isLast ? amParts[i] : '${amParts[i]}። ';
    observations.add({
      'startVerse': ranges[i]['start']!,
      'endVerse': ranges[i]['end']!,
      'en': enText,
      'am': amText,
    });
  }

  // Reconstruct check: each part already carries its trailing delimiter ('. '
  // / '። '), so concatenating them must reproduce the original prose exactly.
  final enRejoined = observations.map((r) => r['en'] as String).join();
  final amRejoined = observations.map((r) => r['am'] as String).join();
  if (enRejoined != en) {
    throw 'entry $id: English prose changed during the split';
  }
  if (amRejoined != am) {
    throw 'entry $id: Amharic prose changed during the split';
  }

  return observations.map((r) => Map<String, dynamic>.from(r)).toList();
}

void main(List<String> args) {
  const path = 'assets/data/study.json';
  final source = File(path).readAsStringSync();
  final data = jsonDecode(source) as Map<String, dynamic>;
  if (data['version'] != 2) {
    stdout.writeln('expected version 2, found ${data['version']} — aborting');
    exit(1);
  }

  final entries = <Map<String, dynamic>>[];
  for (final e in data['entries'] as List) {
    final entry = (e as Map<String, dynamic>).cast<String, dynamic>();
    final id = entry['id'] as String;
    final sections = _sectionsFor(entry);
    final kinds = sections.map((s) => s['kind'] as String).toList();
    if (kinds.join(',') != _canonicalKinds.join(',')) {
      throw 'entry $id: section order mismatch (${kinds.join(',')})';
    }
    entries.add({
      'id': id,
      'bookId': entry['bookId'],
      'chapter': entry['chapter'],
      'startVerse': entry['startVerse'],
      'endVerse': entry['endVerse'],
      'sections': sections,
      'anchor': _anchors[id]!,
    });
  }

  final migrated = <String, dynamic>{
    'version': 3,
    'entries': entries,
  };

  final encoder = const JsonEncoder.withIndent('  ');
  File(path).writeAsStringSync('${encoder.convert(migrated)}\n');
  stdout.writeln('migrated ${entries.length} entries to version 3');
}