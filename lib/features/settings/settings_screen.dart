import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';
import '../../core/services/notification_service.dart';
import '../../core/providers/streak_provider.dart';

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
  String _reminderTime = '20:00';

  @override
  void initState() {
    super.initState();
    _loadReminderTime();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
  }

  Future<void> _loadReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _reminderTime = prefs.getString('reminderTime') ?? '20:00');
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
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/profile')), title: Text(l.settings)),
      body: ListView(controller: _scroll, padding: const EdgeInsets.all(20), children: [
        Text(key: _appearanceKey, l.appearance, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
          child: SwitchListTile(
            title: Text(l.darkMode, style: AppTextStyles.bodyMedium),
            subtitle: Text(isAm ? 'የጨለማ/የብርሃን ሁነታን ቀይር' : 'Toggle light/dark theme', style: AppTextStyles.bodySmall),
            value: themeMode == ThemeMode.dark,
            onChanged: (val) => ref.read(themeModeProvider.notifier).toggle(),
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 16),
        Text(isAm ? 'ገጽታ' : 'Theme', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        _ThemePalettePicker(),
        const SizedBox(height: 24),
        Text(key: _languageKey, l.language, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
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
        Text(isAm ? '🕊️ የእረፍት ቀን' : '🕊️ Sabbath Rest', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
          child: userAsync.when(
            data: (user) => ListTile(
              leading: const Icon(Icons.weekend, color: AppColors.primary),
              title: Text(isAm ? 'የእረፍት ቀንህን ምረጥ' : 'Choose your rest day', style: AppTextStyles.bodyMedium),
              subtitle: Text(
                user.sabbathDay == -1
                    ? (isAm ? 'አልተመረጠም። እረፍት የሌለበት ቀን' : 'Not set — no rest day')
                    : (isAm ? _dayName(user.sabbathDay, isAm) : _dayName(user.sabbathDay, isAm)),
                style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
              trailing: Text(
                user.sabbathDay == -1 ? (isAm ? '--' : '--') : _dayName(user.sabbathDay, isAm),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              contentPadding: EdgeInsets.zero,
              onTap: () => _pickSabbathDay(context, ref, user),
            ),
            loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('$e'),
          ),
        ),
        const SizedBox(height: 24),
        Text(key: _remindersKey, l.reminders, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
          child: ListTile(
            leading: const Icon(Icons.access_time, color: AppColors.primary),
            title: Text(isAm ? 'ዕለታዊ ማሳሰቢያ' : 'Daily reading reminder', style: AppTextStyles.bodyMedium),
            subtitle: Text(isAm ? 'በየቀኑ ለማንበብ ያስታውስሃል' : 'Reminds you to read daily', style: AppTextStyles.bodySmall),
            trailing: Text(_reminderTime, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              final parts = _reminderTime.split(':');
              final initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? 20, minute: int.tryParse(parts[1]) ?? 0);
              final time = await showTimePicker(context: context, initialTime: initial);
              if (time != null) {
                final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('reminderTime', formatted);
                await NotificationService.scheduleDailyReminder(time.hour, time.minute);
                if (mounted) {
                  setState(() => _reminderTime = formatted);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isAm ? 'ማሳሰቢያ ተቀናብሯል በ$formatted' : 'Reminder set at $formatted'),
                    backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2),
                  ));
                }
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(key: _aboutKey, l.aboutApp, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ብስለት — Beslet', style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(isAm ? 'በአርባ ምንጭ ዩኒቨርሲቲ ውስጥ ላሉ ክርስቲያን ተማሪዎች የበጋ የ90 ቀን የመንፈሳዊ እድገት መተግበሪያ።' : 'A 90-day summer spiritual growth app for Christian students at Arba Minch University and beyond.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: c.textSecondary, height: 1.4)),
            const SizedBox(height: 12),
            Text('Made by Amanuel Lamesa', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: c.textMuted)),
            Text('Summer 2026 · v1.0', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: c.textMuted)),
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
        NotificationService.setLanguage(code == 'am');
        ref.invalidate(userProvider);
        if (context.mounted) {
          final l = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l.languageChanged, style: const TextStyle(fontFamily: 'Inter')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ));
        }
      },
    );
  }

  String _dayName(int day, bool isAm) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const amNames = ['ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ', 'እሁድ'];
    if (day < 0 || day > 6) return isAm ? 'አልተመረጠም' : 'Not set';
    return isAm ? amNames[day] : names[day];
  }

  Future<void> _pickSabbathDay(BuildContext context, WidgetRef ref, User user) async {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final day = await showDialog<int>(
      context: context,
      builder: (ctx) {
          final cc = AppColors.of(ctx);
          return SimpleDialog(
            backgroundColor: cc.card,
            title: Text(isAm ? 'የእረፍት ቀንህን ምረጥ' : 'Choose your rest day', style: AppTextStyles.labelLarge),
            children: List.generate(8, (i) {
              if (i == 7) {
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, -1),
                  child: Text(isAm ? 'የለም (የእረፍት ቀን የለም)' : 'None (no rest day)',
                      style: AppTextStyles.bodyMedium.copyWith(color: cc.textMuted)),
                );
              }
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, i),
                child: Text('${_dayName(i, isAm)}${i == 6 ? (isAm ? ' (እሁድ)' : ' (Sunday)') : ''}',
                    style: AppTextStyles.bodyMedium),
              );
            }),
          );
        },
    );
    if (day != null && day != user.sabbathDay) {
      final db = ref.read(databaseProvider);
      await db.update(db.users).replace(user.copyWith(sabbathDay: day));
      ref.invalidate(userProvider);
      ref.invalidate(streakStateProvider);
    }
  }
}

// ─── Theme Palette Picker ─────────────────────────────────────
class _ThemePalettePicker extends ConsumerWidget {
  @override Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themePaletteProvider);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final opt in AppThemeOption.values)
            _PaletteChip(
              option: opt,
              isSelected: opt == selected,
              label: isAm ? _paletteNameAm(opt) : _paletteNameEn(opt),
              onTap: () => ref.read(themePaletteProvider.notifier).select(opt),
            ),
        ]),
      ]),
    );
  }

  String _paletteNameEn(AppThemeOption opt) => switch (opt) {
    AppThemeOption.classic => 'Classic Gold',
    AppThemeOption.sepia => 'Sepia Warm',
    AppThemeOption.calmBlue => 'Calm Blue',
    AppThemeOption.forestGreen => 'Forest Green',
    AppThemeOption.midnight => 'Midnight',
  };

  String _paletteNameAm(AppThemeOption opt) => switch (opt) {
    AppThemeOption.classic => 'ክላሲክ ወርቅ',
    AppThemeOption.sepia => 'ሴፒያ',
    AppThemeOption.calmBlue => 'ሰላማዊ ሰማያዊ',
    AppThemeOption.forestGreen => 'ደን አረንጓዴ',
    AppThemeOption.midnight => 'እኩለ ሌሊት',
  };
}

class _PaletteChip extends StatelessWidget {
  final AppThemeOption option;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;
  const _PaletteChip({required this.option, required this.isSelected, required this.label, required this.onTap});

  @override Widget build(BuildContext context) {
    final c = AppColors.of(context, option: option);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? c.primary : c.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected ? c.primary : c.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
