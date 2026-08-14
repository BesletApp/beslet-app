import 'dart:async';
import 'dart:io';

import 'package:beslet_app/core/ai/study/study_backend.dart';
import 'package:beslet_app/core/ai/study/study_cross_refs.dart';
import 'package:beslet_app/core/ai/study/study_intro.dart';
import 'package:beslet_app/core/ai/study/study_local_bank.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

class _CountingBackend implements StudyBackend {
  final StudyLocalBank bank;
  final void Function() onCall;

  _CountingBackend(this.bank, this.onCall);

  @override
  Future<StudyResult?> study(StudyRequest request) async {
    onCall();
    final entry = bank.entryFor(
      request.reference.bookId,
      request.reference.chapter,
      request.reference.startVerse,
    );
    if (entry == null) return null;
    return StudyResult(
      reference: request.reference,
      source: StudySource.localBank,
      sections: entry.sections,
      cachedAt: DateTime.now(),
      isAvailable: true,
    );
  }
}

void main() {
  late StudyLocalBank bank;

  setUpAll(() {
    bank = StudyLocalBank.fromJsonString(
        File('assets/data/study.json').readAsStringSync());
  });

  StudyRequest psalmRequest({int start = 1, int end = 3, bool am = false}) =>
      StudyRequest(
        reference: StudyReference(
            bookId: 'psalms', chapter: 23, startVerse: start, endVerse: end),
        isAmharic: am,
        verseTexts: const ['a', 'b', 'c'],
      );

  StudyService serviceWith({Map<String, String>? cache}) => StudyService(
        backend: LocalStudyBackend(bank),
        readCache: (k) async => cache?[k],
        writeCache: (k, v) async => cache?[k] = v,
      );

  group('StudyService.study', () {
    test('resolves a banked passage to all eight sections', () async {
      final result = await serviceWith().study(psalmRequest());
      expect(result.isAvailable, isTrue);
      expect(result.source, StudySource.localBank);
      expect(result.sections.length, 8);
      expect(result.reference.referenceFor(false), 'Psalms 23:1–3');
    });

    test('unbanked passage returns the quiet unavailable fallback', () async {
      final result = await serviceWith().study(
        StudyRequest(
          reference: const StudyReference(
              bookId: 'genesis', chapter: 1, startVerse: 1, endVerse: 1),
          isAmharic: false,
          verseTexts: const ['x'],
        ),
      );
      expect(result.isAvailable, isFalse);
      expect(result.sections, isEmpty);
    });

    test('sections carry both languages and answer in the reader language',
        () async {
      final result = await serviceWith().study(psalmRequest());
      final literary = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.literaryContext);
      expect(literary.textFor(false), literary.en);
      expect(literary.textFor(true), literary.am);
    });

    test('writes the cache and serves the second call from it', () async {
      final cache = <String, String>{};
      var backendCalls = 0;
      final service = StudyService(
        backend: _CountingBackend(bank, () => backendCalls++),
        readCache: (k) async => cache[k],
        writeCache: (k, v) async => cache[k] = v,
      );

      final first = await service.study(psalmRequest());
      expect(first.isAvailable, isTrue);
      expect(backendCalls, 1);

      final second = await service.study(psalmRequest());
      expect(second.isAvailable, isTrue);
      expect(second.sections.length, 8);
      expect(backendCalls, 1, reason: 'second call must come from the cache');
      expect(
          cache.containsKey(
              'study_v${studyPromptVersion}_psalms_23_1_3_en_standard'),
          isTrue);
    });

    test('cache is keyed by language', () async {
      final cache = <String, String>{};
      final service = StudyService(
        backend: LocalStudyBackend(bank),
        readCache: (k) async => cache[k],
        writeCache: (k, v) async => cache[k] = v,
      );
      await service.study(psalmRequest(am: true));
      expect(
          cache.containsKey(
              'study_v${studyPromptVersion}_psalms_23_1_3_am_standard'),
          isTrue);
    });

    test('cache key embeds the prompt version and the depth', () {
      final service = serviceWith();
      expect(service.cacheKeyFor(psalmRequest()),
          'study_v${studyPromptVersion}_psalms_23_1_3_en_standard');
    });

    test('a corrupt cache entry falls through to the backend', () async {
      final cache = <String, String>{
        'study_v${studyPromptVersion}_psalms_23_1_3_en_standard': 'not-json',
      };
      final result = await serviceWith(cache: cache).study(psalmRequest());
      expect(result.isAvailable, isTrue);
      expect(result.sections.length, 8);
    });

    test('a repeated open within a session is served from memory', () async {
      final cache = <String, String>{};
      var backendCalls = 0;
      final service = StudyService(
        backend: _CountingBackend(bank, () => backendCalls++),
        readCache: (k) async {
          throw StateError('disk must not be read again');
        },
        writeCache: (k, v) async => cache[k] = v,
      );

      final first = await service.study(psalmRequest());
      expect(first.isAvailable, isTrue);
      expect(backendCalls, 1);
      // The disk-cache read throws, so only the in-memory cache can make the
      // second open succeed — proving the memo is hit and no disk I/O shapes
      // the answer.
      final second = await service.study(psalmRequest());
      expect(second.isAvailable, isTrue);
      expect(second.sections.length, 8);
      expect(backendCalls, 1, reason: 'memo must serve the second open');
    });

    test('concurrent opens are deduplicated (single flight)', () async {
      var started = 0;
      var completed = 0;
      final completer = Completer<StudyResult?>();
      final backend = _BlockingBackend(() {
        started++;
        return completer.future;
      }, () {
        completed++;
      });
      final service = StudyService(
        backend: backend,
        readCache: (k) async => null,
        writeCache: (k, v) async {},
      );

      final first = service.study(psalmRequest());
      final second = service.study(psalmRequest());
      await Future<void>.delayed(Duration.zero);
      expect(started, 1, reason: 'the backend must be called exactly once');

      completer.complete(StudyResult(
        reference: psalmRequest().reference,
        source: StudySource.localBank,
        sections: bank.entryFor('psalms', 23, 1)!.sections,
        cachedAt: DateTime.now(),
        isAvailable: true,
      ));
      final a = await first;
      final b = await second;
      expect(a.isAvailable, isTrue);
      expect(b.isAvailable, isTrue);
      expect(completed, 1);
    });
  });

  group('StudyService never-blank offline assembly', () {
    late StudyIntroLibrary intros;
    late StudyCrossRefIndex crossRefs;

    setUpAll(() {
      intros = loadTestIntros();
      crossRefs = loadTestCrossRefs();
    });

    StudyService service({StudyBackend? backend}) => StudyService(
          backend: backend ?? LocalStudyBackend(bank),
          intros: intros,
          crossRefs: crossRefs,
          readCache: (k) async => null,
          writeCache: (k, v) async {},
        );

    test('an unbanked canon passage still gets a curated offline note',
        () async {
      final result = await service().study(
        StudyRequest(
          reference: const StudyReference(
              bookId: 'genesis', chapter: 1, startVerse: 1, endVerse: 1),
          isAmharic: false,
          verseTexts: const ['x'],
        ),
      );
      expect(result.isAvailable, isTrue,
          reason: 'a canon passage must never be left blank offline');
      expect(result.source, StudySource.knowledge);
      expect(result.sections, isNotEmpty);
      final kinds = result.sections.map((s) => s.kind).toSet();
      expect(kinds.contains(StudySectionKind.passageOverview), isTrue,
          reason: 'the book background must render as the passage overview');
      expect(kinds.contains(StudySectionKind.literaryContext), isTrue);
      expect(kinds.contains(StudySectionKind.originalLanguage), isTrue);
    });

    test('an unbanked passage with curated cross-references includes them',
        () async {
      final result = await service().study(
        StudyRequest(
          reference: const StudyReference(
              bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 1),
          isAmharic: false,
          verseTexts: const ['x'],
        ),
      );
      expect(result.isAvailable, isTrue);
      final refs = result.sections
          .where((s) =>
              s.kind == StudySectionKind.scriptureInterconnections)
          .expand((s) => s.references)
          .toList();
      expect(refs, isNotEmpty,
          reason: 'the cross-reference index must surface for psalm 23');
      expect(refs.any((r) =>
              r.bookId == 'john' && r.chapter == 10 && r.startVerse == 11),
          isTrue);
    });

    test('the assembled note answers in the reader language', () async {
      final result = await service().study(
        StudyRequest(
          reference: const StudyReference(
              bookId: 'genesis', chapter: 1, startVerse: 1, endVerse: 1),
          isAmharic: true,
          verseTexts: const ['x'],
        ),
      );
      final overview = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.passageOverview);
      expect(overview.textFor(true), overview.am,
          reason: 'an Amharic reader must get the Amharic text');
      expect(overview.textFor(true), isNotEmpty);
    });

    test('an assembled note is never persisted to the disk cache', () async {
      final cache = <String, String>{};
      final service = StudyService(
        backend: LocalStudyBackend(bank),
        intros: intros,
        crossRefs: crossRefs,
        readCache: (k) async => null,
        writeCache: (k, v) async => cache[k] = v,
      );
      await service.study(
        StudyRequest(
          reference: const StudyReference(
              bookId: 'genesis', chapter: 1, startVerse: 1, endVerse: 1),
          isAmharic: false,
          verseTexts: const ['x'],
        ),
      );
      expect(cache, isEmpty,
          reason: 'a knowledge note must never shadow a richer backend note');
    });

    test('without knowledge layers a null result stays the quiet fallback',
        () async {
      final result = await serviceWith().study(
        StudyRequest(
          reference: const StudyReference(
              bookId: 'genesis', chapter: 1, startVerse: 1, endVerse: 1),
          isAmharic: false,
          verseTexts: const ['x'],
        ),
      );
      expect(result.isAvailable, isFalse);
      expect(result.sections, isEmpty);
    });
  });
}

/// A backend whose calls can be started and completed by the test, so a
/// concurrent dedup can be observed mid-flight.
class _BlockingBackend implements StudyBackend {
  final Future<StudyResult?> Function() start;
  final void Function() complete;

  _BlockingBackend(this.start, this.complete);

  @override
  Future<StudyResult?> study(StudyRequest request) async {
    final result = await start();
    complete();
    return result;
  }
}
