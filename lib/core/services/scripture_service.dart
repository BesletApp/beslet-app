class Scripture {
  final String reference;
  final String text;
  final String? textAm;
  const Scripture({required this.reference, required this.text, this.textAm});
}

class BibleSection {
  final String id;
  final String nameEn;
  final String nameAm;
  final List<BibleBook> books;
  const BibleSection({required this.id, required this.nameEn, required this.nameAm, required this.books});
}

class BibleBook {
  final String id;
  final String nameEn;
  final String nameAm;
  final int chapters;
  final String sectionId;
  final String themeEn;
  final String themeAm;
  const BibleBook({
    required this.id, required this.nameEn, required this.nameAm,
    required this.chapters, required this.sectionId,
    required this.themeEn, required this.themeAm,
  });
}

class BiblePlanEntry {
  final int day;
  final String reference;
  const BiblePlanEntry({required this.day, required this.reference});
}

class ScriptureService {
  static const List<BibleSection> sections = [
    BibleSection(id: 'torah', nameEn: 'Torah (Law)', nameAm: 'ኦሪት', books: [
      BibleBook(id: 'genesis', nameEn: 'Genesis', nameAm: 'ዘፍጥረት', chapters: 50, sectionId: 'torah', themeEn: 'Beginnings — creation, fall, covenant', themeAm: 'መጀመሪያ — ፍጥረት፣ ውድቀት፣ ቃል ኪዳን'),
      BibleBook(id: 'exodus', nameEn: 'Exodus', nameAm: 'ዘጸአት', chapters: 40, sectionId: 'torah', themeEn: 'Deliverance — God rescues His people', themeAm: 'መዳን — እግዚአብሔር ሕዝቡን ያድናል'),
      BibleBook(id: 'leviticus', nameEn: 'Leviticus', nameAm: 'ዘሌዋውያን', chapters: 27, sectionId: 'torah', themeEn: 'Holiness — how to approach God', themeAm: 'ቅድስና — ወደ እግዚአብሔር መቅረብ'),
      BibleBook(id: 'numbers', nameEn: 'Numbers', nameAm: 'ዘኁልቁ', chapters: 36, sectionId: 'torah', themeEn: 'Wilderness — testing and provision', themeAm: 'ምድረ በዳ — ፈተና እና አቅርቦት'),
      BibleBook(id: 'deuteronomy', nameEn: 'Deuteronomy', nameAm: 'ዘዳግም', chapters: 34, sectionId: 'torah', themeEn: 'Reminder — covenant renewed before entering', themeAm: 'ማስታወሻ — ከመግባት በፊት ቃል ኪዳን መታደስ'),
    ]),
    BibleSection(id: 'history', nameEn: 'History', nameAm: 'ታሪክ', books: [
      BibleBook(id: 'joshua', nameEn: 'Joshua', nameAm: 'ኢያሱ', chapters: 24, sectionId: 'history', themeEn: 'Conquest — possessing the promise', themeAm: 'ድል — ተስፋውን መውረስ'),
      BibleBook(id: 'judges', nameEn: 'Judges', nameAm: 'መሳፍንት', chapters: 21, sectionId: 'history', themeEn: 'Cycles — sin, cry, deliverance', themeAm: 'ዑደቶች — ኃጢአት፣ ጩኸት፣ መዳን'),
      BibleBook(id: 'ruth', nameEn: 'Ruth', nameAm: 'ሩት', chapters: 4, sectionId: 'history', themeEn: 'Redemption — loyalty and lineage', themeAm: 'ቤዛነት — ታማኝነት እና የትውልድ መስመር'),
      BibleBook(id: '1samuel', nameEn: '1 Samuel', nameAm: '1 ሳሙኤል', chapters: 31, sectionId: 'history', themeEn: 'Transition — judges to kings', themeAm: 'ሽግግር — ከመሳፍንት ወደ ነገሥታት'),
      BibleBook(id: '2samuel', nameEn: '2 Samuel', nameAm: '2 ሳሙኤል', chapters: 24, sectionId: 'history', themeEn: 'David\'s reign — triumph and failure', themeAm: 'የዳዊት መንግሥት — ድል እና ውድቀት'),
      BibleBook(id: '1kings', nameEn: '1 Kings', nameAm: '1 ነገሥት', chapters: 22, sectionId: 'history', themeEn: 'Kingdom divided — Solomon to exile', themeAm: 'መንግሥት መከፋፈል — ከሰሎሞን እስከ ምርኮ'),
      BibleBook(id: '2kings', nameEn: '2 Kings', nameAm: '2 ነገሥት', chapters: 25, sectionId: 'history', themeEn: 'Fall — prophets warn, exile comes', themeAm: 'ውድቀት — ነቢያት ያስጠነቅቃሉ፣ ምርኮ ይመጣል'),
      BibleBook(id: '1chronicles', nameEn: '1 Chronicles', nameAm: '1 ዜና መዋዕል', chapters: 29, sectionId: 'history', themeEn: 'David\'s legacy — worship and order', themeAm: 'የዳዊት ቅርስ — አምልኮ እና ሥርዓት'),
      BibleBook(id: '2chronicles', nameEn: '2 Chronicles', nameAm: '2 ዜና መዋዕል', chapters: 36, sectionId: 'history', themeEn: 'Temple — revival and ruin', themeAm: 'ቤተ መቅደስ — መነቃቃት እና ውድመት'),
      BibleBook(id: 'ezra', nameEn: 'Ezra', nameAm: 'ዕዝራ', chapters: 10, sectionId: 'history', themeEn: 'Return — rebuilding the temple', themeAm: 'መመለስ — ቤተ መቅደስን መገንባት'),
      BibleBook(id: 'nehemiah', nameEn: 'Nehemiah', nameAm: 'ነህምያ', chapters: 13, sectionId: 'history', themeEn: 'Rebuild — walls and community restored', themeAm: 'መገንባት — ቅጥር እና ማህበረሰብ መታደስ'),
      BibleBook(id: 'esther', nameEn: 'Esther', nameAm: 'አስቴር', chapters: 10, sectionId: 'history', themeEn: 'Providence — God works behind the scenes', themeAm: 'አመራር — እግዚአብሔር በስውር ይሠራል'),
    ]),
    BibleSection(id: 'poetry', nameEn: 'Poetry & Wisdom', nameAm: 'ግጥም እና ጥበብ', books: [
      BibleBook(id: 'job', nameEn: 'Job', nameAm: 'ኢዮብ', chapters: 42, sectionId: 'poetry', themeEn: 'Suffering — faith through loss', themeAm: 'መከራ — በማጣት ውስጥ እምነት'),
      BibleBook(id: 'psalms', nameEn: 'Psalms', nameAm: 'መዝሙረ ዳዊት', chapters: 150, sectionId: 'poetry', themeEn: 'Worship — the soul\'s song to God', themeAm: 'አምልኮ — የነፍስ ዝማሬ ለእግዚአብሔር'),
      BibleBook(id: 'proverbs', nameEn: 'Proverbs', nameAm: 'ምሳሌ', chapters: 31, sectionId: 'poetry', themeEn: 'Wisdom — practical fear of the Lord', themeAm: 'ጥበብ — እግዚአብሔርን መፍራት በተግባር'),
      BibleBook(id: 'ecclesiastes', nameEn: 'Ecclesiastes', nameAm: 'መክብብ', chapters: 12, sectionId: 'poetry', themeEn: 'Vanity — meaning found in God alone', themeAm: 'ከንቱነት — ትርጉም በእግዚአብሔር ብቻ'),
      BibleBook(id: 'songofsongs', nameEn: 'Song of Songs', nameAm: 'መኃልየ መኃልይ', chapters: 8, sectionId: 'poetry', themeEn: 'Love — the beauty of covenant intimacy', themeAm: 'ፍቅር — የቃል ኪዳን ቅርበት ውበት'),
    ]),
    BibleSection(id: 'majorProphets', nameEn: 'Major Prophets', nameAm: 'ታላላቅ ነቢያት', books: [
      BibleBook(id: 'isaiah', nameEn: 'Isaiah', nameAm: 'ኢሳይያስ', chapters: 66, sectionId: 'majorProphets', themeEn: 'Salvation — judgment and coming Messiah', themeAm: 'መዳን — ፍርድ እና የሚመጣው መሲህ'),
      BibleBook(id: 'jeremiah', nameEn: 'Jeremiah', nameAm: 'ኤርምያስ', chapters: 52, sectionId: 'majorProphets', themeEn: 'Weeping — judgment and new covenant', themeAm: 'ልቅሶ — ፍርድ እና አዲስ ቃል ኪዳን'),
      BibleBook(id: 'lamentations', nameEn: 'Lamentations', nameAm: 'ልቅሶ', chapters: 5, sectionId: 'majorProphets', themeEn: 'Grief — mercy in the midst of ruin', themeAm: 'ሐዘን — በውድመት መካከል ምሕረት'),
      BibleBook(id: 'ezekiel', nameEn: 'Ezekiel', nameAm: 'ሕዝቅኤል', chapters: 48, sectionId: 'majorProphets', themeEn: 'Visions — God\'s glory and restoration', themeAm: 'ራእዮች — የእግዚአብሔር ክብር እና መልሶ ማቋቋም'),
      BibleBook(id: 'daniel', nameEn: 'Daniel', nameAm: 'ዳንኤል', chapters: 12, sectionId: 'majorProphets', themeEn: 'Sovereignty — God rules over kingdoms', themeAm: 'ሉዓላዊነት — እግዚአብሔር በመንግሥታት ላይ ይገዛል'),
    ]),
    BibleSection(id: 'minorProphets', nameEn: 'Minor Prophets', nameAm: 'ታናናሽ ነቢያት', books: [
      BibleBook(id: 'hosea', nameEn: 'Hosea', nameAm: 'ሆሴዕ', chapters: 14, sectionId: 'minorProphets', themeEn: 'Love — God\'s faithful love to unfaithful people', themeAm: 'ፍቅር — የእግዚአብሔር ታማኝ ፍቅር'),
      BibleBook(id: 'joel', nameEn: 'Joel', nameAm: 'ዮኤል', chapters: 3, sectionId: 'minorProphets', themeEn: 'Day of the Lord — repentance brings revival', themeAm: 'የጌታ ቀን — ንስሐ መነቃቃትን ያመጣል'),
      BibleBook(id: 'amos', nameEn: 'Amos', nameAm: 'አሞጽ', chapters: 9, sectionId: 'minorProphets', themeEn: 'Justice — religion without justice is empty', themeAm: 'ፍትህ — ያለ ፍትህ ሃይማኖት ባዶ ነው'),
      BibleBook(id: 'obadiah', nameEn: 'Obadiah', nameAm: 'አብድዩ', chapters: 1, sectionId: 'minorProphets', themeEn: 'Pride — humbled by God', themeAm: 'ትዕቢት — በእግዚአብሔር የተዋረደ'),
      BibleBook(id: 'jonah', nameEn: 'Jonah', nameAm: 'ዮናስ', chapters: 4, sectionId: 'minorProphets', themeEn: 'Mercy — God\'s compassion beyond borders', themeAm: 'ምሕረት — የእግዚአብሔር ርኅራኄ ከወሰን በላይ'),
      BibleBook(id: 'micah', nameEn: 'Micah', nameAm: 'ሚክያስ', chapters: 7, sectionId: 'minorProphets', themeEn: 'Humble — walk justly, love mercy', themeAm: 'ትሑት — በፍትህ ሂዱ፣ ምሕረትን ውደዱ'),
      BibleBook(id: 'nahum', nameEn: 'Nahum', nameAm: 'ናሆም', chapters: 3, sectionId: 'minorProphets', themeEn: 'Justice — God\'s judgment on evil', themeAm: 'ፍትህ — የእግዚአብሔር ፍርድ በክፉ ላይ'),
      BibleBook(id: 'habakkuk', nameEn: 'Habakkuk', nameAm: 'ዕንባቆም', chapters: 3, sectionId: 'minorProphets', themeEn: 'Faith — trusting God in suffering', themeAm: 'እምነት — በመከራ ውስጥ እግዚአብሔርን ማመን'),
      BibleBook(id: 'zephaniah', nameEn: 'Zephaniah', nameAm: 'ሶፎንያስ', chapters: 3, sectionId: 'minorProphets', themeEn: 'Judgment — the day of the Lord', themeAm: 'ፍርድ — የጌታ ቀን'),
      BibleBook(id: 'haggai', nameEn: 'Haggai', nameAm: 'ሐጌ', chapters: 2, sectionId: 'minorProphets', themeEn: 'Priorities — rebuild God\'s house first', themeAm: 'ቅድሚያ — የእግዚአብሔርን ቤት ቀድሞ ገንቡ'),
      BibleBook(id: 'zechariah', nameEn: 'Zechariah', nameAm: 'ዘካርያስ', chapters: 14, sectionId: 'minorProphets', themeEn: 'Hope — the coming King', themeAm: 'ተስፋ — የሚመጣው ንጉሥ'),
      BibleBook(id: 'malachi', nameEn: 'Malachi', nameAm: 'ሚልክያስ', chapters: 4, sectionId: 'minorProphets', themeEn: 'Faithfulness — God remembers His own', themeAm: 'ታማኝነት — እግዚአብሔር የራሱን ያስታውሳል'),
    ]),
    BibleSection(id: 'gospels', nameEn: 'Gospels', nameAm: 'ወንጌላት', books: [
      BibleBook(id: 'matthew', nameEn: 'Matthew', nameAm: 'ማቴዎስ', chapters: 28, sectionId: 'gospels', themeEn: 'King — Jesus is the promised Messiah', themeAm: 'ንጉሥ — ኢየሱስ የተስፋው መሲህ ነው'),
      BibleBook(id: 'mark', nameEn: 'Mark', nameAm: 'ማርቆስ', chapters: 16, sectionId: 'gospels', themeEn: 'Servant — Jesus acts with power', themeAm: 'አገልጋይ — ኢየሱስ በኃይል ይሠራል'),
      BibleBook(id: 'luke', nameEn: 'Luke', nameAm: 'ሉቃስ', chapters: 24, sectionId: 'gospels', themeEn: 'Savior — Jesus came for all people', themeAm: 'አዳኝ — ኢየሱስ ለሁሉም ሰዎች መጣ'),
      BibleBook(id: 'john', nameEn: 'John', nameAm: 'ዮሐንስ', chapters: 21, sectionId: 'gospels', themeEn: 'Son of God — believe and have life', themeAm: 'የእግዚአብሔር ልጅ — እመን ሕይወትን አግኝ'),
    ]),
    BibleSection(id: 'acts', nameEn: 'Acts & History', nameAm: 'የሐዋርያት ሥራ', books: [
      BibleBook(id: 'acts', nameEn: 'Acts', nameAm: 'የሐዋርያት ሥራ', chapters: 28, sectionId: 'acts', themeEn: 'Spirit — the church is launched', themeAm: 'መንፈስ — ቤተክርስቲያን ተጀመረች'),
    ]),
    BibleSection(id: 'paulsLetters', nameEn: 'Paul\'s Letters', nameAm: 'የጳውሎስ መልእክታት', books: [
      BibleBook(id: 'romans', nameEn: 'Romans', nameAm: 'ሮሜ', chapters: 16, sectionId: 'paulsLetters', themeEn: 'Gospel — righteousness through faith', themeAm: 'ወንጌል — በእምነት ጽድቅ'),
      BibleBook(id: '1corinthians', nameEn: '1 Corinthians', nameAm: '1 ቆሮንቶስ', chapters: 16, sectionId: 'paulsLetters', themeEn: 'Church — unity and love in Christ', themeAm: 'ቤተክርስቲያን — አንድነት እና ፍቅር'),
      BibleBook(id: '2corinthians', nameEn: '2 Corinthians', nameAm: '2 ቆሮንቶስ', chapters: 13, sectionId: 'paulsLetters', themeEn: 'Ministry — strength in weakness', themeAm: 'አገልግሎት — በደካማነት ጉልበት'),
      BibleBook(id: 'galatians', nameEn: 'Galatians', nameAm: 'ገላትያ', chapters: 6, sectionId: 'paulsLetters', themeEn: 'Freedom — grace not law', themeAm: 'ነፃነት — ጸጋ እንጂ ሕግ አይደለም'),
      BibleBook(id: 'ephesians', nameEn: 'Ephesians', nameAm: 'ኤፌሶን', chapters: 6, sectionId: 'paulsLetters', themeEn: 'Identity — seated with Christ', themeAm: 'ማንነት — ከክርስቶስ ጋር ተቀምጠዋል'),
      BibleBook(id: 'philippians', nameEn: 'Philippians', nameAm: 'ፊልጵስዩስ', chapters: 4, sectionId: 'paulsLetters', themeEn: 'Joy — contentment in every circumstance', themeAm: 'ደስታ — በሁሉም ሁኔታ ውስጥ እርካታ'),
      BibleBook(id: 'colossians', nameEn: 'Colossians', nameAm: 'ቆላስይስ', chapters: 4, sectionId: 'paulsLetters', themeEn: 'Supremacy — Christ above all', themeAm: 'ልዕልና — ክርስቶስ ከሁሉ በላይ'),
      BibleBook(id: '1thessalonians', nameEn: '1 Thessalonians', nameAm: '1 ተሰሎንቄ', chapters: 5, sectionId: 'paulsLetters', themeEn: 'Hope — live in light of His return', themeAm: 'ተስፋ — በመመለሱ ብርሃን ኑሩ'),
      BibleBook(id: '2thessalonians', nameEn: '2 Thessalonians', nameAm: '2 ተሰሎንቄ', chapters: 3, sectionId: 'paulsLetters', themeEn: 'Endurance — stand firm until He comes', themeAm: 'ጽናት — እስከሚመለስ ድረስ ጽኑ'),
      BibleBook(id: '1timothy', nameEn: '1 Timothy', nameAm: '1 ጢሞቴዎስ', chapters: 6, sectionId: 'paulsLetters', themeEn: 'Leadership — shepherding God\'s people', themeAm: 'አመራር — የእግዚአብሔርን ሕዝብ መጠበቅ'),
      BibleBook(id: '2timothy', nameEn: '2 Timothy', nameAm: '2 ጢሞቴዎስ', chapters: 4, sectionId: 'paulsLetters', themeEn: 'Legacy — pass on the gospel', themeAm: 'ቅርስ — ወንጌልን አስተላልፉ'),
      BibleBook(id: 'titus', nameEn: 'Titus', nameAm: 'ቲቶ', chapters: 3, sectionId: 'paulsLetters', themeEn: 'Order — sound doctrine, good deeds', themeAm: 'ሥርዓት — ትክክለኛ ትምህርት፣ መልካም ሥራ'),
      BibleBook(id: 'philemon', nameEn: 'Philemon', nameAm: 'ፊልሞና', chapters: 1, sectionId: 'paulsLetters', themeEn: 'Reconciliation — restore broken relationships', themeAm: 'እርቅ — የተሰበሩ ግንኙነቶችን መመለስ'),
    ]),
    BibleSection(id: 'generalEpistles', nameEn: 'General Epistles', nameAm: 'አጠቃላይ መልእክታት', books: [
      BibleBook(id: 'hebrews', nameEn: 'Hebrews', nameAm: 'ዕብራውያን', chapters: 13, sectionId: 'generalEpistles', themeEn: 'Greater — Christ is superior, hold fast', themeAm: 'ይልቅ — ክርስቶስ ይበልጣል፣ ጽኑ'),
      BibleBook(id: 'james', nameEn: 'James', nameAm: 'ያዕቆብ', chapters: 5, sectionId: 'generalEpistles', themeEn: 'Action — faith that works', themeAm: 'ተግባር — የሚሠራ እምነት'),
      BibleBook(id: '1peter', nameEn: '1 Peter', nameAm: '1 ጴጥሮስ', chapters: 5, sectionId: 'generalEpistles', themeEn: 'Hope — suffering for the believer', themeAm: 'ተስፋ — ለምእመን መከራ'),
      BibleBook(id: '2peter', nameEn: '2 Peter', nameAm: '2 ጴጥሮስ', chapters: 3, sectionId: 'generalEpistles', themeEn: 'Growth — add to your faith', themeAm: 'እድገት — በእምነትህ ላይ ጨምር'),
      BibleBook(id: '1john', nameEn: '1 John', nameAm: '1 ዮሐንስ', chapters: 5, sectionId: 'generalEpistles', themeEn: 'Love — walk in the light', themeAm: 'ፍቅር — በብርሃን ሂዱ'),
      BibleBook(id: '2john', nameEn: '2 John', nameAm: '2 ዮሐንስ', chapters: 1, sectionId: 'generalEpistles', themeEn: 'Truth — guard the doctrine of Christ', themeAm: 'እውነት — የክርስቶስን ትምህርት ጠብቁ'),
      BibleBook(id: '3john', nameEn: '3 John', nameAm: '3 ዮሐንስ', chapters: 1, sectionId: 'generalEpistles', themeEn: 'Hospitality — support fellow workers', themeAm: 'እንግዳ መቀበል — የሥራ ባልንጀሮችን ደግፉ'),
      BibleBook(id: 'jude', nameEn: 'Jude', nameAm: 'ይሁዳ', chapters: 1, sectionId: 'generalEpistles', themeEn: 'Contend — fight for the faith', themeAm: 'ታገሉ — ለእምነት ተጋደሉ'),
    ]),
    BibleSection(id: 'revelation', nameEn: 'Revelation', nameAm: 'ራእይ', books: [
      BibleBook(id: 'revelation', nameEn: 'Revelation', nameAm: 'ራእይ', chapters: 22, sectionId: 'revelation', themeEn: 'Victory — Jesus wins, all made new', themeAm: 'ድል — ኢየሱስ ያሸንፋል፣ ሁሉም ይታደሳል'),
    ]),
  ];

  static List<BibleBook> get allBooks => sections.expand((s) => s.books).toList();
  static Map<String, BibleBook> get bookMap => {for (final b in allBooks) b.id: b};

  static List<BibleBook> get otBooks => sections.where((s) => ['torah', 'history', 'poetry', 'majorProphets', 'minorProphets'].contains(s.id)).expand((s) => s.books).toList();
  static List<BibleBook> get ntBooks => sections.where((s) => ['gospels', 'acts', 'paulsLetters', 'generalEpistles', 'revelation'].contains(s.id)).expand((s) => s.books).toList();

  /// Generates a reading plan for a given testament. Each entry is "Book Chapter:StartVerse" or "Book Chapter".
  static List<BiblePlanEntry> getPlan(String planId, {int days = 90}) {
    final books = planId == 'ot' ? otBooks : ntBooks;
    final totalChapters = books.fold<int>(0, (int s, b) => s + b.chapters);
    final entries = <BiblePlanEntry>[];
    int chapterIdx = 0;
    for (int day = 0; day < days && chapterIdx < totalChapters; day++) {
      final book = _bookForChapter(books, chapterIdx);
      if (book == null) break;
      final chInBook = chapterIdx - books.takeWhile((b) => b.id != book.id).fold<int>(0, (int s, b) => s + b.chapters) + 1;
      entries.add(BiblePlanEntry(day: day + 1, reference: '${book.nameEn} $chInBook'));
      chapterIdx++;
    }
    return entries;
  }

  static BibleBook? _bookForChapter(List<BibleBook> books, int globalChapter) {
    int acc = 0;
    for (final b in books) {
      acc += b.chapters;
      if (globalChapter < acc) return b;
    }
    return null;
  }

  static final List<Scripture> verses = [
    Scripture(reference: 'Philippians 4:13', text: 'I can do all things through Christ who strengthens me.', textAm: 'ኃይልን በሚሰጠኝ በክርስቶስ ሁሉን እችላለሁ።'),
    Scripture(reference: 'Psalm 23:1', text: 'The Lord is my shepherd; I shall not want.', textAm: 'እግዚአብሔር እረኛዬ ነው፥ የሚያሳጣኝ የለም።'),
    Scripture(reference: 'Jeremiah 29:11', text: 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you.'),
    Scripture(reference: 'Proverbs 3:5-6', text: 'Trust in the Lord with all your heart and lean not on your own understanding.'),
    Scripture(reference: 'Romans 8:28', text: 'All things work together for good to those who love God.'),
    Scripture(reference: 'Isaiah 40:31', text: 'Those who hope in the Lord will renew their strength. They will soar on wings like eagles.'),
    Scripture(reference: 'Matthew 6:33', text: 'But seek first His kingdom and His righteousness, and all these things will be added to you.'),
    Scripture(reference: 'Joshua 1:9', text: 'Be strong and courageous. Do not be afraid; the Lord your God will be with you wherever you go.'),
    Scripture(reference: '2 Timothy 1:7', text: 'For God has not given us a spirit of fear, but of power, love, and a sound mind.'),
    Scripture(reference: 'John 3:16', text: 'For God so loved the world that He gave His one and only Son.'),
    Scripture(reference: 'Psalm 46:10', text: 'Be still, and know that I am God.'),
    Scripture(reference: '1 Corinthians 13:4', text: 'Love is patient, love is kind. It does not envy, it does not boast.'),
    Scripture(reference: 'Galatians 5:22-23', text: 'The fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness.'),
    Scripture(reference: 'Ephesians 2:8', text: 'For it is by grace you have been saved, through faith.'),
    Scripture(reference: 'Hebrews 11:1', text: 'Faith is confidence in what we hope for and assurance about what we do not see.'),
    Scripture(reference: 'James 1:2-3', text: 'Consider it pure joy whenever you face trials, because the testing of your faith produces perseverance.'),
    Scripture(reference: '1 Peter 5:7', text: 'Cast all your anxiety on Him because He cares for you.'),
    Scripture(reference: 'Romans 12:2', text: 'Do not conform to the pattern of this world, but be transformed by the renewing of your mind.'),
    Scripture(reference: 'Psalm 119:105', text: 'Your word is a lamp for my feet, a light on my path.'),
    Scripture(reference: 'Matthew 11:28', text: 'Come to me, all you who are weary and burdened, and I will give you rest.'),
    Scripture(reference: 'John 14:6', text: 'I am the way and the truth and the life.'),
    Scripture(reference: 'Romans 5:8', text: 'But God demonstrates his own love for us in this: while we were still sinners, Christ died for us.'),
    Scripture(reference: 'Lamentations 3:22-23', text: 'His mercies are new every morning; great is your faithfulness.'),
    Scripture(reference: 'Psalm 34:8', text: 'Taste and see that the Lord is good.'),
    Scripture(reference: 'Isaiah 41:10', text: 'Do not fear, for I am with you; do not be dismayed, for I am your God.'),
    Scripture(reference: 'Colossians 3:23', text: 'Whatever you do, work at it with all your heart, as working for the Lord.'),
    Scripture(reference: '1 Thessalonians 5:16-18', text: 'Rejoice always, pray continually, give thanks in all circumstances.'),
    Scripture(reference: 'Psalm 1:1-2', text: 'Blessed is the one whose delight is in the law of the Lord.'),
    Scripture(reference: 'Micah 6:8', text: 'Act justly, love mercy, and walk humbly with your God.'),
    Scripture(reference: 'Revelation 21:4', text: 'He will wipe every tear from their eyes. There will be no more death or mourning.'),
  ];

  static const List<String> phaseNamesAm = ['ዲሲፕሊን', 'እምነት', 'ታዛዥነት', 'ተፅዕኖ'];
  static const List<String> phaseNamesEn = ['Discipline', 'Faith', 'Obedience', 'Impact'];

  static int getPhase(int day, {int totalDays = 90}) {
    final perPhase = totalDays ~/ 4;
    if (day <= perPhase) return 0;
    if (day <= perPhase * 2) return 1;
    if (day <= perPhase * 3) return 2;
    return 3;
  }

  static String getBookName(String bookId, bool isAm) {
    final book = bookMap[bookId];
    return book != null ? (isAm ? book.nameAm : book.nameEn) : bookId;
  }

  static String getTheme(String reference) {
    for (final section in sections) {
      for (final book in section.books) {
        if (reference.startsWith(book.nameEn)) return book.themeAm;
      }
    }
    return 'እግዚአብሔርን በቃሉ አግኙት';
  }

  static String getThemeEn(String reference) {
    for (final section in sections) {
      for (final book in section.books) {
        if (reference.startsWith(book.nameEn)) return book.themeEn;
      }
    }
    return 'Encounter God through His Word';
  }

  static Scripture getDailyScripture() => verses[DateTime.now().day % verses.length];

  static BiblePlanEntry getTodaysReading(String planId) {
    final plan = getPlan(planId);
    final day = ((DateTime.now().day - 1) % plan.length);
    return plan[day];
  }
}
