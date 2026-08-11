import 'package:beslet_app/core/ai/study/book_meta.dart';
import 'package:beslet_app/core/ai/study/study_backend.dart';
import 'package:beslet_app/core/ai/study/study_fallback_backend.dart';
import 'package:beslet_app/core/ai/study/study_local_bank.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_sources.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAi implements StudyBackend {
  int calls = 0;
  bool fail = false;
  _FakeAi({this.fail = false});

  @override
  Future<StudyResult?> study(StudyRequest request) async {
    calls++;
    if (fail) throw Exception('boom');
    return StudyResult(
      reference: request.reference,
      source: StudySource.gemini,
      sections: const [],
      cachedAt: DateTime.now(),
      isAvailable: true,
    );
  }
}

StudyRequest _request({String book = 'genesis'}) => StudyRequest(
      reference: StudyReference(
          bookId: book, chapter: 1, startVerse: 1, endVerse: 1),
      isAmharic: false,
      verseTexts: const ['a'],
    );

void main() {
  group('StudyFallbackBackend', () {
    test('a banked passage is served locally — AI is never called', () async {
      var aiCalls = 0;
      final backend = StudyFallbackBackend(
        local: _banked(),
        ai: _CountingAi(() => aiCalls++),
        isOnline: () async => true,
        mayUseAi: () async => true,
        recordAiUse: () async {},
      );
      final result = await backend.study(_request());
      expect(result, isNotNull);
      expect(result!.source, StudySource.localBank);
      expect(aiCalls, 0);
    });

    test('unbanked + offline yields null (quiet fallback)', () async {
      final ai = _FakeAi();
      final backend = StudyFallbackBackend(
        local: _unbanked(),
        ai: ai,
        isOnline: () async => false,
        mayUseAi: () async => true,
        recordAiUse: () async {},
      );
      expect(await backend.study(_request()), isNull);
      expect(ai.calls, 0);
    });

    test('unbanked + online + under cap + AI success records the use', () async {
      var recorded = 0;
      final ai = _FakeAi();
      final backend = StudyFallbackBackend(
        local: _unbanked(),
        ai: ai,
        isOnline: () async => true,
        mayUseAi: () async => true,
        recordAiUse: () async => recorded++,
      );
      final result = await backend.study(_request());
      expect(result, isNotNull);
      expect(result!.source, StudySource.gemini);
      expect(ai.calls, 1);
      expect(recorded, 1);
    });

    test('unbanked + over the daily cap refuses — AI is never called', () async {
      final ai = _FakeAi();
      final backend = StudyFallbackBackend(
        local: _unbanked(),
        ai: ai,
        isOnline: () async => true,
        mayUseAi: () async => false,
        recordAiUse: () async {},
      );
      expect(await backend.study(_request()), isNull);
      expect(ai.calls, 0);
    });

    test('an AI failure yields null and never raises', () async {
      final ai = _FakeAi(fail: true);
      final backend = StudyFallbackBackend(
        local: _unbanked(),
        ai: ai,
        isOnline: () async => true,
        mayUseAi: () async => true,
        recordAiUse: () async {},
      );
      expect(await backend.study(_request()), isNull);
      expect(ai.calls, 1);
    });
  });
}

LocalStudyBackend _banked() => LocalStudyBackend(_Bank());

LocalStudyBackend _unbanked() => LocalStudyBackend(_Bank(empty: true));

class _CountingAi implements StudyBackend {
  final void Function() onCall;
  _CountingAi(this.onCall);
  @override
  Future<StudyResult?> study(StudyRequest request) async {
    onCall();
    return null;
  }
}

class _Bank implements StudyLocalBank {
  final bool empty;
  _Bank({this.empty = false});

  @override
  int get version => 2;

  @override
  List<StudyBankEntry> get entries => empty ? const [] : const [
        StudyBankEntry(
          id: 'genesis_1_1',
          bookId: 'genesis',
          chapter: 1,
          startVerse: 1,
          endVerse: 1,
          sections: [],
        ),
      ];

  @override
  StudyBankEntry? entryFor(String bookId, int chapter, int startVerse) =>
      empty ? null : const StudyBankEntry(
          id: 'genesis_1_1',
          bookId: 'genesis',
          chapter: 1,
          startVerse: 1,
          endVerse: 1,
          sections: [],
        );

  @override
  List<String> validate({StudyCanon? canon, StudySourceRegistry? sources}) =>
      const [];
}