import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/scripture_service.dart';
import '../../core/services/plan_progress_service.dart';
import '../../core/providers/bible_read_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/audio_player_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/scripture_provider.dart';
import '../../core/providers/reading_preferences_provider.dart';
import '../../core/providers/bible_session_provider.dart';
import '../../core/services/audio_bible_service.dart';
import '../../core/services/verse_reflection_service.dart';
import '../../shared/widgets/error_card.dart';
import 'widgets/audio_player_bar.dart';
import 'widgets/verse_list_view.dart';
import 'widgets/chapter_picker.dart';
import 'widgets/wisdom_dialog.dart';
import 'widgets/download_sheet.dart';
import 'widgets/journal_sheet.dart';
import 'widgets/kept_verses_sheet.dart';

class BibleScreen extends ConsumerStatefulWidget {
  final String? initialBookId;
  final int? initialChapter;

  const BibleScreen({super.key, this.initialBookId, this.initialChapter});
  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  List<BiblePlanEntry>? _cachedPlan;
  String? _selectedLang;
  String? _pickedBookId;
  int? _pickedChapter;
  bool _completing = false;
  BibleBook? _offlineBook;
  bool _cardVisible = false;
  bool _showInlineReflection = false;
  bool _showReflectionPrompt = false;
  int? _pendingKeepIndex;
  final _reflectionKey = GlobalKey();
  Timer? _idleTimer;
  Timer? _dismissTimer;
  bool _showPeek = false;

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
    _tryRestoreLastRead();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) setState(() => _cardVisible = true);
      final kept = await ReadingPreferences.loadKeptVerse();
      if (mounted) ref.read(keptVerseProvider.notifier).state = kept;
      final all = await ReadingPreferences.loadAllKeptVerses();
      if (mounted) ref.read(allKeptVersesProvider.notifier).state = all;
    });
  }

  Future<void> _tryRestoreLastRead() async {
    if (_pickedBookId != null) return;
    final last = await ReadingPreferences.loadLastRead();
    if (last.bookId != null && last.chapter != null && mounted) {
      setState(() {
        _pickedBookId = last.bookId;
        _pickedChapter = last.chapter;
        if (last.language != null) _selectedLang = last.language;
      });
    }
  }

  @override
  void didUpdateWidget(covariant BibleScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialBookId != old.initialBookId ||
        widget.initialChapter != old.initialChapter) {
      if (widget.initialBookId != null && widget.initialChapter != null) {
        setState(() {
          _pickedBookId = widget.initialBookId;
          _pickedChapter = widget.initialChapter;
        });
      }
    }
  }

  void _saveReadingPosition() {
    if (_pickedBookId != null && _pickedChapter != null) {
      ReadingPreferences.saveLastRead(_pickedBookId!, _pickedChapter!, _effectiveLang);
    }
  }

  ({String bookId, int chapter})? _resolveParsed() {
    if (_pickedBookId != null && _pickedChapter != null) {
      return (bookId: _pickedBookId!, chapter: _pickedChapter!);
    }
    final plan = _cachedPlan;
    if (plan == null || plan.isEmpty) return null;
    final day = ScriptureService.getTodaysReading(_planId).day;
    final entry = day <= plan.length ? plan[day - 1] : plan.last;
    return ScriptureService.parseReference(entry.reference);
  }

  void _seekToVerse(int index) {
    ref.read(audioPlayerProvider.notifier).seekToVerse(index);
  }

  int? _keptVerseIndex() {
    final kept = ref.read(keptVerseProvider);
    if (kept == null) return null;
    final parsed = _resolveParsed();
    if (parsed == null) return null;
    if (kept.bookId != parsed.bookId || kept.chapter != parsed.chapter) return null;
    return kept.verse - 1;
  }

  void _appendKeptVerse(KeptVerse v) {
    final list = [...ref.read(allKeptVersesProvider)];
    ReadingPreferences.appendKeptVerse(list, v);
    ref.read(allKeptVersesProvider.notifier).state = list;
    ReadingPreferences.saveAllKeptVerses(list);
  }

  void _confirmKeep(int verseNumber, String text) {
    final parsed = _resolveParsed();
    if (parsed == null) return;
    final kept = KeptVerse(
      bookId: parsed.bookId, chapter: parsed.chapter, verse: verseNumber,
      text: text, timestamp: DateTime.now().millisecondsSinceEpoch, isAm: _isAm,
    );
    ref.read(keptVerseProvider.notifier).state = kept;
    ReadingPreferences.saveKeptVerse(kept);
    _appendKeptVerse(kept);
    setState(() => _pendingKeepIndex = null);
  }

  void _handleReflectionAvailable(bool v) {
    setState(() => _showReflectionPrompt = v);
  }

  void _openReflection(int verseNumber, String text) {
    final parsed = _resolveParsed();
    if (parsed == null) return;
    final book = ScriptureService.bookMap[parsed.bookId];
    final kept = KeptVerse(
      bookId: parsed.bookId, chapter: parsed.chapter, verse: verseNumber,
      text: text, timestamp: DateTime.now().millisecondsSinceEpoch, isAm: _isAm,
    );
    ref.read(keptVerseProvider.notifier).state = kept;
    ReadingPreferences.saveKeptVerse(kept);
    _appendKeptVerse(kept);
    setState(() { _pendingKeepIndex = null; _showReflectionPrompt = false; });
    _showReflectionSheet(verseNumber, text, parsed.bookId, book?.nameEn ?? parsed.bookId);
  }

  void _showReflectionSheet(int verseNumber, String text, String bookId, String bookName) {
    final svc = VerseReflectionService();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      builder: (ctx) => _ReflectionSheet(
        text: text,
        reference: '$bookName $verseNumber',
        reflection: svc.forVerse(bookId, text, _isAm),
        onVerseTap: () {
          Navigator.pop(ctx);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _openJournalFromVerse(verseNumber, text, bookId);
          });
        },
      ),
    );
  }

  void _openJournalFromVerse(int verseNumber, String text, String bookId) {
    final book = ScriptureService.bookMap[bookId];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      builder: (_) => JournalSheet(
        reference: '${book?.nameEn ?? bookId} $verseNumber',
        verseText: text,
        verseId: '${bookId}_$verseNumber',
      ),
    );
  }

  static const _reflectionTextEn = [
    'What\'s happening here',
    'Something about God in these words',
    'Something that stays',
  ];

  static const _reflectionTextAm = [
    'እዚህ ምን እየተከሰተ ነው',
    'በእነዚህ ቃላት ውስጥ ስለ እግዚአብሔር',
    'የሚቀመጥ ነገር',
  ];

  void _resetIdleTimers() {
    _idleTimer?.cancel();
    _dismissTimer?.cancel();
    if (_showPeek) setState(() => _showPeek = false);
    _idleTimer = Timer(const Duration(milliseconds: 1800), _showPeekSheet);
  }

  void _showPeekSheet() {
    final verses = ref.read(allKeptVersesProvider);
    if (verses.isEmpty || !mounted) return;
    setState(() => _showPeek = true);
    _dismissTimer = Timer(const Duration(seconds: 5), _dismissPeek);
  }

  void _dismissPeek() {
    _idleTimer?.cancel();
    if (mounted) setState(() => _showPeek = false);
  }

  void _openFullKeptVersesSheet() {
    setState(() => _showPeek = false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      builder: (_) => KeptVersesSheet(isAm: _isAm),
    );
  }

  Widget _buildPeekSheet() {
    final verses = ref.read(allKeptVersesProvider);
    final v = verses.first;
    final c = AppColors.of(context);
    final book = ScriptureService.bookMap[v.bookId];
    final refStr = '${_isAm ? book?.nameAm ?? v.bookId : book?.nameEn ?? v.bookId} ${v.verse}';
    final peekHeight = MediaQuery.of(context).size.height * 0.18;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
        offset: _showPeek ? Offset.zero : const Offset(0, 1),
        child: GestureDetector(
          onTap: () {
            setState(() => _showPeek = false);
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              builder: (_) => JournalSheet(
                reference: refStr,
                verseText: v.text,
                verseId: '${v.bookId}_${v.verse}',
              ),
            );
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
              _openFullKeptVersesSheet();
            }
          },
          child: Container(
            height: peekHeight,
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        refStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        v.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textPrimary,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildKeepPrompt() {
    return const SizedBox.shrink();
  }

  Widget _buildReflectionPrompt() {
    return const SizedBox.shrink();
  }

  Widget _buildKeptVerseBanner() {
    final kept = ref.watch(keptVerseProvider);
    if (kept == null) return const SizedBox.shrink();
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Text(
        kept.text,
        style: TextStyle(
          fontSize: 13,
          color: c.textPrimary.withValues(alpha: 0.7),
          height: 1.4,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildInlineReflection({Key? key}) {
    final prompts = _isAm ? _reflectionTextAm : _reflectionTextEn;
    final c = AppColors.of(context);
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 12),
        Text(prompts[0],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: c.textPrimary, height: 1.6)),
        SizedBox(height: 12),
        Text(prompts[1],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13,
            color: c.textPrimary.withValues(alpha: 0.75), height: 1.6)),
        SizedBox(height: 10),
        Text(prompts[2],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12,
            color: c.textPrimary.withValues(alpha: 0.5), height: 1.6)),
        SizedBox(height: 16),
      ],
    );
  }

  String get _planId {
    final user = ref.read(userProvider).valueOrNull;
    return user?.biblePlan ?? 'nt';
  }

  void _onAudioComplete(AudioPlayerState? prev, AudioPlayerState next) {
    final wasActive = prev?.state == AudioState.playing ||
        prev?.state == AudioState.paused;
    final nowStopped = next.state == AudioState.stopped;

    if (wasActive && nowStopped && !_completing) {
      _handleChapterComplete();
    }
  }

  Future<void> _handleChapterComplete() async {
    if (_completing) return;
    _completing = true;

    final parsed = _resolveParsed();
    if (parsed == null) {
      _completing = false;
      return;
    }

    final book = ScriptureService.bookMap[parsed.bookId];
    if (book == null) {
      _completing = false;
      return;
    }
    final refStr =
        '${_isAm ? book.nameAm : book.nameEn} ${parsed.chapter}';

    await ref
        .read(bibleNotifierProvider.notifier)
        .markAsRead(refStr);

    ref.read(bibleSessionNotifierProvider.notifier).logSession(
      bookId: parsed.bookId,
      chapterStart: parsed.chapter,
      chapterEnd: parsed.chapter,
      durationMinutes: 10,
    );

    if (!mounted) { _completing = false; return; }

    final db = ref.read(databaseProvider);
    final prog = await PlanProgressService.compute(db);
    final bookCompleted = prog.otProgress
            .any((p) => p.book.id == parsed.bookId && p.isComplete) ||
        prog.ntProgress
            .any((p) => p.book.id == parsed.bookId && p.isComplete);

    if (bookCompleted && mounted) {
      showWisdomDialog(context, ref, parsed.bookId, _isAm);
    }

    if (mounted) {
      _showChapterCompleteModal(book, parsed.chapter);
    }

    _completing = false;
  }

  static const _completionMessages = [
    'Showing up matters.',
    'A few minutes with the Word is never wasted.',
    'He is present.',
  ];

  static const _completionMessagesAm = [
    'መገኘት ትርጉም አለው።',
    'ጥቂት ደቂቃ ከቃሉ ጋር ፍሬ አለው።',
    'እሱ አለ።',
  ];

  void _showChapterCompleteModal(BibleBook book, int chapter) {
    final c = AppColors.of(context);
    final isAm = _isAm;
    final msgIdx = DateTime.now().millisecond % _completionMessages.length;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('📖', style: TextStyle(fontSize: 32)),
          SizedBox(height: 12),
          Text(
            isAm ? _completionMessagesAm[msgIdx] : _completionMessages[msgIdx],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.textSecondary, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _continueToNextChapter(book, chapter);
                },
                child: Text(isAm ? 'ቀጥል' : 'Continue'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAm ? 'ዝጋ' : 'Close'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _continueToNextChapter(BibleBook book, int chapter) {
    setState(() {
      _showInlineReflection = false;
      _showReflectionPrompt = false;
      _pendingKeepIndex = null;
    });
    final allBooks = ScriptureService.allBooks;
    if (chapter < book.chapters) {
      setState(() {
        _pickedBookId = book.id;
        _pickedChapter = chapter + 1;
      });
      _saveReadingPosition();
      return;
    }
    final idx = allBooks.indexWhere((b) => b.id == book.id);
    if (idx >= 0 && idx + 1 < allBooks.length) {
      setState(() {
        _pickedBookId = allBooks[idx + 1].id;
        _pickedChapter = 1;
      });
      _saveReadingPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(audioPlayerProvider, _onAudioComplete);

    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    if (!isOnline) {
      return _buildOfflineView();
    }

    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: ErrorCard(message: 'Could not load Bible plan')),
      data: (user) {
        final planId = user.biblePlan;
        _cachedPlan ??= ScriptureService.getPlan(planId);

        final parsed = _resolveParsed();
        final c = AppColors.of(context);

        if (parsed != null) {
          _saveReadingPosition();
        }

        final scriptureAsync = parsed != null
            ? ref.watch(scriptureProvider((
                bookId: parsed.bookId,
                chapter: parsed.chapter,
                isAmharic: _isAm,
              )))
            : null;

        final playerState = ref.watch(audioPlayerProvider);
        final audioChapterLoaded = playerState.chapter != null &&
            playerState.verseTexts.isNotEmpty;

        String title;
        if (parsed != null) {
          final book = ScriptureService.bookMap[parsed.bookId];
          title = book != null
              ? '📖 ${_isAm ? book.nameAm : book.nameEn} ${parsed.chapter}'
              : (_isAm ? '📖 መጽሐፍ ቅዱስ' : '📖 Bible');
        } else {
          title = _isAm ? 'መጽሐፍ ቅዱስ' : 'Bible';
        }

        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: c.textPrimary.withValues(alpha: 0.4)),
              onPressed: () => context.go('/'),
            ),
            title: Text(title,
                style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
            actions: [
              _buildLangToggle(),
              IconButton(
                icon: Icon(Icons.text_fields,
                    color: c.textSecondary.withValues(alpha: 0.4), size: 18),
                tooltip: _isAm ? 'የቃላት መጠን' : 'Font Size',
                onPressed: () => _showFontSettings(context),
              ),
              IconButton(
                icon: Icon(Icons.menu_book,
                    color: c.textSecondary.withValues(alpha: 0.4), size: 18),
                tooltip: _isAm ? 'መጻሕፍት' : 'Books',
                onPressed: () => _showBookPicker(context),
              ),
              IconButton(
                icon: Icon(Icons.download_outlined,
                    color: c.textSecondary.withValues(alpha: 0.4), size: 18),
                tooltip: _isAm ? 'የወረዱ' : 'Downloads',
                onPressed: () => _showLibrary(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              Listener(
                onPointerDown: (_) => _resetIdleTimers(),
                onPointerUp: (_) => _resetIdleTimers(),
                child: Column(
                  children: [
                    AudioPlayerBar(isAm: _isAm),
                    _buildKeptVerseBanner(),
                    _buildStartTodayCard(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: KeyedSubtree(
                          key: ValueKey(parsed != null ? '${parsed.bookId}:${parsed.chapter}' : 'null'),
                          child: scriptureAsync != null
                              ? scriptureAsync.when(
                              loading: () => VerseListView(
                                chapter: null,
                                isAm: _isAm,
                                pendingKeepIndex: _pendingKeepIndex,
                                keptVerseIndex: _keptVerseIndex(),
                                onKeepPendingChanged: (i) => setState(() => _pendingKeepIndex = i),
                                onKeepConfirmed: (vNum, text) { _confirmKeep(vNum, text); Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _resetIdleTimers(); }); },
                                onReflectionRequested: (vNum, text) { _openReflection(vNum, text); Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _resetIdleTimers(); }); },
                                onReflectionAvailable: _handleReflectionAvailable,
                                trailing: parsed != null
                                    ? (_showInlineReflection
                                        ? TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0, end: 1),
                                            duration: Duration(milliseconds: 400),
                                            builder: (ctx, value, child) =>
                                                Opacity(opacity: value, child: child),
                                            child: _buildInlineReflection(key: _reflectionKey),
                                          )
                                        : _showReflectionPrompt
                                            ? _buildReflectionPrompt()
                                            : _pendingKeepIndex != null
                                                ? _buildKeepPrompt()
                                                : null)
                                    : null,
                              ),
                              error: (e, _) => Center(
                                child: Text(
                                  _isAm ? 'ጽሑፉን ማምጣት አልተቻለም' : 'Couldn\'t load this passage',
                                  style: TextStyle(color: c.textSecondary),
                                ),
                              ),
                              data: (chapter) => VerseListView(
                                chapter: chapter,
                                currentVerseIndex: audioChapterLoaded
                                    ? playerState.currentVerse
                                    : null,
                                isAm: _isAm,
                                onVerseTap: audioChapterLoaded ? (i) { _seekToVerse(i); _resetIdleTimers(); } : null,
                                pendingKeepIndex: _pendingKeepIndex,
                                keptVerseIndex: _keptVerseIndex(),
                                onKeepPendingChanged: (i) => setState(() => _pendingKeepIndex = i),
                                onKeepConfirmed: (vNum, text) { _confirmKeep(vNum, text); Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _resetIdleTimers(); }); },
                                onReflectionRequested: (vNum, text) { _openReflection(vNum, text); Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _resetIdleTimers(); }); },
                                onReflectionAvailable: _handleReflectionAvailable,
                                trailing: parsed != null
                                    ? (_showInlineReflection
                                        ? TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0, end: 1),
                                            duration: Duration(milliseconds: 400),
                                            builder: (ctx, value, child) =>
                                                Opacity(opacity: value, child: child),
                                            child: _buildInlineReflection(key: _reflectionKey),
                                          )
                                        : _showReflectionPrompt
                                            ? _buildReflectionPrompt()
                                            : _pendingKeepIndex != null
                                                ? _buildKeepPrompt()
                                                : null)
                                    : null,
                              ),
                            )
                          : VerseListView(
                              chapter: null,
                              isAm: _isAm,
                            ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showPeek) _buildPeekSheet(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartTodayCard() {
    final c = AppColors.of(context);
    final todayReads = ref.watch(todayBibleReadProvider).valueOrNull ?? [];
    final alreadyRead = todayReads.isNotEmpty;

    Widget card;
    if (alreadyRead) {
      card = Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Text('🕊️', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Text(
            _isAm ? 'ዛሬ ተነቧል።' : 'Read today.',
            style: TextStyle(fontSize: 12, color: AppColors.success),
          ),
        ]),
      );
    } else {
      final suggestion = ref.watch(todaySuggestionProvider).valueOrNull;
      if (suggestion == null) return const SizedBox.shrink();
      final book = ScriptureService.bookMap[suggestion.bookId];
      if (book == null) return const SizedBox.shrink();

      card = Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Text('☀️', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_isAm ? book.nameAm : book.nameEn} ${suggestion.chapter}',
              style: TextStyle(fontSize: 12, color: c.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _showInlineReflection = false;
                _showReflectionPrompt = false;
                _pendingKeepIndex = null;
                _pickedBookId = suggestion.bookId;
                _pickedChapter = suggestion.chapter;
              });
              _saveReadingPosition();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _isAm ? 'ክፈት' : 'Open',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ]),
      );
    }

    return AnimatedOpacity(
      opacity: _cardVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: card,
    );
  }

  Widget _buildLangToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _langChip('AMH', 'am'),
        SizedBox(width: 4),
        _langChip('ENG', 'en'),
      ]),
    );
  }

  Widget _langChip(String label, String lang) {
    final c = AppColors.of(context);
    final active = _effectiveLang == lang;
    return GestureDetector(
      onTap: () {
        if (_effectiveLang != lang) {
          setState(() {
            _showInlineReflection = false;
            _showReflectionPrompt = false;
            _pendingKeepIndex = null;
            _selectedLang = lang;
          });
          _saveReadingPosition();
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
            color: active
                ? const Color(0xFF07090E)
                : c.textMuted,
          ),
        ),
      ),
    );
  }

  void _showFontSettings(BuildContext context) {
    final c = AppColors.of(context);
    final currentSize = ref.read(fontSizeProvider);
    final currentSpacing = ref.read(lineSpacingProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.text_fields, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(_isAm ? 'የቃላት መጠን' : 'Text Settings',
                        style: AppTextStyles.labelLarge),
                  ]),
                  const SizedBox(height: 16),
                  Text(_isAm ? 'የቃላት መጠን' : 'Font Size',
                      style: TextStyle(fontSize: 11, color: c.textMuted)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.text_fields, size: 16, color: c.textMuted),
                    Expanded(
                      child: Slider(
                        value: currentSize,
                        min: 12,
                        max: 24,
                        divisions: 12,
                        label: '${currentSize.round()}',
                        onChanged: (v) {
                          ref.read(fontSizeProvider.notifier).state = v;
                          ReadingPreferences.saveFontSize(v);
                          setSheetState(() {});
                        },
                      ),
                    ),
                    Icon(Icons.text_fields, size: 24, color: c.textMuted),
                  ]),
                  const SizedBox(height: 12),
                  Text(_isAm ? 'የመስመር ክፍተት' : 'Line Spacing',
                      style: TextStyle(fontSize: 11, color: c.textMuted)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('1.3', style: TextStyle(fontSize: 11, color: c.textMuted)),
                    Expanded(
                      child: Slider(
                        value: currentSpacing,
                        min: 1.3,
                        max: 2.2,
                        divisions: 9,
                        label: currentSpacing.toStringAsFixed(1),
                        onChanged: (v) {
                          ref.read(lineSpacingProvider.notifier).state = v;
                          ReadingPreferences.saveLineSpacing(v);
                          setSheetState(() {});
                        },
                      ),
                    ),
                    Text('2.2', style: TextStyle(fontSize: 11, color: c.textMuted)),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isAm
                          ? 'ቃልህ ለእግሮቼ መብራት፥ ለመንገዴም ብርሃን ነው።'
                          : 'Your word is a lamp for my feet, a light on my path.',
                      style: TextStyle(
                        fontSize: currentSize,
                        height: currentSpacing,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBookPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: _BookChapterPicker(
            isAm: _isAm,
            onSelected: (bookId, chapter) {
              Navigator.pop(ctx);
              setState(() {
                _showInlineReflection = false;
                _showReflectionPrompt = false;
                _pendingKeepIndex = null;
                _pickedBookId = bookId;
                _pickedChapter = chapter;
              });
              _saveReadingPosition();
            },
          ),
        );
      },
    );
  }

  void _showLibrary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      builder: (_) => LibrarySheet(
        isAm: _isAm,
        onBookSelected: (bookId, chapter, language) {
          setState(() {
            _showInlineReflection = false;
            _showReflectionPrompt = false;
            _pendingKeepIndex = null;
            _selectedLang = language;
            _pickedBookId = bookId;
            _pickedChapter = chapter;
          });
          _saveReadingPosition();
        },
      ),
    );
  }

  Widget _buildOfflineView() {
    final c = AppColors.of(context);
    final downloaded = ref.watch(downloadedBooksProvider).valueOrNull ?? [];
    final bookIds = downloaded.map((b) => b.bookId).toSet();
    final books = ScriptureService.allBooks
        .where((b) => bookIds.contains(b.id)).toList();

    if (books.isEmpty) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: c.textPrimary.withValues(alpha: 0.4)),
            onPressed: () => context.go('/'),
          ),
          title: Text(_isAm ? 'የወረዱ' : 'Downloads',
              style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
          actions: [_buildLangToggle()],
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off,
                size: 40, color: c.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(_isAm ? 'ምንም የወረዱ መጻሕፍት የሉም' : 'No downloaded books',
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 13, color: c.textMuted)),
            const SizedBox(height: 4),
            Text(_isAm ? 'መጽሐፍ ያውርዱ እና ያንብቡ' : 'Download a book to read offline',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: c.textMuted.withValues(alpha: 0.6))),
          ]),
        ),
      );
    }

    if (_offlineBook != null) {
      return _buildOfflineChapterPicker(c);
    }

    return _buildOfflineBookList(c, books);
  }

  Widget _buildOfflineBookList(ThemePalette c, List<BibleBook> books) {
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary.withValues(alpha: 0.4)),
          onPressed: () => context.go('/'),
        ),
        title: Text(_isAm ? 'የወረዱ' : 'Downloads',
            style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
        actions: [_buildLangToggle()],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: AppColors.warning.withValues(alpha: 0.1),
          child: Row(children: [
            Icon(Icons.wifi_off, size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(_isAm ? 'ከበይነ መረብ ውጪ ነዎት' : 'You\'re offline',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning)),
            const Spacer(),
            Text('${books.length} ${_isAm ? 'መጽሐፍ' : 'books'}',
                style: TextStyle(fontSize: 11, color: c.textMuted)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(Icons.check_circle,
                    color: AppColors.primary, size: 20),
                title: Text(_isAm ? books[i].nameAm : books[i].nameEn,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary)),
                subtitle: Text(
                    '${books[i].chapters} ${_isAm ? 'ምዕራፎች' : 'chapters'}',
                    style: TextStyle(fontSize: 11, color: c.textMuted)),
                trailing: Icon(Icons.chevron_right,
                    size: 18, color: c.textMuted),
                onTap: () => setState(() => _offlineBook = books[i]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildOfflineChapterPicker(ThemePalette c) {
    final book = _offlineBook!;

    final enChapters = ref.watch(
        downloadedChaptersProvider((bookId: book.id, language: 'en')));
    final amChapters = ref.watch(
        downloadedChaptersProvider((bookId: book.id, language: 'am')));
    final downloaded = {
      ...?enChapters.valueOrNull,
      ...?amChapters.valueOrNull,
    };

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary.withValues(alpha: 0.4)),
          onPressed: () => setState(() => _offlineBook = null),
        ),
        title: Text(_isAm ? book.nameAm : book.nameEn,
            style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
        actions: [_buildLangToggle()],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text(_isAm ? 'ምዕራፍ ምረጥ' : 'Choose a chapter',
                style: TextStyle(fontSize: 13, color: c.textMuted)),
            const Spacer(),
            Text('${downloaded.length}/${book.chapters}',
                style: TextStyle(fontSize: 11, color: c.textMuted)),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: book.chapters,
            itemBuilder: (ctx, i) {
              final ch = i + 1;
              final dled = downloaded.contains(ch);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _pickedBookId = book.id;
                    _pickedChapter = ch;
                    _offlineBook = null;
                  });
                  _saveReadingPosition();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: dled
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : c.card,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$ch',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: dled
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: dled
                                  ? AppColors.primary
                                  : c.textMuted)),
                      if (dled)
                        const Icon(Icons.check, size: 12,
                            color: AppColors.primary),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ReflectionSheet extends StatelessWidget {
  final String text;
  final String reference;
  final String reflection;
  final VoidCallback? onVerseTap;
  const _ReflectionSheet({
    required this.text, required this.reference, required this.reflection,
    this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(reference,
                    style: TextStyle(fontSize: 11,
                      color: c.textMuted, fontWeight: FontWeight.w500))),
                  IconButton(
                    icon: Icon(Icons.share, size: 18, color: c.textMuted),
                    onPressed: () {
                      SharePlus.instance.share(ShareParams(
                        text: '$reference\n\n$text\n\n$reflection',
                      ));
                    },
                  ),
                ]),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: onVerseTap,
                  child: Text(text,
                    style: TextStyle(fontSize: 15,
                      color: c.textPrimary.withValues(alpha: 0.9),
                      height: 1.6, fontStyle: FontStyle.italic)),
                ),
                SizedBox(height: 20),
                Text(reflection,
                  style: TextStyle(fontSize: 14,
                    color: c.textPrimary, height: 1.7)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _BookChapterPicker extends ConsumerStatefulWidget {
  final bool isAm;
  final void Function(String bookId, int chapter) onSelected;
  const _BookChapterPicker(
      {required this.isAm, required this.onSelected});
  @override
  ConsumerState<_BookChapterPicker> createState() =>
      _BookChapterPickerState();
}

class _BookChapterPickerState
    extends ConsumerState<_BookChapterPicker> {
  BibleBook? _selectedBook;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _selectedBook != null
                ? () => setState(() => _selectedBook = null)
                : () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            _selectedBook != null
                ? (widget.isAm
                    ? _selectedBook!.nameAm
                    : _selectedBook!.nameEn)
                : (widget.isAm ? 'መጻሕፍት' : 'Books'),
            style: AppTextStyles.displaySmall.copyWith(fontSize: 18),
          ),
        ]),
      ),
      Expanded(
        child: _selectedBook == null
            ? ListView(
                children: ScriptureService.sections
                    .map((s) => _buildSection(s))
                    .toList())
            : ChapterPicker(
                book: _selectedBook!,
                onSelected: (ch) =>
                    widget.onSelected(_selectedBook!.id, ch)),
      ),
    ]);
  }

  Widget _buildSection(BibleSection s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding:
            const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(
          widget.isAm ? s.nameAm : s.nameEn,
          style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.of(context).textMuted.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500),
        ),
      ),
      ...s.books.map((b) => ListTile(
            dense: true,
            title: Text(widget.isAm ? b.nameAm : b.nameEn,
                style: const TextStyle(fontSize: 15)),
            subtitle: Text(
              widget.isAm ? b.themeAm : b.themeEn,
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.of(context).textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => setState(() => _selectedBook = b),
          )),
    ]);
  }
}
