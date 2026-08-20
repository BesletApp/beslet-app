import 'package:beslet_app/core/ai/voice_journal/voice_journal_models.dart';
import 'package:beslet_app/core/ai/voice_journal/voice_journal_validator.dart';
import 'package:flutter_test/flutter_test.dart';

const _transcript =
    'Today I went to the market with my brother. I felt happy and tired. '
    'I prayed in the evening and felt peace. I learned to trust God more. '
    'Keep going John.';

VoiceJournalRequest _request({bool am = false}) =>
    VoiceJournalRequest(transcript: _transcript, isAmharic: am);

const _raw = {
  'whatHappened': 'went to the market with my brother',
  'emotions': 'felt happy and tired',
  'spiritualMoments': 'prayed in the evening and felt peace',
  'insights': 'learned to trust God more',
  'sentenceToRemember': 'I learned to trust God more.',
};

const _validator = VoiceJournalValidator();

void main() {
  group('VoiceJournalValidator', () {
    test('accepts an honest editorial organization', () {
      final result = _validator.validate(raw: _raw, request: _request());
      expect(result, isNotNull);
      expect(result!.isAvailable, isTrue);
      expect(result.sections, hasLength(5));
    });

    test('preserve silence: an omitted section is fine', () {
      final raw = Map<String, dynamic>.from(_raw)..remove('emotions');
      final result = _validator.validate(raw: raw, request: _request());
      expect(result, isNotNull);
      expect(result!.sections.map((s) => s.kind),
          isNot(contains(VoiceNoteSectionKind.emotions)));
    });

    test('any banned phrase anywhere rejects the whole journal', () {
      final raw = Map<String, dynamic>.from(_raw)
        ..['spiritualMoments'] = 'You should pray more tomorrow';
      final result = _validator.validate(raw: raw, request: _request());
      expect(result, isNull);
    });

    test('a section the model authored (unfamiliar vocabulary) is dropped', () {
      final raw = Map<String, dynamic>.from(_raw)
        ..['insights'] = 'quantum nebulous zephyr introspection';
      final result = _validator.validate(raw: raw, request: _request());
      expect(result, isNotNull);
      expect(result!.sections.map((s) => s.kind),
          isNot(contains(VoiceNoteSectionKind.insights)));
    });

    test('a manufactured one-sentence takeaway is dropped, not invented', () {
      final raw = Map<String, dynamic>.from(_raw)
        ..['sentenceToRemember'] = 'Every journey begins with a single step.';
      final result = _validator.validate(raw: raw, request: _request());
      expect(result, isNotNull);
      expect(result!.sections.map((s) => s.kind),
          isNot(contains(VoiceNoteSectionKind.sentenceToRemember)));
    });

    test('an authoring phrase like "you should" rejects the whole journal', () {
      final raw = Map<String, dynamic>.from(_raw)
        ..['insights'] = 'You should pray more tomorrow';
      final result = _validator.validate(raw: raw, request: _request());
      expect(result, isNull);
    });

    test('script mismatch drops the section, in both languages', () {
      final rawEn = Map<String, dynamic>.from(_raw)
        ..['emotions'] = 'በጣም ተደስቻለሁ';
      final en = _validator.validate(raw: rawEn, request: _request());
      expect(en, isNotNull);
      expect(en!.sections.map((s) => s.kind),
          isNot(contains(VoiceNoteSectionKind.emotions)));

      const amRaw = {
        'whatHappened': 'ከወንድሜ ጋር ወደ ገበያ ሄድን',
        'emotions': 'happiness and fatigue',
        'sentenceToRemember': 'እግዚአብሔርን በመተማመን ቀጣይኩ',
      };
      const amTranscript =
          'ከወንድሜ ጋር ወደ ገበያ ሄድን። እግዚአብሔርን በመተማመን ቀጣይኩ።';
      final am = _validator.validate(
        raw: amRaw,
        request: VoiceJournalRequest(
            transcript: amTranscript, isAmharic: true),
      );
      expect(am, isNotNull);
      expect(am!.sections.map((s) => s.kind),
          isNot(contains(VoiceNoteSectionKind.emotions)));
      expect(am.sections.map((s) => s.kind),
          contains(VoiceNoteSectionKind.whatHappened));
    });

    test('an empty or all-dropped payload yields null (never a blank)', () {
      expect(_validator.validate(raw: const {}, request: _request()), isNull);
      final deflated = Map<String, dynamic>.from(_raw)
        ..['whatHappened'] = 'completely unrelated different vocabulary text'
        ..['emotions'] = 'also completely unrelated different vocabulary'
        ..['spiritualMoments'] = 'nothing like the transcript at all okay now'
        ..['insights'] = 'still another invented thought here entirely'
        ..['sentenceToRemember'] = 'A manufactured sentence that is not there.';
      expect(_validator.validate(raw: deflated, request: _request()), isNull);
    });

    test('a single runaway section is dropped (preserve silence)', () {
      final words = List.filled(400, 'today I went to the market').join(' ');
      final raw = Map<String, dynamic>.from(_raw)..['whatHappened'] = words;
      final result = _validator.validate(raw: raw, request: _request());
      expect(result, isNotNull);
      expect(result!.sections.map((s) => s.kind),
          isNot(contains(VoiceNoteSectionKind.whatHappened)));
    });

    test('an organized journal that dwarfs the transcript is rejected', () {
      final filler = List.filled(5, 'went to the market with my brother')
          .join(' ');
      final raw = {
        'whatHappened': filler,
        'emotions': filler,
        'spiritualMoments': filler,
        'insights': filler,
        'sentenceToRemember': 'I learned to trust God more.',
      };
      final result = _validator.validate(raw: raw, request: _request());
      expect(result, isNull);
    });

    test('Amharic organization keeps Ethiopic script and validates the quote', () {
      const amRaw = {
        'whatHappened': 'ከወንድሜ ጋር ወደ ገበያ ሄድን',
        'emotions': 'ደስተኛ ብሆንም ደክሞኝ ነበር',
        'spiritualMoments': 'ምሽት ላይ ጸልዬ ሰላም አግኝቼ ነበር',
        'insights': 'እግዚአብሔርን በመተማመን ቀስ በቀስ እያደግኩ ነው',
        'sentenceToRemember': 'እግዚአብሔርን በመተማመን ቀስ በቀስ እያደግኩ ነው',
      };
      const amTranscript =
          'ከወንድሜ ጋር ወደ ገበያ ሄድን። ደስተኛ ብሆንም ደክሞኝ ነበር። '
          'ምሽት ላይ ጸልዬ ሰላም አግኝቼ ነበር። እግዚአብሔርን በመተማመን ቀስ በቀስ እያደግኩ ነው።';
      final result = _validator.validate(
        raw: amRaw,
        request: VoiceJournalRequest(transcript: amTranscript, isAmharic: true),
      );
      expect(result, isNotNull);
      expect(result!.sections, hasLength(5));
    });
  });
}