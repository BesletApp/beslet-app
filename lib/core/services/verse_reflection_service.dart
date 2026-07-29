import 'dart:math';
import 'scripture_service.dart';

class VerseReflectionService {
  const VerseReflectionService();

  static final _rng = Random();

  static const _en = <String, List<String>>{
    'torah': [
      'These words carry weight.\nThey have for a long time.',
      'Something steady runs through these lines.\nIt\'s still here.',
      'They come from somewhere deep.\nThey still reach.',
    ],
    'history': [
      'This is part of a longer story.\nIt doesn\'t end here.',
      'It happened in a moment.\nBut it didn\'t stay there.',
      'It moves — even now.',
    ],
    'poetry': [
      'These words don\'t rush.\nThey sit as they are.',
      'Not everything here asks to be figured out.\nIt can remain.',
      'The words rest where they are.',
    ],
    'majorProphets': [
      'These words were spoken into something real.\nThat hasn\'t disappeared.',
      'They carry a weight that doesn\'t fade quickly.\nIt\'s still present.',
      'Spoken then.\nStill here now.',
    ],
    'minorProphets': [
      'Few words.\nNot a small weight.',
      'It\'s brief.\nBut it stays.',
    ],
    'gospels': [
      'He is here in these words.\nNothing more is needed.',
      'This moment holds Him.\nIt is enough as it is.',
      'He is here.\nIt is enough.',
    ],
    'acts': [
      'Something began to move.\nIt didn\'t stop there.',
      'This was lived, not planned.\nIt kept going.',
      'A movement. Still moving.',
    ],
    'paulsLetters': [
      'Someone wrote these words from a distance.\nThey still arrive.',
      'It was personal then.\nIt still feels that way.',
      'These words crossed miles and years.\nThey found their way here.',
    ],
    'generalEpistles': [
      'Written to those far from home.\nStill reaching.',
      'They traveled far to reach someone.\nThey traveled through time too.',
    ],
    'revelation': [
      'Not everything here settles quickly.\nIt doesn\'t need to.',
      'Some things are seen in time.\nSome things remain as they are.',
      'Wide enough to hold mystery.\nStill enough to hold hope.',
    ],
  };

  static const _am = <String, List<String>>{
    'torah': [
      'እነዚህ ቃላት ክብደት አላቸው።\nከድሮ ጀምሮ ነው።',
      'በእነዚህ መስመሮች ውስጥ የሚሄድ ነገር አለ።\nአሁንም አለ።',
      'ከጥልቅ ቦታ የመጡ ናቸው።\nአሁንም ይደርሳሉ።',
    ],
    'history': [
      'ይህ የረጅም ታሪክ ክፍል ነው።\nእዚህ አይቆምም።',
      'በአንድ ጊዜ ተከሰተ።\nግን እዚያ አልቀረም።',
      'ይንቀሳቀሳል — አሁንም።',
    ],
    'poetry': [
      'እነዚህ ቃላት አይቸኩሉም።\nእንዳሉ ይቀመጣሉ።',
      'እዚህ ያለው ሁሉ መፍታት አይጠይቅም።\nእንዲሁ ሊቀመጥ ይችላል።',
      'ቃላቱ እንዳሉ ያርፋሉ።',
    ],
    'majorProphets': [
      'እነዚህ ቃላት ወደ እውነተኛ ነገር ተነገሩ።\nያ አልጠፋም።',
      'እነሱ ፈጣን የማይጠፋ ክብደት ይይዛሉ።\nአሁንም አለ።',
      'ያኔ ተነገረ።\nአሁንም እዚህ አለ።',
    ],
    'minorProphets': [
      'ቃላት ጥቂት ናቸው።\nክብደታቸው ግን አይቀንስም።',
      'አጭር ነው።\nግን ይቀመጣል።',
    ],
    'gospels': [
      'እሱ በእነዚህ ቃላት ውስጥ አለ።\nሌላ አያስፈልግም።',
      'ይህ ጊዜ እሱን ይይዛል።\nእንዳለ በቃ።',
      'እሱ እዚህ አለ።\nይህ በቃ።',
    ],
    'acts': [
      'አንድ ነገር መንቀሳቀስ ጀመረ።\nእዚያ አልቆምም።',
      'ይህ ተለማመደ፣ አልታቀደም።\nቀጠለ።',
      'እንቅስቃሴ። አሁንም ይንቀሳቀሳል።',
    ],
    'paulsLetters': [
      'አንድ ሰው ከሩቅ የጻፋቸው ቃላት ናቸው።\nአሁንም ይደርሳሉ።',
      'በዚያን ጊዜ የግል ነበር።\nአሁንም እንዲሁ ይመስላል።',
      'እነዚህ ቃላት ማይሎችንና ዓመታትን ተሻገሩ።\nወደዚህ መጡ።',
    ],
    'generalEpistles': [
      'ከቤት ርቀው ላሉ የተጻፈ።\nአሁንም ያገናኛል።',
      'ሩቅ ለነበሩ ሰዎች ተጻፈ።\nጊዜው አላለፈውም።',
    ],
    'revelation': [
      'እዚህ ያለው ሁሉ በፍጥነት አይረጋም።\nእንዲሁ መሆኑ ይበቃል።',
      'አንዳንድ ነገሮች በጊዜ ይታያሉ።\nአንዳንድ ነገሮች እንዳሉ ይቀመጣሉ።',
      'ምሥጢር ይዟል።\nተስፋም ይዟል።',
    ],
  };

  String forVerse(String bookId, String verseText, bool isAm) {
    final book = ScriptureService.bookMap[bookId];
    final section = book?.sectionId ?? 'poetry';
    final pool = isAm ? _am : _en;
    final variants = pool[section] ?? pool['poetry']!;
    return variants[_rng.nextInt(variants.length)];
  }
}
