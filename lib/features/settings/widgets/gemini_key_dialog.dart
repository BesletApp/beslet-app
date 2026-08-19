import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ai/study/gemini_study_backend.dart';
import '../../../core/ai/study/study_models.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// The single, shared dialog for connecting or removing a reader's own Gemini
/// key. Used both by the Settings screen and by the Study panel's "Add my
/// Gemini API key" action, so a key is always entered the same way through the
/// same `AiKeyStore`.
///
/// A key is **verified with a live probe before it is saved** — an invalid key
/// is never persisted, and a saved return value always means the key works and
/// the caller can immediately retry the study with it.
///
/// Returns `'saved'` when a key was verified and stored, `'removed'` when one
/// was cleared, or `null` when the dialog was dismissed without a change.
Future<String?> showGeminiKeyDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => _GeminiKeyDialog(controller: controller),
  ).whenComplete(controller.dispose);
}

class _GeminiKeyDialog extends ConsumerStatefulWidget {
  final TextEditingController controller;

  const _GeminiKeyDialog({required this.controller});

  @override
  ConsumerState<_GeminiKeyDialog> createState() => _GeminiKeyDialogState();
}

class _GeminiKeyDialogState extends ConsumerState<_GeminiKeyDialog> {
  bool _verifying = false;
  bool _hasConnectedKey = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConnectedState();
  }

  Future<void> _loadConnectedState() async {
    final store = ref.read(aiKeyStoreProvider);
    final key = await store.readUserKey();
    if (mounted) {
      setState(() => _hasConnectedKey = key != null && key.trim().isNotEmpty);
    }
  }

  Future<void> _verifyAndSave() async {
    final value = widget.controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.aiKeyInvalidEmpty);
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    var saved = false;
    try {
      await verifyGeminiKey(value);
      await ref.read(aiKeyStoreProvider).saveUserKey(value);
      saved = true;
    } catch (e) {
      final reason = e is StudyGeminiException
          ? e.reason
          : StudyUnavailability.server;
      if (mounted) {
        setState(() => _error = _errorMessage(context, reason));
      }
    }
    if (!mounted) return;
    setState(() => _verifying = false);
    if (saved) {
      // Show the brief "verified" confirmation, then close so the panel can
      // immediately retry the study with the verified key.
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) Navigator.of(context).pop('saved');
    }
  }

  String _errorMessage(BuildContext context, StudyUnavailability reason) {
    final l = AppLocalizations.of(context)!;
    switch (reason) {
      case StudyUnavailability.authInvalid:
        return l.aiKeyInvalid;
      case StudyUnavailability.offline:
        return '${l.aiKeyInvalid}: ${l.studyReasonOffline}';
      case StudyUnavailability.timeout:
        return '${l.aiKeyInvalid}: ${l.studyReasonTimeout}';
      case StudyUnavailability.rateLimited:
        return '${l.aiKeyInvalid}: ${l.studyReasonRateLimited}';
      case StudyUnavailability.server:
        return '${l.aiKeyInvalid}: ${l.studyReasonServer}';
      case StudyUnavailability.contentRejected:
        return l.aiKeyInvalid;
      case StudyUnavailability.none:
      case StudyUnavailability.capped:
        return l.aiKeyInvalid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cc = AppColors.of(context);
    return AlertDialog(
      backgroundColor: cc.card,
      title: Text(l.aiKeyDialogTitle, style: AppTextStyles.labelLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.aiKeyDialogBody,
              style:
                  AppTextStyles.bodySmall.copyWith(color: cc.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: widget.controller,
            obscureText: true,
            enabled: !_verifying,
            decoration: InputDecoration(
              hintText: l.aiKeyPlaceholder,
              isDense: true,
            ),
          ),
          if (_verifying) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(l.aiKeyVerifying,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: cc.textSecondary)),
            ]),
          ] else if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.warning)),
          ],
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: () => launchUrl(
                Uri.parse('https://aistudio.google.com/apikey')),
            icon: const Icon(Icons.open_in_new, size: 16),
            label:
                Text(l.aiKeyOpenStudio, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
      actions: [
        if (_hasConnectedKey)
          TextButton(
            onPressed: _verifying
                ? null
                : () async {
                    await ref.read(aiKeyStoreProvider).clearUserKey();
                    if (context.mounted) {
                      Navigator.of(context).pop('removed');
                    }
                  },
            child: Text(l.aiKeyRemove,
                style: TextStyle(color: AppColors.warning)),
          ),
        TextButton(
          onPressed: _verifying ? null : _verifyAndSave,
          child: Text(l.aiKeyVerify,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}