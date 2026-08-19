import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beslet_app/core/ai/study/gemini_study_backend.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_validator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
      'passageOverview': {'text': 'A psalm of David, a song of trust.'},
      'historicalBackground': {
        'text': 'A psalm of David, a man who knew shepherding.',
        'entries': [
          {
            'label': 'author',
            'category': 'probable',
            'text': 'Tradition ascribes this psalm to David.',
          },
        ],
      },
      'literaryContext': {
        'text': 'The psalm moves from provision to presence in the valley.',
      },
      'verseByVerse': {
        'observations': [
          {
            'startVerse': 1,
            'endVerse': 1,
            'text': 'The LORD is named as the shepherd.',
          },
        ],
      },
      'originalLanguage': {
        'text': 'A shepherd leads, feeds, and protects the flock.',
      },
      'scriptureInterconnections': {
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
      'explicitTeachings': {
        'blocks': [
          {'tier': 'clearlyStated', 'text': 'God is a personal keeper.'},
        ],
      },
      'questionsToCarry': {'text': 'Where do you need His presence?'},
      'anchor': {
        'image': 'a shepherd by still waters',
        'keyword': 'shepherd',
        'sentence': 'The LORD stays close through the valley.',
      },
    });

void main() {
  group('GeminiStudyBackend', () {
    test('a valid transport payload becomes an available gemini result',
        () async {
      final attempt = await _backend((_) async => _goodJson()).study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(attempt.result!.source, StudySource.gemini);
    });

    test('a throwing transport yields a classified reason (never raises)',
        () async {
      final attempt =
          await _backend((_) async => throw Exception('boom')).study(_request());
      expect(attempt.isAvailable, isFalse);
      expect(attempt.unavailability, StudyUnavailability.server);
    });

    test('a malformed transport reply is contentRejected', () async {
      final attempt =
          await _backend((_) async => 'not json at all').study(_request());
      expect(attempt.isAvailable, isFalse);
      expect(attempt.unavailability, StudyUnavailability.contentRejected);
    });

    test('a non-map JSON reply is contentRejected', () async {
      final attempt =
          await _backend((_) async => '[1,2,3]').study(_request());
      expect(attempt.isAvailable, isFalse);
      expect(attempt.unavailability, StudyUnavailability.contentRejected);
    });

    test('an empty reply is contentRejected', () async {
      final attempt = await _backend((_) async => '   ').study(_request());
      expect(attempt.isAvailable, isFalse);
      expect(attempt.unavailability, StudyUnavailability.contentRejected);
    });

    test("the prompt asks for the reader's language", () async {
      String? seen;
      // The payload here is English, so the note itself would be rejected for
      // an Amharic reader — this test only checks the *prompt*, not the note.
      await _backend((prompt) async {
        seen = prompt;
        return _goodJson();
      }).study(_request(am: true));
      expect(seen, contains('Write in: amharic'));
      expect(seen, contains('እግዚአብሔር'));
    });

    test('the prompt demands a faithful study aid with honest boundaries',
        () async {
      String? seen;
      final attempt = await _backend((prompt) async {
        seen = prompt;
        return _goodJson();
      }).study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(seen, contains('a faithful study aid'));
      expect(seen, contains('NEUTRAL TO ALL TRADITIONS'));
      expect(seen, contains('MEMORY ANCHOR'));
      expect(seen, contains('"terms"'));
    });

    test('the prompt structures the note around the eight-section vocabulary',
        () async {
      String? seen;
      final attempt = await _backend((prompt) async {
        seen = prompt;
        return _goodJson();
      }).study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(seen, contains('LOOK CLOSELY AT THE WORDS'));
      expect(seen, contains('WHAT THE TEXT COMMUNICATES'));
      expect(seen, contains('VERSE BY VERSE'));
      expect(seen, contains('SCRIPTURE ALONGSIDE SCRIPTURE'));
      expect(seen, contains('WHAT IS CLEAR / WHAT REQUIRES CARE'));
      expect(seen, contains('CONSIDER'));
    });

    test('the prompt names the length band for the passage', () async {
      String? seen;
      final attempt = await _backend((prompt) async {
        seen = prompt;
        return _goodJson();
      }).study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(seen, contains('LENGTH \u2014'));
      expect(seen, contains('words (a "'));
    });

    test('invalid content (banned phrase) is contentRejected', () async {
      final attempt = await _backend((_) async => jsonEncode({
            'literaryContext': {'text': 'God is telling you to do this.'},
          })).study(_request());
      expect(attempt.isAvailable, isFalse);
      expect(attempt.unavailability, StudyUnavailability.contentRejected);
    });
  });

  group('GeminiStudyBackend failure classification', () {
    Future<StudyUnavailability> reasonFor(
            Future<String> Function(String) transport) async {
      final attempt = await _backend(transport).study(_request());
      expect(attempt.isAvailable, isFalse);
      return attempt.unavailability;
    }

    test('a timeout becomes timeout', () async {
      expect(await reasonFor((_) async => throw TimeoutException('late')),
          StudyUnavailability.timeout);
    });

    test('a socket error becomes offline', () async {
      expect(await reasonFor((_) async => throw const SocketException('no net')),
          StudyUnavailability.offline);
    });

    test('an invalid API key becomes authInvalid', () async {
      expect(
          await reasonFor(
              (_) async => throw InvalidApiKey('API_KEY_INVALID')),
          StudyUnavailability.authInvalid);
    });

    test('a 429 server reply becomes rateLimited', () async {
      expect(
          await reasonFor(
              (_) async => throw ServerException('429 RESOURCE_EXHAUSTED')),
          StudyUnavailability.rateLimited);
    });

    test('a generic server reply becomes server', () async {
      expect(
          await reasonFor(
              (_) async => throw ServerException('500 Internal Server Error')),
          StudyUnavailability.server);
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

  group('verifyGeminiKey', () {
    test('an empty key is rejected without a network call', () async {
      await expectLater(
        verifyGeminiKey('   '),
        throwsA(isA<StudyGeminiException>()
            .having((e) => e.reason, 'reason', StudyUnavailability.authInvalid)),
      );
    });
  });
}
