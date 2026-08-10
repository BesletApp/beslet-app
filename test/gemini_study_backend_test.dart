import 'dart:convert';

import 'package:beslet_app/core/ai/study/gemini_study_backend.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:flutter_test/flutter_test.dart';

StudyRequest _request({bool am = false}) => StudyRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 3),
      isAmharic: am,
      verseTexts: const ['a', 'b', 'c'],
    );

String _goodJson() => jsonEncode({
      'summary': {'text': 'The Lord is a caring shepherd who provides and guides.'},
      'context': {
        'behindTheText': 'A psalm of David, a man who knew shepherding.',
        'inTheText': 'The psalm moves from provision to presence in the valley.',
      },
      'observations': {'text': 'Notice the verbs: leads, restores, guides.'},
      'teachings': {'text': 'God provides what we truly need (v. 1).'},
      'reflection': {'text': 'Where do you need his presence?'},
      'crossReferences': {
        'items': [
          {
            'bookId': 'john',
            'chapter': 10,
            'startVerse': 11,
            'endVerse': 11,
            'reason': 'Jesus calls Himself the good Shepherd.',
          },
        ],
      },
    });

void main() {
  group('GeminiStudyBackend', () {
    test('a valid transport payload becomes an available gemini result', () async {
      final backend = GeminiStudyBackend(transport: (_) async => _goodJson());
      final result = await backend.study(_request());
      expect(result, isNotNull);
      expect(result!.isAvailable, isTrue);
      expect(result.source, StudySource.gemini);
    });

    test('a throwing transport yields null (never raises)', () async {
      final backend = GeminiStudyBackend(
        transport: (_) async => throw Exception('offline'),
      );
      expect(await backend.study(_request()), isNull);
    });

    test('a malformed transport reply yields null', () async {
      final backend = GeminiStudyBackend(
        transport: (_) async => 'not json at all',
      );
      expect(await backend.study(_request()), isNull);
    });

    test('a non-map JSON reply yields null', () async {
      final backend = GeminiStudyBackend(transport: (_) async => '[1,2,3]');
      expect(await backend.study(_request()), isNull);
    });

    test('an empty reply yields null', () async {
      final backend = GeminiStudyBackend(transport: (_) async => '   ');
      expect(await backend.study(_request()), isNull);
    });

    test("the prompt asks for the reader's language", () async {
      String? seen;
      final backend = GeminiStudyBackend(transport: (prompt) async {
        seen = prompt;
        return _goodJson();
      });
      await backend.study(_request(am: true));
      expect(seen, contains('Write in: amharic'));
      expect(seen, contains('እግዚአብሔር'));
    });

    test('invalid content (banned phrase) fails validation and yields null',
        () async {
      final backend = GeminiStudyBackend(
        transport: (_) async => jsonEncode({
          'teachings': {'text': 'God is telling you to do this.'},
        }),
      );
      expect(await backend.study(_request()), isNull);
    });
  });

  group('buildGeminiTransport', () {
    test('refuses to run without any usable key', () async {
      final transport = buildGeminiTransport(
        bundledKey: 'YOUR_API_KEY',
        userKeyProvider: () async => null,
      );
      await expectLater(transport('prompt'), throwsStateError);
    });
  });
}