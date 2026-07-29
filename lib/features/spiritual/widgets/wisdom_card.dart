import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WisdomCard extends StatelessWidget {
  final String note;
  final String bookName;
  final bool isAm;
  const WisdomCard({super.key, required this.note, required this.bookName, required this.isAm});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('📜', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(isAm ? 'ከቀድሞ ጉዞህ' : 'From your past journey', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 8),
        Text(note, style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5, fontStyle: FontStyle.italic)),
        const SizedBox(height: 6),
        Text('— $bookName', style: TextStyle(fontSize: 10, color: c.textMuted)),
      ]),
    );
  }
}
