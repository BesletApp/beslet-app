import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final userAsync = ref.watch(userProvider);
    final l = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()), title: Text(l.settings)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(isAm ? 'መልክ' : 'Appearance', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
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
        Text(l.language, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
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
        Text(isAm ? 'ማሳሰቢያ' : 'Reminders', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
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
        Text(isAm ? 'ስለ መተግበሪያ' : 'About this app', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
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
