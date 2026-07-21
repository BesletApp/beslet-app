import 'dart:math';
import 'types.dart';

class _PoolEntry {
  final String text;
  final String variant;
  final List<UserMood>? moodAffinity;

  const _PoolEntry(this.text, this.variant, [this.moodAffinity]);
}

final Map<ExperienceIntent, List<_PoolEntry>> _enInvitations = {
  ExperienceIntent.grounding: const [
    _PoolEntry('Let these words settle softly in your heart. There\'s no rush.', 'grounding-1'),
    _PoolEntry('Let your breath slow. This moment is yours alone.', 'grounding-2', [UserMood.anxious]),
    _PoolEntry('Still your heart and listen. Something gentle is coming.', 'grounding-3'),
    _PoolEntry('You are here. That is enough. Let the words find you.', 'grounding-4', [UserMood.tired]),
    _PoolEntry('No need to strive. You are free to receive.', 'grounding-5', [UserMood.peaceful]),
    _PoolEntry('The quiet before the word is part of the word.', 'grounding-6'),
  ],
  ExperienceIntent.slowing: const [
    _PoolEntry('Breathe. Let the stillness hold you. This moment is yours.', 'slowing-1', [UserMood.anxious]),
    _PoolEntry('Slow down, dear one. There is nowhere to be but here.', 'slowing-2', [UserMood.tired]),
    _PoolEntry('The world can wait. This pause is sacred.', 'slowing-3'),
    _PoolEntry('Let your shoulders drop. Let your breath deepen. Be still.', 'slowing-4', [UserMood.anxious, UserMood.tired]),
    _PoolEntry('You don\'t need to rush toward peace. It is already here.', 'slowing-5'),
    _PoolEntry('Each word will come in its own time. The pace is your own.', 'slowing-6'),
  ],
  ExperienceIntent.comforting: const [
    _PoolEntry('You are held. Even here, even now, you are not alone.', 'comforting-1', [UserMood.sorrowful, UserMood.anxious]),
    _PoolEntry('Let this be a balm for your weary heart.', 'comforting-2', [UserMood.tired, UserMood.sorrowful]),
    _PoolEntry('You are seen. You are known. You are loved beyond measure.', 'comforting-3'),
    _PoolEntry('Whatever you carry today, you do not carry it alone.', 'comforting-4', [UserMood.sorrowful]),
    _PoolEntry('Grace wraps around you like a warm embrace. Rest in it.', 'comforting-5', [UserMood.tired]),
    _PoolEntry('Even in the valley, light finds a way to reach you.', 'comforting-6', [UserMood.sorrowful]),
  ],
  ExperienceIntent.affirming: const [
    _PoolEntry('You are beloved. Not for what you do — for who you are.', 'affirming-1'),
    _PoolEntry('You are enough. You have always been enough.', 'affirming-2', [UserMood.tired]),
    _PoolEntry('Your faithfulness is a quiet strength that moves mountains.', 'affirming-3', [UserMood.joyful]),
    _PoolEntry('You were created with purpose, woven with intention.', 'affirming-4'),
    _PoolEntry('Your journey matters. Every step, every stumble, every rise.', 'affirming-5'),
    _PoolEntry('You are growing, even when you cannot see it.', 'affirming-6'),
  ],
  ExperienceIntent.awakening: const [
    _PoolEntry('A new day. A new breath. A new beginning awaits you.', 'awakening-1', [UserMood.joyful]),
    _PoolEntry('Wake up to the beauty that already surrounds you.', 'awakening-2'),
    _PoolEntry('Dawn breaks, and with it, fresh mercy.', 'awakening-3'),
    _PoolEntry('Today is a gift. Unwrap it with open hands.', 'awakening-4', [UserMood.joyful]),
    _PoolEntry('Light is breaking through. Can you feel it?', 'awakening-5', [UserMood.peaceful]),
    _PoolEntry('The morning sings of hope. Listen closely.', 'awakening-6'),
  ],
  ExperienceIntent.resting: const [
    _PoolEntry('Rest now. You have done enough. Let grace carry the rest.', 'resting-1', [UserMood.tired]),
    _PoolEntry('Lay down your burdens. This space is safe.', 'resting-2', [UserMood.anxious, UserMood.tired]),
    _PoolEntry('You are allowed to rest. You are allowed to be still.', 'resting-3'),
    _PoolEntry('Nothing is required of you right now but to be.', 'resting-4', [UserMood.tired]),
    _PoolEntry('The day is done. Peace is here.', 'resting-5', [UserMood.peaceful]),
    _PoolEntry('Rest is not weakness. Rest is wisdom.', 'resting-6'),
  ],
};

final Map<ExperienceIntent, List<_PoolEntry>> _amInvitations = {
  ExperienceIntent.grounding: const [
    _PoolEntry('እነዚህ ቃላት በልብህ ውስጥ በቀስታ ይቀመጡ። አትቸኩል።', 'grounding-am-1'),
    _PoolEntry('በቀስታ ተንፍስ። ይህ ጊዜ የአንተ ብቻ ነው።', 'grounding-am-2', [UserMood.anxious]),
    _PoolEntry('ልብህን አረጋጋና ስማ። የሚያረጋጋ ነገር ይመጣል።', 'grounding-am-3'),
    _PoolEntry('እዚህ ነህ። ይህ በቂ ነው። ቃላቱ ያገኙሃል።', 'grounding-am-4', [UserMood.tired]),
    _PoolEntry('መታገል አያስፈልግም። ተቀበል ብቻ።', 'grounding-am-5', [UserMood.peaceful]),
  ],
  ExperienceIntent.slowing: const [
    _PoolEntry('ተንፍስ። ፀጥታ ይይዝህ። ይህ ጊዜ የአንተ ነው።', 'slowing-am-1', [UserMood.anxious]),
    _PoolEntry('ዘገም በል ውዴ። ከመሆን በቀር ሌላ ቦታ የለም።', 'slowing-am-2', [UserMood.tired]),
    _PoolEntry('አለም ሊጠብቅ ይችላል። ይህ አረፍት የተቀደሰ ነው።', 'slowing-am-3'),
    _PoolEntry('ትከሻህን አውርድ። ትንፋሽህን አጠናክር። ጸጥ በል።', 'slowing-am-4', [UserMood.anxious, UserMood.tired]),
  ],
  ExperienceIntent.comforting: const [
    _PoolEntry('ተይዘሃል። እዚህም ቢሆን፣ አሁንም ቢሆን፣ ብቻህን አይደለህም።', 'comforting-am-1', [UserMood.sorrowful, UserMood.anxious]),
    _PoolEntry('ይህ ለደከመ ልብህ መድሀኒት ይሁን።', 'comforting-am-2', [UserMood.tired, UserMood.sorrowful]),
    _PoolEntry('ታይተሃል። ታውቀሃል። ከልክ በላይ ተወድጄሃል።', 'comforting-am-3'),
    _PoolEntry('ዛሬ ምንም ብትሸከም፣ ብቻህን አትሸከመውም።', 'comforting-am-4', [UserMood.sorrowful]),
  ],
  ExperienceIntent.affirming: const [
    _PoolEntry('ተወዳጅ ነህ። በምትሠራው ሳይሆን — በማንነትህ ነው።', 'affirming-am-1'),
    _PoolEntry('በቂ ነህ። ሁል ጊዜም በቂ ነበርህ።', 'affirming-am-2', [UserMood.tired]),
    _PoolEntry('ታማኝነትህ ተራራን የሚያንቀሳቅስ ጸጥ ያለ ሀይል ነው።', 'affirming-am-3', [UserMood.joyful]),
    _PoolEntry('በዓላማ ተፈጠርህ፣ በአሳብ ተሸምነሃል።', 'affirming-am-4'),
  ],
  ExperienceIntent.awakening: const [
    _PoolEntry('አዲስ ቀን። አዲስ እስትንፋስ። አዲስ መጀመሪያ ይጠብቅሃል።', 'awakening-am-1', [UserMood.joyful]),
    _PoolEntry('በዙሪያህ ያለውን ውበት ለማየት ንቃ።', 'awakening-am-2'),
    _PoolEntry('ንጋት ይበራል፣ አዲስ ምህረትም ይመጣል።', 'awakening-am-3'),
    _PoolEntry('ዛሬ ስጦታ ነው። በክፍት እጆች ፍታው።', 'awakening-am-4', [UserMood.joyful]),
  ],
  ExperienceIntent.resting: const [
    _PoolEntry('አሁን እረፍ። በቂ አድርገሃል። ጸጋ የቀረውን ይሸከማል።', 'resting-am-1', [UserMood.tired]),
    _PoolEntry('ሸክምህን አስቀምጥ። ይህ ቦታ ደህነት ነው።', 'resting-am-2', [UserMood.anxious, UserMood.tired]),
    _PoolEntry('ማረፍ ተፈቅዶልሃል። ጸጥ ማለት ተፈቅዶልሃል።', 'resting-am-3'),
    _PoolEntry('አሁን ከአንተ ምንም አይጠበቅም። መኖር ብቻ።', 'resting-am-4', [UserMood.tired]),
  ],
};

final Map<ExperienceIntent, List<_PoolEntry>> _enBlessings = {
  ExperienceIntent.grounding: const [
    _PoolEntry('Go in peace. The ground beneath you is holy.', 'blessing-grounding-1'),
    _PoolEntry('You are rooted in love that never fails.', 'blessing-grounding-2'),
    _PoolEntry('Walk gently. You carry the presence of the Divine with you.', 'blessing-grounding-3'),
    _PoolEntry('May you remember: you belong. You have always belonged.', 'blessing-grounding-4', [UserMood.anxious]),
    _PoolEntry('The same love that holds the stars holds you.', 'blessing-grounding-5', [UserMood.peaceful]),
    _PoolEntry('You are planted in good soil. Grow at your own pace.', 'blessing-grounding-6'),
  ],
  ExperienceIntent.slowing: const [
    _PoolEntry('May you carry this stillness into the rest of your day.', 'blessing-slowing-1'),
    _PoolEntry('Go slowly, dear heart. There is beauty in the pace of grace.', 'blessing-slowing-2'),
    _PoolEntry('You have permission to move at the speed of peace.', 'blessing-slowing-3', [UserMood.anxious, UserMood.tired]),
    _PoolEntry('Let patience be your companion and gentleness your guide.', 'blessing-slowing-4', [UserMood.tired]),
    _PoolEntry('The world will wait. Your soul will thank you.', 'blessing-slowing-5'),
  ],
  ExperienceIntent.comforting: const [
    _PoolEntry('You are wrapped in grace that will not let you go.', 'blessing-comforting-1'),
    _PoolEntry('May you feel the arms of love around you, even when you cannot see them.', 'blessing-comforting-2', [UserMood.sorrowful]),
    _PoolEntry('You are not broken. You are being held together by love.', 'blessing-comforting-3', [UserMood.sorrowful, UserMood.tired]),
    _PoolEntry('Tears are not weakness. They are the heart speaking its deepest truth.', 'blessing-comforting-4', [UserMood.sorrowful]),
    _PoolEntry('Healing comes like the dawn — slowly, gently, surely.', 'blessing-comforting-5', [UserMood.sorrowful]),
    _PoolEntry('You are safe. You are seen. You are loved.', 'blessing-comforting-6', [UserMood.anxious]),
  ],
  ExperienceIntent.affirming: const [
    _PoolEntry('You are a light that cannot be dimmed. Shine boldly.', 'blessing-affirming-1', [UserMood.joyful]),
    _PoolEntry('May you walk in the confidence of one who is deeply loved.', 'blessing-affirming-2'),
    _PoolEntry('You are not what you produce. You are a beloved child of the Divine.', 'blessing-affirming-3', [UserMood.tired]),
    _PoolEntry('Your presence is a gift to the world.', 'blessing-affirming-4'),
    _PoolEntry('Every step you take is seen. Every effort you make matters.', 'blessing-affirming-5'),
    _PoolEntry('You carry goodness within you. Trust it. Live it.', 'blessing-affirming-6', [UserMood.peaceful]),
  ],
  ExperienceIntent.awakening: const [
    _PoolEntry('Go and be the hope the world needs today.', 'blessing-awakening-1', [UserMood.joyful]),
    _PoolEntry('The light within you is greater than any darkness you face.', 'blessing-awakening-2'),
    _PoolEntry('Today is full of possibility. Walk into it with courage.', 'blessing-awakening-3'),
    _PoolEntry('You are made for more than mere surviving. You are made to thrive.', 'blessing-awakening-4'),
    _PoolEntry('Dawn has broken in your heart. Let it shine.', 'blessing-awakening-5', [UserMood.joyful, UserMood.peaceful]),
  ],
  ExperienceIntent.resting: const [
    _PoolEntry('Rest in the peace that passes all understanding.', 'blessing-resting-1'),
    _PoolEntry('May your sleep be deep and your dreams be gentle.', 'blessing-resting-2', [UserMood.tired, UserMood.anxious]),
    _PoolEntry('You are held, even as you let go of the day.', 'blessing-resting-3', [UserMood.peaceful]),
    _PoolEntry('The night is not empty. It is full of grace.', 'blessing-resting-4', [UserMood.sorrowful]),
    _PoolEntry('Let go. Sleep. Trust. Tomorrow has its own mercy.', 'blessing-resting-5', [UserMood.anxious]),
    _PoolEntry('You have run well. Now rest in the arms of love.', 'blessing-resting-6', [UserMood.tired]),
  ],
};

final Map<ExperienceIntent, List<_PoolEntry>> _amBlessings = {
  ExperienceIntent.grounding: const [
    _PoolEntry('በሰላም ሂድ። ከእግርህ በታች ያለው መሬት ቅዱስ ነው።', 'blessing-grounding-am-1'),
    _PoolEntry('በማይከታው ፍቅር ሥር ሰድተሃል።', 'blessing-grounding-am-2'),
    _PoolEntry('በቀስታ ሂድ። የአምላክን መገኘት ይዘህ ትሄዳለህ።', 'blessing-grounding-am-3'),
    _PoolEntry('እንደሚገባህ አስታውስ። ሁል ጊዜም የምትገባ ነበርክ።', 'blessing-grounding-am-4', [UserMood.anxious]),
  ],
  ExperienceIntent.slowing: const [
    _PoolEntry('ይህን ፀጥታ ወደ ቀንህ ተሸክመህ ሂድ።', 'blessing-slowing-am-1'),
    _PoolEntry('በቀስታ ሂድ ውድ ልቤ። በጸጋ ፍጥነት ውስጥ ውበት አለ።', 'blessing-slowing-am-2'),
    _PoolEntry('በሰላም ፍጥነት ለመንቀሳቀስ ፈቃድ አለህ።', 'blessing-slowing-am-3', [UserMood.anxious, UserMood.tired]),
  ],
  ExperienceIntent.comforting: const [
    _PoolEntry('በማይለቅህ ጸጋ ተጠቅልለሃል።', 'blessing-comforting-am-1'),
    _PoolEntry('ማየት ባትችላቸውም እንኳ የፍቅር እቅፍ በዙሪያህ ይሁን።', 'blessing-comforting-am-2', [UserMood.sorrowful]),
    _PoolEntry('አልተሰበርህም። በፍቅር አንድ ላይ ትያዛለህ።', 'blessing-comforting-am-3', [UserMood.sorrowful, UserMood.tired]),
  ],
  ExperienceIntent.affirming: const [
    _PoolEntry('የማትጠፋ ብርሃን ነህ። በድፍረት ብርሃንህን አብራ።', 'blessing-affirming-am-1', [UserMood.joyful]),
    _PoolEntry('በሚወደው ሰው እምነት ተመላለስ።', 'blessing-affirming-am-2'),
    _PoolEntry('አንተ የምታፈራው ነገር አይደለህም። የአምላክ የተወደደ ልጅ ነህ።', 'blessing-affirming-am-3', [UserMood.tired]),
  ],
  ExperienceIntent.awakening: const [
    _PoolEntry('ሂድና ዛሬ አለም የሚፈልገው ተስፋ ሁን።', 'blessing-awakening-am-1', [UserMood.joyful]),
    _PoolEntry('በውስጥህ ያለው ብርሃን ከማንኛውም ጨለማ ይበልጣል።', 'blessing-awakening-am-2'),
    _PoolEntry('ዛሬ በተስፋ የተሞላ ነው። በድፍረት ግባበት።', 'blessing-awakening-am-3'),
  ],
  ExperienceIntent.resting: const [
    _PoolEntry('ከማስተዋል በላይ በሆነ ሰላም ውስጥ እረፍ።', 'blessing-resting-am-1'),
    _PoolEntry('እንቅልፍህ ጥልቅ ይሁን ህልምህም ለስላሳ ይሁን።', 'blessing-resting-am-2', [UserMood.tired, UserMood.anxious]),
    _PoolEntry('ቀኑን ስትለቅ ተይዘሃል።', 'blessing-resting-am-3', [UserMood.peaceful]),
    _PoolEntry('ሌሊት ባዶ አይደለም። በጸጋ የተሞላ ነው።', 'blessing-resting-am-4', [UserMood.sorrowful]),
  ],
};

final Set<String> _sessionUsedVariants = {};

void resetSessionVariants() {
  _sessionUsedVariants.clear();
}

_PoolEntry _selectFromPool(List<_PoolEntry> pool, UserMood? mood) {
  final moodMatch = mood != null
      ? pool.where((e) => e.moodAffinity?.contains(mood) ?? false).toList()
      : <_PoolEntry>[];
  final candidates = moodMatch.isNotEmpty ? moodMatch : pool;
  final unused = candidates.where((e) => !_sessionUsedVariants.contains(e.variant)).toList();
  final available = unused.isNotEmpty ? unused : candidates;
  final pick = available[Random().nextInt(available.length)];
  _sessionUsedVariants.add(pick.variant);
  return pick;
}

InvitationContent getInvitationText(ExperienceContext ctx, ExperienceIntent intent) {
  final en = _selectFromPool(_enInvitations[intent]!, ctx.userMood);
  final am = _selectFromPool(_amInvitations[intent]!, ctx.userMood);
  return InvitationContent(en: en.text, am: am.text, variant: en.variant);
}

BlessingContent getBlessingText(ExperienceContext ctx, ExperienceIntent intent) {
  final en = _selectFromPool(_enBlessings[intent]!, ctx.userMood);
  final am = _selectFromPool(_amBlessings[intent]!, ctx.userMood);
  return BlessingContent(en: en.text, am: am.text, variant: en.variant);
}

List<String> splitVerseIntoPhrases(String text, {bool isAmharic = false}) {
  final parts = text.split(RegExp(r'(?<=[.!?;—።፣])'));
  var raw = parts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  if (raw.length <= 1) {
    final commaParts = text.split(RegExp(r'(?<=,)'));
    raw = commaParts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  if (raw.length <= 1) {
    final words = text.split(' ').where((s) => s.isNotEmpty).toList();
    final groupSize = isAmharic ? 3 : 4;
    final groups = <String>[];
    for (int i = 0; i < words.length; i += groupSize) {
      groups.add(words.sublist(i, (i + groupSize).clamp(0, words.length)).join(' '));
    }
    return groups;
  }

  if (raw.length <= 8) return raw;

  final merged = <String>[];
  for (int i = 0; i < raw.length; i += 2) {
    final pair = [raw[i], i + 1 < raw.length ? raw[i + 1] : ''].where((s) => s.isNotEmpty).join(' ');
    merged.add(pair);
  }
  return merged;
}
