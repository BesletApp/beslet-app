import 'dart:convert';

import 'package:beslet_app/core/ai/study/gemini_study_backend.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

StudyRequest _request({bool am = false}) => StudyRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 3),
      isAmharic: am,
      verseTexts: const ['a', 'b', 'c'],
    );

GeminiStudyBackend _backend(Future<String> Function(String) transport) =>
    GeminiStudyBackend(
      transport: transport,
      validator: StudyValidator(canon: loadTestCanon()),
    );

String _goodJson() => jsonEncode({
      'setting': {'text': 'A psalm of David, a song of trust.'},
      'context': {
        'behindTheText': 'A psalm of David, a man who knew shepherding.',
        'inTheText': 'The psalm moves from provision to presence in the valley.',
      },
      'whatTextSays': {
        'text': 'The Lord is a caring shepherd who provides and guides.',
      },
      'meaningBackground': {
        'text': 'A shepherd leads, feeds, and protects the flock.',
      },
      'reflection': {'text': 'Where do you need his presence?'},
      'biblicalConnections': {
        'items': [
          {
            'bookId': 'john',
            'chapter': 10,
            'startVerse': 11,
            'endVerse': 11,
            'priority': 0,
            'reason': 'Jesus calls Himself the good Shepherd.',
          },
        ],
      },
      'whatCanBeUnderstood': {
        'blocks': [
          {'tier': 'clearlyStated', 'text': 'God is a personal keeper.'},
        ],
      },
    });

void main() {
  group('GeminiStudyBackend', () {
    test('a valid transport payload becomes an available gemini result', () async {
      final backend = _backend((_) async => _goodJson());
      final result = await backend.study(_request());
      expect(result, isNotNull);
      expect(result!.isAvailable, isTrue);
      expect(result.source, StudySource.gemini);
    });

    test('a throwing transport yields null (never raises)', () async {
      final backend = _backend((_) async => throw Exception('offline'));
      expect(await backend.study(_request()), isNull);
    });

    test('a malformed transport reply yields null', () async {
      final backend = _backend((_) async => 'not json at all');
      expect(await backend.study(_request()), isNull);
    });

    test('a non-map JSON reply yields null', () async {
      final backend = _backend((_) async => '[1,2,3]');
      expect(await backend.study(_request()), isNull);
    });

    test('an empty reply yields null', () async {
      final backend = _backend((_) async => '   ');
      expect(await backend.study(_request()), isNull);
    });

    test("the prompt asks for the reader's language", () async {
      String? seen;
      final backend = _backend((prompt) async {
        seen = prompt;
        return _goodJson();
      });
      await backend.study(_request(am: true));
      expect(seen, contains('Write in: amharic'));
      expect(seen, contains('እግዚአብሔር'));
    });

    test('invalid content (banned phrase) fails validation and yields null',
        () async {
      final backend = _backend((_) async => jsonEncode({
            'whatTextSays': {'text': 'God is telling you to do this.'},
          }));
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