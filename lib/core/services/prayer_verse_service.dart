import 'scripture_service.dart';

class PrayerVerseService {
  static final List<Scripture> _prayerVerses = [
    Scripture(reference: '1 ተሰሎንቄ 5:17', text: '', textAm: 'ያለማቋረጥ ጸልዩ።'),
    Scripture(reference: 'ፊልጵስዩስ 4:6', text: '', textAm: 'በነገር ሁሉ በጸሎትና በልመና ምስጋናችሁን ለእግዚአብሔር ግለጡ።'),
    Scripture(reference: 'መዝሙር 145:18', text: '', textAm: 'እግዚአብሔር ወደሚጠሩት ሁሉ ቅርብ ነው።'),
    Scripture(reference: 'ማቴዎስ 7:7', text: '', textAm: 'ለምኑ ይሰጣችኋልና፤ ፈልጉ ታገኛላችሁና፤ አንኳኩ ይከፈትላችኋልና።'),
    Scripture(reference: 'ዮሐንስ 15:7', text: '', textAm: 'በእኔ ብትኖሩ ቃሎቼም በእናንተ ቢኖሩ የምትወዱትን ሁሉ ለምኑ ይሆንላችኋልና።'),
    Scripture(reference: '1 ዮሐንስ 5:14', text: '', textAm: 'በእርሱ ዘንድ ያለን መታመን ይህ ነው፤ እንደ ፈቃዱ ማንኛውንም ነገር ብንለምን ይሰማናል።'),
    Scripture(reference: 'ኤርምያስ 33:3', text: '', textAm: 'ጩኸት ወደ እኔ እርሳ እመልስልሃለሁ፤ የማታውቀውን ታላቅና ልቅ የሆነን ነገር እነግርሃለሁ።'),
    Scripture(reference: 'መዝሙር 34:17', text: '', textAm: 'ጻድቃን ጮኹ እግዚአብሔርም ሰማቸው፥ ከመከራቸውም ሁሉ አዳናቸው።'),
    Scripture(reference: 'መዝሙር 86:6', text: '', textAm: 'ጸሎቴን አድምጥ አቤቱ ልመናዬንም አስተውል።'),
    Scripture(reference: 'ማቴዎስ 21:22', text: '', textAm: 'የምትለምኑትንም ሁሉ በማመን ብትቀበሉ ታገኙታላችሁ።'),
    Scripture(reference: 'ሉቃስ 11:9', text: '', textAm: 'ለምኑ ይሰጣችሁላልና፤ ፈልጉ ታገኛላችሁና፤ አንኳኩ ይከፈትላችኋልና።'),
    Scripture(reference: '2 ዜና መዋዕል 7:14', text: '', textAm: 'ሕዝቤ የሚጠሩ ቢጸልዩ ፊቴንም ቢሹ ከክፉ መንገዳቸውም ቢመለሱ ከሰማይ እሰማለሁ።'),
    Scripture(reference: 'መዝሙር 5:3', text: '', textAm: 'ጠዋት ጸሎቴን ታደርጋለህ፥ ጠዋትም ላንተ እጸልያለሁ።'),
    Scripture(reference: 'መዝሙር 55:17', text: '', textAm: 'ማታ ጠዋት ቀትር እጮሃለሁ ወይም እጸልያለሁ፥ እርሱም ድምፄን ይሰማል።'),
    Scripture(reference: 'መዝሙር 66:19', text: '', textAm: 'እግዚአብሔር ግን ሰምቶአል፥ የጸሎቴንም ድምፅ አድምጦአል።'),
  ];

  static Scripture getPrayerVerse(int dayIndex) {
    return _prayerVerses[dayIndex % _prayerVerses.length];
  }

  static int get verseCount => _prayerVerses.length;
}
