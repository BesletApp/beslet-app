import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/voice_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// Read-only view of the voice pipeline diagnostics. It is a support aid, never
/// a user-facing feature: it shows what the pipeline observed (permission
/// state, supported formats, durations, errors) without raw audio or keys.
class VoiceDiagnosticsScreen extends ConsumerStatefulWidget {
  const VoiceDiagnosticsScreen({super.key});

  @override
  ConsumerState<VoiceDiagnosticsScreen> createState() => _VoiceDiagnosticsScreenState();
}

class _VoiceDiagnosticsScreenState extends ConsumerState<VoiceDiagnosticsScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    final diagnostics = ref.watch(voiceDiagnosticsProvider);
    final text = diagnostics.toDebugString();
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l.voiceDiagnosticsTitle, style: AppTextStyles.labelLarge),
        actions: [
          IconButton(
            tooltip: l.voiceDiagnosticsCopy,
            icon: const Icon(Icons.copy_outlined, size: 20),
            onPressed: () async {
              await _copy(text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l.voiceDiagnosticsCopied, style: AppTextStyles.bodyMedium),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border.withValues(alpha: 0.3)),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                height: 1.6,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copy(String text) async {
    try {
      await SystemChannels.platform.invokeMethod<void>(
        'Clipboard.setData',
        {'text': text},
      );
    } catch (_) {
      // Clipboard unavailable on some platforms; copying is best-effort.
    }
  }
}