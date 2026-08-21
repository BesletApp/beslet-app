import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/scripture_provider.dart';

class BibleJourneyPlan {
  final String type;
  final String? bookId;
  final int pace;
  final int currentDayIndex;
  final bool paused;
  final bool completed;
  final String startDate;

  const BibleJourneyPlan({
    required this.type,
    this.bookId,
    required this.pace,
    required this.currentDayIndex,
    required this.paused,
    required this.completed,
    required this.startDate,
  });

  BibleJourneyPlan copyWith({
    String? type,
    String? bookId,
    int? pace,
    int? currentDayIndex,
    bool? paused,
    bool? completed,
    String? startDate,
  }) {
    return BibleJourneyPlan(
      type: type ?? this.type,
      bookId: bookId ?? this.bookId,
      pace: pace ?? this.pace,
      currentDayIndex: currentDayIndex ?? this.currentDayIndex,
      paused: paused ?? this.paused,
      completed: completed ?? this.completed,
      startDate: startDate ?? this.startDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'bookId': bookId,
    'pace': pace,
    'currentDayIndex': currentDayIndex,
    'paused': paused,
    'completed': completed,
    'startDate': startDate,
  };

  static BibleJourneyPlan? fromJson(Map<String, dynamic> j) {
    try {
      return BibleJourneyPlan(
        type: j['type'] as String,
        bookId: j['bookId'] as String?,
        pace: j['pace'] as int,
        currentDayIndex: j['currentDayIndex'] as int,
        paused: j['paused'] as bool,
        completed: j['completed'] as bool,
        startDate: j['startDate'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

class BibleJourneyService {
  static const _key = 'bible_journey_plan';

  static Future<BibleJourneyPlan?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return BibleJourneyPlan.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(BibleJourneyPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(plan.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> initialize(ProviderContainer container) async {
    final plan = await load();
    if (plan != null) {
      container.read(bibleJourneyProvider.notifier).state = plan;
    }
  }
}