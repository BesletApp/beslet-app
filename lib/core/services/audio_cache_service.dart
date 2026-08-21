import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';
import 'wordproject_bible_service.dart';
import 'ebible_web_audio_service.dart';
import 'scripture_service.dart';

const maxCacheMB = 300;
const minFreeMB = 100;

class CacheStats {
  final int totalBytes;
  final int pinnedBytes;
  final int cacheBytes;
  final int freeDeviceBytes;
  final int totalEntries;
  final int pinnedBooks;

  const CacheStats({
    required this.totalBytes,
    required this.pinnedBytes,
    required this.cacheBytes,
    required this.freeDeviceBytes,
    required this.totalEntries,
    required this.pinnedBooks,
  });

  int get totalMB => totalBytes ~/ (1024 * 1024);
  int get pinnedMB => pinnedBytes ~/ (1024 * 1024);
  int get cacheMB => cacheBytes ~/ (1024 * 1024);
  int get freeMB => freeDeviceBytes ~/ (1024 * 1024);
}

class BookDownloadInfo {
  final String bookId;
  final String language;
  final String nameEn;
  final String nameAm;
  final int totalChapters;
  final int downloadedChapters;
  final int totalBytes;
  final bool isPinned;

  const BookDownloadInfo({
    required this.bookId,
    required this.language,
    required this.nameEn,
    required this.nameAm,
    required this.totalChapters,
    required this.downloadedChapters,
    required this.totalBytes,
    required this.isPinned,
  });
}

class AudioCacheService {
  final AppDatabase _db;

  AudioCacheService(this._db);

  Future<File?> playChapter({
    required String id,
    required String bookId,
    required int chapter,
    required String language,
  }) async {
    final entry = await (_db.audioCache.select()
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (entry != null) {
      final file = File(entry.localPath);
      if (await file.exists()) {
        return file;
      }
    }

    final book = ScriptureService.bookMap[bookId];
    if (book == null) return null;

    final file = await _downloadAudio(book, chapter, language);
    if (file == null) return null;

    final now = DateTime.now();
    if (entry == null) {
      await _db.into(_db.audioCache).insert(AudioCacheCompanion.insert(
            id: id,
            bookId: bookId,
            chapter: chapter,
            language: language,
            localPath: file.path,
            sizeBytes: await file.length(),
            downloadedAt: now,
            status: 'ready',
          ));
    }

    await evictIfNeeded();
    return file;
  }

  Future<File?> ensureCached({
    required String id,
    required String bookId,
    required int chapter,
    required String language,
  }) async {
    final entry = await (_db.audioCache.select()
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (entry != null) {
      final file = File(entry.localPath);
      if (await file.exists()) return file;
    }

    return await playChapter(
      id: id,
      bookId: bookId,
      chapter: chapter,
      language: language,
    );
  }

  Future<List<BookDownloadInfo>> getBooks() async {
    final rows = await _db.audioCache.select().get();

    final bookAggs = <String, _BookAgg>{};
    for (final r in rows) {
      final key = '${r.bookId}_${r.language}';
      final agg = bookAggs.putIfAbsent(key, () => _BookAgg());
      agg.count++;
      agg.bytes += r.sizeBytes;
      if (r.isPinned) agg.isPinned = true;
    }

    final result = <BookDownloadInfo>[];
    for (final section in ScriptureService.sections) {
      for (final book in section.books) {
        for (final lang in ['en', 'am']) {
          final key = '${book.id}_$lang';
          final agg = bookAggs[key];
          if (agg == null) continue;
          result.add(BookDownloadInfo(
            bookId: book.id,
            language: lang,
            nameEn: book.nameEn,
            nameAm: book.nameAm,
            totalChapters: book.chapters,
            downloadedChapters: agg.count,
            totalBytes: agg.bytes,
            isPinned: agg.isPinned,
          ));
        }
      }
    }
    return result;
  }

  Future<List<AudioCacheData>> getCacheEntries() async {
    return await _db.audioCache.select().get();
  }

  Future<CacheStats> getStats() async {
    final rows = await _db.audioCache.select().get();
    int totalBytes = 0;
    int pinnedBytes = 0;
    for (final r in rows) {
      totalBytes += r.sizeBytes;
      if (r.isPinned) pinnedBytes += r.sizeBytes;
    }

    final pinnedBookIds = <String>{};
    for (final r in rows) {
      if (r.isPinned) pinnedBookIds.add('${r.bookId}_${r.language}');
    }

    return CacheStats(
      totalBytes: totalBytes,
      pinnedBytes: pinnedBytes,
      cacheBytes: totalBytes - pinnedBytes,
      freeDeviceBytes: await _getFreeDeviceBytes(),
      totalEntries: rows.length,
      pinnedBooks: pinnedBookIds.length,
    );
  }

  Future<void> pinBook(String bookId, String language) async {
    final book = ScriptureService.bookMap[bookId];
    if (book == null) return;

    final now = DateTime.now();

    for (int ch = 1; ch <= book.chapters; ch++) {
      final id = '${book.id}_${ch}_$language';
      final existing = await (_db.audioCache.select()
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();

      if (existing != null) {
        if (!existing.isPinned) {
          await (_db.audioCache.update()
                ..where((t) => t.id.equals(id)))
              .write(AudioCacheCompanion(isPinned: Value(true)));
        }
        continue;
      }

      final file = await _downloadAudio(book, ch, language);
      if (file == null) continue;

      await _db.into(_db.audioCache).insert(AudioCacheCompanion.insert(
            id: id,
            bookId: bookId,
            chapter: ch,
            language: language,
            localPath: file.path,
            sizeBytes: await file.length(),
            downloadedAt: now,
            isPinned: Value(true),
            status: 'ready',
          ));
    }
  }

  /// Downloads the recorded narration for a chapter from the provider that
  /// serves the given language: Amharic from WordProject (code `17`), English
  /// from the public-domain WEB recording on eBible.org.
  Future<File?> _downloadAudio(BibleBook book, int chapter, String language) async {
    try {
      return language == 'am'
          ? await WordProjectBibleService.getAudio(
              book.wordprojectId, chapter,
              languageCode: '17')
          : await EbibleWebAudioService.getAudio(book.id, chapter);
    } catch (_) {
      return null;
    }
  }

  Future<void> unpinBook(String bookId, String language) async {
    await (_db.audioCache.update()
          ..where((t) => t.bookId.equals(bookId))
          ..where((t) => t.language.equals(language)))
        .write(AudioCacheCompanion(isPinned: Value(false)));
  }

  Future<void> evictIfNeeded() async {
    while (true) {
      final stats = await getStats();
      if (stats.cacheMB <= maxCacheMB && stats.freeMB >= minFreeMB) break;

      final all = await (_db.audioCache.select()
            ..where((t) => t.isPinned.equals(false))
            ..orderBy([(t) => OrderingTerm(
                expression: t.downloadedAt, mode: OrderingMode.asc)]))
          .get();

      if (all.isEmpty) break;

      final victim = all.first;
      try {
        final file = File(victim.localPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      await (_db.audioCache.delete()
            ..where((t) => t.id.equals(victim.id)))
          .go();
    }
  }

  Future<Set<int>> getDownloadedChapters(String bookId, String language) async {
    final rows = await (_db.audioCache.select()
          ..where((t) => t.bookId.equals(bookId))
          ..where((t) => t.language.equals(language)))
        .get();
    return rows.map((r) => r.chapter).toSet();
  }

  Future<void> repairOrphans() async {
    final entries = await _db.audioCache.select().get();
    for (final e in entries) {
      final file = File(e.localPath);
      if (!await file.exists()) {
        await (_db.audioCache.delete()
              ..where((t) => t.id.equals(e.id)))
            .go();
      }
    }
  }

  Future<void> removeBook(String bookId) async {
    final entries = await (_db.audioCache.select()
          ..where((t) => t.bookId.equals(bookId)))
        .get();
    for (final e in entries) {
      try {
        final file = File(e.localPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await (_db.audioCache.delete()
          ..where((t) => t.bookId.equals(bookId)))
        .go();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/bible_text_cache');
      if (await cacheDir.exists()) {
        final files = await cacheDir.list().where((e) =>
            e is File && e.path.contains('/${bookId}_')).toList();
        for (final f in files) {
          await (f as File).delete();
        }
      }
    } catch (_) {}
  }

  static Future<int> _getFreeDeviceBytes() async {
    return 1024 * 1024 * 1024;
  }
}

class _BookAgg {
  int count = 0;
  int bytes = 0;
  bool isPinned = false;
}
