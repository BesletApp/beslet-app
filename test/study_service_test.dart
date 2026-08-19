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
  Future<StudyAttempt> study(StudyRequest request) async {
    onCall();
    final entry = bank.entryFor(
      request.reference.bookId,
      request.reference.chapter,
      request.reference.startVerse,
    );
    if (entry == null) return const StudyAttempt.nothing();
    return StudyAttempt.available(StudyResult(
      reference: request.reference,
      source: StudySource.localBank,
      sections: entry.sections,
      cachedAt: DateTime.now(),
      isAvailable: true,
    ));
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
      final completer = Completer<StudyAttempt>();
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

      completer.complete(StudyAttempt.available(StudyResult(
        reference: psalmRequest().reference,
        source: StudySource.localBank,
        sections: bank.entryFor('psalms', 23, 1)!.sections,
        cachedAt: DateTime.now(),
        isAvailable: true,
      )));
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

  group('StudyService cap / refresh', () {
    test(
        'a cap sentinel with knowledge layers yields a flagged offline note, '
        'never cached', () async {
      final cache = <String, String>{};
      final service = StudyService(
        backend: const _CapBackend(),
        intros: loadTestIntros(),
        crossRefs: loadTestCrossRefs(),
        readCache: (k) async => null,
        writeCache: (k, v) async => cache[k] = v,
      );
      final result = await service.study(psalmRequest());
      expect(result.limitReached, isTrue);
      expect(result.isAvailable, isTrue,
          reason: 'offline material is still known to be available');
      expect(result.source, StudySource.knowledge);
      expect(cache, isEmpty,
          reason: 'a limited/offline note must never be persisted');
    });

    test('a cap sentinel with no knowledge layers surfaces the prompt alone',
        () async {
      final service = StudyService(
        backend: const _CapBackend(),
        readCache: (k) async => null,
        writeCache: (k, v) async {},
      );
      final result = await service.study(psalmRequest());
      expect(result.limitReached, isTrue);
      expect(result.isAvailable, isFalse);
      expect(result.source, StudySource.limitReached);
    });

    test('refresh clears the in-memory limit note so adding a key re-resolves',
        () async {
      final backend = _SwitchableBackend();
      final service = StudyService(
        backend: backend,
        readCache: (k) async => null,
        writeCache: (k, v) async {},
      );

      final first = await service.study(psalmRequest());
      expect(first.limitReached, isTrue);

      // A personal key is now present and the app key quota no longer gates.
      backend.mode = _SwitchableBackend.gemini;
      final refreshed = await service.refresh(psalmRequest());
      expect(refreshed.source, StudySource.gemini);
      expect(refreshed.limitReached, isFalse);
      expect(backend.calls, 2, reason: 'refresh must re-run the backend');
    });

    test('refresh with bypassDisk ignores a stale persisted note', () async {
      final cache = <String, String>{};
      final backend = _SwitchableBackend();
      final service = StudyService(
        backend: backend,
        readCache: (k) async => cache[k],
        writeCache: (k, v) async => cache[k] = v,
      );
      final key = service.cacheKeyFor(psalmRequest());

      // A stale AI note from a previous session sits on disk.
      cache[key] = 'stale-from-before';
      backend.mode = _SwitchableBackend.gemini;

      final refreshed = await service.refresh(psalmRequest(),
          bypassDisk: true);
      expect(refreshed.source, StudySource.gemini);
      expect(backend.calls, 1,
          reason: 'bypassDisk must drop the stale note so the backend runs');
      expect(cache.containsKey(key), isTrue,
          reason: 'the fresh gemini note replaces the stale one on disk');
      expect(cache[key], isNot('stale-from-before'));
    });
  });

  group('StudyService reliability (failures are never silent or sticky)', () {
    StudyRequest genesisRequest() => StudyRequest(
          reference: const StudyReference(
              bookId: 'genesis', chapter: 1, startVerse: 1, endVerse: 1),
          isAmharic: false,
          verseTexts: const ['x'],
        );

    test('an unavailable resolution is NOT memoized — a re-open re-attempts',
        () async {
      var calls = 0;
      final backend = _FlakyBackend(() => calls++ < 1
          ? const StudyAttempt.unavailable(StudyUnavailability.timeout)
          : StudyAttempt.available(StudyResult(
              reference: genesisRequest().reference,
              source: StudySource.gemini,
              sections: const [],
              cachedAt: DateTime.now(),
              isAvailable: true,
            )));
      final service = StudyService(
        backend: backend,
        intros: loadTestIntros(),
        crossRefs: loadTestCrossRefs(),
        readCache: (k) async => null,
        writeCache: (k, v) async {},
      );

      final first = await service.study(genesisRequest());
      expect(first.isAvailable, isTrue,
          reason: 'the offline assembly keeps the passage readable');
      expect(first.unavailability, StudyUnavailability.timeout,
          reason: 'the panel must know why AI was unavailable');
      expect(calls, 1);

      // A re-open must NOT be served the previous offline assembly from memory.
      final second = await service.study(genesisRequest());
      expect(second.source, StudySource.gemini,
          reason: 'a re-open must re-attempt AI, not replay the stale failure');
      expect(calls, 2);
    });

    test('an offline assembly with a reason is never persisted', () async {
      final cache = <String, String>{};
      final service = StudyService(
        backend: const _ReasonBackend(StudyUnavailability.offline),
        intros: loadTestIntros(),
        crossRefs: loadTestCrossRefs(),
        readCache: (k) async => null,
        writeCache: (k, v) async => cache[k] = v,
      );
      final result = await service.study(genesisRequest());
      expect(result.isAvailable, isTrue);
      expect(result.unavailability, StudyUnavailability.offline);
      expect(cache, isEmpty,
          reason: 'a failure-backed note must never shadow a future AI note');
    });

    test('a bank note served after an AI failure keeps the reason attached '
        'and is not cached as a fresh answer', () async {
      final cache = <String, String>{};
      final service = StudyService(
        backend: _BankAfterFailureBackend(bank),
        intros: loadTestIntros(),
        crossRefs: loadTestCrossRefs(),
        readCache: (k) async => null,
        writeCache: (k, v) async => cache[k] = v,
      );
      final result = await service.study(psalmRequest());
      expect(result.isAvailable, isTrue);
      expect(result.source, StudySource.localBank);
      expect(result.unavailability, StudyUnavailability.rateLimited,
          reason: 'the offline fallback must stay non-silent');
      expect(cache, isEmpty);
    });
  });
}

/// Returns a backend that reports a failure while the study has no knowledge
/// layers, so the service falls back to the quiet unavailable note.
class _ReasonBackend implements StudyBackend {
  final StudyUnavailability reason;

  const _ReasonBackend(this.reason);

  @override
  Future<StudyAttempt> study(StudyRequest request) async =>
      StudyAttempt.unavailable(reason);
}

/// A backend whose result can change between calls (first failure, then a real
/// note) so "re-open re-attempts" can be observed.
class _FlakyBackend implements StudyBackend {
  final StudyAttempt Function() next;

  _FlakyBackend(this.next);

  @override
  Future<StudyAttempt> study(StudyRequest request) async => next();
}

/// A backend that answers with the curated bank only *after* AI would have
/// failed — mirroring the fallback composer — and attaches the failure reason
/// to the banked note.
class _BankAfterFailureBackend implements StudyBackend {
  final StudyLocalBank bank;

  _BankAfterFailureBackend(this.bank);

  @override
  Future<StudyAttempt> study(StudyRequest request) async {
    final entry = bank.entryFor(
      request.reference.bookId,
      request.reference.chapter,
      request.reference.startVerse,
    );
    if (entry == null) return const StudyAttempt.nothing();
    return StudyAttempt.available(StudyResult(
      reference: request.reference,
      source: StudySource.localBank,
      sections: entry.sections,
      cachedAt: DateTime.now(),
      isAvailable: true,
      unavailability: StudyUnavailability.rateLimited,
    ));
  }
}

/// A backend whose calls can be started and completed by the test, so a
/// concurrent dedup can be observed mid-flight.
class _BlockingBackend implements StudyBackend {
  final Future<StudyAttempt> Function() start;
  final void Function() complete;

  _BlockingBackend(this.start, this.complete);

  @override
  Future<StudyAttempt> study(StudyRequest request) async {
    final result = await start();
    complete();
    return result;
  }
}

/// Always reports that the app's free daily AI allowance was reached.
class _CapBackend implements StudyBackend {
  const _CapBackend();

  @override
  Future<StudyAttempt> study(StudyRequest request) async =>
      StudyAttempt.available(StudyResult.aiLimit(reference: request.reference));
}

/// A backend that can switch from "capped" to "AI available" mid-test, so the
/// `refresh` path (after the reader adds their own key) can be observed.
class _SwitchableBackend implements StudyBackend {
  static const capped = 0;
  static const gemini = 1;

  int mode = capped;
  int calls = 0;

  _SwitchableBackend();

  @override
  Future<StudyAttempt> study(StudyRequest request) async {
    calls++;
    if (mode == gemini) {
      return StudyAttempt.available(StudyResult(
        reference: request.reference,
        source: StudySource.gemini,
        sections: const [],
        cachedAt: DateTime.now(),
        isAvailable: true,
      ));
    }
    return StudyAttempt.available(StudyResult.aiLimit(reference: request.reference));
  }
}
