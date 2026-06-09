import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final String? section;
  const SettingsScreen({super.key, this.section});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _scroll = ScrollController();
  final _appearanceKey = GlobalKey();
  final _languageKey = GlobalKey();
  final _remindersKey = GlobalKey();
  final _aboutKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
  }

  void _scrollToSection() {
    final key = switch (widget.section) {
      'appearance' => _appearanceKey,
      'language' => _languageKey,
      'reminders' => _remindersKey,
      'about' => _aboutKey,
      _ => null,
    };
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!, duration: const Duration(milliseconds: 300), alignment: 0.1);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final userAsync = ref.watch(userProvider);
    final l = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/profile')), title: Text(l.settings)),
      body: ListView(controller: _scroll, padding: const EdgeInsets.all(20), children: [
        Text(key: _appearanceKey, l.appearance, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: SwitchListTile(
            title: Text(l.darkMode, style: AppTextStyles.bodyMedium),
            subtitle: Text(isAm ? 'የጨለማ/የብርሃን ሁነታን ቀይር' : 'Toggle light/dark theme', style: AppTextStyles.bodySmall),
            value: themeMode == ThemeMode.dark,
            onChanged: (val) => ref.read(themeModeProvider.notifier).toggle(),
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 24),
        Text(key: _languageKey, l.language, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: userAsync.when(
            data: (user) => Column(children: [
              _langTile(context, ref, user, 'en', l.english, '🇬🇧'),
              const Divider(height: 1),
              _langTile(context, ref, user, 'am', l.amharic, '🇪🇹'),
            ]),
            loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('$e'),
          ),
        ),
        const SizedBox(height: 24),
        Text(key: _remindersKey, l.reminders, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: ListTile(
            leading: const Icon(Icons.access_time, color: AppColors.primary),
            title: Text(isAm ? 'ዕለታዊ ማሳሰቢያ' : 'Daily reading reminder', style: AppTextStyles.bodyMedium),
            subtitle: Text(isAm ? 'በየቀኑ ለማንበብ ያስታውስሃል' : 'Reminds you to read daily', style: AppTextStyles.bodySmall),
            trailing: Text('20:00', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
              // notification service integration point
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(key: _aboutKey, l.aboutApp, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ብስለት — Beslet', style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(isAm ? 'በአርባ ምንጭ ዩኒቨርሲቲ ውስጥ ላሉ ክርስቲያን ተማሪዎች የበጋ የ90 ቀን የመንፈሳዊ እድገት መተግበሪያ።' : 'A 90-day summer spiritual growth app for Christian students at Arba Minch University and beyond.', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 12),
            Text('Made with love by Amanuel Lamesa · Computer Science, AMU', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted)),
            Text('Summer 2026 · v1.0', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  launchUrl(Uri.parse('https://t.me/emnverse'), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: Text(isAm ? 'አስተያየት እና አስተያየት' : 'Comment & Suggestions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _langTile(BuildContext context, WidgetRef ref, User user, String code, String label, String flag) {
    final isSelected = user.lang == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.success) : null,
      contentPadding: EdgeInsets.zero,
      onTap: isSelected ? null : () async {
        final db = ref.read(databaseProvider);
        await db.update(db.users).replace(user.copyWith(lang: code));
        ref.invalidate(userProvider);
      },
    );
  }
}
