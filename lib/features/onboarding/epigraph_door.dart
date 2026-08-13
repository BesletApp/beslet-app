import 'package:flutter/material.dart';
import '../../core/services/daily_verse_service.dart';
import '../../core/services/scripture_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/brand_mark.dart';
import '../../l10n/app_localizations.dart';

/// The Epigraph — the permanent doorway of Beslet.
///
/// A single vine-and-branches passage (John 15:5) resolves entirely offline
/// from the bundled Bible — the same text the reader shows — so the very first
/// thing a person meets is Scripture, not an argument for the app. There is no
/// form, no promise, no tour: just the Word, one identity line, the language,
/// and the door that opens into it.
///
/// The whole screen reads the app locale, so choosing አማርኛ or English here
/// switches the epigraph itself. The chosen language is persisted by the
/// caller the moment it is tapped ([onLanguage]) and finalized on [onOpen].
class EpigraphDoor extends StatefulWidget {
  const EpigraphDoor({super.key, required this.onLanguage, required this.onOpen});

  /// Called with `true` for Amharic, `false` for English when a chip is tapped.
  final ValueChanged<bool> onLanguage;

  /// Called when the doorway is opened (the CTA is pressed).
  final VoidCallback onOpen;

  @override
  State<EpigraphDoor> createState() => _EpigraphDoorState();
}

class _EpigraphDoorState extends State<EpigraphDoor> {
  /// The permanent epigraph: the vine saying itself. Kept as a single constant
  /// so the doorway never changes with the calendar.
  static const String _permanent = 'John 15:5';

  Scripture? _verse;

  bool get _isAm => Localizations.localeOf(context).languageCode == 'am';

  @override
  void initState() {
    super.initState();
    _loadVerse();
  }

  Future<void> _loadVerse() async {
    final resolved = await DailyVerseService.resolveReference(_permanent);
    if (!mounted) return;
    final ok = resolved.text.trim().isNotEmpty &&
        (resolved.textAm?.trim().isNotEmpty ?? false);
    setState(() => _verse = ok ? resolved : null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final isAm = _isAm;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            children: [
              _buildHeader(l, c, t, isAm),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        _buildVerse(l, c, t, isAm),
                        const SizedBox(height: 26),
                        Text(
                          l.doorBridge,
                          textAlign: TextAlign.center,
                          style: t.bodyMedium.copyWith(
                            color: c.textSecondary,
                            fontFamily: isAm ? 'NotoSansEthiopic' : 'Inter',
                            fontSize: 14,
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildChips(c, isAm),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              _buildCta(l, c),
              const SizedBox(height: 16),
              _buildWhisper(l, c, t, isAm),
            ],
          ),
        ),
      ),
    );
  }

  /// The top band: the brand seal, the name-and-vocation signal line, and a
  /// quiet hairline below it.
  Widget _buildHeader(AppLocalizations l, ThemePalette c, AppTextTheme t, bool isAm) {
    return Column(
      children: [
        const SizedBox(height: 6),
        BrandMark(size: 38, color: c.primaryLight),
        const SizedBox(height: 14),
        Text(
          l.doorSignal,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: isAm ? 'NotoSansEthiopic' : 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: isAm ? 1 : 3.2,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: c.border),
      ],
    );
  }

  /// Scripture as a doorway — unresolved gracefully into the identity line.
  Widget _buildVerse(AppLocalizations l, ThemePalette c, AppTextTheme t, bool isAm) {
    final verse = _verse;
    if (verse == null) return const SizedBox(height: 60);
    final reference =
        isAm ? ScriptureService.amharicReference(verse.reference) : verse.reference;
    final text = isAm ? (verse.textAm ?? verse.text) : verse.text;
    return Column(
      children: [
        Text(
          reference,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: isAm ? 'NotoSansEthiopic' : 'Inter',
            fontSize: isAm ? 12 : 11,
            fontWeight: FontWeight.w800,
            letterSpacing: isAm ? 0.8 : 2.2,
            color: c.warningOrange,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: isAm ? 'NotoSansEthiopic' : 'CormorantGaramond',
            fontSize: isAm ? 17 : 20,
            fontStyle: FontStyle.italic,
            height: isAm ? 1.7 : 1.55,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return Container(
              width: 4,
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.textMuted.withValues(alpha: 0.5)),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildChips(ThemePalette c, bool isAm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip('አማርኛ', true, c, isAm),
        const SizedBox(width: 12),
        _chip('English', false, c, isAm),
      ],
    );
  }

  Widget _chip(String label, bool chipIsAm, ThemePalette c, bool isAm) {
    final selected = chipIsAm == isAm;
    return GestureDetector(
      onTap: () => widget.onLanguage(chipIsAm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.14) : c.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? c.primary : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: chipIsAm ? 'NotoSansEthiopic' : 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? c.primary : c.textSecondary,
          ),
        ),
      ),
    );
  }

  /// The doorway itself: a plum door with the invitation in fidel, and the
  /// Latin reading beneath it.
  Widget _buildCta(AppLocalizations l, ThemePalette c) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onOpen,
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: const Color(0xFF0A0A0A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.doorCta,
              style: const TextStyle(
                fontFamily: 'NotoSansEthiopic',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              l.doorCtaCaps,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.6,
                color: const Color(0xFF0A0A0A).withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The quiet whisper beneath the door: the life's rhythm, in the chosen tongue.
  Widget _buildWhisper(AppLocalizations l, ThemePalette c, AppTextTheme t, bool isAm) {
    return Text(
      l.doorWhisper,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: isAm ? 'NotoSansEthiopic' : 'Inter',
        fontSize: isAm ? 12 : 10,
        fontWeight: FontWeight.w700,
        letterSpacing: isAm ? 0.6 : 2.2,
        color: c.textMuted.withValues(alpha: 0.85),
      ),
    );
  }
}