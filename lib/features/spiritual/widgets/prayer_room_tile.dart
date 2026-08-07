import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/prayer_rooms_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// Localized label for a room's soft grouping.
String prayerRoomGroupLabel(AppLocalizations l, String group) {
  switch (group) {
    case PrayerRoomGroup.intercession:
      return l.groupIntercession;
    case PrayerRoomGroup.struggle:
      return l.groupStruggle;
    case PrayerRoomGroup.family:
      return l.groupFamily;
    default:
      return l.groupPersonal;
  }
}

/// A single room on the threshold — a name, a quiet kind, and a warmth dot
/// that simply says "you have been here". Tap to enter; long-press to tend.
class PrayerRoomTile extends StatelessWidget {
  final PrayerRoom room;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PrayerRoomTile({
    super.key,
    required this.room,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final title = AppTextStyles.of(context).displaySmall.copyWith(fontSize: isAm ? 19 : 18);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border.withValues(alpha: 0.6)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(room.name, style: title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  prayerRoomGroupLabel(l, room.group),
                  style: AppTextStyles.of(context).labelSmall.copyWith(fontSize: 10),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            if (room.lastEnteredAt != null) ...[
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.35),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8, spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right, size: 18, color: AppColors.of(context).textMuted),
          ]),
        ),
      ),
    );
  }
}
