import 'package:beslet_app/core/ai/voice_journal/voice_journal_models.dart';
import 'package:beslet_app/core/ai/voice_journal/voice_journal_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

VoiceJournalRequest _request({bool am = false}) => VoiceJournalRequest(
      transcript:
          'Today I went to the market with my brother. I felt happy and tired. '
          'I prayed in the evening and felt peace. I learned to trust God more. '
          'Keep going John.',
      isAmharic: am,
    );

void main() {
  group('VoiceJournalPromptBuilder', () {
    test('fences the reader transcript as the only source of truth', () {
      final prompt = const VoiceJournalPromptBuilder().build(_request());
      expect(prompt, contains('----- TRANSCRIPT -----'));
      expect(prompt, contains('----- END TRANSCRIPT -----'));
      expect(prompt, contains('I went to the market with my brother.'));
    });

    test('states the editor-not-author contract and non-negotiables', () {
      final prompt = const VoiceJournalPromptBuilder().build(_request());
      final lower = prompt.toLowerCase();
      expect(lower, contains('editor'));
      expect(lower, contains('never invent'));
      expect(lower, contains('preserve the chronology'));
      expect(lower, contains('sentence to remember'));
      expect(lower, contains('quotation marks'));
      expect(lower, contains('never pad, never invent'));
    });

    test('requests the reader language and json-only output', () {
      final en = const VoiceJournalPromptBuilder().build(_request());
      final am = const VoiceJournalPromptBuilder().build(_request(am: true));
      expect(en, contains('write every section in the reader\'s language (english)'));
      expect(am, contains('(amharic)'));
      expect(en, contains('"sentenceToRemember"'));
      expect(en, contains('Reply with ONLY the JSON below'));
    });

    test('caps the transcript without reaching the model when over budget', () {
      final long = 'hello world ' * 1200;
      final capped = capVoiceJournalTranscript(long);
      expect(capped.length, lessThanOrEqualTo(voiceJournalMaxTranscriptChars));
      expect(capped.length, greaterThan(voiceJournalMaxTranscriptChars - 400));
    });

    test('transcript key is stable and content-sensitive', () {
      final a = voiceJournalTranscriptKey('  Today I went   to market ');
      final b = voiceJournalTranscriptKey('today i went to market');
      final c = voiceJournalTranscriptKey('a totally different day');
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}