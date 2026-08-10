import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/ai/ai_backend.dart';
import 'package:beslet_app/core/ai/ai_boundary.dart';
import 'package:beslet_app/core/ai/ai_assembler.dart';
import 'package:beslet_app/core/ai/ai_content.dart';
import 'package:beslet_app/core/ai/ai_models.dart';
import 'package:beslet_app/core/ai/ai_service.dart';
import 'package:beslet_app/core/ai/ai_validator.dart';

class FakeGemini implements AiBackend {
  final AiOutput? output;
  const FakeGemini(this.output);

  @override
  Future<AiOutput?> select({
    required ContextPacket context,
    required AiMomentType type,
    required DateTime now,
  }) async =>
      output;
}

void main() {
  late AiContentBank bank;

  setUpAll(() {
    bank = AiContentBank.fromJsonString(
        File('assets/data/ai_bank.json').readAsStringSync());
  });

  final now = DateTime(2026, 8, 9, 9);

  AiService buildService({
    AiOutput? geminiOutput,
    int Function(String dayKey)? countFor,
    List<AiMoment>? recorded,
  }) {
    return AiService(
      bank: bank,
      gate: const AiBoundaryGate(),
      assembler: const AiContextAssembler(),
      validator: AiOutputValidator(bank),
      local: LocalRuleBackend(bank),
      gemini: geminiOutput != null ? FakeGemini(geminiOutput) : null,
      momentCountFor: ({required dayKey}) async => countFor?.call(dayKey) ?? 0,
      recordMoment: (moment) async => recorded?.add(moment),
    );
  }

  group('AiService.decide', () {
    test('boundary gate denial means silence and nothing recorded', () async {
      final recorded = <AiMoment>[];
      final service = buildService(countFor: (_) => 3, recorded: recorded);
      final result = await service.decide(
        type: AiMomentType.stillPoint,
        now: now,
        isAmharic: false,
        currentStreak: 0,
        isRestDay: false,
        wasAwayForDays: false,
        completedToday: false,
      );
      expect(result.isSilent, isTrue);
      expect(recorded, isEmpty);
    });

    test('valid Gemini pointer is shown and recorded as gemini', () async {
      final recorded = <AiMoment>[];
      final service = buildService(
        geminiOutput:
            AiOutput(mode: 'scripturePointer', itemId: bank.pointers.first.id),
        recorded: recorded,
      );
      final result = await service.decide(
        type: AiMomentType.stillPoint,
        now: now,
        isAmharic: false,
        currentStreak: 0,
        isRestDay: false,
        wasAwayForDays: false,
        completedToday: false,
      );
      expect(result.isSilent, isFalse);
      expect(result.mode, AiMode.scripturePointer);
      expect(result.reference, isNotEmpty);
      expect(result.source, AiSource.gemini);
      expect(recorded, hasLength(1));
      expect(recorded.single.source, AiSource.gemini);
    });

    test('Gemini failure falls back to the local engine (offline-identical)', () async {
      final service = buildService(geminiOutput: null);
      final result = await service.decide(
        type: AiMomentType.stillPoint,
        now: now,
        isAmharic: false,
        currentStreak: 0,
        isRestDay: false,
        wasAwayForDays: false,
        completedToday: false,
      );
      expect(result.isSilent, isFalse);
      expect(result.mode, AiMode.scripturePointer);
      expect(result.source, AiSource.local);
      expect(result.reference, isNotEmpty);
    });

    test('a fabricated reference is rejected to silence', () async {
      final recorded = <AiMoment>[];
      final service = buildService(
        geminiOutput: const AiOutput(mode: 'scripturePointer', itemId: 'ptr_fake'),
        recorded: recorded,
      );
      final result = await service.decide(
        type: AiMomentType.stillPoint,
        now: now,
        isAmharic: false,
        currentStreak: 0,
        isRestDay: false,
        wasAwayForDays: false,
        completedToday: false,
      );
      expect(result.isSilent, isTrue);
      expect(recorded, isEmpty);
    });

    test('Gemini choosing silence is honored and not counted', () async {
      final recorded = <AiMoment>[];
      final service = buildService(
        geminiOutput: const AiOutput(mode: 'silence'),
        recorded: recorded,
      );
      final result = await service.decide(
        type: AiMomentType.stillPoint,
        now: now,
        isAmharic: false,
        currentStreak: 0,
        isRestDay: false,
        wasAwayForDays: false,
        completedToday: false,
      );
      expect(result.isSilent, isTrue);
      expect(recorded, isEmpty);
    });

    test('a reflective line resolves in the user language', () async {
      final q = bank.questions.first;
      final service = buildService(
        geminiOutput: AiOutput(mode: 'reflectiveGuidance', itemId: q.id),
      );
      final en = await service.decide(
        type: AiMomentType.weeklyReflection,
        now: now,
        isAmharic: false,
        currentStreak: 0,
        isRestDay: false,
        wasAwayForDays: false,
        completedToday: false,
      );
      expect(en.line, q.en);

      final am = await service.decide(
        type: AiMomentType.weeklyReflection,
        now: now,
        isAmharic: true,
        currentStreak: 0,
        isRestDay: false,
        wasAwayForDays: false,
        completedToday: false,
      );
      expect(am.line, q.am);
    });

    test('local engine is deterministic for the same day', () async {
      final service = buildService(geminiOutput: null);
      final a = await service.decide(
        type: AiMomentType.stillPoint,
        now: now,
        isAmharic: false,
        currentStreak: 0,
        isRestDay: false,
        wasAwayForDays: false,
        completedToday: false,
      );
      final b = await service.decide(
        type: AiMomentType.stillPoint,
        now: now,
        isAmharic: false,
        currentStreak: 0,
        isRestDay: false,
        wasAwayForDays: false,
        completedToday: false,
      );
      expect(a.reference, b.reference);
      expect(a.reference, isNotNull);
    });
  });
}
