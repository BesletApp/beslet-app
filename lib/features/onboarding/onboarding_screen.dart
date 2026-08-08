import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/database/app_database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/prayer_reminder_service.dart';
import '../../core/widgets/brand_mark.dart';
import '../../l10n/app_localizations.dart';

class _PrayerSlot {
  final String id;
  final String labelEn;
  final String labelAm;
  final int hour;
  final int minute;
  const _PrayerSlot(this.id, this.labelEn, this.labelAm, this.hour, this.minute);
}

const List<_PrayerSlot> _prayerSlots = [
  _PrayerSlot('dawn', 'Morning · 6:00', 'ጥዋት · 6:00', 6, 0),
  _PrayerSlot('noon', 'Midday · 12:00', 'እኩለ ቀን · 12:00', 12, 0),
  _PrayerSlot('dusk', 'Evening · 18:00', 'ምሽት · 18:00', 18, 0),
  _PrayerSlot('evening', 'Before sleep · 21:00', 'ከመተኛቱ በፊት · 21:00', 21, 0),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController(text: '');
  int _page = 0;
  String _biblePlan = 'nt';
  bool _isAm = false;
  String? _gender;
  String? _spiritualIntent;
  final Set<String> _selectedSlots = {};
  final List<({int hour, int minute})> _customTimes = [];

  /// Dynamic page count: gender page only appears for Amharic users.
  int get _pages => _isAm ? 7 : 6;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final db = ref.read(databaseProvider);
    final users = await db.select(db.users).get();
    final now = DateTime.now().toIso8601String();
    if (users.isNotEmpty) {
      await db.update(db.users).replace(users.first.copyWith(
        name: _nameController.text.isEmpty ? 'Friend' : _nameController.text,
        biblePlan: _biblePlan,
        lang: _isAm ? 'am' : 'en',
        gender: Value(_gender),
        spiritualIntent: Value(_spiritualIntent),
        onboarded: true,
      ));
    } else {
      await db.into(db.users).insert(UsersCompanion.insert(
        createdAt: now,
        name: Value(_nameController.text.isEmpty ? 'Friend' : _nameController.text),
        biblePlan: Value(_biblePlan),
        lang: Value(_isAm ? 'am' : 'en'),
        gender: Value(_gender),
        spiritualIntent: Value(_spiritualIntent),
        onboarded: Value(true),
      ));
    }
    if (!mounted) return;
    for (final id in _selectedSlots) {
      final slot = _prayerSlots.firstWhere((s) => s.id == id);
      try {
        await PrayerReminderService.addPrayerTime(slot.hour, slot.minute);
      } catch (_) {}
    }
    for (final t in _customTimes) {
      try {
        await PrayerReminderService.addPrayerTime(t.hour, t.minute);
      } catch (_) {}
    }
    if (!mounted) return;
    ref.invalidate(userProvider);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_page < _pages - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_page + 1) / _pages,
                          backgroundColor: c.border,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _pageController.jumpToPage(_pages - 1),
                      child: Text(l.skip, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: c.textMuted)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildWelcomePage(l, c),
                  _buildHowItWorksPage(l, c),
                  _buildSetupPage(l, c),
                  _buildPrayerRhythmPage(l, c),
                  if (_isAm) _buildGenderPage(l, c),
                  _buildIntentPage(l, c),
                  _buildCtaPage(l, c),
                ],
              ),
            ),
            if (_page < _pages - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages - 1, (i) => Container(
                    width: _page == i ? 20 : 8, height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _page == i ? AppColors.primary : c.border,
                    ),
                  )),
                ),
              ),
            if (_page == 0)
              _buildBottomButton(l, 'Start', () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
            if (_page == 1 || _page == 2 || _page == 3)
              _buildBottomButton(l, 'Next', () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
            if (_page == 4 && _isAm)
              _buildBottomButton(l, 'Next', () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut), enabled: _gender != null),
            if (_page == 4 && !_isAm)
              _buildBottomButton(l, 'Next', () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
            if (_page == 5 && _isAm)
              _buildBottomButton(l, 'Next', () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
            if (_page == _pages - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _complete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF0A0A0A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_isAm ? 'ዕለታዊ አብሮነትህን ጀምር' : 'Begin your daily walk', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(AppLocalizations l, String label, VoidCallback onTap, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: const Color(0xFF0A0A0A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildWelcomePage(AppLocalizations l, ThemePalette c) {
    final h = _isAm ? 'እንኳን ወደ ብስለት በደህና መጡ!' : 'Welcome to ብስለት';
    final subtitle = _isAm
        ? 'ይህ በእግዚአብሔር ዕለታዊ አብሮነት ነው — ቃል፣ ጸሎት እና የተሞላ ህይወት'
        : 'A daily companion for your walk with God — Word, prayer, and a purposeful life.';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandMark(size: 100),
          const SizedBox(height: 24),
          Text(h, style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pillarIcon('🙏', _isAm ? 'መንፈሳዊ' : 'Spiritual', c),
              const SizedBox(width: 16),
              _pillarIcon('🎯', _isAm ? 'ክህሎቶች' : 'Skills', c),
              const SizedBox(width: 16),
              _pillarIcon('👥', _isAm ? 'ህብረት' : 'Fellowship', c),
              const SizedBox(width: 16),
              _pillarIcon('👨‍👩‍👧‍👧', _isAm ? 'ቤተሰብ' : 'Family', c),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _isAm = !_isAm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isAm ? 'EN' : 'አማ', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: c.textMuted)),
                  const SizedBox(width: 6),
                  Icon(Icons.translate, size: 16, color: c.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillarIcon(String emoji, String label, ThemePalette c) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Center(child: Text(emoji, style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: c.textMuted)),
      ],
    );
  }

  Widget _buildHowItWorksPage(AppLocalizations l, ThemePalette c) {
    final title = _isAm ? '90 ቀናት እንዴት ይሠራሉ' : 'How the 90 Days Work';
    final per = 90 ~/ 4;
    final ranges = List.generate(4, (i) {
      final s = i * per + 1;
      final e = i == 3 ? 90 : (i + 1) * per;
      return '$s–$e';
    });
    final phases = _isAm
        ? [
            {'icon': '🌱', 'label': 'ዲሲፕሊን', 'desc': 'መሠረት መጣል (ቀን ${ranges[0]})'},
            {'icon': '🌿', 'label': 'እምነት', 'desc': 'ጥልቅ ማደግ (ቀን ${ranges[1]})'},
            {'icon': '🌳', 'label': 'ታዛዥነት', 'desc': 'መሥረቅ (ቀን ${ranges[2]})'},
            {'icon': '🌲', 'label': 'ተፅዕኖ', 'desc': 'መልሶ መስጠት (ቀን ${ranges[3]})'},
          ]
        : [
            {'icon': '🌱', 'label': 'Discipline', 'desc': 'Build foundation (Days ${ranges[0]})'},
            {'icon': '🌿', 'label': 'Faith', 'desc': 'Grow deeper (Days ${ranges[1]})'},
            {'icon': '🌳', 'label': 'Obedience', 'desc': 'Bear fruit (Days ${ranges[2]})'},
            {'icon': '🌲', 'label': 'Impact', 'desc': 'Give back (Days ${ranges[3]})'},
          ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.displaySmall),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
            ),
            child: Text(
              _isAm
                ? '90 ቀናት በእውነት ለመለወጥ በቂ ጊዜ ነው። ዕለታዊ ምት፣ የአራት ምሰሶች ተጠያቂነት እና የማይረሳ ለውጥ። በየቀኑ አንድ ምሰሶ፣ ቀስ በቀስ እያደግህ ትሄዳለህ።'
                : '90 days is enough time to genuinely change. A daily rhythm, 4-pillar accountability, and real transformation. Each day you show up, you grow — not by chance, but by design. You won\'t be the same person at the end.',
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, height: 1.5, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          Text(_isAm ? 'የእድገት ደረጃዎች' : 'Growth Stages', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: c.textSecondary)),
          const SizedBox(height: 12),
          ...phases.asMap().entries.map((e) => _phaseRow(e.key, e.value, c)),
        ],
      ),
    );
  }

  Widget _phaseRow(int i, Map<String, String> phase, ThemePalette c) {
    final colors = [const Color(0xFF4CAF50), const Color(0xFF2196F3), const Color(0xFFFF6F00), const Color(0xFF9C27B0)];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: colors[i].withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(phase['icon']!, style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(phase['label']!, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
              Text(phase['desc']!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: c.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage(AppLocalizations l, ThemePalette c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isAm ? 'ፍጥነት ማቀናበሪያ' : 'Quick Setup', style: AppTextStyles.displaySmall),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Your name',
              hintText: 'Enter your name...',
              filled: true,
              fillColor: c.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          Text(_isAm ? 'መጽሐፍ ቅዱስ እቅድ' : 'Bible Plan', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: c.textSecondary)),
          const SizedBox(height: 8),
          _planOption('ot', _isAm ? 'ብሉይ ኪዳን' : 'Old Testament', c),
          const SizedBox(height: 8),
          _planOption('nt', _isAm ? 'አዲስ ኪዳን' : 'New Testament', c),
        ],
      ),
    );
  }

  Widget _planOption(String id, String label, ThemePalette c) {
    final selected = _biblePlan == id;
    return GestureDetector(
      onTap: () => setState(() => _biblePlan = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : c.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: selected ? AppColors.primary : c.textMuted),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: selected ? c.textPrimary : c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerRhythmPage(AppLocalizations l, ThemePalette c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isAm ? 'የጸሎት ሪትምህ' : 'Your prayer rhythm',
              style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text(
            _isAm
                ? 'በምን መደበኛ ሰዓት መጸለይ ይፈልጋሉ? ከተመከሩት የቀን ሰዓቶች ይምረጡ፣ ወይም የራስዎን ያዘጋጁ።'
                : 'At what regular time would you like to pray? Pick from the recommended hours of the day, or set your own.',
            style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ..._prayerSlots.map((s) => _slotOption(s, c)),
          if (_customTimes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_isAm ? 'የራስዎ ሰዓቶች' : 'Your custom times',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: c.textSecondary)),
            const SizedBox(height: 8),
            ..._customTimes.asMap().entries.map((e) => _customTimeRow(e.key, e.value, c)),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickCustomTime,
            icon: const Icon(Icons.schedule, size: 16, color: AppColors.primary),
            label: Text(_isAm ? 'የራስህን ሰዓት ምረጥ' : 'Set a custom time',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: c.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotOption(_PrayerSlot slot, ThemePalette c) {
    final selected = _selectedSlots.contains(slot.id);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedSlots.remove(slot.id);
        } else {
          _selectedSlots.add(slot.id);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : c.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.add_circle_outline,
                size: 18,
                color: selected ? AppColors.primary : c.textMuted),
            const SizedBox(width: 10),
            Text(_isAm ? slot.labelAm : slot.labelEn,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: selected ? c.textPrimary : c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _customTimeRow(int index, ({int hour, int minute}) t, ThemePalette c) {
    final hh = t.minute.toString().padLeft(2, '0');
    final label = '${t.hour.toString().padLeft(2, '0')}:$hh';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: c.textSecondary)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _customTimes.removeAt(index)),
            child: Icon(Icons.close, size: 16, color: c.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() => _customTimes.add((hour: time.hour, minute: time.minute)));
  }

  Widget _buildGenderPage(AppLocalizations l, ThemePalette c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isAm ? 'ለግል ብጁ ንግግር' : 'Personal tone',
              style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text(
            _isAm
                ? 'አማርኛ በሚጠቀሙበት መንገድ ለመናገር የፆታ ምርጫህ ይረዳናል።'
                : 'Knowing this helps the app speak to you in your language, the way Amharic addresses you naturally.',
            style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _genderOption('male', _isAm ? 'ወንድ' : 'Male', c),
          const SizedBox(height: 10),
          _genderOption('female', _isAm ? 'ሴት' : 'Female', c),
        ],
      ),
    );
  }

  Widget _genderOption(String id, String label, ThemePalette c) {
    final selected = _gender == id;
    return GestureDetector(
      onTap: () => setState(() => _gender = id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : c.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? AppColors.primary : c.textMuted),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: selected ? c.textPrimary : c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentPage(AppLocalizations l, ThemePalette c) {
    final options = [
      ('grow_in_prayer', '🙏', _isAm ? 'በጸሎት ማደግ' : 'Grow in prayer'),
      ('consistent_bible', '📖', _isAm ? 'በቃሉ ተከታታይ' : 'Be consistent in the Word'),
      ('disciplined_daily', '🌱', _isAm ? 'በየቀኑ ተግሣጽ' : 'Live each day with purpose'),
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isAm ? 'ዛሬ ምን ትፈልጋለህ?' : 'What do you want to grow in?',
              style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text(
            _isAm
                ? 'አንድ ትኩረት ምረጥ — ቀስ በቀስ የእለት ተእለት መሪ ይሆናል።'
                : 'Choose one focus — it gently shapes your daily rhythm. You can always change it later.',
            style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ...options.map((o) => _intentOption(o.$1, o.$2, o.$3, c)),
        ],
      ),
    );
  }

  Widget _intentOption(String id, String emoji, String label, ThemePalette c) {
    final selected = _spiritualIntent == id;
    return GestureDetector(
      onTap: () => setState(() => _spiritualIntent = id),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : c.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: selected ? c.textPrimary : c.textSecondary)),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? AppColors.primary : c.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaPage(AppLocalizations l, ThemePalette c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandMark(size: 120),
          const SizedBox(height: 32),
          Text(l.readyToGrow, style: AppTextStyles.displayMedium),
          const SizedBox(height: 12),
          Text(
            _isAm ? 'የብስለት ጉዞህ ዛሬ ይጀምራል።' : 'Your journey of maturity begins today.',
            style: AppTextStyles.bodyLarge.copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _isAm ? 'በየቀኑ ቃሉን፣ ጸሎትን እና ዓላማህን ይዘህ ትሄዳለህ።' : 'Each day you will walk with the Word, prayer, and purpose.',
            style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
