import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/identity_provider.dart';
import '../../core/services/summer_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/zone_layout.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/error_card.dart';
import 'widgets/lamp_card.dart';

const _avatarColors = {
  'gold': Color(0xFFC8942E),
  'green': Color(0xFF4CAF50),
  'purple': Color(0xFF9C27B0),
  'blue': Color(0xFF2196F3),
  'orange': Color(0xFFFF9800),
  'teal': Color(0xFF009688),
};

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ── ZONE 1: Threshold — who you are ──
  Widget _buildThreshold(AppLocalizations l, Identity id) {
    final initial = id.name.isNotEmpty ? id.name[0].toUpperCase() : '?';
    final color = _avatarColors[id.avatarColor] ?? AppColors.primary;

    return Column(children: [
      GestureDetector(
        onTap: () => _showEditProfile(l, id),
        child: Stack(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: id.avatarColor == 'gold' ? AppColors.gradientGold : null,
                color: id.avatarColor != 'gold' ? color : null,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 2))],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: id.avatarColor == 'gold' ? const Color(0xFF0A0A0A) : Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.of(context).card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.of(context).background, width: 2),
                ),
                child: const Icon(Icons.edit, size: 14, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        id.name,
        style: TextStyle(
          fontFamily: 'CormorantGaramond',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.of(context).textPrimary,
        ),
      ),
    ]);
  }

  // ── Edit Profile Sheet ──
  void _showEditProfile(AppLocalizations l, Identity id) {
    final nameCtl = TextEditingController(text: id.name);
    var avatarColor = id.avatarColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: StatefulBuilder(builder: (ctx, setSheetState) {
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.of(context).border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(l.editProfile, style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.of(context).textPrimary)),
              const SizedBox(height: 20),
              Text(l.displayName, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.of(context).textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtl,
                style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(
                  hintText: l.localeName == 'am' ? 'ስምህን አስገባ' : 'Enter your name',
                  filled: true,
                  fillColor: AppColors.of(context).background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.profileAvatarColor, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.of(context).textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              Row(children: _avatarColors.entries.map((e) {
                final isSelected = avatarColor == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      avatarColor = e.key;
                      setSheetState(() {});
                    },
                    child: Container(
                      height: 38,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppColors.of(context).textPrimary : Colors.transparent, width: 2),
                      ),
                      child: isSelected ? const Center(child: Icon(Icons.check, size: 18, color: Colors.white)) : null,
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF0A0A0A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final newName = nameCtl.text.trim();
                    if (newName.isNotEmpty && newName != id.name) {
                      await ref.read(identityNotifierProvider.notifier).updateName(newName);
                    }
                    if (avatarColor != id.avatarColor) {
                      await ref.read(identityNotifierProvider.notifier).setAvatarColor(avatarColor);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l.profileSaved, style: const TextStyle(fontFamily: 'Inter')),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ));
                    }
                  },
                  child: Text(l.save, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ]);
          }),
        );
      },
    );
  }

  // ── ZONE 3: Season — the shared present ──
  Widget _buildSeason(AppLocalizations l) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final season = SummerService.seasonFor(DateTime.now());
    final isAm = l.localeName == 'am';
    final copy = isAm ? season.am : season.en;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: c.gradientPrimarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(l.profileSeasonIntro, style: t.labelLarge.copyWith(color: AppColors.primary)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(copy, style: t.bodyMedium.copyWith(color: c.textPrimary, height: 1.5)),
      ]),
    );
  }

  // ── ZONE 4: Room — the walkway into settings ──
  Widget _buildRoom(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.of(context).border, width: 0.5),
      ),
      child: Column(children: [
        _tile(Icons.language, l.language, () => context.go('/settings?section=language')),
        Divider(height: 1, color: AppColors.of(context).border),
        _tile(Icons.record_voice_over_outlined, l.settingsVoice, () => context.go('/settings?section=voice')),
        Divider(height: 1, color: AppColors.of(context).border),
        _tile(Icons.palette, l.appearance, () => context.go('/settings?section=appearance')),
        Divider(height: 1, color: AppColors.of(context).border),
        _tile(Icons.notifications_outlined, l.reminders, () => context.go('/settings?section=reminders')),
        Divider(height: 1, color: AppColors.of(context).border),
        _tile(Icons.info_outline, l.aboutApp, () => context.go('/settings?section=about')),
      ]),
    );
  }

  Widget _tile(IconData ic, String t, VoidCallback onTap) {
    return ListTile(
      leading: Icon(ic, color: AppColors.primary, size: 20),
      title: Text(t, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.of(context).textPrimary)),
      trailing: Icon(Icons.chevron_right, color: AppColors.of(context).textMuted, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final identityAsync = ref.watch(identityProvider);
    final bg = AppColors.of(context).background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        title: Text(l.profile, style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
      ),
      body: identityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [ErrorCard(message: l.localeName == 'am' ? 'መገለጫ መጫን አልተቻለም' : 'Could not load profile')],
        ),
        data: (id) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ZoneLayout(
            orientation: _buildThreshold(l, id),
            primary: const LampCard(),
            support: _buildSeason(l),
            anchor: _buildRoom(l),
          ),
        ),
      ),
    );
  }
}
