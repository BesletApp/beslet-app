import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/journal_provider.dart';
import '../../../l10n/app_localizations.dart';

/// A quiet, optional field at the end of the chapter: "What did you
/// understand?". Lightweight on purpose — it is encouragement, not a
/// requirement. The text is saved to today's Daily Journal, debounced so the
/// thought is not lost if the reader leaves without confirming.
class ReflectionInputField extends ConsumerStatefulWidget {
  final TextEditingController? controller;

  const ReflectionInputField({super.key, this.controller});

  @override
  ConsumerState<ReflectionInputField> createState() => _ReflectionInputFieldState();
}

class _ReflectionInputFieldState extends ConsumerState<ReflectionInputField> {
  late final TextEditingController _ctrl = widget.controller ?? TextEditingController();
  Timer? _debounce;
  bool _loaded = false;

  bool get isAm => Localizations.localeOf(context).languageCode == 'am';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    final entry = await ref.read(journalEntryProvider.future);
    if (!mounted || _loaded) return;
    _loaded = true;
    if (entry?.content != null && _ctrl.text.isEmpty) {
      _ctrl.text = entry!.content!;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      ref.read(journalNotifierProvider.notifier).saveEntry(_ctrl.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.whatDidYouUnderstand,
          style: AppTextStyles.labelLarge.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _ctrl,
          maxLines: 4,
          minLines: 2,
          style: AppTextStyles.bodyMedium,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: isAm ? 'አስተምህሮትህን ጻፍ...' : 'Write what you understood...',
            hintStyle: TextStyle(color: c.textMuted),
            filled: true,
            fillColor: c.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
