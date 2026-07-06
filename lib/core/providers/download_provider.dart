import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/download_service.dart';

class DownloadListNotifier extends StateNotifier<List<DownloadedChapter>> {
  DownloadListNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    state = await DownloadService.getDownloads();
  }

  Future<void> add(String bookId, int chapter, String bookName) async {
    await DownloadService.addDownload(bookId, chapter, bookName);
    state = await DownloadService.getDownloads();
  }

  Future<void> remove(String bookId, int chapter) async {
    await DownloadService.removeDownload(bookId, chapter);
    state = await DownloadService.getDownloads();
  }

  Future<void> refresh() async {
    state = await DownloadService.getDownloads();
  }
}

final downloadListProvider = StateNotifierProvider<DownloadListNotifier, List<DownloadedChapter>>((ref) {
  return DownloadListNotifier();
});
