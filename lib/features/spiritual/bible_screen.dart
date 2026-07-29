import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/scripture_service.dart';
import '../../core/providers/audio_player_provider.dart';
import '../../core/providers/scripture_provider.dart';
import '../../core/providers/reading_preferences_provider.dart';
import 'widgets/audio_player_bar.dart';
import 'widgets/verse_list_view.dart';
import 'widgets/chapter_picker.dart';
import 'widgets/journal_sheet.dart';

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
  int? _pendingKeepIndex;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final kept = await ReadingPreferences.loadKeptVerse();
      if (mounted) ref.read(keptVerseProvider.notifier).state = kept;
      final all = await ReadingPreferences.loadAllKeptVerses();
      if (mounted) ref.read(allKeptVersesProvider.notifier).state = all;
    });
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

  ({String bookId, int chapter})? _resolveParsed() {
    if (_pickedBookId != null && _pickedChapter != null) {
      return (bookId: _pickedBookId!, chapter: _pickedChapter!);
    }
    return null;
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

  void _handleReflectionFromVerse(int verseNumber, String text) {
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
    _openJournalFromVerse(verseNumber, text, parsed.bookId);
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

  @override
  Widget build(BuildContext context) {
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
        playerState.verseTexts.isNotEmpty;

    String title;
    if (parsed != null) {
      final book = ScriptureService.bookMap[parsed.bookId];
      title = book != null
          ? '${_isAm ? book.nameAm : book.nameEn} ${parsed.chapter}'
          : (_isAm ? 'መጽሐፍ ቅዱስ' : 'Bible');
    } else {
      title = _isAm ? 'መጽሐፍ ቅዱስ' : 'Bible';
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
            icon: Icon(Icons.settings,
                color: c.textSecondary.withValues(alpha: 0.4), size: 18),
            tooltip: _isAm ? 'ማዋቀሪያ' : 'Settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          AudioPlayerBar(isAm: _isAm),
          _buildKeptVerseBanner(),
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
                      onKeepConfirmed: (vNum, text) { _confirmKeep(vNum, text); },
                      onReflectionRequested: (vNum, text) { _handleReflectionFromVerse(vNum, text); },
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
                      onVerseTap: audioChapterLoaded ? (i) { _seekToVerse(i); } : null,
                      pendingKeepIndex: _pendingKeepIndex,
                      keptVerseIndex: _keptVerseIndex(),
                      onKeepPendingChanged: (i) => setState(() => _pendingKeepIndex = i),
                      onKeepConfirmed: (vNum, text) { _confirmKeep(vNum, text); },
                      onReflectionRequested: (vNum, text) { _handleReflectionFromVerse(vNum, text); },
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
            _pendingKeepIndex = null;
            _selectedLang = lang;
          });
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
                _pendingKeepIndex = null;
                _pickedBookId = bookId;
                _pickedChapter = chapter;
              });
            },
          ),
        );
      },
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
