import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

/// Voice journal sessions for a given day (yyyy-MM-dd), newest first. A session
/// row keeps the raw transcript and the organized journal together forever,
/// independent of what is currently shown as the day's entry content.
final voiceJournalSessionsForDateProvider =
    FutureProvider.family<List<VoiceJournalData>, String>((ref, date) async {
  final db = ref.watch(databaseProvider);
  final rows = await (db.select(db.voiceJournal)
        ..where((s) => s.date.equals(date))
        ..orderBy([(s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc)]))
      .get();
  return rows;
});

/// Whether any voice journal session has already been saved into today's entry.
final voiceJournalSavedTodayProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final rows = await (db.select(db.voiceJournal)
        ..where((s) => s.date.equals(today) & s.savedToJournal.equals(true)))
      .get();
  return rows.isNotEmpty;
});

/// Persists voice-journal sessions: raw transcript + organized content + status.
class VoiceJournalNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<String> createSession({
    required String date,
    required String locale,
    required String rawTranscript,
    required String status,
    String? organizedContent,
    String? errorReason,
  }) async {
    final db = ref.read(databaseProvider);
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await db.into(db.voiceJournal).insert(VoiceJournalCompanion.insert(
      id: id,
      date: date,
      locale: locale,
      rawTranscript: rawTranscript,
      organizedContent: Value(organizedContent),
      status: status,
      errorReason: Value(errorReason),
      savedToJournal: const Value(false),
      createdAt: now,
      updatedAt: now,
    ));
    _invalidate();
    return id;
  }

  Future<void> updateSession({
    required String id,
    String? status,
    String? organizedContent,
    String? errorReason,
  }) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.voiceJournal)..where((s) => s.id.equals(id))).write(
      VoiceJournalCompanion(
        status: status == null ? const Value.absent() : Value(status),
        organizedContent:
            organizedContent == null ? const Value.absent() : Value(organizedContent),
        errorReason: errorReason == null ? const Value.absent() : Value(errorReason),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
    _invalidate();
  }

  /// Records that a session's organized content was saved into the day's
  /// journal entry.
  Future<void> markSaved(String id) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.voiceJournal)..where((s) => s.id.equals(id))).write(
      VoiceJournalCompanion(
        savedToJournal: const Value(true),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
    _invalidate();
  }

  void _invalidate() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    ref.invalidate(voiceJournalSessionsForDateProvider(today));
    ref.invalidate(voiceJournalSavedTodayProvider);
  }
}

final voiceJournalNotifierProvider =
    AsyncNotifierProvider<VoiceJournalNotifier, void>(VoiceJournalNotifier.new);