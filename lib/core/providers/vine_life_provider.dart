import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../services/scene_event_bus.dart';
import 'database_provider.dart';
import 'growth_streams_provider.dart';
import 'habits_provider.dart';
import 'soul_log_provider.dart';

/// Continuous living-state of the vine. Each reservoir is fed by its own
/// discipline and fades exponentially with a gentle half-life, so the garden
/// is honest about both yesterday's tending and today's absence. Presence
/// (when the Growth Zone was last opened) is remembered separately — that is
/// the thread that makes the garden feel it missed the user.
class VineLifeState {
  final double water; // prayer — half-life ~20h
  final double light; // the Word — freshness + today's minutes in the bank
  final double warmth; // fellowship — half-life ~30h
  final double diligence; // habits — today's count, fades across the day
  final int daysMissed; // full days since the last visit to the Growth Zone
  final double hoursAway; // hours since the last visit
  final int? mood; // today's soul mood, 1..5, if one was shared

  const VineLifeState({
    required this.water,
    required this.light,
    required this.warmth,
    required this.diligence,
    required this.daysMissed,
    required this.hoursAway,
    this.mood,
  });

  static const Duration _halfLifeWater = Duration(hours: 20);
  static const Duration _halfLifeLight = Duration(hours: 16);
  static const Duration _halfLifeWarmth = Duration(hours: 30);

  /// A quiet day is still a beautiful day: without tending the vine does not
  /// die, it simply rests.
  factory VineLifeState.compute({
    required List<VineDayData> rows,
    required DateTime now,
    required int todayReadingMinutes,
    required int todayHabitsDone,
    int? mood,
  }) {
    DateTime? latestPrayer;
    DateTime? latestReading;
    DateTime? latestFellowship;
    DateTime? lastVisit;
    for (final row in rows) {
      final prayer = _parse(row.prayerAt);
      final reading = _parse(row.readingAt);
      final fellowship = _parse(row.fellowshipAt);
      final visit = _parse(row.lastVisitAt);
      if (prayer != null && (latestPrayer == null || prayer.isAfter(latestPrayer))) {
        latestPrayer = prayer;
      }
      if (reading != null && (latestReading == null || reading.isAfter(latestReading))) {
        latestReading = reading;
      }
      if (fellowship != null && (latestFellowship == null || fellowship.isAfter(latestFellowship))) {
        latestFellowship = fellowship;
      }
      if (visit != null && (lastVisit == null || visit.isAfter(lastVisit))) {
        lastVisit = visit;
      }
    }

    final water = _decay(latestPrayer, now, _halfLifeWater);

    final freshness = _decay(latestReading, now, _halfLifeLight);
    final bank = _clamp01(todayReadingMinutes / 20); // 20 minutes is a full bank
    final light = _clamp01(0.62 * freshness + 0.38 * bank);

    final warmth = _decay(latestFellowship, now, _halfLifeWarmth);

    // Habit completions are known only by date; today's count fades from the
    // day's start so yesterday's diligence does not linger past its day.
    final midnight = DateTime(now.year, now.month, now.day);
    final diligence =
        _clamp01(todayHabitsDone / 4) * _decay(midnight, now, const Duration(hours: 26));

    var daysMissed = 0;
    var hoursAway = 0.0;
    if (lastVisit != null) {
      final gap = now.difference(lastVisit);
      if (!gap.isNegative) {
        daysMissed = gap.inDays;
        hoursAway = gap.inMinutes / 60;
      }
    }

    return VineLifeState(
      water: water,
      light: light,
      warmth: warmth,
      diligence: diligence,
      daysMissed: daysMissed,
      hoursAway: hoursAway,
      mood: mood,
    );
  }

  static DateTime? _parse(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso);

  static double _decay(DateTime? at, DateTime now, Duration halfLife) {
    if (at == null) return 0;
    final dtSeconds = now.difference(at).inSeconds;
    if (dtSeconds <= 0) return 1;
    return _clamp01(math.exp(-math.ln2 * dtSeconds / halfLife.inSeconds));
  }

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
}

String _dateOnly(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Persists the garden's memory. Hooks into the [SceneEventBus] so every
/// discipline is remembered the moment it happens — even on screens far from
/// the Growth Zone — and stamps presence whenever the Growth Zone is opened.
class VineLifeWriter {
  VineLifeWriter(this._ref);

  final Ref _ref;

  /// Writes the day's timestamp for the discipline a gesture belongs to.
  Future<void> recordEvent(SceneEvent event) async {
    final column = switch (event.type) {
      SceneEventType.water => 'prayerAt',
      SceneEventType.leafLight => 'readingAt',
      SceneEventType.branchGrow => 'fellowshipAt',
      _ => null,
    };
    if (column == null) return; // bloom / fruitPop / milestone move nothing.
    final db = _ref.read(databaseProvider);
    final today = _dateOnly(event.at);
    final iso = event.at.toIso8601String();
    try {
      final rows = await (db.select(db.vineDay)..where((t) => t.date.equals(today))).get();
      final companion = VineDayCompanion(
        date: Value(today),
        prayerAt: column == 'prayerAt' ? Value(iso) : const Value.absent(),
        readingAt: column == 'readingAt' ? Value(iso) : const Value.absent(),
        fellowshipAt: column == 'fellowshipAt' ? Value(iso) : const Value.absent(),
      );
      if (rows.isEmpty) {
        await db.into(db.vineDay).insert(companion);
      } else {
        await (db.update(db.vineDay)..where((t) => t.date.equals(today))).write(companion);
      }
      _ref.invalidate(vineLifeProvider);
    } catch (_) {
      // The garden must never break a discipline just because its memory failed.
    }
  }

  /// Stamps presence: the Growth Zone was opened just now.
  Future<void> touchLastVisit({DateTime? at}) async {
    final db = _ref.read(databaseProvider);
    final now = at ?? DateTime.now();
    final today = _dateOnly(now);
    final iso = now.toIso8601String();
    try {
      final rows = await (db.select(db.vineDay)..where((t) => t.date.equals(today))).get();
      if (rows.isEmpty) {
        await db.into(db.vineDay).insert(
          VineDayCompanion.insert(date: today, lastVisitAt: Value(iso)),
        );
      } else {
        await (db.update(db.vineDay)..where((t) => t.date.equals(today)))
            .write(VineDayCompanion(lastVisitAt: Value(iso)));
      }
      _ref.invalidate(vineLifeProvider);
    } catch (_) {}
  }

  /// Counts a transcendence moment played today (Dawn of Grace, lamp flare…).
  Future<void> recordMoment() async {
    final db = _ref.read(databaseProvider);
    final today = _dateOnly(DateTime.now());
    try {
      final rows = await (db.select(db.vineDay)..where((t) => t.date.equals(today))).get();
      if (rows.isEmpty) {
        await db.into(db.vineDay)
            .insert(VineDayCompanion.insert(date: today, momentsPlayed: const Value(1)));
      } else {
        await (db.update(db.vineDay)..where((t) => t.date.equals(today)))
            .write(VineDayCompanion(momentsPlayed: Value(rows.first.momentsPlayed + 1)));
      }
      _ref.invalidate(vineLifeProvider);
    } catch (_) {}
  }
}

final vineLifeWriterProvider = Provider<VineLifeWriter>((ref) => VineLifeWriter(ref));

/// The living state of the vine, recomputed whenever a discipline lands, the
/// day's Word/habits/mood change, or the Growth Zone is opened.
final vineLifeProvider = FutureProvider<VineLifeState>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final since = DateTime(now.year, now.month, now.day - 3);
  final rows = await (db.select(db.vineDay)
        ..where((t) => t.date.isBiggerOrEqualValue(_dateOnly(since))))
      .get();
  final readingMinutes = ref.watch(todayReadingProvider).valueOrNull?.minutes ?? 0;
  final habitsDone = ref.watch(todayCompletionsProvider).valueOrNull?.length ?? 0;
  final mood = ref.watch(todaySoulLogProvider).valueOrNull?.mood;
  return VineLifeState.compute(
    rows: rows,
    now: now,
    todayReadingMinutes: readingMinutes,
    todayHabitsDone: habitsDone,
    mood: mood,
  );
});
