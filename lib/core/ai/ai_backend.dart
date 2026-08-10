import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:google_generative_ai/google_generative_ai.dart';

import '../secrets.dart';
import 'ai_boundary.dart';
import 'ai_content.dart';
import 'ai_models.dart';

/// The seam that lets the Quiet Guide use any engine behind the same contract.
/// A backend returns a *raw choice* (an existing bank item id) or null on any
/// failure — it never throws, and it never writes prose. The validator is the
/// next step and rejects anything that is not an existing item.
abstract class AiBackend {
  Future<AiOutput?> select({
    required ContextPacket context,
    required AiMomentType type,
    required DateTime now,
  });
}

/// Tier 0 — the deterministic local engine. Offline, free, instant, and
/// identical on every device. It rotates through the curated bank by the day,
/// so each day offers a stable, gentle pointer. This is the default path.
class LocalRuleBackend implements AiBackend {
  final AiContentBank bank;

  const LocalRuleBackend(this.bank);

  @override
  Future<AiOutput?> select({
    required ContextPacket context,
    required AiMomentType type,
    required DateTime now,
  }) async {
    final dayIndex = math.max(0, now.difference(DateTime(2025, 1, 1)).inDays);
    switch (type) {
      case AiMomentType.weeklyReflection:
        final q = bank.questions[dayIndex % bank.questions.length];
        return AiOutput(mode: 'reflectiveGuidance', itemId: q.id);
      default:
        final p = bank.pointers[dayIndex % bank.pointers.length];
        return AiOutput(mode: 'scripturePointer', itemId: p.id);
    }
  }
}

/// Tier 1 — the free-tier Flash model, used as a *selector only*. It receives
/// nothing but coarse buckets and the allow-listed items; it returns one id or
/// silence. Any failure (offline, quota, malformed reply, no key) yields null
/// and the service falls back to Tier 0 or silence. It is wrapped so it can
/// never surface an error to the user and never block rendering.
class GeminiBackend implements AiBackend {
  final AiContentBank bank;
  final String? bundledKey;
  final Future<String?> Function() userKeyProvider;
  final String modelName;
  final Duration timeout;
  final int maxCallsPerDay;

  final Map<String, int> _callsByDay = {};
  String _lastDay = '';

  GeminiBackend({
    required this.bank,
    required this.bundledKey,
    required this.userKeyProvider,
    this.modelName = aiModelName,
    this.timeout = const Duration(seconds: 15),
    this.maxCallsPerDay = 6,
  });

  @override
  Future<AiOutput?> select({
    required ContextPacket context,
    required AiMomentType type,
    required DateTime now,
  }) async {
    final day = AiBoundaryGate.dayKeyFor(now);
    if (!_bumpBudget(day)) return null;

    final key = await _effectiveKey();
    if (key == null) return null;

    try {
      final model = GenerativeModel(model: modelName, apiKey: key);
      final schema = Schema.object(
        properties: {
          'mode': Schema.enumString(
            enumValues: const ['scripturePointer', 'reflectiveGuidance', 'silence'],
            description: 'Which kind of quiet moment to offer, or silence.',
          ),
          'itemId': Schema.string(
            description:
                'One of the provided pointer or question ids. Omit for silence.',
          ),
        },
        requiredProperties: ['mode'],
      );
      final response = await model
          .generateContent(
            [Content.text(_prompt(context, type))],
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
              responseSchema: schema,
            ),
          )
          .timeout(timeout);
      final text = response.text;
      if (text == null) return null;
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic>) return null;
      return AiOutput.fromJson(data);
    } catch (_) {
      return null; // silence-first: a failed call is never shown to a user
    }
  }

  /// Keeps the seam honest: even if the gate is bypassed, the engine will not
  /// spend more than a small daily budget.
  bool _bumpBudget(String day) {
    if (_lastDay != day) {
      _lastDay = day;
      _callsByDay.clear();
    }
    final next = (_callsByDay[day] ?? 0) + 1;
    _callsByDay[day] = next;
    return next <= maxCallsPerDay;
  }

  Future<String?> _effectiveKey() async {
    try {
      final user = await userKeyProvider();
      if (user != null && user.trim().isNotEmpty) return user.trim();
    } catch (_) {}
    final bundled = bundledKey;
    if (bundled == null ||
        bundled.isEmpty ||
        bundled.contains('YOUR_API_KEY')) {
      return null;
    }
    return bundled;
  }

  String _prompt(ContextPacket context, AiMomentType type) {
    final pointerList = [
      for (final p in bank.pointers)
        '{"id":"${p.id}","ref":"${p.toReference().referenceFor(false)}"}',
    ].join(',\n');
    final questionList = [
      for (final q in bank.questions) '{"id":"${q.id}"}',
    ].join(',\n');
    return '''
You are a selector inside a quiet spiritual reading app. You are not a chat
assistant, you have no voice, and you are never seen by the user.

Non-negotiable rules:
- You never speak as God, never interpret God's will, never give directives,
  never advise, never console in your own words, and never invent Scripture.
- You only ever return ONE existing id from the lists below, or silence.
- Silence is honorable: choose it when the context asks for less, not more.

Context (coarse, non-personal buckets):
${jsonEncode(_contextToJson(context))}

Moment being prepared: ${type.name}

Allow-listed scripture pointers (choose one id, or none):
[
$pointerList
]

Allow-listed reflective lines (choose one id, or none):
[
$questionList
]

Reply with ONLY JSON: {"mode":"scripturePointer"|"reflectiveGuidance"|"silence","itemId":"<id>"}.
For silence set itemId to null or omit it.
''';
  }

  Map<String, Object> _contextToJson(ContextPacket c) => {
        'language': c.language.name,
        'dayPart': c.dayPart.name,
        'maturity': c.maturity.name,
        'engagement': c.engagement.name,
        'absence': c.absence.name,
        'restDay': c.isRestDay,
        'fastingSeason': c.isFastingSeason,
      };
}
