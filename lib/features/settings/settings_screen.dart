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
import '../../core/services/vineyard_reminder_service.dart';
import '../../core/services/vineyard_reminder_content.dart';
import '../../core/services/vine_chime_service.dart';
import '../../core/providers/streak_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/zone_layout.dart';

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
  final _voiceKey = GlobalKey();
  final _remindersKey = GlobalKey();
  final _aboutKey = GlobalKey();
  String _reminderTime = '20:00';
  bool _visitsEnabled = false;
  String _visitsFrequency = 'gentle';
  String _visitsWindow = 'evening';
  bool _chimeEnabled = false;
  String _voice = 'warm';

  @override
  void initState() {
    super.initState();
    _loadReminderTime();
    _loadVisits();
    _loadVoice();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
  }

  Future<void> _loadReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _reminderTime = prefs.getString('reminderTime') ?? '20:00');
  }

  Future<void> _loadVisits() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _visitsEnabled = prefs.getBool('vineyardVisitsEnabled') ?? false;
      _visitsFrequency = prefs.getString('vineyardVisitsFrequency') ?? 'gentle';
      _visitsWindow = prefs.getString('vineyardVisitsWindow') ?? 'evening';
      _chimeEnabled = prefs.getBool('vineChimeEnabled') ?? false;
    });
  }

  Future<void> _loadVoice() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _voice = prefs.getString('voice') ?? 'warm');
  }

  Future<void> _setVoice(String value) async {
    setState(() => _voice = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice', value);
  }

  String _visitsModeLabel(bool isAm) {
    final l = AppLocalizations.of(context)!;
    if (!_visitsEnabled) return l.visitsOff;
    final freq = _visitsFrequency == 'attentive' ? l.visitsAttentive : l.visitsGentle;
    final window = _visitsWindow == 'morning' ? l.windowMorning : l.windowEvening;
    return '$freq Â· $window';
  }

  Future<void> _pickVineyardVisits(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Material(
        color: AppColors.of(context).background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.vineyardVisits, style: AppTextStyles.displaySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(l.vineyardVisitsSubtitle,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                _visitsOption(sheet, 'off', l.visitsOff, !_visitsEnabled),
                _visitsOption(sheet, 'gentle', l.visitsGentle, _visitsEnabled && _visitsFrequency == 'gentle'),
                _visitsOption(sheet, 'attentive', l.visitsAttentive, _visitsEnabled && _visitsFrequency == 'attentive'),
                const Divider(height: 24),
                Text(l.visitWindow,
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.of(context).textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                _windowOption(sheet, 'evening', l.windowEvening, _visitsWindow == 'evening'),
                _windowOption(sheet, 'morning', l.windowMorning, _visitsWindow == 'morning'),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    final kind = result.$1;
    final value = result.$2;
    if (kind == 'freq') {
      final enabled = value != 'off';
      setState(() {
        _visitsEnabled = enabled;
        if (enabled) _visitsFrequency = value;
      });
      if (!enabled) {
        await VineyardReminderService.setEnabled(false);
      } else {
        await VineyardReminderService.setFrequency(
          value == 'attentive' ? ReminderFrequency.attentive : ReminderFrequency.gentle,
        );
        await VineyardReminderService.setEnabled(true);
      }
    } else {
      setState(() => _visitsWindow = value);
      await VineyardReminderService.setWindow(value == 'morning');
    }
  }

  Widget _visitsOption(BuildContext context, String value, String label, bool selected) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.primary : AppColors.of(context).textMuted,
      ),
      title: Text(label, style: AppTextStyles.bodyMedium),
      onTap: () => Navigator.of(context).pop(('freq', value)),
    );
  }

  Widget _windowOption(BuildContext context, String value, String label, bool selected) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.primary : AppColors.of(context).textMuted,
      ),
      title: Text(label, style: AppTextStyles.bodyMedium),
      onTap: () => Navigator.of(context).pop(('window', value)),
    );
  }

  Widget _voiceChip(String value, String label) {
    final selected = _voice == value;
    return GestureDetector(
      onTap: () => _setVoice(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.of(context).border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.of(context).textSecondary,
          ),
        ),
      ),
    );
  }

  void _scrollToSection() {
    final key = switch (widget.section) {
      'appearance' => _appearanceKey,
      'language' => _languageKey,
      'voice' => _voiceKey,
      'reminders' => _remindersKey,
      'about' => _aboutKey,
      _ => null,
    };
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!, duration: const Duration(milliseconds: 300), alignment: 0.1, curve: Curves.easeInOut);
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
      body: SingleChildScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        child: ZoneLayout(
          orientation: Column(children: [
            Text(key: _appearanceKey, l.appearance, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
              child: SwitchListTile(
                title: Text(l.darkMode, style: AppTextStyles.bodyMedium),
                subtitle: Text(isAm ? 'á‹¨áŒ¨áˆˆáˆ›/á‹¨á‰¥áˆ­áˆƒáŠ• áˆáŠá‰³áŠ• á‰€á‹­áˆ­' : 'Toggle light/dark theme', style: AppTextStyles.bodySmall),
                value: themeMode == ThemeMode.dark,
                onChanged: (val) => ref.read(themeModeProvider.notifier).toggle(),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(isAm ? 'áŒˆáŒ½á‰³' : 'Theme', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            _ThemePalettePicker(),
          ]),
          primary: Column(children: [
            Text(key: _languageKey, l.language, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
              child: userAsync.when(
                data: (user) => Column(children: [
                  _langTile(context, ref, user, 'en', l.english, 'ðŸ‡¬ðŸ‡§'),
                  const Divider(height: 1),
                  _langTile(context, ref, user, 'am', l.amharic, 'ðŸ‡ªðŸ‡¹'),
                ]),
                loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('$e'),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(key: _voiceKey, l.settingsVoice, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.settingsVoiceSubtitle, style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                  _voiceChip('quiet', l.voiceQuiet),
                  _voiceChip('warm', l.voiceWarm),
                  _voiceChip('still', l.voiceStill),
                ]),
              ]),
            ),
          ]),
          support: Column(children: [
            Text(isAm ? 'ðŸ•Šï¸ á‹¨áŠ¥áˆ¨áá‰µ á‰€áŠ•' : 'ðŸ•Šï¸ Sabbath Rest', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
              child: userAsync.when(
                data: (user) => ListTile(
                  leading: const Icon(Icons.weekend, color: AppColors.primary),
                  title: Text(isAm ? 'á‹¨áŠ¥áˆ¨áá‰µ á‰€áŠ•áˆ…áŠ• áˆáˆ¨áŒ¥' : 'Choose your rest day', style: AppTextStyles.bodyMedium),
                  subtitle: Text(
                    user.sabbathDay == -1
                        ? (isAm ? 'áŠ áˆá‰°áˆ˜áˆ¨áŒ áˆá¢ áŠ¥áˆ¨áá‰µ á‹¨áˆŒáˆˆá‰ á‰µ á‰€áŠ•' : 'Not set â€” no rest day')
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
            SizedBox(height: AppSpacing.lg),
            Text(key: _remindersKey, l.reminders, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.access_time, color: AppColors.primary),
                    title: Text(isAm ? 'á‹•áˆˆá‰³á‹Š áˆ›áˆ³áˆ°á‰¢á‹«' : 'Daily reading reminder', style: AppTextStyles.bodyMedium),
                    subtitle: Text(isAm ? 'á‰ á‹¨á‰€áŠ‘ áˆˆáˆ›áŠ•á‰ á‰¥ á‹«áˆµá‰³á‹áˆµáˆƒáˆ' : 'Reminds you to read daily', style: AppTextStyles.bodySmall),
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
                        if (context.mounted) {
                          setState(() => _reminderTime = formatted);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isAm ? 'áˆ›áˆ³áˆ°á‰¢á‹« á‰°á‰€áŠ“á‰¥áˆ¯áˆ á‰ $formatted' : 'Reminder set at $formatted'),
                            backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2),
                          ));
                        }
                      }
                    },
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(Icons.eco, color: AppColors.primary),
                    title: Text(l.vineyardVisits, style: AppTextStyles.bodyMedium),
                    subtitle: Text(_visitsModeLabel(isAm), style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
                    trailing: Icon(
                      _visitsEnabled ? Icons.chevron_right : Icons.toggle_off_outlined,
                      color: _visitsEnabled ? AppColors.primary : c.textMuted,
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _pickVineyardVisits(context),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.self_improvement, color: AppColors.primary),
                    title: Text(l.vineSound, style: AppTextStyles.bodyMedium),
                    subtitle: Text(l.vineSoundSubtitle,
                        style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
                    value: _chimeEnabled,
                    onChanged: (value) async {
                      setState(() => _chimeEnabled = value);
                      await VineChime.setEnabled(value);
                      if (value) await VineChime.chime();
                    },
                  ),
                ],
              ),
            ),
          ]),
          anchor: Column(children: [
            Text(key: _aboutKey, l.aboutApp, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('á‰¥áˆµáˆˆá‰µ â€” Beslet', style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: AppSpacing.sm),
                Text(isAm ? 'á‰ áŠ áˆ­á‰£ áˆáŠ•áŒ­ á‹©áŠ’á‰¨áˆ­áˆ²á‰² á‹áˆµáŒ¥ áˆ‹áˆ‰ áŠ­áˆ­áˆµá‰²á‹«áŠ• á‰°áˆ›áˆªá‹Žá‰½ á‹¨á‰ áŒ‹ á‹¨90 á‰€áŠ• á‹¨áˆ˜áŠ•áˆáˆ³á‹Š áŠ¥á‹µáŒˆá‰µ áˆ˜á‰°áŒá‰ áˆªá‹«á¢' : 'A 90-day summer spiritual growth app for Christian students at Arba Minch University and beyond.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: c.textSecondary, height: 1.4)),
                const SizedBox(height: AppSpacing.sm),
                Text(l.madeByAmanuel, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: c.textMuted)),
                Text(l.versionTag, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: c.textMuted)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      launchUrl(Uri.parse('https://t.me/emnverse'), mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text(isAm ? 'áŠ áˆµá‰°á‹«á‹¨á‰µ áŠ¥áŠ“ áŠ áˆµá‰°á‹«á‹¨á‰µ' : 'Comment & Suggestions'),
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
        ),
      ),
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
    const amNames = ['áˆ°áŠž', 'áˆ›áŠ­áˆ°áŠž', 'áˆ¨á‰¡á‹•', 'áˆáˆ™áˆµ', 'áŠ áˆ­á‰¥', 'á‰…á‹³áˆœ', 'áŠ¥áˆá‹µ'];
    if (day < 0 || day > 6) return isAm ? 'áŠ áˆá‰°áˆ˜áˆ¨áŒ áˆ' : 'Not set';
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
            title: Text(isAm ? 'á‹¨áŠ¥áˆ¨áá‰µ á‰€áŠ•áˆ…áŠ• áˆáˆ¨áŒ¥' : 'Choose your rest day', style: AppTextStyles.labelLarge),
            children: List.generate(8, (i) {
              if (i == 7) {
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, -1),
                  child: Text(isAm ? 'á‹¨áˆˆáˆ (á‹¨áŠ¥áˆ¨áá‰µ á‰€áŠ• á‹¨áˆˆáˆ)' : 'None (no rest day)',
                      style: AppTextStyles.bodyMedium.copyWith(color: cc.textMuted)),
                );
              }
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, i),
                child: Text('${_dayName(i, isAm)}${i == 6 ? (isAm ? ' (áŠ¥áˆá‹µ)' : ' (Sunday)') : ''}',
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

// â”€â”€â”€ Theme Palette Picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ThemePalettePicker extends ConsumerWidget {
  @override Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themePaletteProvider);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
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
    AppThemeOption.classic => 'áŠ­áˆ‹áˆ²áŠ­ á‹ˆáˆ­á‰…',
    AppThemeOption.sepia => 'áˆ´á’á‹«',
    AppThemeOption.calmBlue => 'áˆ°áˆ‹áˆ›á‹Š áˆ°áˆ›á‹«á‹Š',
    AppThemeOption.forestGreen => 'á‹°áŠ• áŠ áˆ¨áŠ•áŒ“á‹´',
    AppThemeOption.midnight => 'áŠ¥áŠ©áˆˆ áˆŒáˆŠá‰µ',
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

