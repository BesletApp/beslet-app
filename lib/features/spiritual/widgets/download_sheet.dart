import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/services/wordproject_bible_service.dart';
import '../../../core/services/bible_text_service.dart';

class DownloadSheet extends ConsumerStatefulWidget {
  final String currentBookId;
  final int currentChapter;
  final bool isAmharic;
  final bool isAlreadyDownloaded;
  final VoidCallback onDownloaded;

  const DownloadSheet({
    super.key,
    required this.currentBookId,
    required this.currentChapter,
    required this.isAmharic,
    required this.isAlreadyDownloaded,
    required this.onDownloaded,
  });

  @override
  ConsumerState<DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends ConsumerState<DownloadSheet> {
  bool _downloading = false;
  String? _downloadSize;

  @override
  void initState() {
    super.initState();
    if (!widget.isAlreadyDownloaded) _loadSize();
  }

  Future<void> _loadSize() async {
    try {
      final book = ScriptureService.bookMap[widget.currentBookId];
      if (book != null) {
        final langCode = widget.isAmharic ? '17' : '01';
        final sizeBytes = await WordProjectBibleService.getAudioSize(
            book.wordprojectId, widget.currentChapter, languageCode: langCode);
        if (sizeBytes != null && mounted) {
          setState(() => _downloadSize = (sizeBytes / (1024 * 1024)).toStringAsFixed(1));
        }
      }
    } catch (_) {}
  }

  Future<void> _doDownload() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final book = ScriptureService.bookMap[widget.currentBookId];
      await Future.wait([
        BibleTextService.cacheChapter(widget.currentBookId, widget.currentChapter, isAmharic: true),
        BibleTextService.cacheChapter(widget.currentBookId, widget.currentChapter, isAmharic: false),
      ]);
      if (book != null) {
        try {
          final langCode = widget.isAmharic ? '17' : '01';
          await WordProjectBibleService.getAudio(
              book.wordprojectId, widget.currentChapter, languageCode: langCode);
        } catch (_) {}
      }
      await ref.read(downloadListProvider.notifier).add(
        widget.currentBookId,
        widget.currentChapter,
        book?.nameEn ?? widget.currentBookId,
      );
      if (mounted) {
        setState(() => _downloading = false);
        widget.onDownloaded();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isAmharic ? 'ተከማችቷል' : 'Downloaded'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isAmharic ? 'ማውረድ አልተሳካም' : 'Download failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadListProvider);
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(children: [
            const Icon(Icons.download, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(isAm ? 'ማውረዶች' : 'Downloads', style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const Spacer(),
            Text('${downloads.length}', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: c.textMuted)),
          ]),
        ),
        Divider(height: 1, color: c.border),
        if (!widget.isAlreadyDownloaded)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _downloading ? null : _doDownload,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: _downloading
                      ? const Padding(padding: EdgeInsets.all(9), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : const Icon(Icons.download, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isAm ? 'ይህን ምዕራፍ አውርድ' : 'Download this chapter',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    if (_downloadSize != null)
                       Text('~$_downloadSize MB · ${isAm ? 'ኦዲዮን ያካትታል' : 'includes audio'}',
                           style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: c.textMuted)),
                  ])),
                  if (!_downloading) const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                ]),
              ),
            ),
          ),
        if (downloads.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(children: [
              Icon(Icons.download_outlined, size: 40, color: c.textMuted.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text(isAm ? 'ገና ምንም የወረዱ ምዕራፎች የሉም' : 'No downloaded chapters yet',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: c.textMuted)),
            ]),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: downloads.length,
              itemBuilder: (_, i) {
                final dl = downloads[i];
                final book = ScriptureService.bookMap[dl.bookId];
                final label = book != null
                    ? '${isAm ? book.nameAm : book.nameEn} ${dl.chapter}'
                    : '${dl.bookName} ${dl.chapter}';
                final isCurrent = dl.bookId == widget.currentBookId && dl.chapter == widget.currentChapter;
                return Column(children: [
                  if (i == 0 && !widget.isAlreadyDownloaded) Divider(height: 1, color: c.border),
                  ListTile(
                    dense: true,
                    leading: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary.withValues(alpha: 0.15) : c.border.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(isCurrent ? Icons.play_arrow : Icons.menu_book, size: 16,
                          color: isCurrent ? AppColors.primary : c.textMuted),
                    ),
                    title: Text(label, style: TextStyle(
                      fontFamily: 'Inter', fontSize: 13,
                      color: isCurrent ? AppColors.primary : c.textPrimary,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    )),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: c.textMuted),
                      onPressed: () => ref.read(downloadListProvider.notifier).remove(dl.bookId, dl.chapter),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/bible?book=${dl.bookId}&chapter=${dl.chapter}');
                    },
                  ),
                ]);
              },
            ),
          ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ]),
    );
  }
}
