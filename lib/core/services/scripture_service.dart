class Scripture {
  final String reference;
  final String text;
  final String? textAm;
  const Scripture({required this.reference, required this.text, this.textAm});
}

/// A single chapter entry in a reading plan.
class PlanChapter {
  final String bookId;
  final int chapter;
  final BibleBook book;
  const PlanChapter({
    required this.bookId,
    required this.chapter,
    required this.book,
  });
}

/// Today's assigned reading from a plan (can span multiple chapters for pace > 1).
class PlanAssignment {
  final String bookId;
  final int startChapter;
  final int endChapter;
  final BibleBook book;
  const PlanAssignment({
    required this.bookId,
    required this.startChapter,
    required this.endChapter,
    required this.book,
  });
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
  final int wordprojectId;
  final String themeEn;
  final String themeAm;
  const BibleBook({
    required this.id, required this.nameEn, required this.nameAm,
    required this.chapters, required this.sectionId,
    required this.wordprojectId,
    required this.themeEn, required this.themeAm,
  });
}

class ScriptureService {
  static const List<BibleSection> sections = [
    BibleSection(id: 'torah', nameEn: 'Torah (Law)', nameAm: 'ኦሪት', books: [
      BibleBook(id: 'genesis', nameEn: 'Genesis', nameAm: 'ዘፍጥረት', chapters: 50, sectionId: 'torah', wordprojectId: 1, themeEn: 'Beginnings — creation, fall, covenant', themeAm: 'መጀመሪያ — ፍጥረት፣ ውድቀት፣ ቃል ኪዳን'),
      BibleBook(id: 'exodus', nameEn: 'Exodus', nameAm: 'ዘጸአት', chapters: 40, sectionId: 'torah', wordprojectId: 2, themeEn: 'Deliverance — God rescues His people', themeAm: 'መዳን — እግዚአብሔር ሕዝቡን ያድናል'),
      BibleBook(id: 'leviticus', nameEn: 'Leviticus', nameAm: 'ዘሌዋውያን', chapters: 27, sectionId: 'torah', wordprojectId: 3, themeEn: 'Holiness — how to approach God', themeAm: 'ቅድስና — ወደ እግዚአብሔር መቅረብ'),
      BibleBook(id: 'numbers', nameEn: 'Numbers', nameAm: 'ዘኁልቁ', chapters: 36, sectionId: 'torah', wordprojectId: 4, themeEn: 'Wilderness — testing and provision', themeAm: 'ምድረ በዳ — ፈተና እና አቅርቦት'),
      BibleBook(id: 'deuteronomy', nameEn: 'Deuteronomy', nameAm: 'ዘዳግም', chapters: 34, sectionId: 'torah', wordprojectId: 5, themeEn: 'Reminder — covenant renewed before entering', themeAm: 'ማስታወሻ — ከመግባት በፊት ቃል ኪዳን መታደስ'),
    ]),
    BibleSection(id: 'history', nameEn: 'History', nameAm: 'ታሪክ', books: [
      BibleBook(id: 'joshua', nameEn: 'Joshua', nameAm: 'ኢያሱ', chapters: 24, sectionId: 'history', wordprojectId: 6, themeEn: 'Conquest — possessing the promise', themeAm: 'ድል — ተስፋውን መውረስ'),
      BibleBook(id: 'judges', nameEn: 'Judges', nameAm: 'መሳፍንት', chapters: 21, sectionId: 'history', wordprojectId: 7, themeEn: 'Cycles — sin, cry, deliverance', themeAm: 'ዑደቶች — ኃጢአት፣ ጩኸት፣ መዳን'),
      BibleBook(id: 'ruth', nameEn: 'Ruth', nameAm: 'ሩት', chapters: 4, sectionId: 'history', wordprojectId: 8, themeEn: 'Redemption — loyalty and lineage', themeAm: 'ቤዛነት — ታማኝነት እና የትውልድ መስመር'),
      BibleBook(id: '1samuel', nameEn: '1 Samuel', nameAm: '1 ሳሙኤል', chapters: 31, sectionId: 'history', wordprojectId: 9, themeEn: 'Transition — judges to kings', themeAm: 'ሽግግር — ከመሳፍንት ወደ ነገሥታት'),
      BibleBook(id: '2samuel', nameEn: '2 Samuel', nameAm: '2 ሳሙኤል', chapters: 24, sectionId: 'history', wordprojectId: 10, themeEn: 'David\'s reign — triumph and failure', themeAm: 'የዳዊት መንግሥት — ድል እና ውድቀት'),
      BibleBook(id: '1kings', nameEn: '1 Kings', nameAm: '1 ነገሥት', chapters: 22, sectionId: 'history', wordprojectId: 11, themeEn: 'Kingdom divided — Solomon to exile', themeAm: 'መንግሥት መከፋፈል — ከሰሎሞን እስከ ምርኮ'),
      BibleBook(id: '2kings', nameEn: '2 Kings', nameAm: '2 ነገሥት', chapters: 25, sectionId: 'history', wordprojectId: 12, themeEn: 'Fall — prophets warn, exile comes', themeAm: 'ውድቀት — ነቢያት ያስጠነቅቃሉ፣ ምርኮ ይመጣል'),
      BibleBook(id: '1chronicles', nameEn: '1 Chronicles', nameAm: '1 ዜና መዋዕል', chapters: 29, sectionId: 'history', wordprojectId: 13, themeEn: 'David\'s legacy — worship and order', themeAm: 'የዳዊት ቅርስ — አምልኮ እና ሥርዓት'),
      BibleBook(id: '2chronicles', nameEn: '2 Chronicles', nameAm: '2 ዜና መዋዕል', chapters: 36, sectionId: 'history', wordprojectId: 14, themeEn: 'Temple — revival and ruin', themeAm: 'ቤተ መቅደስ — መነቃቃት እና ውድመት'),
      BibleBook(id: 'ezra', nameEn: 'Ezra', nameAm: 'ዕዝራ', chapters: 10, sectionId: 'history', wordprojectId: 15, themeEn: 'Return — rebuilding the temple', themeAm: 'መመለስ — ቤተ መቅደስን መገንባት'),
      BibleBook(id: 'nehemiah', nameEn: 'Nehemiah', nameAm: 'ነህምያ', chapters: 13, sectionId: 'history', wordprojectId: 16, themeEn: 'Rebuild — walls and community restored', themeAm: 'መገንባት — ቅጥር እና ማህበረሰብ መታደስ'),
      BibleBook(id: 'esther', nameEn: 'Esther', nameAm: 'አስቴር', chapters: 10, sectionId: 'history', wordprojectId: 17, themeEn: 'Providence — God works behind the scenes', themeAm: 'አመራር — እግዚአብሔር በስውር ይሠራል'),
    ]),
    BibleSection(id: 'poetry', nameEn: 'Poetry & Wisdom', nameAm: 'ግጥም እና ጥበብ', books: [
      BibleBook(id: 'job', nameEn: 'Job', nameAm: 'ኢዮብ', chapters: 42, sectionId: 'poetry', wordprojectId: 18, themeEn: 'Suffering — faith through loss', themeAm: 'መከራ — በማጣት ውስጥ እምነት'),
      BibleBook(id: 'psalms', nameEn: 'Psalms', nameAm: 'መዝሙረ ዳዊት', chapters: 150, sectionId: 'poetry', wordprojectId: 19, themeEn: 'Worship — the soul\'s song to God', themeAm: 'አምልኮ — የነፍስ ዝማሬ ለእግዚአብሔር'),
      BibleBook(id: 'proverbs', nameEn: 'Proverbs', nameAm: 'ምሳሌ', chapters: 31, sectionId: 'poetry', wordprojectId: 20, themeEn: 'Wisdom — practical fear of the Lord', themeAm: 'ጥበብ — እግዚአብሔርን መፍራት በተግባር'),
      BibleBook(id: 'ecclesiastes', nameEn: 'Ecclesiastes', nameAm: 'መክብብ', chapters: 12, sectionId: 'poetry', wordprojectId: 21, themeEn: 'Vanity — meaning found in God alone', themeAm: 'ከንቱነት — ትርጉም በእግዚአብሔር ብቻ'),
      BibleBook(id: 'songofsongs', nameEn: 'Song of Songs', nameAm: 'መኃልየ መኃልይ', chapters: 8, sectionId: 'poetry', wordprojectId: 22, themeEn: 'Love — the beauty of covenant intimacy', themeAm: 'ፍቅር — የቃል ኪዳን ቅርበት ውበት'),
    ]),
    BibleSection(id: 'majorProphets', nameEn: 'Major Prophets', nameAm: 'ታላላቅ ነቢያት', books: [
      BibleBook(id: 'isaiah', nameEn: 'Isaiah', nameAm: 'ኢሳይያስ', chapters: 66, sectionId: 'majorProphets', wordprojectId: 23, themeEn: 'Salvation — judgment and coming Messiah', themeAm: 'መዳን — ፍርድ እና የሚመጣው መሲህ'),
      BibleBook(id: 'jeremiah', nameEn: 'Jeremiah', nameAm: 'ኤርምያስ', chapters: 52, sectionId: 'majorProphets', wordprojectId: 24, themeEn: 'Weeping — judgment and new covenant', themeAm: 'ልቅሶ — ፍርድ እና አዲስ ቃል ኪዳን'),
      BibleBook(id: 'lamentations', nameEn: 'Lamentations', nameAm: 'ልቅሶ', chapters: 5, sectionId: 'majorProphets', wordprojectId: 25, themeEn: 'Grief — mercy in the midst of ruin', themeAm: 'ሐዘን — በውድመት መካከል ምሕረት'),
      BibleBook(id: 'ezekiel', nameEn: 'Ezekiel', nameAm: 'ሕዝቅኤል', chapters: 48, sectionId: 'majorProphets', wordprojectId: 26, themeEn: 'Visions — God\'s glory and restoration', themeAm: 'ራእዮች — የእግዚአብሔር ክብር እና መልሶ ማቋቋም'),
      BibleBook(id: 'daniel', nameEn: 'Daniel', nameAm: 'ዳንኤል', chapters: 12, sectionId: 'majorProphets', wordprojectId: 27, themeEn: 'Sovereignty — God rules over kingdoms', themeAm: 'ሉዓላዊነት — እግዚአብሔር በመንግሥታት ላይ ይገዛል'),
    ]),
    BibleSection(id: 'minorProphets', nameEn: 'Minor Prophets', nameAm: 'ታናናሽ ነቢያት', books: [
      BibleBook(id: 'hosea', nameEn: 'Hosea', nameAm: 'ሆሴዕ', chapters: 14, sectionId: 'minorProphets', wordprojectId: 28, themeEn: 'Love — God\'s faithful love to unfaithful people', themeAm: 'ፍቅር — የእግዚአብሔር ታማኝ ፍቅር'),
      BibleBook(id: 'joel', nameEn: 'Joel', nameAm: 'ዮኤል', chapters: 3, sectionId: 'minorProphets', wordprojectId: 29, themeEn: 'Day of the Lord — repentance brings revival', themeAm: 'የጌታ ቀን — ንስሐ መነቃቃትን ያመጣል'),
      BibleBook(id: 'amos', nameEn: 'Amos', nameAm: 'አሞጽ', chapters: 9, sectionId: 'minorProphets', wordprojectId: 30, themeEn: 'Justice — religion without justice is empty', themeAm: 'ፍትህ — ያለ ፍትህ ሃይማኖት ባዶ ነው'),
      BibleBook(id: 'obadiah', nameEn: 'Obadiah', nameAm: 'አብድዩ', chapters: 1, sectionId: 'minorProphets', wordprojectId: 31, themeEn: 'Pride — humbled by God', themeAm: 'ትዕቢት — በእግዚአብሔር የተዋረደ'),
      BibleBook(id: 'jonah', nameEn: 'Jonah', nameAm: 'ዮናስ', chapters: 4, sectionId: 'minorProphets', wordprojectId: 32, themeEn: 'Mercy — God\'s compassion beyond borders', themeAm: 'ምሕረት — የእግዚአብሔር ርኅራኄ ከወሰን በላይ'),
      BibleBook(id: 'micah', nameEn: 'Micah', nameAm: 'ሚክያስ', chapters: 7, sectionId: 'minorProphets', wordprojectId: 33, themeEn: 'Humble — walk justly, love mercy', themeAm: 'ትሑት — በፍትህ ሂዱ፣ ምሕረትን ውደዱ'),
      BibleBook(id: 'nahum', nameEn: 'Nahum', nameAm: 'ናሆም', chapters: 3, sectionId: 'minorProphets', wordprojectId: 34, themeEn: 'Justice — God\'s judgment on evil', themeAm: 'ፍትህ — የእግዚአብሔር ፍርድ በክፉ ላይ'),
      BibleBook(id: 'habakkuk', nameEn: 'Habakkuk', nameAm: 'ዕንባቆም', chapters: 3, sectionId: 'minorProphets', wordprojectId: 35, themeEn: 'Faith — trusting God in suffering', themeAm: 'እምነት — በመከራ ውስጥ እግዚአብሔርን ማመን'),
      BibleBook(id: 'zephaniah', nameEn: 'Zephaniah', nameAm: 'ሶፎንያስ', chapters: 3, sectionId: 'minorProphets', wordprojectId: 36, themeEn: 'Judgment — the day of the Lord', themeAm: 'ፍርድ — የጌታ ቀን'),
      BibleBook(id: 'haggai', nameEn: 'Haggai', nameAm: 'ሐጌ', chapters: 2, sectionId: 'minorProphets', wordprojectId: 37, themeEn: 'Priorities — rebuild God\'s house first', themeAm: 'ቅድሚያ — የእግዚአብሔርን ቤት ቀድሞ ገንቡ'),
      BibleBook(id: 'zechariah', nameEn: 'Zechariah', nameAm: 'ዘካርያስ', chapters: 14, sectionId: 'minorProphets', wordprojectId: 38, themeEn: 'Hope — the coming King', themeAm: 'ተስፋ — የሚመጣው ንጉሥ'),
      BibleBook(id: 'malachi', nameEn: 'Malachi', nameAm: 'ሚልክያስ', chapters: 4, sectionId: 'minorProphets', wordprojectId: 39, themeEn: 'Faithfulness — God remembers His own', themeAm: 'ታማኝነት — እግዚአብሔር የራሱን ያስታውሳል'),
    ]),
    BibleSection(id: 'gospels', nameEn: 'Gospels', nameAm: 'ወንጌላት', books: [
      BibleBook(id: 'matthew', nameEn: 'Matthew', nameAm: 'ማቴዎስ', chapters: 28, sectionId: 'gospels', wordprojectId: 40, themeEn: 'King — Jesus is the promised Messiah', themeAm: 'ንጉሥ — ኢየሱስ የተስፋው መሲህ ነው'),
      BibleBook(id: 'mark', nameEn: 'Mark', nameAm: 'ማርቆስ', chapters: 16, sectionId: 'gospels', wordprojectId: 41, themeEn: 'Servant — Jesus acts with power', themeAm: 'አገልጋይ — ኢየሱስ በኃይል ይሠራል'),
      BibleBook(id: 'luke', nameEn: 'Luke', nameAm: 'ሉቃስ', chapters: 24, sectionId: 'gospels', wordprojectId: 42, themeEn: 'Savior — Jesus came for all people', themeAm: 'አዳኝ — ኢየሱስ ለሁሉም ሰዎች መጣ'),
      BibleBook(id: 'john', nameEn: 'John', nameAm: 'ዮሐንስ', chapters: 21, sectionId: 'gospels', wordprojectId: 43, themeEn: 'Son of God — believe and have life', themeAm: 'የእግዚአብሔር ልጅ — እመን ሕይወትን አግኝ'),
    ]),
    BibleSection(id: 'acts', nameEn: 'Acts & History', nameAm: 'የሐዋርያት ሥራ', books: [
      BibleBook(id: 'acts', nameEn: 'Acts', nameAm: 'የሐዋርያት ሥራ', chapters: 28, sectionId: 'acts', wordprojectId: 44, themeEn: 'Spirit — the church is launched', themeAm: 'መንፈስ — ቤተክርስቲያን ተጀመረች'),
    ]),
    BibleSection(id: 'paulsLetters', nameEn: 'Paul\'s Letters', nameAm: 'የጳውሎስ መልእክታት', books: [
      BibleBook(id: 'romans', nameEn: 'Romans', nameAm: 'ሮሜ', chapters: 16, sectionId: 'paulsLetters', wordprojectId: 45, themeEn: 'Gospel — righteousness through faith', themeAm: 'ወንጌል — በእምነት ጽድቅ'),
      BibleBook(id: '1corinthians', nameEn: '1 Corinthians', nameAm: '1 ቆሮንቶስ', chapters: 16, sectionId: 'paulsLetters', wordprojectId: 46, themeEn: 'Church — unity and love in Christ', themeAm: 'ቤተክርስቲያን — አንድነት እና ፍቅር'),
      BibleBook(id: '2corinthians', nameEn: '2 Corinthians', nameAm: '2 ቆሮንቶስ', chapters: 13, sectionId: 'paulsLetters', wordprojectId: 47, themeEn: 'Ministry — strength in weakness', themeAm: 'አገልግሎት — በደካማነት ጉልበት'),
      BibleBook(id: 'galatians', nameEn: 'Galatians', nameAm: 'ገላትያ', chapters: 6, sectionId: 'paulsLetters', wordprojectId: 48, themeEn: 'Freedom — grace not law', themeAm: 'ነፃነት — ጸጋ እንጂ ሕግ አይደለም'),
      BibleBook(id: 'ephesians', nameEn: 'Ephesians', nameAm: 'ኤፌሶን', chapters: 6, sectionId: 'paulsLetters', wordprojectId: 49, themeEn: 'Identity — seated with Christ', themeAm: 'ማንነት — ከክርስቶስ ጋር ተቀምጠዋል'),
      BibleBook(id: 'philippians', nameEn: 'Philippians', nameAm: 'ፊልጵስዩስ', chapters: 4, sectionId: 'paulsLetters', wordprojectId: 50, themeEn: 'Joy — contentment in every circumstance', themeAm: 'ደስታ — በሁሉም ሁኔታ ውስጥ እርካታ'),
      BibleBook(id: 'colossians', nameEn: 'Colossians', nameAm: 'ቆላስይስ', chapters: 4, sectionId: 'paulsLetters', wordprojectId: 51, themeEn: 'Supremacy — Christ above all', themeAm: 'ልዕልና — ክርስቶስ ከሁሉ በላይ'),
      BibleBook(id: '1thessalonians', nameEn: '1 Thessalonians', nameAm: '1 ተሰሎንቄ', chapters: 5, sectionId: 'paulsLetters', wordprojectId: 52, themeEn: 'Hope — live in light of His return', themeAm: 'ተስፋ — በመመለሱ ብርሃን ኑሩ'),
      BibleBook(id: '2thessalonians', nameEn: '2 Thessalonians', nameAm: '2 ተሰሎንቄ', chapters: 3, sectionId: 'paulsLetters', wordprojectId: 53, themeEn: 'Endurance — stand firm until He comes', themeAm: 'ጽናት — እስከሚመለስ ድረስ ጽኑ'),
      BibleBook(id: '1timothy', nameEn: '1 Timothy', nameAm: '1 ጢሞቴዎስ', chapters: 6, sectionId: 'paulsLetters', wordprojectId: 54, themeEn: 'Leadership — shepherding God\'s people', themeAm: 'አመራር — የእግዚአብሔርን ሕዝብ መጠበቅ'),
      BibleBook(id: '2timothy', nameEn: '2 Timothy', nameAm: '2 ጢሞቴዎስ', chapters: 4, sectionId: 'paulsLetters', wordprojectId: 55, themeEn: 'Legacy — pass on the gospel', themeAm: 'ቅርስ — ወንጌልን አስተላልፉ'),
      BibleBook(id: 'titus', nameEn: 'Titus', nameAm: 'ቲቶ', chapters: 3, sectionId: 'paulsLetters', wordprojectId: 56, themeEn: 'Order — sound doctrine, good deeds', themeAm: 'ሥርዓት — ትክክለኛ ትምህርት፣ መልካም ሥራ'),
      BibleBook(id: 'philemon', nameEn: 'Philemon', nameAm: 'ፊልሞና', chapters: 1, sectionId: 'paulsLetters', wordprojectId: 57, themeEn: 'Reconciliation — restore broken relationships', themeAm: 'እርቅ — የተሰበሩ ግንኙነቶችን መመለስ'),
    ]),
    BibleSection(id: 'generalEpistles', nameEn: 'General Epistles', nameAm: 'አጠቃላይ መልእክታት', books: [
      BibleBook(id: 'hebrews', nameEn: 'Hebrews', nameAm: 'ዕብራውያን', chapters: 13, sectionId: 'generalEpistles', wordprojectId: 58, themeEn: 'Greater — Christ is superior, hold fast', themeAm: 'ይልቅ — ክርስቶስ ይበልጣል፣ ጽኑ'),
      BibleBook(id: 'james', nameEn: 'James', nameAm: 'ያዕቆብ', chapters: 5, sectionId: 'generalEpistles', wordprojectId: 59, themeEn: 'Action — faith that works', themeAm: 'ተግባር — የሚሠራ እምነት'),
      BibleBook(id: '1peter', nameEn: '1 Peter', nameAm: '1 ጴጥሮስ', chapters: 5, sectionId: 'generalEpistles', wordprojectId: 60, themeEn: 'Hope — suffering for the believer', themeAm: 'ተስፋ — ለምእመን መከራ'),
      BibleBook(id: '2peter', nameEn: '2 Peter', nameAm: '2 ጴጥሮስ', chapters: 3, sectionId: 'generalEpistles', wordprojectId: 61, themeEn: 'Growth — add to your faith', themeAm: 'እድገት — በእምነትህ ላይ ጨምር'),
      BibleBook(id: '1john', nameEn: '1 John', nameAm: '1 ዮሐንስ', chapters: 5, sectionId: 'generalEpistles', wordprojectId: 62, themeEn: 'Love — walk in the light', themeAm: 'ፍቅር — በብርሃን ሂዱ'),
      BibleBook(id: '2john', nameEn: '2 John', nameAm: '2 ዮሐንስ', chapters: 1, sectionId: 'generalEpistles', wordprojectId: 63, themeEn: 'Truth — guard the doctrine of Christ', themeAm: 'እውነት — የክርስቶስን ትምህርት ጠብቁ'),
      BibleBook(id: '3john', nameEn: '3 John', nameAm: '3 ዮሐንስ', chapters: 1, sectionId: 'generalEpistles', wordprojectId: 64, themeEn: 'Hospitality — support fellow workers', themeAm: 'እንግዳ መቀበል — የሥራ ባልንጀሮችን ደግፉ'),
      BibleBook(id: 'jude', nameEn: 'Jude', nameAm: 'ይሁዳ', chapters: 1, sectionId: 'generalEpistles', wordprojectId: 65, themeEn: 'Contend — fight for the faith', themeAm: 'ታገሉ — ለእምነት ተጋደሉ'),
    ]),
    BibleSection(id: 'revelation', nameEn: 'Revelation', nameAm: 'ራእይ', books: [
      BibleBook(id: 'revelation', nameEn: 'Revelation', nameAm: 'ራእይ', chapters: 22, sectionId: 'revelation', wordprojectId: 66, themeEn: 'Victory — Jesus wins, all made new', themeAm: 'ድል — ኢየሱስ ያሸንፋል፣ ሁሉም ይታደሳል'),
    ]),
  ];

  static List<BibleBook> get allBooks => sections.expand((s) => s.books).toList();
  static Map<String, BibleBook> get bookMap => {for (final b in allBooks) b.id: b};

  static List<BibleBook> get otBooks => sections.where((s) => ['torah', 'history', 'poetry', 'majorProphets', 'minorProphets'].contains(s.id)).expand((s) => s.books).toList();
  static List<BibleBook> get ntBooks => sections.where((s) => ['gospels', 'acts', 'paulsLetters', 'generalEpistles', 'revelation'].contains(s.id)).expand((s) => s.books).toList();
  static List<BibleBook> get gospelsBooks => sections.where((s) => s.id == 'gospels').expand((s) => s.books).toList();

  /// The Day's Thread canon: one fixed reference per calendar day, cycling
  /// this finite loop. Only the REFERENCES live here; the wording is resolved
  /// from the bundled Bible at display time (see DailyVerseService), so the
  /// app never shows a second, hand-typed translation.
  static final List<Scripture> verses = [
    Scripture(reference: 'Philippians 4:13', text: ''),
    Scripture(reference: 'Psalm 23:1', text: ''),
    Scripture(reference: 'Jeremiah 29:11', text: ''),
    Scripture(reference: 'Proverbs 3:5-6', text: ''),
    Scripture(reference: 'Romans 8:28', text: ''),
    Scripture(reference: 'Isaiah 40:31', text: ''),
    Scripture(reference: 'Matthew 6:33', text: ''),
    Scripture(reference: 'Joshua 1:9', text: ''),
    Scripture(reference: '2 Timothy 1:7', text: ''),
    Scripture(reference: 'John 3:16', text: ''),
    Scripture(reference: 'Psalm 46:10', text: ''),
    Scripture(reference: '1 Corinthians 13:4', text: ''),
    Scripture(reference: 'Galatians 5:22-23', text: ''),
    Scripture(reference: 'Ephesians 2:8', text: ''),
    Scripture(reference: 'Hebrews 11:1', text: ''),
    Scripture(reference: 'James 1:2-3', text: ''),
    Scripture(reference: '1 Peter 5:7', text: ''),
    Scripture(reference: 'Romans 12:2', text: ''),
    Scripture(reference: 'Psalm 119:105', text: ''),
    Scripture(reference: 'Matthew 11:28', text: ''),
    Scripture(reference: 'John 14:6', text: ''),
    Scripture(reference: 'Romans 5:8', text: ''),
    Scripture(reference: 'Lamentations 3:22-23', text: ''),
    Scripture(reference: 'Psalm 34:8', text: ''),
    Scripture(reference: 'Isaiah 41:10', text: ''),
    Scripture(reference: 'Colossians 3:23', text: ''),
    Scripture(reference: 'Philippians 4:6-7', text: ''),
    Scripture(reference: 'Psalm 1:1-2', text: ''),
    Scripture(reference: 'Micah 6:8', text: ''),
    Scripture(reference: 'Revelation 21:4', text: ''),
  ];

  static const List<String> phaseNamesAm = ['ዲሲፕሊን', 'እምነት', 'ታዛዥነት', 'ተፅዕኖ'];
  static const List<String> phaseNamesEn = ['Discipline', 'Faith', 'Obedience', 'Impact'];

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

  static Scripture getDailyScripture() => threadVerseFor(DateTime.now());

  /// The chapter-of-the-day for the NT plan: a gentle sequential walk through
  /// the New Testament, one chapter per day. Pure math, offline, serverless.
  static ({String bookId, int chapter, BibleBook book})? ntPlanFor(DateTime day) {
    final epoch = DateTime(2025, 6, 1);
    final idx = day.difference(epoch).inDays;
    if (idx < 0) return null;
    final totalChapters = ntBooks.fold<int>(0, (sum, b) => sum + b.chapters);
    var cursor = idx % totalChapters;
    for (final book in ntBooks) {
      if (cursor < book.chapters) {
        return (bookId: book.id, chapter: cursor + 1, book: book);
      }
      cursor -= book.chapters;
    }
    return null;
  }

  /// The Day's Thread: one fixed single verse per calendar day, cycling the
  /// canon-verified list as a finite repeating loop. Pure math, offline,
  /// serverless, untrackable.
  static Scripture threadVerseFor(DateTime day) {
    final epoch = DateTime(2025, 1, 1);
    final idx = day.difference(epoch).inDays % verses.length;
    return verses[idx < 0 ? idx + verses.length : idx];
  }

  static ({String bookId, int chapter})? parseReference(String reference) {
    final book = _matchBook(reference);
    if (book == null) return null;
    final rest = reference.substring(book.nameEn.length).trim();
    final chapter = int.tryParse(rest.split(':').first) ??
        int.tryParse(rest.split('-').first);
    if (chapter == null) return null;
    return (bookId: book.id, chapter: chapter);
  }

  /// Expands a reference like "Proverbs 3:5-6" (or "Psalm 23:1") into its
  /// book, chapter, and every requested verse number. Returns null when the
  /// reference cannot be parsed into a known book.
  static ({String bookId, int chapter, List<int> verses})? referenceRange(
      String reference) {
    final book = _matchBook(reference);
    if (book == null) return null;
    final rest = reference.substring(book.nameEn.length).trim();
    final parts = rest.split(':');
    final chapter = int.tryParse(parts.first);
    if (chapter == null || parts.length < 2) return null;
    final verseParts = parts[1].split('-');
    final start = int.tryParse(verseParts.first);
    final end = int.tryParse(
        verseParts.length > 1 ? verseParts[1] : verseParts.first);
    if (start == null || end == null || end < start) return null;
    return (
      bookId: book.id,
      chapter: chapter,
      verses: [for (var v = start; v <= end; v++) v],
    );
  }

  static String amharicReference(String reference) {
    final book = _matchBook(reference);
    if (book == null) return reference;
    if (book.id == 'psalms' && reference.startsWith('Psalm ')) {
      return reference.replaceFirst('Psalm ', '${book.nameAm} ');
    }
    return reference.replaceFirst(book.nameEn, book.nameAm);
  }

  /// Finds the book a reference names, tolerating the singular "Psalm" form
  /// used by the daily-verse canon for Amharic book naming.
  static BibleBook? _matchBook(String reference) {
    for (final book in allBooks) {
      if (reference.startsWith(book.nameEn)) return book;
      if (book.id == 'psalms' && reference.startsWith('Psalm ')) return book;
    }
    return null;
  }

  static String referenceFor(String bookId, int chapter, int verse, bool isAm) {
    final book = bookMap[bookId];
    final name = book != null ? (isAm ? book.nameAm : book.nameEn) : bookId;
    return '$name $chapter:$verse';
  }

  /// Generate the full ordered chapter list for a reading plan type.
  static List<PlanChapter> generatePlanChapters(String type, String? bookId) {
    List<BibleBook> books;
    switch (type) {
      case 'whole':
        books = allBooks;
        break;
      case 'ot':
        books = otBooks;
        break;
      case 'nt':
        books = ntBooks;
        break;
      case 'gospels':
        books = gospelsBooks;
        break;
      case 'book':
        if (bookId == null) return [];
        final book = bookMap[bookId];
        books = book != null ? [book] : [];
        break;
      default:
        return [];
    }
    return [
      for (final book in books)
        for (var c = 1; c <= book.chapters; c++)
          PlanChapter(bookId: book.id, chapter: c, book: book),
    ];
  }

  /// Get today's assigned reading for a plan at the given day index and pace.
  static PlanAssignment? getTodayAssignment(
    List<PlanChapter> chapters,
    int pace,
    int dayIndex,
  ) {
    if (chapters.isEmpty || pace <= 0) return null;
    final startIdx = dayIndex * pace;
    if (startIdx >= chapters.length) return null;
    final endIdx = (startIdx + pace - 1).clamp(0, chapters.length - 1);
    final first = chapters[startIdx];
    final last = chapters[endIdx];
    return PlanAssignment(
      bookId: first.bookId,
      startChapter: first.chapter,
      endChapter: last.chapter,
      book: first.book,
    );
  }

  /// Total number of days to complete the plan at the given pace.
  static int totalDays(List<PlanChapter> chapters, int pace) {
    if (chapters.isEmpty || pace <= 0) return 0;
    return (chapters.length + pace - 1) ~/ pace;
  }
}
