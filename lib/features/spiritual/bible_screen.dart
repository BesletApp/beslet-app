import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/scripture_service.dart';
import '../../core/providers/audio_player_provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/scripture_provider.dart';
import '../../core/providers/reading_preferences_provider.dart';
import '../../core/providers/growth_streams_provider.dart';
import '../../core/providers/journal_provider.dart';
import '../../core/services/scene_event_bus.dart';
import '../../l10n/app_localizations.dart';
import '../growth/widgets/mini_vine.dart';
import 'widgets/audio_player_bar.dart';
import 'widgets/verse_list_view.dart';
import 'widgets/chapter_picker.dart';
import 'widgets/download_sheet.dart';
import 'widgets/verse_action_sheet.dart';
import 'widgets/reflection_input_field.dart';
import 'widgets/bottom_confirmation_button.dart';

class BibleScreen extends ConsumerStatefulWidget {
  final String? initialBookId;
  final int? initialChapter;

  const BibleScreen({super.key, this.initialBookId, this.initialChapter});
  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  String? _selectedLang;
  String? _pickedBookId;
  int? _pickedChapter;
  BibleBook? _offlineBook;

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _reflectionCtrl = TextEditingController();
  bool _footerRevealed = false;
  bool _confirming = false;
  Timer? _dwellTimer;

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onChapterOpened();
      });
    }
    _restoreOpenPage();
    _loadHighlightsState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _scrollCtrl.dispose();
    _reflectionCtrl.dispose();
    super.dispose();
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
        _resetFooter();
      }
    }
  }

  Future<void> _loadHighlightsState() async {
    final all = await ReadingPreferences.loadAllHighlights();
    if (!mounted) return;
    ref.read(highlightsProvider.notifier).state = all;
  }

  Future<void> _restoreOpenPage() async {
    if (_pickedBookId != null) return;
    final last = await ReadingPreferences.loadOpenPage();
    if (last.bookId != null && last.chapter != null && mounted) {
      setState(() {
        _pickedBookId = last.bookId;
        _pickedChapter = last.chapter;
        if (last.language != null) _selectedLang = last.language;
      });
    }
  }

  void _saveOpenPage() {
    if (_pickedBookId != null && _pickedChapter != null) {
      ReadingPreferences.saveOpenPage(_pickedBookId!, _pickedChapter!, _effectiveLang);
    }
  }

  void _onChapterOpened() {
    ref.read(readingNotifierProvider.notifier).logReading(
      minutes: 1,
      bookId: _pickedBookId,
      chapter: _pickedChapter,
    );
    ref.read(sceneEventBusProvider).emit(SceneEventType.leafLight);
  }

  /// The reader must reach the end of the chapter before the "I have read"
  /// button appears — a quick tap at the top can never finish the reading.
  void _onScroll() {
    if (_footerRevealed || !_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.maxScrollExtent > 0 &&
        pos.pixels >= pos.maxScrollExtent - 200) {
      setState(() => _footerRevealed = true);
    }
  }

  /// A very short chapter fits on one screen (no scroll extent). After a quiet
  /// dwell the footer appears anyway — the button is never there at open.
  void _armDwell() {
    _dwellTimer?.cancel();
    _dwellTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _footerRevealed = true);
      }
    });
  }

  void _resetFooter() {
    _dwellTimer?.cancel();
    _footerRevealed = false;
  }

  /// Once a chapter is laid out, if it fits on a single screen (no scroll
  /// extent) the reader can't "reach the end" by scrolling — so a short dwell
  /// quietly brings the confirmation into view. Long chapters never get this:
  /// the button waits for a real scroll to the bottom.
  void _scheduleShortChapterCheck() {
    if (_footerRevealed || _dwellTimer != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _footerRevealed) return;
      if (_scrollCtrl.hasClients && _scrollCtrl.position.maxScrollExtent <= 0) {
        _armDwell();
      }
    });
  }

  ({String bookId, int chapter})? _resolveParsed() {
    if (_pickedBookId != null && _pickedChapter != null) {
      return (bookId: _pickedBookId!, chapter: _pickedChapter!);
    }
    return null;
  }

  /// The quiet "done" state that lives at the bottom of the chapter — the
  /// reader reaches it only after actually reading. It carries the onward
  /// Prayer CTA so the flow continues without leaving the reader behind.
  Widget _buildDoneFooter(AppLocalizations l) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
        const SizedBox(width: 8),
        Text(
          l.readCompletedToday,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () => context.go('/prayer'),
          icon: const Icon(Icons.favorite, size: 16, color: Color(0xFF07090E)),
          label: Text(
            l.continueToPrayer,
            style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF07090E), fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  /// The bottom-of-screen footer: the reflection (optional) and the single
  /// "I have read" confirmation. It is hidden until the reader scrolls near
  /// the end of the chapter, so skipping is impossible.
  Widget _buildFooter(AppLocalizations l) {
    final c = AppColors.of(context);
    final todayReading = ref.watch(todayReadingProvider).valueOrNull;
    final done = todayReading?.completed == true;

    if (!_footerRevealed) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.cardElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border.withValues(alpha: 0.25)),
        ),
        child: done
            ? _buildDoneFooter(l)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ReflectionInputField(controller: _reflectionCtrl),
                const SizedBox(height: AppSpacing.md),
                BottomConfirmationButton(
                  busy: _confirming,
                  onPressed: _markReadingDone,
                ),
              ]),
      ),
    );
  }

  Future<void> _markReadingDone() async {
    final parsed = _resolveParsed();
    setState(() => _confirming = true);
    if (_reflectionCtrl.text.trim().isNotEmpty) {
      await ref.read(journalNotifierProvider.notifier).saveEntry(_reflectionCtrl.text.trim());
    }
    await ref.read(readingNotifierProvider.notifier).markCompleted(
      bookId: parsed?.bookId,
      chapter: parsed?.chapter,
    );
    ref.read(sceneEventBusProvider).emit(SceneEventType.fruitPop);
    if (!mounted) return;
    setState(() => _confirming = false);
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.readingXpEarned),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Map<int, String> _highlightedVerseColors() {
    final parsed = _resolveParsed();
    if (parsed == null) return {};
    return {
      for (final h in ref.read(highlightsProvider))
        if (h.bookId == parsed.bookId && h.chapter == parsed.chapter) h.verse: h.colorId,
    };
  }

  void _showVerseSheet(ScriptureVerse verse, int index) {
    final parsed = _resolveParsed();
    if (parsed == null) return;
    final reference = ScriptureService.referenceFor(
        parsed.bookId, parsed.chapter, verse.number, _isAm);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      builder: (_) => VerseActionSheet(
        bookId: parsed.bookId,
        chapter: parsed.chapter,
        verseNumber: verse.number,
        text: verse.text,
        reference: reference,
        isAm: _isAm,
        verseIndex: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    final l = AppLocalizations.of(context)!;

    if (!isOnline) {
      return _buildOfflineView();
    }

    final parsed = _resolveParsed();
    final c = AppColors.of(context);

    final scriptureAsync = parsed != null
        ? ref.watch(scriptureProvider((
            bookId: parsed.bookId,
            chapter: parsed.chapter,
            isAmharic: _isAm,
          )))
        : null;

    final playerState = ref.watch(audioPlayerProvider);
    final audioChapterLoaded = playerState.chapter != null &&
        playerState.verseTexts.isNotEmpty &&
        parsed != null &&
        playerState.chapter!.bookId == parsed.bookId &&
        playerState.chapter!.chapter == parsed.chapter &&
        playerState.chapter!.isAmharic == _isAm;
    final highlightedVerseColors = _highlightedVerseColors();

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
          onPressed: () {
            _saveOpenPage();
            context.go('/');
          },
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
      body: Column(
        children: [
          MiniVine(
            seed: 902,
            emphasis: MiniVineEmphasis.light,
            eventSource: ref.read(sceneEventBusProvider),
            height: 68,
          ),
          AudioPlayerBar(
            isAm: _isAm,
            bookId: parsed?.bookId,
            chapterNum: parsed?.chapter,
          ),
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
                        ),
                        error: (e, _) => Center(
                          child: Text(
                            _isAm ? 'ጽሑፉን ማምጣት አልተቻለም' : 'Couldn\'t load this passage',
                            style: TextStyle(color: c.textSecondary),
                          ),
                        ),
                        data: (chapter) {
                          _scheduleShortChapterCheck();
                          return VerseListView(
                            chapter: chapter,
                            currentVerseIndex: audioChapterLoaded
                                ? playerState.currentVerse
                                : null,
                            isAm: _isAm,
                            onVerseTap: _showVerseSheet,
                            highlightedVerseColors: highlightedVerseColors,
                            controller: _scrollCtrl,
                          );
                        },
                      )
                    : VerseListView(
                        chapter: null,
                        isAm: _isAm,
                      ),
              ),
            ),
          ),
          _buildFooter(l),
        ],
      ),
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
          setState(() => _selectedLang = lang);
          _saveOpenPage();
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
                _pickedBookId = bookId;
                _pickedChapter = chapter;
              });
              _resetFooter();
              _saveOpenPage();
              _onChapterOpened();
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
            _selectedLang = language;
            _pickedBookId = bookId;
            _pickedChapter = chapter;
          });
          _resetFooter();
          _saveOpenPage();
          _onChapterOpened();
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
                  _resetFooter();
                  _saveOpenPage();
                  _onChapterOpened();
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
