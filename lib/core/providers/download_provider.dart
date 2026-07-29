import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/audio_cache_service.dart';
import 'database_provider.dart';

final audioCacheServiceProvider = Provider<AudioCacheService>((ref) {
  final db = ref.watch(databaseProvider);
  return AudioCacheService(db);
});

final cacheStatsProvider = FutureProvider<CacheStats>((ref) async {
  final service = ref.watch(audioCacheServiceProvider);
  return await service.getStats();
});

final downloadedBooksProvider = FutureProvider<List<BookDownloadInfo>>((ref) async {
  final service = ref.watch(audioCacheServiceProvider);
  return await service.getBooks();
});

final cacheEntriesProvider = FutureProvider<List<AudioCacheData>>((ref) async {
  final service = ref.watch(audioCacheServiceProvider);
  return await service.getCacheEntries();
});

final downloadedChaptersProvider =
    FutureProvider.family<Set<int>, ({String bookId, String language})>(
  (ref, params) async {
    final service = ref.watch(audioCacheServiceProvider);
    return await service.getDownloadedChapters(params.bookId, params.language);
  },
);
