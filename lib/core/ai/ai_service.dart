import 'ai_assembler.dart';
import 'ai_backend.dart';
import 'ai_boundary.dart';
import 'ai_content.dart';
import 'ai_models.dart';
import 'ai_validator.dart';

/// The Quiet Guide orchestrator.
///
/// Order is deliberate and silence-first:
///   1. assemble coarse context (never personal),
///   2. ask the boundary gate (dependence guard) — deny -> silence,
///   3. ask the Tier 1 selector, fall back to Tier 0 on any failure,
///   4. validate the choice against the allow-listed bank — reject -> silence,
///   5. record the moment (only when something is actually shown).
///
/// Every step is non-blocking and can never raise to the caller.
class AiService {
  final AiContentBank bank;
  final AiBoundaryGate gate;
  final AiContextAssembler assembler;
  final AiOutputValidator validator;
  final LocalRuleBackend local;
  final AiBackend? gemini;
  final Future<int> Function({required String dayKey}) momentCountFor;
  final Future<void> Function(AiMoment moment) recordMoment;

  AiService({
    required this.bank,
    required this.gate,
    required this.assembler,
    required this.validator,
    required this.local,
    required this.gemini,
    required this.momentCountFor,
    required this.recordMoment,
  });

  Future<QuietGuideResult> decide({
    required AiMomentType type,
    required DateTime now,
    required bool isAmharic,
    required int currentStreak,
    required bool isRestDay,
    required bool wasAwayForDays,
    required bool completedToday,
  }) async {
    final context = assembler.assemble(
      isAmharic: isAmharic,
      now: now,
      currentStreak: currentStreak,
      isRestDay: isRestDay,
      wasAwayForDays: wasAwayForDays,
      completedToday: completedToday,
    );

    final dayKey = AiBoundaryGate.dayKeyFor(now);
    final int count;
    try {
      count = await momentCountFor(dayKey: dayKey);
    } catch (_) {
      return const QuietGuideResult.silent();
    }

    if (!gate.allows(
      todayMomentCount: count,
      maturity: context.maturity,
      absence: context.absence,
    )) {
      return const QuietGuideResult.silent();
    }

    var source = AiSource.gemini;
    AiOutput? output;
    try {
      output = await gemini?.select(context: context, type: type, now: now);
    } catch (_) {
      output = null;
    }
    if (output == null) {
      source = AiSource.local;
      output = await local.select(context: context, type: type, now: now);
    }

    final choice = validator.validate(output ?? const AiOutput(mode: 'silence'));
    if (choice == null) return const QuietGuideResult.silent();

    final result = _resolve(context, choice, source);
    if (result.isSilent) return result;

    try {
      await recordMoment(AiMoment(
        dayKey: dayKey,
        type: type,
        mode: result.mode,
        source: result.source,
        reference: result.reference,
        itemId: choice.itemId,
        createdAt: now,
      ));
    } catch (_) {
      // Recording must never break the app.
    }
    return result;
  }

  QuietGuideResult _resolve(
      ContextPacket context, AiChoice choice, AiSource source) {
    switch (choice.mode) {
      case AiMode.silence:
        return const QuietGuideResult.silent();
      case AiMode.scripturePointer:
        final ref = choice.reference;
        if (ref == null) return const QuietGuideResult.silent();
        return QuietGuideResult(
          mode: AiMode.scripturePointer,
          reference: ref.referenceFor(context.language == AiLanguageBucket.amharic),
          source: source,
        );
      case AiMode.reflectiveGuidance:
        final question = choice.itemId == null
            ? null
            : bank.questionById[choice.itemId];
        if (question == null) return const QuietGuideResult.silent();
        return QuietGuideResult(
          mode: AiMode.reflectiveGuidance,
          line: question.lineFor(context.language),
          source: source,
        );
    }
  }
}
