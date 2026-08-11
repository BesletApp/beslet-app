import 'dart:io';

import 'package:beslet_app/core/ai/study/study_backend.dart';
import 'package:beslet_app/core/ai/study/study_local_bank.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
    test('resolves a banked passage to all seven sections', () async {
      final result = await serviceWith().study(psalmRequest());
      expect(result.isAvailable, isTrue);
      expect(result.source, StudySource.localBank);
      expect(result.sections.length, 7);
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
      final summary = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.whatTextSays);
      expect(summary.textFor(false), summary.en);
      expect(summary.textFor(true), summary.am);
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
      expect(second.sections.length, 7);
      expect(backendCalls, 1, reason: 'second call must come from the cache');
      expect(cache.containsKey('study_v${studyPromptVersion}_psalms_23_1_3_en'),
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
      expect(cache.containsKey('study_v${studyPromptVersion}_psalms_23_1_3_am'),
          isTrue);
    });

    test('cache key embeds the prompt version', () {
      final service = serviceWith();
      expect(service.cacheKeyFor(psalmRequest()),
          'study_v${studyPromptVersion}_psalms_23_1_3_en');
    });

    test('a corrupt cache entry falls through to the backend', () async {
      final cache = <String, String>{
        'study_v${studyPromptVersion}_psalms_23_1_3_en': 'not-json',
      };
      final result = await serviceWith(cache: cache).study(psalmRequest());
      expect(result.isAvailable, isTrue);
      expect(result.sections.length, 7);
    });
  });
}
