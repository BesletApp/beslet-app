import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../l10n/app_localizations.dart';

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

  static const _pages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final db = ref.read(databaseProvider);
    final users = await db.select(db.users).get();
    if (users.isNotEmpty) {
      await db.update(db.users).replace(users.first.copyWith(
        name: _nameController.text.isEmpty ? 'Friend' : _nameController.text,
        biblePlan: _biblePlan,
        lang: _isAm ? 'am' : 'en',
        onboarded: true,
      ));
    }
    if (!mounted) return;
    ref.invalidate(userProvider);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _pageController.jumpToPage(_pages - 1),
                      child: Text(l.skip, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildWelcomePage(l),
                  _buildHowItWorksPage(l),
                  _buildSetupPage(l),
                  _buildCtaPage(l),
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
                      color: _page == i ? AppColors.primary : AppColors.border,
                    ),
                  )),
                ),
              ),
            if (_page == 0)
              _buildBottomButton(l, 'Start', () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
            if (_page == 1)
              _buildBottomButton(l, 'Next', () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
            if (_page == 2)
              _buildBottomButton(l, 'Done', () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
            if (_page == 3)
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
                    child: Text(_isAm ? 'ክረምትህን ጀምር' : 'Start your summer', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(AppLocalizations l, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
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

  Widget _buildWelcomePage(AppLocalizations l) {
    final h = _isAm ? 'እንኳን ወደ ብስለት በደህና መጡ!' : 'Welcome to ብስለት';
    final subtitle = _isAm
        ? 'በዚህ ክረምት በአራት ምሰሶች እድገትህን ገንባ፦ መንፈሳዊ፣ ክህሎቶች፣ ህብረት፣ ቤተሰብ'
        : 'Grow intentionally this summer through 4 pillars: Spiritual, Skills, Fellowship, Family';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100, height: 100,
            child: CustomPaint(
              painter: _SeedlingPainter(),
              child: const SizedBox(),
            ),
          ),
          const SizedBox(height: 24),
          Text(h, style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pillarIcon('🙏', _isAm ? 'መንፈሳዊ' : 'Spiritual'),
              const SizedBox(width: 16),
              _pillarIcon('🎯', _isAm ? 'ክህሎቶች' : 'Skills'),
              const SizedBox(width: 16),
              _pillarIcon('👥', _isAm ? 'ህብረት' : 'Fellowship'),
              const SizedBox(width: 16),
              _pillarIcon('👨‍👩‍👧‍👧', _isAm ? 'ቤተሰብ' : 'Family'),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _isAm = !_isAm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isAm ? 'EN' : 'አማ', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(width: 6),
                  Icon(Icons.translate, size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillarIcon(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(child: Text(emoji, style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildHowItWorksPage(AppLocalizations l) {
    final title = _isAm ? '90 ቀናት እንዴት ይሠራሉ' : 'How the 90 Days Work';
    final phases = _isAm
        ? [
            {'icon': '🌱', 'label': 'ዲሲፕሊን', 'desc': 'መሠረት መጣል (ቀን 1-7)'},
            {'icon': '🌿', 'label': 'እምነት', 'desc': 'ጥልቅ ማደግ (ቀን 8-15)'},
            {'icon': '🌳', 'label': 'ታዛዥነት', 'desc': 'መሥረቅ (ቀን 16-23)'},
            {'icon': '🌲', 'label': 'ተፅዕኖ', 'desc': 'መልሶ መስጠት (ቀን 24-30)'},
          ]
        : [
            {'icon': '🌱', 'label': 'Discipline', 'desc': 'Build foundation (Days 1-7)'},
            {'icon': '🌿', 'label': 'Faith', 'desc': 'Grow deeper (Days 8-15)'},
            {'icon': '🌳', 'label': 'Obedience', 'desc': 'Bear fruit (Days 16-23)'},
            {'icon': '🌲', 'label': 'Impact', 'desc': 'Give back (Days 24-30)'},
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
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          Text(_isAm ? 'የእድገት ደረጃዎች' : 'Growth Stages', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...phases.asMap().entries.map((e) => _phaseRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _phaseRow(int i, Map<String, String> phase) {
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
              Text(phase['label']!, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(phase['desc']!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage(AppLocalizations l) {
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
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          Text(_isAm ? 'መጽሐፍ ቅዱስ እቅድ' : 'Bible Plan', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _planOption('ot', _isAm ? 'ብሉይ ኪዳን' : 'Old Testament'),
          const SizedBox(height: 8),
          _planOption('nt', _isAm ? 'አዲስ ኪዳን' : 'New Testament'),
        ],
      ),
    );
  }

  Widget _planOption(String id, String label) {
    final selected = _biblePlan == id;
    return GestureDetector(
      onTap: () => setState(() => _biblePlan = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: selected ? AppColors.textPrimary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaPage(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120, height: 120,
            child: CustomPaint(
              painter: _SeedlingPainter(),
              child: const SizedBox(),
            ),
          ),
          const SizedBox(height: 32),
          Text('Ready to grow!', style: AppTextStyles.displayMedium),
          const SizedBox(height: 12),
          Text(
            _isAm ? 'የብስለት ጉዞህ ዛሬ ይጀምራል።' : 'Your journey of maturity begins today.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SeedlingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final stem = Path();
    stem.moveTo(cx, cy + 24);
    stem.cubicTo(cx - 2, cy + 8, cx + 3, cy - 2, cx, cy - 16);
    canvas.drawPath(stem, paint);

    paint.style = PaintingStyle.fill;
    final leftLeaf = Path();
    leftLeaf.moveTo(cx, cy - 8);
    leftLeaf.quadraticBezierTo(cx - 14, cy - 10, cx - 16, cy - 22);
    leftLeaf.quadraticBezierTo(cx - 8, cy - 20, cx, cy - 12);
    leftLeaf.close();
    canvas.drawPath(leftLeaf, paint..color = AppColors.primary.withValues(alpha: 0.35));

    final rightLeaf = Path();
    rightLeaf.moveTo(cx, cy - 6);
    rightLeaf.quadraticBezierTo(cx + 14, cy - 12, cx + 18, cy - 24);
    rightLeaf.quadraticBezierTo(cx + 10, cy - 20, cx, cy - 10);
    rightLeaf.close();
    canvas.drawPath(rightLeaf, paint..color = AppColors.primary.withValues(alpha: 0.5));

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(cx - 18, cy + 24), Offset(cx + 18, cy + 24), paint..color = AppColors.primary.withValues(alpha: 0.4));

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 8, cy + 28), 1.5, paint..color = AppColors.primary.withValues(alpha: 0.25));
    canvas.drawCircle(Offset(cx + 6, cy + 29), 1, paint..color = AppColors.primary.withValues(alpha: 0.25));
    canvas.drawCircle(Offset(cx, cy + 27), 1.2, paint..color = AppColors.primary.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
