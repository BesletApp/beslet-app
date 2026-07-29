import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final localeCode = ref.watch(localeCodeProvider);
    final l = AppLocalizations.of(context)!;
    final isAm = localeCode == 'am';
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')), title: Text(l.settings)),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.appearance, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          const _ThemePalettePicker(),
          const SizedBox(height: 16),
          Text(l.language, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: Column(children: [
              _langTile(context, ref, 'en', l.english, '🇬🇧', localeCode),
              const Divider(height: 1),
              _langTile(context, ref, 'am', l.amharic, '🇪🇹', localeCode),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _langTile(BuildContext context, WidgetRef ref, String code, String label, String flag, String currentCode) {
    final isSelected = currentCode == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.success) : null,
      contentPadding: EdgeInsets.zero,
      onTap: isSelected ? null : () {
        saveLocale(code);
        ref.read(localeCodeProvider.notifier).state = code;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.languageChanged, style: const TextStyle(fontFamily: 'Inter')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ));
        }
      },
    );
  }
}

class _ThemePalettePicker extends ConsumerWidget {
  const _ThemePalettePicker();

  @override Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themePaletteProvider);
    final isAm = ref.watch(localeCodeProvider) == 'am';
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
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
            Container(width: 28, height: 28, decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: isSelected ? c.primary : c.textSecondary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
