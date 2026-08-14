import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
/// Returns `'saved'` when a key was stored, `'removed'` when one was cleared,
/// or `null` when the dialog was dismissed without a change.
Future<String?> showGeminiKeyDialog(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final keyStore = ref.read(aiKeyStoreProvider);
        return FutureBuilder<String?>(
          future: keyStore.readUserKey(),
          builder: (ctx, snap) {
            final key = snap.data;
            final connected = key != null && key.trim().isNotEmpty;
            final cc = AppColors.of(ctx);
            return AlertDialog(
              backgroundColor: cc.card,
              title: Text(l.aiKeyDialogTitle, style: AppTextStyles.labelLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.aiKeyDialogBody,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: cc.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: l.aiKeyPlaceholder,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: () => launchUrl(
                        Uri.parse('https://aistudio.google.com/apikey')),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l.aiKeyOpenStudio,
                        style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
              actions: [
                if (connected)
                  TextButton(
                    onPressed: () async {
                      await keyStore.clearUserKey();
                      if (ctx.mounted) Navigator.of(ctx).pop('removed');
                    },
                    child: Text(l.aiKeyRemove,
                        style: TextStyle(color: AppColors.warning)),
                  ),
                TextButton(
                  onPressed: () async {
                    if (controller.text.trim().isNotEmpty) {
                      await keyStore.saveUserKey(controller.text);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop('saved');
                  },
                  child: Text(l.aiKeySave),
                ),
              ],
            );
          },
        );
      },
    ),
  ).whenComplete(controller.dispose);
}