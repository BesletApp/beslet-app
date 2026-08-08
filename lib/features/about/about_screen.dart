import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const String _cbeAccount = '1000583215167';
  static const String _telegramUrl = 'https://t.me/emnverse';

  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  Future<void> _copyAccount() async {
    final l = AppLocalizations.of(context)!;
    await Clipboard.setData(const ClipboardData(text: _cbeAccount));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.accountCopied),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _openTelegram() async {
    final uri = Uri.parse(_telegramUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // No external handler — fall back to in-app browser silently.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/profile')),
        title: Text(l.aboutApp),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8, AppSpacing.screenPadding, AppSpacing.bottomPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.aboutBesletTitle, style: t.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          _paragraph(l.aboutPara1),
          const SizedBox(height: AppSpacing.sm),
          _paragraph(l.aboutPara2),
          const SizedBox(height: AppSpacing.sm),
          _paragraph(l.aboutPara3),
          if (_version != null) ...[
            const SizedBox(height: AppSpacing.md),
            _versionLine(l.aboutVersion(_version!)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(l.aboutSupportTitle, style: t.labelLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.sm),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _paragraph(l.aboutSupportBody),
            const SizedBox(height: AppSpacing.md),
            Text(l.aboutCbeAccount, style: t.labelLarge.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              Expanded(
                child: Text(
                  _cbeAccount,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: _copyAccount,
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l.copyAccountNumber),
              ),
            ]),
          ])),
          const SizedBox(height: AppSpacing.lg),
          Text(l.aboutFeedbackTitle, style: t.labelLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.sm),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _paragraph(l.aboutFeedbackBody),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openTelegram,
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: Text(l.aboutFeedbackTitle),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
              ),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _paragraph(String text) {
    final c = AppColors.of(context);
    return Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: c.textSecondary, height: 1.6));
  }

  Widget _versionLine(String text) {
    final c = AppColors.of(context);
    return Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: c.textMuted));
  }

  Widget _card(Widget child) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}