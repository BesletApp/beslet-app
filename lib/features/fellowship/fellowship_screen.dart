import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/fellowship_provider.dart';

class _Prompt {
  final String emoji;
  final String title;
  final String titleAm;
  final String message;
  final String messageAm;
  final bool shareable;
  const _Prompt({required this.emoji, required this.title, required this.titleAm, required this.message, required this.messageAm, this.shareable = true});
  String text(bool isAm) => isAm ? titleAm : title;
  String msg(bool isAm) => isAm ? messageAm : message;
}

const _prompts = [
  _Prompt(
    emoji: '📖', title: 'Send an encouraging verse', titleAm: 'አበረታች ጥቅስ ላክ',
    message: 'Hey! I was reading my Bible today and came across this verse — thought of you.\n\n"The Lord bless you and keep you; the Lord make his face shine on you and be gracious to you." — Numbers 6:24-25\n\nJust wanted to share. Hope it encourages you!',
    messageAm: 'ሰላም! ዛሬ መጽሐፍ ቅዱሴን ሳነብ ይህን ጥቅስ አገኘሁት — ስላንተ አሰብኩ።\n\n"እግዚአብሔር ይባርክህ ይጠብቅህም፤ እግዚአብሔር ፊቱን በአንተ ላይ ያብራ ይራራልህም።" — ዘኍልቍ 6:24-25\n\nላካፍላችሁ ፈለግሁ። ያበረታታችኋል ብዬ ተስፋ አደርጋለሁ!',
  ),
  _Prompt(
    emoji: '💝', title: 'Tell someone you appreciate them', titleAm: 'አመሰግናለሁ በል',
    message: 'Hey, just wanted to say — I really appreciate you. Thinking about all the ways you\'ve been a blessing in my life. Thank you for being you.',
    messageAm: 'ሰላም፣ ልነግርህ ፈልጌ ነበር — በእውነት አመሰግንሃለሁ። በሕይወቴ ውስጥ በረከት ሆነህ/ሽ በኖርህ/ሽ መንገዶች ሁሉ እያሰብኩ ነው። ስላንተ/ሽ አመሰግናለሁ።',
  ),
  _Prompt(
    emoji: '🤗', title: 'Check in on someone', titleAm: 'ሰላም በል',
    message: 'Hey! I was just thinking about you and wanted to check in — how are you doing? No pressure to reply, just wanted you to know I care.',
    messageAm: 'ሰላም! እያሰብኩህ/ሽ ነበርና ልጠይቅ ፈለግሁ — እንዴት ነህ/ነሽ? መልስ መስጠት ካልቻልህ/ሽ ደህና ነው፣ እንደምጨነቅልህ/ሽ ብቻ ልታውቅ ፈለግሁ።',
  ),
  _Prompt(
    emoji: '💡', title: 'Share what you\'re learning', titleAm: 'የምትማረውን አካፍል',
    message: 'Hey! I\'ve been reading in the Bible lately and something really stood out to me today. Made me think of you. Would love to hear your thoughts when you have time.',
    messageAm: 'ሰላም! በቅርቡ መጽሐፍ ቅዱስን እያነበብኩ ነበርና ዛሬ አንድ ነገር በእውነት ልቤን ነካው። ስላንተ/ሽ አስባለሁ። ጊዜ ሲኖርህ/ሽ አስተያየትህን/ሽ ብሰማ ደስ ይለኛል።',
  ),
  _Prompt(
    emoji: '🙏', title: 'Pray for someone and tell them', titleAm: 'ጸልይና ንገራቸው',
    message: 'Hey! Just wanted you to know I prayed for you today. God knows what\'s on your heart. Trusting Him with you.',
    messageAm: 'ሰላም! ዛሬ እንደጸለይኩልህ/ሽ ልታውቅ ፈለግሁ። እግዚአብሔር በልብህ/ሽ ላይ ያለውን ያውቃል። ከአንተ/አንቺ ጋር እተማመናለሁ።',
  ),
  _Prompt(
    emoji: '📞', title: 'Call a family member', titleAm: 'ቤተሰብህን ደውልላቸው',
    message: 'Hey! Just called to say hi and that I love you. No special reason — just thinking of you. Hope you\'re having a good day!',
    messageAm: 'ሰላም! ሰላም ልበል እና እንደምወድህ/ሽ ልነግርህ/ሽ ደውያለሁ። ምንም ልዩ ምክንያት የለም — እያሰብኩህ/ሽ ነው። መልካም ቀን እንዲሆንልህ/ሽ ተስፋ አደርጋለሁ!',
  ),
  _Prompt(
    emoji: '🕊️', title: 'Rest — reflect on blessings', titleAm: 'ዕረፍት — በረከቶችህን አሰላስል',
    message: 'Take a moment today to think about someone who has blessed you this week. A friend, a family member, a teacher, or someone you barely know. Let gratitude fill your heart.',
    messageAm: 'ዛሬ ትንሽ ጊዜ ወስደህ/ሽ በዚህ ሳምንት የባረከህ/ሽን ሰው አስብ። ጓደኛ፣ ቤተሰብ፣ አስተማሪ፣ ወይም ብዙም የማታውቀው ሰው። ልብህ/ሽ በምስጋና ይሞላ።',
    shareable: false,
  ),
];

int _todayPromptIndex() {
  final wd = DateTime.now().weekday;
  return wd - 1;
}

class FellowshipScreen extends ConsumerWidget {
  const FellowshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayFellowshipProvider);
    final weeklyCountAsync = ref.watch(weeklyFellowshipCountProvider);
    final todayLog = todayAsync.valueOrNull;
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final idx = _todayPromptIndex();
    final prompt = _prompts[idx];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        title: Text(isAm ? 'በርናባስ' : 'Barnabas'),
      ),
      body: RefreshIndicator(
        onRefresh: () async { ref.invalidate(todayFellowshipProvider); ref.invalidate(weeklyFellowshipCountProvider); },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _buildMissionCard(context, prompt, todayLog, ref, isAm, c),
            const SizedBox(height: 24),
            _buildWeeklyCount(weeklyCountAsync.valueOrNull ?? 0, c, isAm),
          ]),
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context, _Prompt prompt, FellowshipLog? todayLog, WidgetRef ref, bool isAm, ThemePalette c) {
    final done = todayLog != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientGoldSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(prompt.emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Text(isAm ? 'የዛሬ ተልእኮ' : 'Today\'s Mission', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        const SizedBox(height: 12),
        Text(prompt.text(isAm), style: AppTextStyles.displaySmall.copyWith(fontSize: 20, color: AppColors.of(context).textPrimary)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.of(context).card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 2)),
          ),
          child: Text(
            prompt.msg(isAm),
            style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: AppColors.of(context).textSecondary, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        if (done)
          _buildDoneState(context, prompt, todayLog, ref, isAm, c)
        else
          _buildActionButtons(context, prompt, ref, isAm, c),
      ]),
    );
  }

  Widget _buildActionButtons(BuildContext context, _Prompt prompt, WidgetRef ref, bool isAm, ThemePalette c) {
    return Column(children: [
      if (prompt.shareable) ...[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 16),
            label: Text(isAm ? 'ላክኩ & መዝገብ 🙌' : 'Share & Log 🙌', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            onPressed: () {
              SharePlus.instance.share(ShareParams(text: prompt.msg(isAm)));
              ref.read(fellowshipNotifierProvider.notifier).logConnection(promptType: _todayPromptIndex());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF07090E),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: Icon(Icons.check, size: 16),
          label: Text(isAm ? 'ተከናውኗል ብቻ' : 'Just Log It', style: const TextStyle(fontSize: 13)),
          onPressed: () => ref.read(fellowshipNotifierProvider.notifier).logConnection(promptType: _todayPromptIndex()),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildDoneState(BuildContext context, _Prompt prompt, FellowshipLog todayLog, WidgetRef ref, bool isAm, ThemePalette c) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.progressGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.progressGreen.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 18, color: AppColors.progressGreen),
          const SizedBox(width: 8),
          Text(isAm ? 'ተከናውኗል! +5 XP' : 'Done! +5 XP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.progressGreen)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (prompt.shareable)
          TextButton.icon(
            icon: const Icon(Icons.replay, size: 16),
            label: Text(isAm ? 'እንደገና ላክ' : 'Share Again', style: const TextStyle(fontSize: 12)),
            onPressed: () => SharePlus.instance.share(ShareParams(text: prompt.msg(isAm))),
          ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.undo, size: 16),
          label: Text(isAm ? 'ቀልብስ' : 'Undo', style: TextStyle(fontSize: 12, color: AppColors.error)),
          onPressed: () => ref.read(fellowshipNotifierProvider.notifier).removeToday(),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ]),
    ]);
  }

  Widget _buildWeeklyCount(int count, ThemePalette c, bool isAm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.2), border: Border.all(color: AppColors.primary.withValues(alpha: 0.5))),
          child: const Center(child: Text('📅', style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isAm ? 'ይህ ሳምንት' : 'This Week', style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
            const SizedBox(height: 4),
            Text(isAm ? '$count ቀናት' : '$count days', style: AppTextStyles.displaySmall.copyWith(fontSize: 24)),
          ]),
        ),
      ]),
    );
  }
}
