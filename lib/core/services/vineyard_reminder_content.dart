import 'dart:math';

import 'growth_content.dart';

/// Bilingual reminder content for "Vineyard visits".
/// Pure, offline, deterministic given a [ReminderContext] and the send history.
/// No database, no plugins — every function is unit-testable.

enum ReminderKind { stage, intention, verse, weather, comeback }

enum ReminderFrequency { gentle, attentive }

class ReminderContext {
  final int day;
  final JourneyMovement movement;
  final VineStage stage;
  final JourneyIntention intention;
  final int? mood;
  final bool harvested;
  final bool isAm;
  const ReminderContext({
    required this.day,
    required this.movement,
    required this.stage,
    required this.intention,
    this.mood,
    this.harvested = false,
    this.isAm = false,
  });
}

class ReminderCard {
  final ReminderKind kind;
  final String title;
  final String body;
  final String bigText;
  const ReminderCard({
    required this.kind,
    required this.title,
    required this.body,
    required this.bigText,
  });
}

class _Candidate {
  final ReminderKind kind;
  final int index;
  final ReminderCard card;
  const _Candidate(this.kind, this.index, this.card);
}

class VineyardReminderContent {
  const VineyardReminderContent._();

  static final Random _rng = Random();

  static String _pick(Localized pair, bool isAm) => isAm ? pair.am : pair.en;

  static const List<Localized> _stageTitle = [
    (en: 'The seed is planted', am: 'ዘሩ ተተክሏል'),
    (en: 'A green shoot appears', am: 'አረንጓዴ ቡቃያ ታየ'),
    (en: 'Roots are reaching deep', am: 'ሥሩ ጥልቅ እየደረሰ ነው'),
    (en: 'The blossoms are opening', am: 'አበቦቹ እየተከፈቱ ነው'),
    (en: 'The fruit is ripening', am: 'ፍሬው እየበሰለ ነው'),
  ];

  static const List<Localized> _stageBody = [
    (en: 'God is at work beneath the soil before you ever see it.', am: 'ሳታይ እግዚአብሔር በአፈር ውስጥ ይሠራል።'),
    (en: 'Something is growing in you that no one can rush.', am: 'ማንም ሊቸኩለው የማይችለው ነገር በውስጥህ እያደገ ነው።'),
    (en: 'What is unseen is becoming unshakable.', am: 'የማይታየው የማይናወጥ እየሆነ ነው።'),
    (en: 'Faith is turning toward the light.', am: 'እምነት ወደ ብርሃን እየዞረ ነው።'),
    (en: 'The harvest is at hand — come see.', am: 'መከሩ ቀርቧል — ኑ ተመልከት።'),
  ];

  static const List<Localized> _stageBig = [
    (en: 'Unless a grain of wheat falls into the earth and dies, it remains alone. — John 12:24', am: 'የስንዴ ቅንጣት በመሬት ውስጥ ወድቆ ካልሞተ በቀር ብቻውን ይቀራል። — ዮሐንስ 12፥24'),
    (en: 'He who began a good work in you will carry it to completion. — Philippians 1:6', am: 'መልካሙን ሥራ በእናንተ የጀመረው ይፈጽመዋል። — ፊልጵስዩስ 1፥6'),
    (en: 'Rooted and built up in him. — Colossians 2:7', am: 'በእርሱ ሥር ሰድዳችሁ ተገንብታችሁ። — ቆላስይስ 2፥7'),
    (en: 'I chose you, that you should bear fruit — and fruit that remains. — John 15:16', am: 'ፍሬ እንድታፈራ መረጥኩህ። — ዮሐንስ 15፥16'),
    (en: 'In due season you will reap, if you do not give up. — Galatians 6:9', am: 'በጊዜውስ ትሰበስባለህ ካልተታከትክ። — ገላትያ 6፥9'),
  ];

  static const List<Localized> _intentionTitle = [
    (en: 'Your Word journey', am: 'የቃል ጉዞህ'),
    (en: 'Your discipline journey', am: 'የሥርዓት ጉዞህ'),
    (en: 'Your heart journey', am: 'የልብ ጉዞህ'),
    (en: 'Your faithfulness journey', am: 'የታማኝነት ጉዞህ'),
    (en: 'Your service journey', am: 'የአገልግሎት ጉዞህ'),
    (en: 'Your abiding journey', am: 'የመቆየት ጉዞህ'),
  ];

  static const List<Localized> _intentionBody = [
    (en: 'Today, let one verse sit with you. The vine drinks quietly.', am: 'ዛሬ አንድ ቁጥር ከአንተ ጋር ይቆይ። ወይኑ በጸጥታ ይጠጣል።'),
    (en: 'One small act of obedience today is still growth.', am: 'የዛሬ ትንሽ ታዛዥነት እንኳን እድገት ነው።'),
    (en: 'Bring your heart as it is. He tends it gently.', am: 'ልብህን እንዳለህ አምጣ። እርሱ በገርነት ይንከባከባል።'),
    (en: 'He who began this work in you will finish it.', am: 'ይህን ሥራ በአንተ የጀመረው ይፈጽመዋል።'),
    (en: 'Somewhere today, someone needs the love you carry.', am: 'ዛሬ የምትሸከመውን ፍቅር የሚያስፈልገው አንድ ሰው አለ።'),
    (en: 'You do not have to do anything. Just stay near Him.', am: 'ምንም ማድረግ የለብህም። ለእርሱ ቅርብ ብቻ ሁን።'),
  ];

  static const List<Localized> _comebackTitle = [
    (en: 'Welcome back', am: 'እንኳን ደህና መጣህ'),
    (en: 'Fresh mercies', am: 'አዲስ ምሕረት'),
    (en: 'Still yours', am: 'አሁንም የአንተ ነው'),
    (en: 'The Vine missed you', am: 'ወይኑ ናፈቀህ'),
  ];

  static const List<Localized> _comebackBody = [
    (en: 'He never left. The vine is still growing — so are you.', am: 'እርሱ ፈጽሞ አልራቀም። ወይኑ እያደገ ነው — አንተም እያደግህ ነው።'),
    (en: 'His mercies are new this morning. Begin again gently.', am: 'ምሕረቱ ዛሬ ጠዋት አዲስ ነው። በገርነት እንደገና ጀምር።'),
    (en: 'Nothing was lost. The soil is yours; the growing is His.', am: 'ምንም አልጠፋም። አፈሩ የአንተ ነው፤ ማደጉ የእግዚአብሔር ነው።'),
    (en: 'The Vine was glad to see you today. Sit a while.', am: 'ወይኑ ዛሬ ሲያይህ ደስ አለው። ትንሽ ተቀመጥ።'),
  ];

  static const Localized _comebackBig =
      (en: 'The steadfast love of the Lord never ceases; his mercies are new every morning. — Lamentations 3:22-23', am: 'የእግዚአብሔር ቸርነት አያልቅም፤ ምሕረቱ በየማለዳው አዲስ ነው። — ልቅሶ 3፥22-23');

  static const List<Localized> _weatherTitle = [
    (en: 'A clear sky', am: 'ግልጽ ሰማይ'),
    (en: 'A little wind', am: 'ትንሽ ነፋስ'),
    (en: 'Clouds today', am: 'ዛሬ ደመና'),
    (en: 'Rain today', am: 'ዛሬ ዝናብ'),
    (en: 'A storm today', am: 'ዛሬ ማዕበል'),
  ];

  static const List<Localized> _weatherBody = [
    (en: 'Even stillness is growing. Rest in Him.', am: 'ፀጥታ እንኳን እያደገ ነው። በእርሱ ዕረፍ።'),
    (en: 'The breeze is gentle. Breathe, and trust the Vine.', am: 'ነፋሱ ገር ነው። ተነፍስ፣ ወይኑን ታመን።'),
    (en: 'You are not alone in the gray. He walks beside you.', am: 'በግራጫው ውስጥ ብቻህ አይደለህም። ከጎንህ ይሄዳል።'),
    (en: 'The roots drink deepest in the storm.', am: 'ሥሩ በማዕበል ጥልቅ ይጠጣል።'),
    (en: 'He is your shelter, not your judge.', am: 'እርሱ መጠጊያህ ነው፥ ፈራጅህ አይደለም።'),
  ];

  static ({ReminderCard card, String key}) pickCard(ReminderContext ctx, {required List<String> history}) {
    final candidates = <_Candidate>[
      _Candidate(ReminderKind.stage, ctx.stage.index, _stageCard(ctx)),
      _Candidate(ReminderKind.intention, ctx.intention.index, _intentionCard(ctx)),
      _Candidate(ReminderKind.verse, ctx.day, _verseCard(ctx)),
      _Candidate(ReminderKind.weather, ctx.mood ?? 3, _weatherCard(ctx)),
      _Candidate(ReminderKind.comeback, ctx.day % _comebackTitle.length, _comebackCard(ctx)),
    ];
    String key(ReminderKind k, int i) => '${k.name}:$i';
    final lastKind = history.isEmpty ? null : history.last.split(':').first;
    final fresh = candidates.where((c) => !history.contains(key(c.kind, c.index))).toList();
    final notLastFresh = fresh.where((c) => c.kind.name != lastKind).toList();
    final notLastAll = candidates.where((c) => c.kind.name != lastKind).toList();
    final pool = notLastFresh.isNotEmpty
        ? notLastFresh
        : notLastAll.isNotEmpty
            ? notLastAll
            : fresh.isNotEmpty
                ? fresh
                : candidates;
    final chosen = pool[_rng.nextInt(pool.length)];
    return (card: chosen.card, key: key(chosen.kind, chosen.index));
  }

  static ReminderCard _stageCard(ReminderContext ctx) {
    final s = ctx.stage.index.clamp(0, _stageTitle.length - 1);
    return ReminderCard(
      kind: ReminderKind.stage,
      title: _pick(_stageTitle[s], ctx.isAm),
      body: _pick(_stageBody[s], ctx.isAm),
      bigText: _pick(_stageBig[s], ctx.isAm),
    );
  }

  static ReminderCard _intentionCard(ReminderContext ctx) {
    final i = ctx.intention.index.clamp(0, _intentionTitle.length - 1);
    return ReminderCard(
      kind: ReminderKind.intention,
      title: _pick(_intentionTitle[i], ctx.isAm),
      body: _pick(_intentionBody[i], ctx.isAm),
      bigText: _pick(_intentionBig, ctx.isAm),
    );
  }

  static ReminderCard _verseCard(ReminderContext ctx) {
    final s = GrowthContent.vineStageLine(ctx.stage);
    return ReminderCard(
      kind: ReminderKind.verse,
      title: ctx.isAm ? 'ቀን ${ctx.day}' : 'Day ${ctx.day}',
      body: _pick(s, ctx.isAm),
      bigText: _pick(s, ctx.isAm),
    );
  }

  static ReminderCard _weatherCard(ReminderContext ctx) {
    final m = (ctx.mood ?? 3).clamp(1, 5);
    final i = m - 1;
    return ReminderCard(
      kind: ReminderKind.weather,
      title: _pick(_weatherTitle[i], ctx.isAm),
      body: _pick(_weatherBody[i], ctx.isAm),
      bigText: _pick(GrowthContent.encouragementFor(ctx.day, m), ctx.isAm),
    );
  }

  static ReminderCard _comebackCard(ReminderContext ctx) {
    final i = ctx.day % _comebackTitle.length;
    return ReminderCard(
      kind: ReminderKind.comeback,
      title: _pick(_comebackTitle[i], ctx.isAm),
      body: _pick(_comebackBody[i], ctx.isAm),
      bigText: _pick(_comebackBig, ctx.isAm),
    );
  }

  static const Localized _intentionBig =
      (en: 'He who began a good work in you will carry it to completion. — Philippians 1:6', am: 'መልካሙን ሥራ በአንተ የጀመረው ይፈጽመዋል። — ፊልጵስዩስ 1፥6');

  /// Next visit time. Gentle = 1–3 days ahead; Attentive = tomorrow.
  /// Hour falls inside Morning (7–9) or Evening (18–20).
  static DateTime pickNextFire(
    DateTime now, {
    required ReminderFrequency frequency,
    required bool evening,
    Random? rng,
  }) {
    final r = rng ?? _rng;
    final gapDays = frequency == ReminderFrequency.attentive ? 1 : 1 + r.nextInt(3);
    final hour = evening ? 18 + r.nextInt(3) : 7 + r.nextInt(3);
    final minute = r.nextInt(60);
    return DateTime(now.year, now.month, now.day)
        .add(Duration(days: gapDays, hours: hour, minutes: minute));
  }
}
