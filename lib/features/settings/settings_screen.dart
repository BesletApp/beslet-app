import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/gemini_key_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/database/app_database.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/vineyard_reminder_service.dart';
import '../../core/services/vineyard_reminder_content.dart';
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
  final _remindersKey = GlobalKey();
  String _reminderTime = '20:00';
  bool _visitsEnabled = false;
  String _visitsFrequency = 'gentle';
  String _visitsWindow = 'evening';
  bool _aiKeyConnected = false;

  @override
  void initState() {
    super.initState();
    _loadReminderTime();
    _loadVisits();
    _loadAiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
  }

  Future<void> _loadAiKey() async {
    final keyStore = ref.read(aiKeyStoreProvider);
    final key = await keyStore.readUserKey();
    if (!mounted) return;
    setState(() => _aiKeyConnected = key != null && key.trim().isNotEmpty);
  }

  /// Quietly lets an advanced user connect their own Gemini key. Optional —
  /// the bundled free-tier key is the default. Never prominent.
  Future<void> _manageAiKey(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showGeminiKeyDialog(context);
    if (result == null || !context.mounted) return;
    await _loadAiKey();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result == 'saved' ? l10n.aiKeySaved : l10n.aiKeyRemoved,
          style: const TextStyle(fontFamily: 'Inter')),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
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
    });
  }

  String _visitsModeLabel() {
    final l = AppLocalizations.of(context)!;
    if (!_visitsEnabled) return l.visitsOff;
    final freq = _visitsFrequency == 'attentive' ? l.visitsAttentive : l.visitsGentle;
    final window = _visitsWindow == 'morning' ? l.windowMorning : l.windowEvening;
    return '$freq · $window';
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

  void _scrollToSection() {
    final key = switch (widget.section) {
      'appearance' => _appearanceKey,
      'language' => _languageKey,
      'reminders' => _remindersKey,
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
                subtitle: Text(l.darkModeToggle, style: AppTextStyles.bodySmall),
                value: themeMode == ThemeMode.dark,
                onChanged: (val) => ref.read(themeModeProvider.notifier).toggle(),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(l.settingsTheme, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
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
                  _langTile(context, ref, user, 'en', l.english, '🇺🇸'),
                  const Divider(height: 1),
                  _langTile(context, ref, user, 'am', l.amharic, '🇪🇹'),
                ]),
                loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('$e'),
              ),
            ),
          ]),
          support: Column(children: [
            Text(l.sabbathRest, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
              child: userAsync.when(
                data: (user) => ListTile(
                  leading: const Icon(Icons.weekend, color: AppColors.primary),
                  title: Text(l.chooseRestDay, style: AppTextStyles.bodyMedium),
                  subtitle: Text(
                    user.sabbathDay == -1
                        ? l.restDayNotSet
                        : _dayName(user.sabbathDay),
                    style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
                  trailing: Text(
                    user.sabbathDay == -1 ? '--' : _dayName(user.sabbathDay),
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
                    title: Text(l.dailyReadingReminder, style: AppTextStyles.bodyMedium),
                    subtitle: Text(l.remindsToReadDaily, style: AppTextStyles.bodySmall),
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
                            content: Text(l.reminderSetAt(formatted)),
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
                    subtitle: Text(_visitsModeLabel(), style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
                    trailing: Icon(
                      _visitsEnabled ? Icons.chevron_right : Icons.toggle_off_outlined,
                      color: _visitsEnabled ? AppColors.primary : c.textMuted,
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _pickVineyardVisits(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(l.aiKeyTitle, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: ListTile(
                leading: const Icon(Icons.key, color: AppColors.primary),
                title: Text(l.aiKeyConnect, style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  _aiKeyConnected ? l.aiKeyConnected : l.aiKeyBuiltIn,
                  style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
                trailing: Icon(Icons.chevron_right, color: c.textMuted, size: 18),
                contentPadding: EdgeInsets.zero,
                onTap: () => _manageAiKey(context),
              ),
            ),
          ]),
          anchor: Column(children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.of(context).border, width: 0.5),
              ),
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                title: Text(l.aboutApp, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.of(context).textPrimary)),
                trailing: Icon(Icons.chevron_right, color: AppColors.of(context).textMuted, size: 18),
                onTap: () => context.go('/about'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                dense: true,
              ),
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

  String _dayName(int day) {
    final l = AppLocalizations.of(context)!;
    if (day < 0 || day > 6) return l.dayNotSet;
    return switch (day) {
      0 => l.dayMonday,
      1 => l.dayTuesday,
      2 => l.dayWednesday,
      3 => l.dayThursday,
      4 => l.dayFriday,
      5 => l.daySaturday,
      _ => l.daySunday,
    };
  }

  Future<void> _pickSabbathDay(BuildContext context, WidgetRef ref, User user) async {
    final l = AppLocalizations.of(context)!;
    final day = await showDialog<int>(
      context: context,
      builder: (ctx) {
          final cc = AppColors.of(ctx);
          return SimpleDialog(
            backgroundColor: cc.card,
            title: Text(l.chooseRestDay, style: AppTextStyles.labelLarge),
            children: List.generate(8, (i) {
              if (i == 7) {
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, -1),
                  child: Text(l.noneRestDay,
                      style: AppTextStyles.bodyMedium.copyWith(color: cc.textMuted)),
                );
              }
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, i),
                child: Text('${_dayName(i)}${i == 6 ? l.sundayInParen : ''}',
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

// ─── Theme Palette Picker ───
class _ThemePalettePicker extends ConsumerWidget {
  @override Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themePaletteProvider);
    final l = AppLocalizations.of(context)!;
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
              label: _paletteName(l, opt),
              onTap: () => ref.read(themePaletteProvider.notifier).select(opt),
            ),
        ]),
      ]),
    );
  }

  String _paletteName(AppLocalizations l, AppThemeOption opt) => switch (opt) {
    AppThemeOption.classic => l.paletteClassic,
    AppThemeOption.sepia => l.paletteSepia,
    AppThemeOption.calmBlue => l.paletteCalmBlue,
    AppThemeOption.forestGreen => l.paletteForestGreen,
    AppThemeOption.midnight => l.paletteMidnight,
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