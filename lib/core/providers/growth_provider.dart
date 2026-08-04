import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../services/growth_content.dart';
import 'database_provider.dart';

/// The user's active journey (their own declared intention). Older rows remain
/// as journey memory and are never treated as tracking data.
final journeyProvider = FutureProvider<GrowthJourneyData?>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await (db.select(db.growthJourney)
    ..orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ])
  ).get();
  return rows.isEmpty ? null : rows.first;
});

/// 1-based day within the current journey; 0 when no journey is planted.
final journeyDayProvider = Provider<int>((ref) {
  final journey = ref.watch(journeyProvider).valueOrNull;
  if (journey == null) return 0;
  final start = DateTime.tryParse(journey.startDate) ?? DateTime.now();
  return GrowthContent.journeyDay(start, DateTime.now());
});

/// The active journey's intention (defaults to [JourneyIntention.abide]).
final activeIntentionProvider = Provider<JourneyIntention?>((ref) {
  final journey = ref.watch(journeyProvider).valueOrNull;
  if (journey == null) return null;
  return JourneyIntention.values.firstWhere(
    (i) => i.name == journey.intention,
    orElse: () => JourneyIntention.abide,
  );
});

/// Days in the active journey, or null for an open (ongoing) journey.
final activeTimeframeDaysProvider = Provider<int?>((ref) {
  return ref.watch(journeyProvider).valueOrNull?.timeframeDays;
});

/// The active journey's current movement, derived purely from its own clock.
final activeMovementProvider = Provider<JourneyMovement?>((ref) {
  final journey = ref.watch(journeyProvider).valueOrNull;
  final day = ref.watch(journeyDayProvider);
  if (journey == null || day <= 0) return null;
  return GrowthContent.movementFor(day, journey.timeframeDays);
});

class JourneyNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> plantJourney(
    JourneyIntention intention,
    int? timeframeDays, {
    String? note,
  }) async {
    final db = ref.read(databaseProvider);
    await db.into(db.growthJourney).insert(GrowthJourneyCompanion.insert(
      id: const Uuid().v4(),
      intention: intention.name,
      timeframeDays: Value<int?>(timeframeDays),
      startDate: DateTime.now().toIso8601String().substring(0, 10),
      note: Value<String?>(note),
      createdAt: DateTime.now().toIso8601String(),
    ));
    ref.invalidate(journeyProvider);
  }

  Future<void> harvestJourney() async {
    final db = ref.read(databaseProvider);
    final journey = await _latestJourney(db);
    if (journey == null) return;
    await (db.update(db.growthJourney)..where((t) => t.id.equals(journey.id)))
        .write(const GrowthJourneyCompanion(harvested: Value(true)));
    ref.invalidate(journeyProvider);
  }

  Future<GrowthJourneyData?> _latestJourney(AppDatabase db) async {
    final rows = await (db.select(db.growthJourney)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ])
    ).get();
    return rows.isEmpty ? null : rows.first;
  }
}

final journeyNotifierProvider =
    AsyncNotifierProvider<JourneyNotifier, void>(JourneyNotifier.new);
