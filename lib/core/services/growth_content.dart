import 'package:flutter/material.dart';
import 'widget_service.dart';

/// Pure, offline, deterministic logic for the Vineyard (Growth) zone.
/// No database, no state, no side effects — every function is testable and
/// derived purely from the journey's own clock (the user's declared intention
/// and timeframe), never from tracked behavior.

enum JourneyIntention { word, discipline, heart, faithfulness, service, abide }

enum JourneyTimeframe { week, fortnight, month, season, open }

enum JourneyMovement { planting, rooting, growing, fruiting }

enum VineStage { seed, sprout, rooted, blooming, fruiting }

enum VineParticle { clear, dust, fireflies, rain }

typedef Localized = ({String en, String am});

class GrowthContent {
  const GrowthContent._();

  // ─── Journey intention ────────────────────────────────────────────────

  static const List<JourneyIntention> intentions = [
    JourneyIntention.word,
    JourneyIntention.discipline,
    JourneyIntention.heart,
    JourneyIntention.faithfulness,
    JourneyIntention.service,
    JourneyIntention.abide,
  ];

  static Localized intentionLabel(JourneyIntention intention) {
    switch (intention) {
      case JourneyIntention.word:
        return (en: 'To know the Word', am: 'ቃሉን ማወቅ');
      case JourneyIntention.discipline:
        return (en: 'To walk in discipline', am: 'በዲሲፕሊን መሄድ');
      case JourneyIntention.heart:
        return (en: 'To tend the heart', am: 'ልብን መጠበቅ');
      case JourneyIntention.faithfulness:
        return (en: 'To abide faithfully', am: 'በታማኝነት መቆየት');
      case JourneyIntention.service:
        return (en: 'To serve others', am: 'ሌሎችን ማገልገል');
      case JourneyIntention.abide:
        return (en: 'Just abide', am: 'መቆየት');
    }
  }

  static Localized intentionCommitment(JourneyIntention intention) {
    switch (intention) {
      case JourneyIntention.word:
        return (en: 'I want to grow in knowing the Word.', am: 'ቃሉን በማወቅ ማደግ እፈልጋለሁ።');
      case JourneyIntention.discipline:
        return (en: 'I want to walk daily in discipline.', am: 'በየቀኑ በዲሲፕሊን መሄድ እፈልጋለሁ።');
      case JourneyIntention.heart:
        return (en: 'I want to tend my heart honestly.', am: 'ልቤን በታማኝነት መጠበቅ እፈልጋለሁ።');
      case JourneyIntention.faithfulness:
        return (en: 'I want to abide faithfully in Christ.', am: 'በክርስቶስ በታማኝነት መቆየት እፈልጋለሁ።');
      case JourneyIntention.service:
        return (en: 'I want to love and serve others.', am: 'ሌሎችን መውደድና ማገልገል እፈልጋለሁ።');
      case JourneyIntention.abide:
        return (en: 'I simply want to stay near to Him.', am: 'በቀላሉ ለእርሱ ቅርብ መሆን እፈልጋለሁ።');
    }
  }

  static const Map<JourneyIntention, List<Localized>> _questionPools = {
    JourneyIntention.word: [
      (en: 'What did the Word show you today?', am: 'ዛሬ ቃሉ ምን አሳየህ?'),
      (en: 'Where do you see Christ in today\'s verse?', am: 'በዛሬው ቁጥር ውስጥ ክርስቶስን የት ታየሃለህ?'),
      (en: 'What will you keep from today\'s Word?', am: 'ከዛሬው ቃል ምንን ትይዛለህ?'),
    ],
    JourneyIntention.discipline: [
      (en: 'What did you practice today?', am: 'ዛሬ ምን ተለማመድክ?'),
      (en: 'Where did you say "no" today?', am: 'ዛሬ በምን ጉዳይ "አይ" አልህ?'),
      (en: 'What did you do on purpose today?', am: 'ዛሬ በዓላማ የሠራኸው ምንድን ነው?'),
    ],
    JourneyIntention.heart: [
      (en: 'How is your heart today?', am: 'ልብህ ዛሬ እንዴት ነው?'),
      (en: 'What is God saying to your heart?', am: 'እግዚአብሔር ለልብህ የሚናገረው ምንድን ነው?'),
      (en: 'What are you carrying? Give it to Him.', am: 'የምትሸከመው ምንድን ነው? ለእርሱ ስጠው።'),
    ],
    JourneyIntention.faithfulness: [
      (en: 'Where did you see God today?', am: 'ዛሬ እግዚአብሔርን የት ታየህ?'),
      (en: 'What are you trusting Him with today?', am: 'ዛሬ የምትታመንበት ምንድን ነው?'),
      (en: 'Where did He meet you today?', am: 'ዛሬ የት አገኘህ?'),
    ],
    JourneyIntention.service: [
      (en: 'Whose life did you touch today?', am: 'ዛሬ የማንን ሕይወት ነካህ?'),
      (en: 'Who did you love today?', am: 'ዛሬ ማንን ወደድክ?'),
      (en: 'What kindness did you offer today?', am: 'ዛሬ ምን ቸርነት አደረግህ?'),
    ],
    JourneyIntention.abide: [
      (en: 'What is the day\'s Word speaking to you?', am: 'የዛሬው ቃል የሚናገርህ ምንድን ነው?'),
      (en: 'Where is your heart before God today?', am: 'ልብህ በእግዚአብሔር ፊት ዛሬ የት ነው?'),
      (en: 'What do you need to rest in today?', am: 'ዛሬ በምን ውስጥ ማረፍ ትፈልጋለህ?'),
    ],
  };

  /// One question per day, rotating deterministically through the intention's pool.
  static Localized questionFor(JourneyIntention intention, int day) {
    final pool = _questionPools[intention]!;
    final idx = (day - 1) % pool.length;
    return pool[idx < 0 ? idx + pool.length : idx];
  }

  // ─── Journey timeframe ────────────────────────────────────────────────

  static const List<JourneyTimeframe> timeframes = [
    JourneyTimeframe.week,
    JourneyTimeframe.fortnight,
    JourneyTimeframe.month,
    JourneyTimeframe.season,
    JourneyTimeframe.open,
  ];

  /// Days for a bounded timeframe, or null for the open (ongoing) journey.
  static int? daysFor(JourneyTimeframe timeframe) {
    switch (timeframe) {
      case JourneyTimeframe.week:
        return 7;
      case JourneyTimeframe.fortnight:
        return 14;
      case JourneyTimeframe.month:
        return 30;
      case JourneyTimeframe.season:
        return 90;
      case JourneyTimeframe.open:
        return null;
    }
  }

  static Localized timeframeLabel(JourneyTimeframe timeframe) {
    switch (timeframe) {
      case JourneyTimeframe.week:
        return (en: '7 days', am: '7 ቀን');
      case JourneyTimeframe.fortnight:
        return (en: '14 days', am: '14 ቀን');
      case JourneyTimeframe.month:
        return (en: '30 days', am: '30 ቀን');
      case JourneyTimeframe.season:
        return (en: '90 days — a season', am: '90 ቀን — አንድ ወቅት');
      case JourneyTimeframe.open:
        return (en: 'Open — until I say otherwise', am: 'እስካልልሁ ድረስ');
    }
  }

  /// 1-based journey day, clamped to at least 1.
  static int journeyDay(DateTime start, DateTime now) {
    final diff = now.difference(start).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  /// The journey's current movement, relative to its own timeframe.
  static JourneyMovement movementFor(int day, int? totalDays) {
    if (day < 1) day = 1;
    if (totalDays == null) {
      if (day <= 7) return JourneyMovement.planting;
      if (day <= 30) return JourneyMovement.rooting;
      if (day <= 90) return JourneyMovement.growing;
      return JourneyMovement.fruiting;
    }
    final q = totalDays ~/ 4;
    if (day <= q) return JourneyMovement.planting;
    if (day <= q * 2) return JourneyMovement.rooting;
    if (day <= q * 3) return JourneyMovement.growing;
    return JourneyMovement.fruiting;
  }

  /// Visual stage of the vine. Day 1 is the seed; each movement grows it.
  static VineStage vineStageFor(int day, int? totalDays) {
    if (day <= 1) return VineStage.seed;
    switch (movementFor(day, totalDays)) {
      case JourneyMovement.planting:
        return VineStage.sprout;
      case JourneyMovement.rooting:
        return VineStage.rooted;
      case JourneyMovement.growing:
        return VineStage.blooming;
      case JourneyMovement.fruiting:
        return VineStage.fruiting;
    }
  }

  /// Geometry for the painter: overall growth 0→1 and branch count.
  /// The vine ripens on the journey's own clock (grace), never on behavior.
  static ({double growth01, int branches}) vineGeometry(int day, int? totalDays) {
    final growth = totalDays == null
        ? (day / 150).clamp(0.0, 1.0)
        : (day / totalDays).clamp(0.0, 1.0);
    final branches = day <= 1 ? 0 : (2 + (growth * 6).round()).clamp(2, 8);
    return (growth01: growth, branches: branches);
  }

  // ─── Season story ─────────────────────────────────────────────────────

  static Localized movementTitle(JourneyMovement movement) {
    switch (movement) {
      case JourneyMovement.planting:
        return (en: 'The Planting', am: 'መትከል');
      case JourneyMovement.rooting:
        return (en: 'The Rooting', am: 'ሥር መስደድ');
      case JourneyMovement.growing:
        return (en: 'The Growing', am: 'ማደግ');
      case JourneyMovement.fruiting:
        return (en: 'The Fruiting', am: 'ፍሬ ማፍራት');
    }
  }

  static Localized movementProse(JourneyMovement movement) {
    switch (movement) {
      case JourneyMovement.planting:
        return (
          en: 'Every branch that bears fruit He prunes, that it may bear more. '
              'These are the days of the spade — the soil is turned, the branch is '
              'grafted into the Vine. What feels like pruning is love making room for fruit.',
          am: 'ፍሬ የሚያፈራ ቅርንጫፍ ሁሉ የበለጠ ፍሬ እንዲያፈራ ይቆርጠዋል። እነዚህ የአፈሩ ቀናት ናቸው — አፈሩ ይዘጋጃል፣ ቅርንጫፉ በወይኑ ውስጥ ይተከላል። መቆረጥ የሚመስለው ለፍሬ ቦታ የሚያዘጋጅ ፍቅር ነው።',
        );
      case JourneyMovement.rooting:
        return (
          en: 'Roots go deep in the dark, where no one sees. Add to your faith — '
              'virtue, knowledge, steadfastness. The vine drinks from the Vine; '
              'you drink from the Word.',
          am: 'ሥር በጨለማ ውስጥ ጥልቅ ይደርሳል፥ ማንም በማያይበት። በእምነትህ ላይ ጨምር — በጎነትን፣ እውቀትን፣ ጽናትን። ወይኑ ከወይኑ ይጠጣል፤ አንተ ከቃሉ ትጠጣለህ።',
        );
      case JourneyMovement.growing:
        return (
          en: 'If you love me, you will keep my commandments. The branches are '
              'trained to the trellis — obedience is not restriction; it is the '
              'Vine guiding the branch upward toward light and fruit.',
          am: 'ትወደኛለህ ከሆነ ትእዛዜን ትጠብቃለህ። ቅርንጫፎቹ ወደ መስቀያው ይመራሉ — ታዛዥነት እገዳ አይደለም፤ ወይኑ ቅርንጫፉን ወደ ብርሃንና ፍሬ የሚመራ ነው።',
        );
      case JourneyMovement.fruiting:
        return (
          en: 'I chose you, that you should bear fruit — and fruit that remains. '
              'The grapes have ripened; the harvest is at hand. What was done in '
              'the secret days is now visible in the lives around you.',
          am: 'ፍሬ እንድታፈራ — እንዲጸናም ፍሬ እንድታፈራ መረጥኩህ። ዘለላዎቹ በስለዋል፤ መከሩ ቀርቧል። በስውር የተሠራው አሁን በዙሪያህ ባሉ ሕይወቶች ውስጥ ይታያል።',
        );
    }
  }

  static String movementVerse(JourneyMovement movement) {
    switch (movement) {
      case JourneyMovement.planting:
        return 'John 15:2';
      case JourneyMovement.rooting:
        return '2 Peter 1:5';
      case JourneyMovement.growing:
        return 'John 14:15';
      case JourneyMovement.fruiting:
        return 'John 15:16';
    }
  }

  /// Horizon line — hope without a countdown.
  static Localized horizonLine() => (
        en: 'The Vine is faithful. In due season, you will reap.',
        am: 'ወይኑ ታማኝ ነው። በጊዜው ትሰበስባለህ።',
      );

  // ─── Vine stage lines ─────────────────────────────────────────────────

  static Localized vineStageLine(VineStage stage) {
    switch (stage) {
      case VineStage.seed:
        return (
          en: 'The seed is hidden in the soil — God is at work before you see it.',
          am: 'ዘሩ በአፈር ውስጥ ተደብቋል — ሳታይ እግዚአብሔር ይሠራል።',
        );
      case VineStage.sprout:
        return (
          en: 'The first green appears. Discipline is the branch learning to hold.',
          am: 'የመጀመሪያው አረንጓዴ ይታያል። ዲሲፕሊን ቅርንጫፉ መቆየት መማር ነው።',
        );
      case VineStage.rooted:
        return (
          en: 'The roots reach deep. Faith drinks from the Vine.',
          am: 'ሥሩ ጥልቅ ይደርሳል። እምነት ከወይኑ ይጠጣል።',
        );
      case VineStage.blooming:
        return (
          en: 'The vine covers the trellis. Obedience turns toward the light.',
          am: 'ወይኑ መስቀያውን ይሸፍናል። ታዛዥነት ወደ ብርሃን ይዞራል።',
        );
      case VineStage.fruiting:
        return (
          en: 'The clusters swell. The harvest is at hand.',
          am: 'ዘለላዎቹ ያብጣሉ። መከሩ ቀርቧል።',
        );
    }
  }

  /// Grace note: the vine grows on God's clock, not ours.
  static Localized graceNote() => (
        en: 'It grows on God\'s clock, not yours — He who began a good work in you will complete it (Phil 1:6).',
        am: 'በእግዚአብሔር ጊዜ ያድጋል እንጂ በአንተ አይደለም — መልካሙን ሥራ የጀመረው ይፈጽመዋልና (ፊልጵስዩስ 1:6)።',
      );

  // ─── Encouragement (weather-aware) ────────────────────────────────────

  static const Map<Object, List<Localized>> _encouragementPools = {
    'clear': [
      (en: 'Taste and see that the Lord is good. — Psalm 34:8', am: 'እግዚአብሔር መልካም መሆኑን ቅመሱ እዩም። — መዝሙር 34:8'),
      (en: 'The LORD your God rejoices over you with gladness. — Zephaniah 3:17', am: 'እግዚአብሔር አምላክህ በደስታ ይደሰትብሃል። — ሶፎንያስ 3:17'),
      (en: 'I can do all things through Christ who strengthens me. — Philippians 4:13', am: 'ኃይልን በሚሰጠኝ በክርስቶስ ሁሉን እችላለሁ። — ፊልጵስዩስ 4:13'),
    ],
    'cloudy': [
      (en: 'I am the vine; you are the branches. Abide in me. — John 15:5', am: 'እኔ ወይኑ ነኝ እናንተም ቅርንጫፎቹ ናችሁ። በእኔ ቆዩ። — ዮሐንስ 15:5'),
      (en: 'He who began a good work in you will carry it to completion. — Philippians 1:6', am: 'መልካሙን ሥራ በእናንተ የጀመረው ይፈጽመዋል። — ፊልጵስዩስ 1:6'),
      (en: 'In due season you will reap, if you do not give up. — Galatians 6:9', am: 'በጊዜውስ ትሰበስባለህ ካልተታከትክ። — ገላትያ 6:9'),
    ],
    'storm': [
      (en: 'Cast all your anxiety on Him, for He cares for you. — 1 Peter 5:7', am: 'ጭንቀትህን ሁሉ በእርሱ ላይ ጣል፥ ያስብሃልና። — 1 ጴጥሮስ 5:7'),
      (en: 'The LORD is near to the brokenhearted. — Psalm 34:18', am: 'እግዚአብሔር ለተሰበሩ ልቦች ቅርብ ነው። — መዝሙር 34:18'),
      (en: 'Come to me, all you who are weary, and I will give you rest. — Matthew 11:28', am: 'ልከብዳችሁ የደከማችሁ ሁሉ ወደ እኔ ኑ፥ እኔም ያሳርፋችኋለሁ። — ማቴዎስ 11:28'),
      (en: 'His mercies are new every morning. — Lamentations 3:22-23', am: 'ምሕረቱ በየማለዳው አዲስ ነው። — ልቅሶ 3:22-23'),
    ],
  };

  static List<Localized> encouragementPool(int? mood) {
    if (mood == null || mood == 3) return _encouragementPools['cloudy']!;
    if (mood <= 2) return _encouragementPools['storm']!;
    return _encouragementPools['clear']!;
  }

  /// A Scripture encouragement, weather-aware and rotating by journey day.
  static Localized encouragementFor(int day, int? mood) {
    final pool = encouragementPool(mood);
    final idx = (day - 1) % pool.length;
    return pool[idx < 0 ? idx + pool.length : idx];
  }

  // ─── Weather of the heart ─────────────────────────────────────────────

  static ({String glyph, String labelEn, String labelAm}) weatherGlyph(int mood) {
    switch (mood.clamp(1, 5)) {
      case 1:
        return (glyph: '⛈', labelEn: 'Storm', labelAm: 'አውሎ ነፋስ');
      case 2:
        return (glyph: '🌧', labelEn: 'Rain', labelAm: 'ዝናብ');
      case 3:
        return (glyph: '☁', labelEn: 'Cloud', labelAm: 'ደመና');
      case 4:
        return (glyph: '⛅', labelEn: 'Brightening', labelAm: 'ደመና ቀላል');
      default:
        return (glyph: '☀', labelEn: 'Clear', labelAm: 'ፀሐይ');
    }
  }

  // ─── Atmosphere (sky + particles) ─────────────────────────────────────

  static Atmosphere atmosphereFor(int? mood, LampLight light) {
    if (mood != null && mood <= 2) {
      return const Atmosphere(
        particle: VineParticle.rain,
        skyTop: _skyStormTop,
        skyBottom: _skyStormBottom,
      );
    }
    switch (light) {
      case LampLight.dawn:
        return const Atmosphere(particle: VineParticle.dust, skyTop: _skyDawnTop, skyBottom: _skyDawnBottom);
      case LampLight.noon:
        return const Atmosphere(particle: VineParticle.clear, skyTop: _skyNoonTop, skyBottom: _skyNoonBottom);
      case LampLight.dusk:
        return const Atmosphere(particle: VineParticle.dust, skyTop: _skyDuskTop, skyBottom: _skyDuskBottom);
      case LampLight.night:
        return const Atmosphere(particle: VineParticle.fireflies, skyTop: _skyNightTop, skyBottom: _skyNightBottom);
    }
  }

  static const Color _skyDawnTop = Color(0xFF274060);
  static const Color _skyDawnBottom = Color(0xFFB57E2E);
  static const Color _skyNoonTop = Color(0xFF7FB0D9);
  static const Color _skyNoonBottom = Color(0xFFF5E6C4);
  static const Color _skyDuskTop = Color(0xFF3B2A5C);
  static const Color _skyDuskBottom = Color(0xFFD97A3D);
  static const Color _skyNightTop = Color(0xFF0B1026);
  static const Color _skyNightBottom = Color(0xFF1B2A4A);
  static const Color _skyStormTop = Color(0xFF3A3F4A);
  static const Color _skyStormBottom = Color(0xFF6A7078);

  // ─── Harvest letter ───────────────────────────────────────────────────

  /// Composes the Harvest Letter from the user's own planted words.
  static String harvestLetter(List<String> answers, JourneyMovement movement, {required bool isAm}) {
    final title = movementTitle(movement);
    final count = answers.length;
    if (count == 0) {
      return isAm
          ? 'በዚህ ወቅት በጸጥታ ቆየህ። እርሻው አሁንም የአንተ ነው — እንደገና ትክል፣ መከሩም ያስታውሳል።'
          : 'You abided quietly this season. The field is still yours — plant again, and the harvest will remember.';
    }
    final first = answers.first;
    final second = answers.length > 1 ? answers[answers.length - 1] : null;
    if (isAm) {
      final quotes = second == null ? '"$first"' : '"$first" … "$second"';
      return 'በዚህ የ${title.am} ወቅት — $count ጊዜ መልሰሃል። ከቃላትህ መካከል፡ $quotes። ይህ የውጤት ወረቀት አይደለም፤ በክርስቶስ የመቆየትህ ፍሬ ነው። በዲሲፕሊን ተተክለሃል፣ በእምነት ሥር ሰድደሃል፣ በታዛዥነት አድገሃል፣ ወደ ተጽዕኖ እየበሰልህ ነው። ደክሞ ነገር በማድረግ አትታክት፥ በጊዜውስ ትሰበስባለህ (ገላትያ 6:9)። መልካሙን ሥራ የጀመረው ወይን ይፈጽመዋል (ፊልጵስዩስ 1:6)።';
    }
    final quotes = second == null ? '"$first"' : '"$first" … "$second"';
    return 'On this season of the ${title.en} — you answered $count times. Among your own words: $quotes. This is not a report card; it is the fruit of your abiding. You were planted in discipline, rooted in faith, trained in obedience, and you are ripening into impact. In due season you will reap, if you do not give up (Galatians 6:9). The Vine who began a good work in you is faithful to complete it (Philippians 1:6).';
  }
}

class Atmosphere {
  final VineParticle particle;
  final Color skyTop;
  final Color skyBottom;
  const Atmosphere({required this.particle, required this.skyTop, required this.skyBottom});
}
