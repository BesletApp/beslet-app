import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/scripture_service.dart';
import '../../core/services/study_data.dart';
import '../../core/services/plan_progress_service.dart';
import '../../core/services/witness_service.dart';
import '../../core/providers/bible_read_provider.dart';
import '../../core/providers/bible_session_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/audio_player_provider.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/wisdom_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/audio_bible_service.dart';
import '../../shared/widgets/error_card.dart';
import 'widgets/audio_player_bar.dart';
import 'widgets/verse_list_view.dart';
import 'widgets/lectio_divina_card.dart';
import 'widgets/phase_bar.dart';
import 'widgets/chapter_picker.dart';
import 'widgets/download_sheet.dart';
import 'widgets/wisdom_dialog.dart';
import 'widgets/wisdom_card.dart';

class BibleScreen extends ConsumerStatefulWidget {
  final String? initialBookId;
  final int? initialChapter;

  const BibleScreen({super.key, this.initialBookId, this.initialChapter});
  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  int? _viewingDay;
  static const int _totalDays = 90;
  static const int _phaseCount = 4;
  List<BiblePlanEntry>? _cachedPlan;
  String? _selectedLang;
  String? _pickedBookId;
  int? _pickedChapter;
  bool _downloaded = false;
  bool _audioLoaded = false;

  String get _effectiveLang {
    final locale = Localizations.localeOf(context).languageCode;
    if (_selectedLang != null) return _selectedLang!;
    return locale == 'am' ? 'am' : 'en';
  }

  bool get _isAm => _effectiveLang == 'am';

  @override
  void initState() {
    super.initState();
    if (widget.initialBookId != null && widget.initialChapter != null) {
      _pickedBookId = widget.initialBookId;
      _pickedChapter = widget.initialChapter;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAudio();
    });
  }

  @override
  void didUpdateWidget(covariant BibleScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialBookId != old.initialBookId || widget.initialChapter != old.initialChapter) {
      if (widget.initialBookId != null && widget.initialChapter != null) {
        setState(() {
          _pickedBookId = widget.initialBookId;
          _pickedChapter = widget.initialChapter;
          _viewingDay = null;
        });
      }
      _loadAudio();
    }
  }

  void _loadAudio() {
    final parsed = _resolveParsed();
    if (parsed == null) return;
    final state = ref.read(audioPlayerProvider);
    if (state.chapter?.bookId == parsed.bookId && state.chapter?.chapter == parsed.chapter && state.verseTexts.isNotEmpty && state.chapter?.isAmharic == _isAm) return;
    _audioLoaded = true;
    ref.read(audioPlayerProvider.notifier).prepare(AudioChapterInfo(
      bookId: parsed.bookId,
      chapter: parsed.chapter,
      reference: _refText,
      bookName: _isAm ? ScriptureService.bookMap[parsed.bookId]?.nameAm ?? parsed.bookId : ScriptureService.bookMap[parsed.bookId]?.nameEn ?? parsed.bookId,
      isAmharic: _isAm,
    ));
    _refreshDownloaded();
  }

  Future<void> _refreshDownloaded() async {
    final parsed = _resolveParsed();
    if (parsed == null) return;
    await ref.read(downloadListProvider.notifier).refresh();
    final downloads = ref.read(downloadListProvider);
    final d = downloads.any((dl) => dl.bookId == parsed.bookId && dl.chapter == parsed.chapter);
    if (mounted) {
      final currentParsed = _resolveParsed();
      if (currentParsed?.bookId == parsed.bookId && currentParsed?.chapter == parsed.chapter) {
        setState(() => _downloaded = d);
      }
    }
  }

  String get _refText {
    if (_pickedBookId != null && _pickedChapter != null) {
      final book = ScriptureService.bookMap[_pickedBookId]!;
      return '${_isAm ? book.nameAm : book.nameEn} $_pickedChapter';
    }
    final plan = _cachedPlan;
    if (plan == null || plan.isEmpty) return '';
    final day = _viewingDay ?? (ScriptureService.getTodaysReading(_planId).day);
    final entry = day <= plan.length ? plan[day - 1] : plan.last;
    return entry.reference;
  }

  ({String bookId, int chapter})? _resolveParsed() {
    if (_pickedBookId != null && _pickedChapter != null) return (bookId: _pickedBookId!, chapter: _pickedChapter!);
    final plan = _cachedPlan;
    if (plan == null || plan.isEmpty) return null;
    final day = _viewingDay ?? (ScriptureService.getTodaysReading(_planId).day);
    final entry = day <= plan.length ? plan[day - 1] : plan.last;
    return ScriptureService.parseReference(entry.reference);
  }

  Future<String?> _showReflectionPrompt(BuildContext context) async {
    final c = AppColors.of(context);
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_isAm ? 'እግዚአብሔር ምን አለ?' : 'What did God say?', style: AppTextStyles.labelLarge),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_isAm ? 'ይህን ምዕራፍ ስታነብ እግዚአብሔር ምን ነገረህ?' : 'What did God speak to you through this chapter?',
                style: TextStyle(fontSize: 13, color: c.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: _isAm ? 'ልብህ ላይ ያለውን ጻፍ...' : 'Write what\'s on your heart...',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                filled: true, fillColor: c.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: Text(_isAm ? 'ዝለል' : 'Skip', style: TextStyle(color: c.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(_isAm ? 'አስቀምጥ' : 'Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) return result;
    return null;
  }

  String get _planId {
    final user = ref.read(userProvider).valueOrNull;
    return user?.biblePlan ?? 'nt';
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final todayRead = ref.watch(todayBibleReadProvider);
    final streakAsync = ref.watch(bibleStreakProvider);
    final chaptersAsync = ref.watch(bibleChaptersReadProvider);
    final coverageAsync = ref.watch(bibleCoverageProvider);
    final completedBooksAsync = ref.watch(bibleBooksCompletedProvider);
    final readDaysAsync = ref.watch(bibleReadDaysProvider);
    final streak = streakAsync.valueOrNull ?? 0;
    final isRead = todayRead.valueOrNull != null;
    final chaptersRead = chaptersAsync.valueOrNull ?? 0;
    final coverage = coverageAsync.valueOrNull;
    final completedBooks = completedBooksAsync.valueOrNull ?? [];
    final readDays = readDaysAsync.valueOrNull ?? {};

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorCard(message: 'Could not load Bible plan')),
      data: (user) {
        final planId = user.biblePlan;
        _cachedPlan ??= ScriptureService.getPlan(planId, days: _totalDays);
        if (!_audioLoaded) _loadAudio();
        final plan = _cachedPlan!;
        final todaysReading = _viewingDay == null ? ScriptureService.getTodaysReading(planId) : null;
        final effectiveDay = _viewingDay ?? (todaysReading?.day ?? 1);
        final parsed = _resolveParsed();

        String theme;
        bool isToday;
        if (_pickedBookId != null && _pickedChapter != null) {
          final book = ScriptureService.bookMap[_pickedBookId]!;
          theme = _isAm ? book.themeAm : book.themeEn;
          isToday = false;
        } else {
          final reading = effectiveDay <= plan.length ? plan[effectiveDay - 1] : plan.last;
          theme = _isAm ? ScriptureService.getTheme(reading.reference) : ScriptureService.getThemeEn(reading.reference);
          isToday = _viewingDay == null;
        }

        final phase = ScriptureService.getPhase(effectiveDay);
        final phaseNames = _isAm ? ScriptureService.phaseNamesAm : ScriptureService.phaseNamesEn;
        final canMarkRead = isToday || _pickedBookId != null;

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          floatingActionButton: canMarkRead && !isRead
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final book = parsed != null ? ScriptureService.bookMap[parsed.bookId] : null;
                    final refStr = book != null ? '${_isAm ? book.nameAm : book.nameEn} ${parsed!.chapter}' : '';
                    if (refStr.isEmpty) return;
                    final note = await _showReflectionPrompt(context);
                    await ref.read(bibleNotifierProvider.notifier).markAsRead(refStr, note: note);
                    if (parsed == null || !mounted) return;
                    final db = ref.read(databaseProvider);
                    final prog = await PlanProgressService.compute(db);
                    final completed = prog.otProgress.any((p) => p.book.id == parsed.bookId && p.isComplete) ||
                        prog.ntProgress.any((p) => p.book.id == parsed.bookId && p.isComplete);
                    if (completed && mounted) {
                      showWisdomDialog(context, ref, parsed.bookId, _isAm);
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(_isAm ? 'ዛሬ አንብቤዋለሁ +20' : 'Mark Read +20', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.progressGreen,
                  foregroundColor: const Color(0xFF07090E),
                )
              : null,
          appBar: AppBar(
            backgroundColor: AppColors.of(context).background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.of(context).textPrimary),
              onPressed: () => context.go('/'),
            ),
            title: Text(
              _isAm ? 'መጽሐፍ ቅዱስ' : 'Bible',
              style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
            ),
            actions: [
              _buildLangToggle(),
                if (_viewingDay != null)
                IconButton(
                  icon: Icon(Icons.today, color: AppColors.of(context).textSecondary, size: 20),
                  tooltip: _isAm ? 'የዛሬው ንባብ' : "Today's Reading",
                  onPressed: () {
                    setState(() { _viewingDay = null; _pickedBookId = null; _pickedChapter = null; _downloaded = false; });
                    _loadAudio();
                  },
                ),
              IconButton(
                icon: Icon(Icons.menu_book, color: AppColors.of(context).textSecondary, size: 20),
                tooltip: _isAm ? 'መጻሕፍት' : 'Books',
                onPressed: () => _showBookPicker(context),
              ),
              IconButton(
                icon: Icon(Icons.auto_stories, color: AppColors.of(context).textSecondary, size: 20),
                tooltip: _isAm ? 'ማስታወሻ ደብተር' : 'Journal',
                onPressed: () => context.go('/bible/book-journal'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.whatshot, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$streak-${_isAm ? 'ቀን' : 'day'}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              _buildStats(chaptersRead, coverage, completedBooks.length, effectiveDay, isToday),
              const SizedBox(height: 16),
              _buildChapterHeader(_refText, theme, phase, phaseNames, effectiveDay, isToday, parsed),
              if (parsed != null && WitnessService.quoteForBook(parsed.bookId, isAm: _isAm) != null) ...[
                const SizedBox(height: 12),
                _buildQuoteCard(parsed.bookId),
              ],
              if (parsed != null) ...[
                const SizedBox(height: 12),
                _buildWisdomCard(parsed.bookId),
              ],
              const SizedBox(height: 16),
              AudioPlayerBar(isAm: _isAm),
              const SizedBox(height: 16),
              VerseListView(isAm: _isAm),
              const SizedBox(height: 16),
              _buildActions(isRead, isToday, parsed),
              const SizedBox(height: 16),
              if (parsed != null)
                LectioDivinaCard(
                  bookId: parsed.bookId,
                  chapter: parsed.chapter,
                  isAm: _isAm,
                  planDay: _pickedBookId == null ? '${todaysReading?.day ?? effectiveDay}' : null,
                ),
              if (_pickedBookId == null) ...[
                const SizedBox(height: 16),
                PhaseBar(
                  day: effectiveDay,
                  phaseIdx: phase,
                  phaseNames: phaseNames,
                  isAm: _isAm,
                  plan: plan,
                  totalDays: _totalDays,
                  phaseCount: _phaseCount,
                  onDaySelected: (d) {
                    setState(() { _viewingDay = d; _pickedBookId = null; _pickedChapter = null; _downloaded = false; });
                    _loadAudio();
                  },
                ),
                const SizedBox(height: 16),
                _buildAttendanceMonth(readDays),
              ],
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats(int chaptersRead, ({double otPercent, double ntPercent, double totalPercent})? coverage, int booksDone, int effectiveDay, bool isToday) {
    final subtitle = !isToday
        ? (_isAm ? 'ቀን $effectiveDay እየተመለከቱ ነው' : 'Viewing day $effectiveDay')
        : (_isAm
            ? '$chaptersRead ምዕራፎች · $booksDone መጻሕፍት ${coverage != null ? '· ${(coverage.totalPercent * 100).round()}%' : ''}'
            : '$chaptersRead ch. · $booksDone books ${coverage != null ? '· ${(coverage.totalPercent * 100).round()}%' : ''}');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Row(children: [
        Icon(!isToday ? Icons.calendar_today : Icons.library_books, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textSecondary, fontSize: 10)),
        ),
        if (coverage != null && isToday) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: coverage.totalPercent,
                backgroundColor: AppColors.of(context).border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildLangToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.of(context).border, width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _langChip('AMH', 'am'),
          Container(width: 1, height: 16, color: AppColors.of(context).border),
          _langChip('ENG', 'en'),
        ]),
      ),
    );
  }

  Widget _langChip(String label, String lang) {
    final active = _effectiveLang == lang;
    return GestureDetector(
      onTap: () {
        if (_effectiveLang != lang) {
          setState(() { _selectedLang = lang; _downloaded = false; });
          _loadAudio();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF07090E) : AppColors.of(context).textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildChapterHeader(String refText, String theme, int phase, List<String> phaseNames, int effectiveDay, bool isToday, ({String bookId, int chapter})? parsed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientGoldSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isToday && _pickedBookId == null) ...[
          Row(children: [
            _badge('${_isAm ? 'ቀን' : 'Day'} $effectiveDay ${_isAm ? 'ከ' : 'of'} $_totalDays', AppColors.primary.withValues(alpha: 0.15), AppColors.primary),
            const SizedBox(width: 6),
            _badge('${phaseNames[phase]} · ${_isAm ? 'ክፍል' : 'Phase'} ${phase + 1} ${_isAm ? 'ከ' : 'of'} $_phaseCount', AppColors.of(context).card.withValues(alpha: 0.5), AppColors.of(context).textSecondary),
          ]),
          const SizedBox(height: 10),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(refText, style: AppTextStyles.displayMedium.copyWith(fontSize: 22, color: AppColors.primary)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.of(context).card.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 2)),
                ),
                child: Text(theme, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.of(context).textSecondary, fontSize: 12)),
              ),
            ]),
          ),
          if (parsed != null) ...[
            const SizedBox(width: 8),
            Column(children: [
              _iconBtn(Icons.download, _downloaded ? (_isAm ? 'ተከማችቷል' : 'Downloaded') : (_isAm ? 'አውርድ' : 'Download'), () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => DownloadSheet(
                    currentBookId: parsed.bookId,
                    currentChapter: parsed.chapter,
                    isAmharic: _isAm,
                    isAlreadyDownloaded: _downloaded,
                    onDownloaded: () {
                      if (mounted) {
                        setState(() => _downloaded = true);
                        _loadAudio();
                        ref.read(downloadListProvider.notifier).refresh();
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
              _iconBtn(Icons.info_outline, _isAm ? 'የመጽሐፉ መረጃ' : 'Book Info', () => _showBookInfo(context, parsed)),
            ]),
          ],
        ]),
      ]),
    );
  }

  Widget _buildQuoteCard(String bookId) {
    final c = AppColors.of(context);
    final quote = WitnessService.quoteForBook(bookId, isAm: _isAm);
    if (quote == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: AppColors.primary.withValues(alpha: 0.4), width: 2)),
      ),
      child: Text(quote, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: c.textSecondary, height: 1.5)),
    );
  }

  Widget _buildWisdomCard(String bookId) {
    return Consumer(builder: (context, ref, _) {
      final wisdomAsync = ref.watch(wisdomForBookProvider(bookId));
      final note = wisdomAsync.valueOrNull;
      if (note == null || note.isEmpty) return const SizedBox.shrink();
      final book = ScriptureService.bookMap[bookId];
      final name = book != null ? (_isAm ? book.nameAm : book.nameEn) : bookId;
      return Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: WisdomCard(note: note, bookName: name, isAm: _isAm),
      );
    });
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.of(context).card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Icon(icon, size: 18, color: AppColors.of(context).textSecondary),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildActions(bool isRead, bool isToday, ({String bookId, int chapter})? parsed) {
    final canMarkRead = isToday || _pickedBookId != null;

    if (canMarkRead) {
      final alreadyRead = isRead;
      return Row(children: [
        Expanded(
          child: alreadyRead
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.progressGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.progressGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.progressGreen),
                    const SizedBox(width: 6),
                    Text('${_isAm ? 'ተከናውኗል' : 'Done'} ✓ +20 XP', style: TextStyle(fontSize: 12, color: AppColors.progressGreen, fontWeight: FontWeight.w600)),
                  ]),
                )
              : ElevatedButton.icon(
                  onPressed: () async {
                    final book = parsed != null ? ScriptureService.bookMap[parsed.bookId] : null;
                    final refStr = book != null ? '${_isAm ? book.nameAm : book.nameEn} ${parsed!.chapter}' : '';
                    if (refStr.isEmpty) return;
                    final note = await _showReflectionPrompt(context);
                    await ref.read(bibleNotifierProvider.notifier).markAsRead(refStr, note: note);
                    if (parsed == null || !mounted) return;
                    final db = ref.read(databaseProvider);
                    final prog = await PlanProgressService.compute(db);
                    final completed = prog.otProgress.any((p) => p.book.id == parsed.bookId && p.isComplete) ||
                        prog.ntProgress.any((p) => p.book.id == parsed.bookId && p.isComplete);
                    if (completed && mounted) {
                      showWisdomDialog(context, ref, parsed.bookId, _isAm);
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(_isAm ? 'ዛሬ አንብቤዋለሁ +20' : 'Mark Read +20', style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.progressGreen,
                    foregroundColor: const Color(0xFF07090E),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
        ),
      ]);
    }

    return Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.of(context).card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_outline, size: 14, color: AppColors.of(context).textMuted),
            const SizedBox(width: 6),
            Text(_isAm ? 'የዛሬ ብቻ' : 'Today only', style: TextStyle(fontSize: 11, color: AppColors.of(context).textMuted)),
          ]),
        ),
      ),
    ]);
  }

  void _showBookPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: _BookChapterPicker(
            isAm: _isAm,
            onSelected: (bookId, chapter) {
              Navigator.pop(ctx);
              setState(() {
                _pickedBookId = bookId;
                _pickedChapter = chapter;
                _viewingDay = null;
                _downloaded = false;
              });
              _loadAudio();
            },
          ),
        );
      },
    );
  }

  void _showBookInfo(BuildContext context, ({String bookId, int chapter}) parsed) {
    final bookInfo = StudyData.getContext(parsed.bookId, _isAm);
    final book = ScriptureService.bookMap[parsed.bookId];
    if (book == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _isAm ? book.nameAm : book.nameEn,
                  style: AppTextStyles.displaySmall.copyWith(fontSize: 20, color: AppColors.of(context).textPrimary),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.of(context).card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.of(context).border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(bookInfo, style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, color: AppColors.of(context).textPrimary, height: 1.6)),
                  const SizedBox(height: 10),
                  Text(
                    _isAm ? 'ቁልፍ ጭብጥ' : 'Key Theme',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAm ? book.themeAm : book.themeEn,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.of(context).textSecondary),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Text(
                _isAm ? 'ለጥልቅ ጥናት፦ Blue Letter Bible፣ BibleHub ይጠቀሙ' : 'For deeper study: Blue Letter Bible, BibleHub',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.of(context).textMuted),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceMonth(Set<int> readDays) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7;
    final today = now.day;
    final labels = _isAm ? ['ሰኞ', 'ማክ', 'ረቡ', 'ሐሙ', 'አርብ', 'ቅዳ', 'እሁድ'] : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.calendar_month, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            _isAm ? '${_monthsAm[now.month - 1]} ንባብ' : '${_monthsEn[now.month - 1]} Reading',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).textSecondary),
          ),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: labels.map((l) => SizedBox(
          width: 28, child: Text(l, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.of(context).textMuted))),
        ).toList()),
        const SizedBox(height: 6),
        ...List.generate((firstWeekday + daysInMonth + 6) ~/ 7, (row) {
          return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(7, (col) {
            final day = row * 7 + col - firstWeekday + 1;
            if (day < 1 || day > daysInMonth) return const SizedBox(width: 28, height: 28);
            final isRead = readDays.contains(day);
            final isToday2 = day == today;
            return Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead ? AppColors.progressGreen.withValues(alpha: 0.25) : (isToday2 ? AppColors.cardElevated : Colors.transparent),
                border: isToday2 ? Border.all(color: AppColors.primary, width: 1.5) : null,
              ),
              child: Center(child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday2 ? FontWeight.w700 : FontWeight.w400,
                  color: isRead ? AppColors.progressGreen : (isToday2 ? AppColors.primary : AppColors.of(context).textMuted),
                ),
              )),
            );
          }));
        }),
      ]),
    );
  }

  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monthsAm = ['ጃንዩ', 'ፌብሩ', 'ማርች', 'ኤፕሪ', 'ሜይ', 'ጁን', 'ጁላይ', 'ኦገስ', 'ሴፕቴ', 'ኦክቶ', 'ኖቬም', 'ዲሴም'];
}

class _BookChapterPicker extends ConsumerStatefulWidget {
  final bool isAm;
  final void Function(String bookId, int chapter) onSelected;
  const _BookChapterPicker({required this.isAm, required this.onSelected});
  @override
  ConsumerState<_BookChapterPicker> createState() => _BookChapterPickerState();
}

class _BookChapterPickerState extends ConsumerState<_BookChapterPicker> {
  BibleBook? _selectedBook;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _selectedBook != null ? () => setState(() => _selectedBook = null) : () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            _selectedBook != null
                ? (widget.isAm ? _selectedBook!.nameAm : _selectedBook!.nameEn)
                : (widget.isAm ? 'መጻሕፍት' : 'Books'),
            style: AppTextStyles.displaySmall.copyWith(fontSize: 18),
          ),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: _selectedBook == null
            ? ListView(children: ScriptureService.sections.map((s) => _buildSection(s)).toList())
            : ChapterPicker(book: _selectedBook!, onSelected: (ch) => widget.onSelected(_selectedBook!.id, ch)),
      ),
    ]);
  }

  Widget _buildSection(BibleSection s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(
          widget.isAm ? s.nameAm : s.nameEn,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.of(context).textMuted, fontWeight: FontWeight.w700),
        ),
      ),
      ...s.books.map((b) => ListTile(
        dense: true,
        title: Text(widget.isAm ? b.nameAm : b.nameEn, style: const TextStyle(fontSize: 15)),
        subtitle: Text(
          widget.isAm ? b.themeAm : b.themeEn,
          style: TextStyle(fontSize: 10, color: AppColors.of(context).textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => setState(() => _selectedBook = b),
      )),
    ]);
  }
}
