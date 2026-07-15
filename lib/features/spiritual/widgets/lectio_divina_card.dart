import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/bible_session_provider.dart';

class LectioDivinaCard extends ConsumerStatefulWidget {
  final String bookId;
  final int chapter;
  final bool isAm;
  final String? planDay;
  final VoidCallback? onDone;
  final TextEditingController? reflectController;

  const LectioDivinaCard({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.isAm,
    this.planDay,
    this.onDone,
    this.reflectController,
  });

  @override
  ConsumerState<LectioDivinaCard> createState() => _LectioDivinaCardState();
}

class _LectioDivinaCardState extends ConsumerState<LectioDivinaCard> {
  final _reflectCtrl = TextEditingController();
  final _applyCtrl = TextEditingController();
  final _prayCtrl = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _reflectCtrl.dispose();
    _applyCtrl.dispose();
    _prayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isAm = widget.isAm;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.spiritualPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_stories, size: 16, color: AppColors.spiritualPurple),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAm ? 'ማሰላሰል' : 'Reflection',
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: c.textSecondary, size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _step(
                    c: c,
                    icon: Icons.headphones,
                    label: isAm ? 'አዳምጥ' : 'Listen',
                    hint: isAm ? 'ቃሉን በማዳመጥ ላይ እያለህ ምን ተሰማህ?' : 'What did you feel as you listened to the Word?',
                    controller: widget.reflectController ?? _reflectCtrl,
                  ),
                  const SizedBox(height: 12),
                  _step(
                    c: c,
                    icon: Icons.lightbulb,
                    label: isAm ? 'አሰላስል' : 'Reflect',
                    hint: isAm ? 'እግዚአብሔር በዚህ ቃል ምን ይነግርሃል?' : 'What is God saying to you through this passage?',
                    controller: _applyCtrl,
                  ),
                  const SizedBox(height: 12),
                  _step(
                    c: c,
                    icon: Icons.build,
                    label: isAm ? 'ተግብር' : 'Apply',
                    hint: isAm ? 'ይህን ቃል ዛሬ እንዴት በተግባር ልታውለው ትችላለህ?' : 'How can you live this out today?',
                    controller: _prayCtrl,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: Text(
                        isAm ? 'አስረክብ' : 'Submit Reflection',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step({
    required ThemePalette c,
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.spiritualPurple),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: c.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 2,
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.textMuted.withValues(alpha: 0.5), fontSize: 12),
            filled: true,
            fillColor: c.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final combined = StringBuffer();
    final reflectText = widget.reflectController?.text ?? _reflectCtrl.text;
    if (reflectText.isNotEmpty) {
      combined.writeln('Listen: $reflectText');
    }
    if (_applyCtrl.text.isNotEmpty) {
      combined.writeln('Reflect: ${_applyCtrl.text}');
    }
    if (_prayCtrl.text.isNotEmpty) {
      combined.writeln('Apply/Pray: ${_prayCtrl.text}');
    }

    ref.read(bibleSessionNotifierProvider.notifier).logSession(
      bookId: widget.bookId,
      chapterStart: widget.chapter,
      chapterEnd: widget.chapter,
      reflection: combined.toString().isNotEmpty ? combined.toString() : null,
      isPlanReading: widget.planDay != null,
      planDay: widget.planDay,
    );

    setState(() => _expanded = false);
    if (widget.reflectController == null) _reflectCtrl.clear();
    _applyCtrl.clear();
    _prayCtrl.clear();

    widget.onDone?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          widget.isAm ? 'ማሰላሰል ተመዝግቧል' : 'Reflection logged +20 XP',
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }
}
