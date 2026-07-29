import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/services/bible_text_service.dart';

class LibrarySheet extends ConsumerStatefulWidget {
  final bool isAm;
  final void Function(String bookId, int chapter, String language)?
      onBookSelected;

  const LibrarySheet({
    super.key,
    this.isAm = false,
    this.onBookSelected,
  });

  @override
  ConsumerState<LibrarySheet> createState() => _LibrarySheetState();
}

class _LibrarySheetState extends ConsumerState<LibrarySheet> {
  String? _downloading;
  final _downloadProgress = <String, double>{};
  BibleBook? _selectedBook;

  @override
  void initState() {
    super.initState();
    ref.read(audioCacheServiceProvider).repairOrphans();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isAm = widget.isAm;

    if (_selectedBook != null) {
      return _buildChapterPickerView(c);
    }

    final perLang = ref.watch(downloadedBooksProvider).valueOrNull ?? [];
    final user = ref.watch(userProvider).valueOrNull;

    final downloadedIds = perLang.map((b) => b.bookId).toSet();

    String? planBookId;
    String? planBookName;
    if (user != null) {
      final plan = ScriptureService.getPlan(user.biblePlan);
      if (plan.isNotEmpty) {
        final today = ScriptureService.getTodaysReading(user.biblePlan);
        final entry =
            today.day <= plan.length ? plan[today.day - 1] : plan.last;
        final parsed = ScriptureService.parseReference(entry.reference);
        if (parsed != null) {
          planBookId = parsed.bookId;
          planBookName = isAm
              ? ScriptureService.bookMap[parsed.bookId]?.nameAm
              : ScriptureService.bookMap[parsed.bookId]?.nameEn;
        }
      }
    }
    final planDownloaded =
        planBookId != null && downloadedIds.contains(planBookId);

    final downloadedBooks = ScriptureService.allBooks
        .where((b) => downloadedIds.contains(b.id))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: c.border, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            const Icon(Icons.download_outlined,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(isAm ? 'የወረዱ' : 'Downloads',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: c.textSecondary,
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: downloadedBooks.isEmpty &&
                  (planBookId == null || planDownloaded)
              ? _buildEmptyState(c, isAm, downloadedIds)
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  children: [
                    if (planBookId != null &&
                        !planDownloaded &&
                        planBookName != null)
                      _buildPlanCard(c, isAm, planBookName, planBookId),
                    if (downloadedBooks.isNotEmpty) ...[
                      if (planBookId != null && !planDownloaded)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 4),
                          child: Text(isAm ? 'የወረዱ' : 'Downloaded',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: c.textMuted)),
                        ),
                      ...downloadedBooks
                          .map((b) => _buildBookRow(c, isAm, b)),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: _downloading == null
                            ? () => _showBookPicker(context, downloadedIds)
                            : null,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(isAm ? 'መጽሐፍ ጨምር' : 'Add a book'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color:
                                  AppColors.primary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _buildChapterPickerView(ThemePalette c) {
    final isAm = widget.isAm;
    final book = _selectedBook!;

    final enChapters = ref.watch(
        downloadedChaptersProvider((bookId: book.id, language: 'en')));
    final amChapters = ref.watch(
        downloadedChaptersProvider((bookId: book.id, language: 'am')));
    final downloaded = {
      ...?enChapters.valueOrNull,
      ...?amChapters.valueOrNull,
    };

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: c.border, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
          child: Row(children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: c.textPrimary),
              onPressed: () => setState(() => _selectedBook = null),
            ),
            Text(isAm ? book.nameAm : book.nameEn,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
            const Spacer(),
            Text('${downloaded.length}/${book.chapters}',
                style: TextStyle(
                    fontSize: 11, color: c.textMuted)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
              color: c.textSecondary,
            ),
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
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.pop(context);
                  widget.onBookSelected!(
                      book.id, ch, isAm ? 'am' : 'en');
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: dled
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : c.card,
                    border: Border.all(
                      color: dled
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : c.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$ch',
                          style: TextStyle(
                              fontSize: 14,
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

  Widget _buildEmptyState(
      ThemePalette c, bool isAm, Set<String> downloadedIds) {
    if (_downloading != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(isAm ? 'በማውረድ ላይ...' : 'Downloading...',
              style: TextStyle(
                  fontSize: 13, color: c.textMuted)),
        ]),
      );
    }
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.download_outlined,
            size: 40, color: c.textMuted.withValues(alpha: 0.3)),
        const SizedBox(height: 8),
        Text(isAm ? 'የወረዱ የሉም' : 'No downloads yet',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: c.textMuted)),
        const SizedBox(height: 4),
        Text(isAm ? 'መጽሐፍ ለማውረድ ነካ ያድርጉ' : 'Tap ＋ to download a book',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: c.textMuted.withValues(alpha: 0.6))),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _downloading == null
              ? () => _showBookPicker(context, downloadedIds)
              : null,
          icon: const Icon(Icons.add, size: 16),
          label: Text(isAm ? 'መጽሐፍ ጨምር' : 'Add a book'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }

  Widget _buildPlanCard(
      ThemePalette c, bool isAm, String bookName, String bookId) {
    final isDownloading = _downloading == bookId;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), c.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_stories,
                size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      isAm
                          ? 'የንባብ እቅድህን ቀጥል'
                          : 'Continue your plan',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: c.textMuted)),
                  const SizedBox(height: 2),
                  Text(bookName,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                ]),
          ),
          const SizedBox(width: 8),
          if (isDownloading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            InkWell(
              onTap: () => _downloadBook(bookId),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(isAm ? 'አውርድ' : 'Download',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildBookRow(ThemePalette c, bool isAm, BibleBook book) {
    final isDownloading = _downloading == book.id;
    final progress = _downloadProgress[book.id];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: InkWell(
        onTap: isDownloading
            ? null
            : () => setState(() => _selectedBook = book),
        onLongPress:
            isDownloading ? null : () => _removeBook(book.id),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(children: [
            Icon(
              isDownloading
                  ? Icons.horizontal_split
                  : Icons.check_circle,
              size: 18,
              color: isDownloading
                  ? AppColors.audioBlue
                  : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAm ? book.nameAm : book.nameEn,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary),
                    ),
                    if (isDownloading && progress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 3,
                                backgroundColor: c.border,
                                valueColor:
                                    const AlwaysStoppedAnimation(
                                        AppColors.audioBlue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: c.textMuted)),
                        ]),
                      )
                    else
                      Text(
                          '${book.chapters} ${isAm ? 'ምዕራፎች' : 'chapters'}',
                          style: TextStyle(
                              fontSize: 11,
                              color: c.textMuted)),
                  ]),
            ),
            if (!isDownloading)
              Icon(Icons.chevron_right,
                  size: 16, color: c.textMuted),
          ]),
        ),
      ),
    );
  }

  Future<void> _downloadBook(String bookId) async {
    final isAm = widget.isAm;
    setState(() {
      _downloading = bookId;
      _downloadProgress[bookId] = 0.0;
    });
    try {
      final service = ref.read(audioCacheServiceProvider);
      final book = ScriptureService.bookMap[bookId];
      if (book == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAm ? 'መጽሐፍ አልተገኘም' : 'Book not found'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      final stats = await service.getStats();
      if (stats.freeMB < 100) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAm ? 'የማከማቻ ቦታ አልበቃም' : 'Not enough storage space'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      await service.pinBook(bookId, 'en');
      if (mounted) setState(() => _downloadProgress[bookId] = 0.5);

      await service.pinBook(bookId, 'am');
      if (mounted) setState(() => _downloadProgress[bookId] = 0.75);

      final all = <Future>[];
      for (int ch = 1; ch <= book.chapters; ch++) {
        if (!mounted) return;
        all.add(
            BibleTextService.cacheChapter(bookId, ch, isAmharic: false));
        all.add(
            BibleTextService.cacheChapter(bookId, ch, isAmharic: true));
      }
      for (int i = 0; i < all.length; i += 10) {
        if (!mounted) return;
        await Future.wait(
            all.sublist(i, (i + 10).clamp(0, all.length)));
      }

      if (mounted) setState(() => _downloadProgress[bookId] = 1.0);

      ref.invalidate(downloadedBooksProvider);
      ref.invalidate(cacheStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAm ? 'ተወረደ' : 'Downloaded'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAm ? 'አልተሳካም' : 'Download failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloading = null;
          _downloadProgress.remove(bookId);
        });
      }
    }
  }

  Future<void> _removeBook(String bookId) async {
    final isAm = widget.isAm;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAm ? 'አውርዱን ያስወግዱ' : 'Remove download?'),
        content: Text(isAm
            ? 'መጽሐፉ ከመሳሪያዎ ይወገዳል'
            : 'Delete all chapters and free up space?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isAm ? 'ተው' : 'Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isAm ? 'አስወግድ' : 'Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    final service = ref.read(audioCacheServiceProvider);
    await service.removeBook(bookId);
    ref.invalidate(downloadedBooksProvider);
    ref.invalidate(cacheStatsProvider);
  }

  void _showBookPicker(BuildContext context, Set<String> downloadedIds) {
    final isAm = widget.isAm;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).background,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: _BookPicker(
            isAm: isAm,
            downloadedIds: downloadedIds,
            onSelected: (bookId) {
              Navigator.pop(ctx);
              _downloadBook(bookId);
            },
          ),
        );
      },
    );
  }
}

class _BookPicker extends StatelessWidget {
  final bool isAm;
  final Set<String> downloadedIds;
  final void Function(String bookId) onSelected;

  const _BookPicker(
      {required this.isAm,
      required this.downloadedIds,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(children: [
      Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: c.border, borderRadius: BorderRadius.circular(2)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Text(isAm ? 'መጽሐፍ ምረጥ' : 'Choose a book',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            color: c.textSecondary,
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding),
          children: ScriptureService.sections.map((section) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      isAm ? section.nameAm : section.nameEn,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.textMuted),
                    ),
                  ),
                  ...section.books.map((book) {
                        final dled = downloadedIds.contains(book.id);
                        return InkWell(
                          onTap: dled ? null : () => onSelected(book.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              Expanded(
                                child: Text(
                                  isAm ? book.nameAm : book.nameEn,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: dled
                                          ? c.textMuted
                                          : c.textPrimary),
                                ),
                              ),
                              if (dled)
                                Icon(Icons.check, size: 14,
                                    color: AppColors.primary),
                            ]),
                          ),
                        );
                      }),
                ]);
          }).toList(),
        ),
      ),
    ]);
  }
}
