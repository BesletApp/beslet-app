import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/scripture_service.dart';
import '../../core/providers/database_provider.dart';

final _bookJournalProvider = FutureProvider<Map<String, List<Map<String, String>>>?>((ref) async {
  final db = ref.watch(databaseProvider);
  final reads = await db.select(db.bibleReads).get();
  final map = <String, List<Map<String, String>>>{};
  for (final r in reads) {
    if (r.note == null || r.note!.isEmpty) continue;
    for (final b in ScriptureService.allBooks) {
      String? nameMatch;
      if (r.reference.startsWith(b.nameEn)) {
        nameMatch = b.nameEn;
      } else if (r.reference.startsWith(b.nameAm)) {
        nameMatch = b.nameAm;
      }
      if (nameMatch != null) {
        final rest = r.reference.substring(nameMatch.length).trim();
        map.putIfAbsent(b.nameEn, () => []);
        map[b.nameEn]!.add({'chapter': rest, 'note': r.note!, 'bookId': b.id});
        break;
      }
    }
  }
  return map;
});

class BookJournalScreen extends ConsumerWidget {
  const BookJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(_bookJournalProvider);
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: c.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(isAm ? 'የእኔ ማስታወሻ' : 'My Journal', style: TextStyle(color: c.textPrimary)),
      ),
      body: journalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load journal', style: TextStyle(color: c.textSecondary))),
        data: (map) {
          if (map == null || map.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('📝', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(isAm ? 'ገና ምንም ማስታወሻ የለም' : 'No journal entries yet', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Text(isAm ? 'መጽሐፍ ቅዱስን ስታነብ እግዚአብሔር የሚነግርህን ጻፍ' : 'Write what God speaks to you as you read', style: TextStyle(color: c.textSecondary)),
                ]),
              ),
            );
          }
          final sortedBooks = map.keys.toList()..sort();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedBooks.length,
            itemBuilder: (_, i) {
              final bookName = sortedBooks[i];
              final entries = map[bookName]!;
              final book = entries.isNotEmpty ? ScriptureService.bookMap[entries.first['bookId']] : null;
              final displayName = book != null ? (isAm ? book.nameAm : book.nameEn) : bookName;
              return _BookSection(bookName: displayName, entries: entries, isAm: isAm, c: c);
            },
          );
        },
      ),
    );
  }
}

class _BookSection extends StatelessWidget {
  final String bookName;
  final List<Map<String, String>> entries;
  final bool isAm;
  final ThemePalette c;
  const _BookSection({required this.bookName, required this.entries, required this.isAm, required this.c});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: c.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c.border)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(bookName, style: AppTextStyles.labelLarge.copyWith(fontSize: 15)),
        subtitle: Text('${entries.length} ${isAm ? 'ማስታወሻ' : 'entries'}', style: TextStyle(fontSize: 11, color: c.textMuted)),
        children: entries.map((e) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${isAm ? 'ምዕራፍ' : 'Ch.'} ${e['chapter']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(e['note'] ?? '', style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.5)),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}
