import 'package:flutter/material.dart';
import '../../core/services/scripture_service.dart';
import '../../l10n/app_localizations.dart';

/// A quiet posture of prayer. Not rooms to manage — just the four ways the
/// Word invites us to turn to God: repent, give thanks, ask, and rest.
class PrayerMode {
  final String id;
  final IconData icon;
  final List<Scripture> verses;
  const PrayerMode({
    required this.id,
    required this.icon,
    required this.verses,
  });
}

const List<Scripture> _repentVerses = [
  Scripture(
    reference: 'Psalm 51:10',
    text: 'Create in me a pure heart, O God, and renew a steadfast spirit within me.',
    textAm: 'አምላክ ሆይ፣ ንጹሕ ልብ ፍጠርልኝ፤ በውስጤም የጸና መንፈስ አድስ።',
  ),
  Scripture(
    reference: '1 John 1:9',
    text: 'If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness.',
    textAm: 'ኃጢአታችንን ብንናዘዝ፣ እርሱ ታማኝና ጻድቅ ነውና ኃጢአታችንን ይቅር ይለናል፤ ከኀጢአትም ሁሉ ያነጻናል።',
  ),
  Scripture(
    reference: 'Psalm 32:5',
    text: 'Then I acknowledged my sin to you and did not cover up my iniquity. And you forgave the guilt of my sin.',
    textAm: 'ኃጢአቴን ለአንተ አውቄ ነበር፤ በደሌንም አልደበቅሁም። የኃጢአቴን በደል ይቅር አልከኝ።',
  ),
  Scripture(
    reference: 'Isaiah 1:18',
    text: 'Come now, let us settle the matter. Though your sins are like scarlet, they shall be as white as snow.',
    textAm: 'ኑ፣ ተሻሻሉ ይላል እግዚአብሔር። ኃጢአታችሁ እንደ ቀይ ቀለም ቢሆንም፣ እንደ በረዶ ነጭ ትሆናለች።',
  ),
];

const List<Scripture> _thanksVerses = [
  Scripture(
    reference: '1 Thessalonians 5:18',
    text: 'Give thanks in all circumstances; for this is God\'s will for you in Christ Jesus.',
    textAm: 'በሁሉ ነገር አመስግኑ፤ ይህ በክርስቶስ ኢየሱስ ለእናንተ የእግዚአብሔር ፈቃድ ነውና።',
  ),
  Scripture(
    reference: 'Psalm 100:4',
    text: 'Enter his gates with thanksgiving and his courts with praise; give thanks to him and praise his name.',
    textAm: 'በምስጋና ወደ በሮቹ፣ በውዳሴም ወደ አደባባዮቹ ግቡ፤ አመስግኑት፣ ስሙንም ባርኩ።',
  ),
  Scripture(
    reference: 'Psalm 107:1',
    text: 'Give thanks to the Lord, for he is good; his love endures forever.',
    textAm: 'እግዚአብሔርን አመስግኑ፤ እርሱ መልካም ነውና፤ ቸርነቱ ለዘላለም ይኖራልና።',
  ),
  Scripture(
    reference: 'Psalm 118:24',
    text: 'This is the day that the Lord has made; let us rejoice and be glad in it.',
    textAm: 'ይህች እግዚአብሔር የሠራት ቀን ናት፤ በእርሷ ደስ ይበለን፣ እንደሰት።',
  ),
];

const List<Scripture> _askVerses = [
  Scripture(
    reference: 'Matthew 7:7',
    text: 'Ask and it will be given to you; seek and you will find; knock and the door will be opened to you.',
    textAm: 'ለምኑ፣ ይሰጣችኋል፤ ፈልጉ፣ ታገኛላችሁ፤ አንኳኩ፣ ይከፈትላችኋል።',
  ),
  Scripture(
    reference: 'Jeremiah 33:3',
    text: 'Call to me and I will answer you and tell you great and unsearchable things you do not know.',
    textAm: 'ጥራኝ፣ እመልስልሃለሁ፤ የማታውቃቸውን ታላላቅና የተደበቁ ነገሮችን እነግርሃለሁ።',
  ),
  Scripture(
    reference: 'Philippians 4:6',
    text: 'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.',
    textAm: 'በምንም ነገር አትጨነቁ፤ ነገር ግን በነገር ሁሉ በጸሎትና በልመና ከምስጋና ጋር ልመናችሁን ለእግዚአብሔር አሳውቁ።',
  ),
  Scripture(
    reference: 'James 1:5',
    text: 'If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault.',
    textAm: 'ከእናንተ ማንም ጥበብ ቢጎድለው፣ ለሁሉ ሳይነቀፍ በልግስና ከሚሰጥ እግዚአብሔር ይለምን፣ ይሰጠዋልም።',
  ),
];

const List<Scripture> _restVerses = [
  Scripture(
    reference: 'Matthew 11:28',
    text: 'Come to me, all you who are weary and burdened, and I will give you rest.',
    textAm: 'የደከማችሁና ሸክም የተሸከማችሁ ሁሉ፣ ወደ እኔ ኑ፣ እኔም ያሳርፋችኋለሁ።',
  ),
  Scripture(
    reference: 'Psalm 46:10',
    text: 'Be still, and know that I am God.',
    textAm: 'ጸጥ ብላችሁ፣ እኔ አምላክ መሆኔን እወቁ።',
  ),
  Scripture(
    reference: 'Isaiah 26:3',
    text: 'You will keep in perfect peace those whose minds are steadfast, because they trust in you.',
    textAm: 'በአንተ ላይ ያመኑትንና አእምሯቸውን ባንተ ያጸኑትን በፍጹም ሰላም ትጠብቃለህ።',
  ),
  Scripture(
    reference: 'Psalm 23:1-2',
    text: 'The Lord is my shepherd, I lack nothing. He makes me lie down in green pastures.',
    textAm: 'እግዚአብሔር እረኛዬ ነው፤ የሚጎድለኝ ነገር የለም። በለመለመ መስክ ያሳድረኛል።',
  ),
];

/// The four postures of prayer. Their order is the rhythm of the Word:
/// confess first, give thanks as you enter, present your requests, then rest.
const List<PrayerMode> prayerModes = [
  PrayerMode(id: 'repent', icon: Icons.cleaning_services_outlined, verses: _repentVerses),
  PrayerMode(id: 'thanks', icon: Icons.volunteer_activism_outlined, verses: _thanksVerses),
  PrayerMode(id: 'ask', icon: Icons.record_voice_over_outlined, verses: _askVerses),
  PrayerMode(id: 'rest', icon: Icons.self_improvement_outlined, verses: _restVerses),
];

/// A verse for the day, rotating gently through each mode's small collection.
Scripture verseForMode(PrayerMode mode, DateTime date) {
  final idx = date.difference(DateTime(2025, 1, 1)).inDays;
  return mode.verses[idx % mode.verses.length];
}

/// The mode's name in the user's language.
String modeLabel(AppLocalizations l, PrayerMode mode) {
  switch (mode.id) {
    case 'repent':
      return l.modeRepent;
    case 'thanks':
      return l.modeThanks;
    case 'ask':
      return l.modeAsk;
    case 'rest':
      return l.modeRest;
    default:
      return mode.id;
  }
}

/// One quiet line guiding each posture — a gentle description, not a script.
String modeGuide(AppLocalizations l, PrayerMode mode) {
  switch (mode.id) {
    case 'repent':
      return l.modeGuideRepent;
    case 'thanks':
      return l.modeGuideThanks;
    case 'ask':
      return l.modeGuideAsk;
    case 'rest':
      return l.modeGuideRest;
    default:
      return mode.id;
  }
}
