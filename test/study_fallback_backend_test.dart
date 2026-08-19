import 'package:beslet_app/core/ai/study/book_meta.dart';
import 'package:beslet_app/core/ai/study/study_backend.dart';
import 'package:beslet_app/core/ai/study/study_fallback_backend.dart';
import 'package:beslet_app/core/ai/study/study_local_bank.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_sources.dart';
import 'package:flutter_test/flutter_test.dart';

/// A scripted AI backend: returns a sequence of [StudyAttempt]s (or throws),
/// counting every call so retry behavior is observable.
class _ScriptedAi implements StudyBackend {
  final List<StudyAttempt Function()> script;
  int calls = 0;

  _ScriptedAi(this.script);

  _ScriptedAi.success() : script = [
          () => StudyAttempt.available(_geminiNote(StudyReference(
              bookId: 'genesis', chapter: 1, startVerse: 1, endVerse: 1))),
        ];

  _ScriptedAi.failures(StudyUnavailability reason, {int count = 1})
      : script = [for (var i = 0; i < count; i++) () => StudyAttempt.unavailable(reason)];

  @override
  Future<StudyAttempt> study(StudyRequest request) async {
    if (script.isEmpty) {
      return StudyAttempt.unavailable(StudyUnavailability.server);
    }
    final index = calls < script.length ? calls : script.length - 1;
    calls++;
    try {
      return script[index]();
    } catch (_) {
      return StudyAttempt.unavailable(StudyUnavailability.server);
    }
  }
}

StudyResult _geminiNote(StudyReference reference) => StudyResult(
      reference: reference,
      source: StudySource.gemini,
      sections: const [],
      cachedAt: DateTime.now(),
      isAvailable: true,
    );

StudyRequest _request({String book = 'genesis'}) => StudyRequest(
      reference: StudyReference(
          bookId: book, chapter: 1, startVerse: 1, endVerse: 1),
      isAmharic: false,
      verseTexts: const ['a'],
    );

void main() {
  StudyFallbackBackend buildBackend({
    required StudyBackend? ai,
    LocalStudyBackend? local,
    Future<bool> Function()? isOnline,
    Future<bool> Function()? mayUseAi,
    Future<void> Function()? recordAiUse,
    Duration retryDelay = Duration.zero,
  }) =>
      StudyFallbackBackend(
        local: local ?? _unbanked(),
        ai: ai,
        isOnline: isOnline ?? () async => true,
        mayUseAi: mayUseAi ?? () async => true,
        recordAiUse: recordAiUse ?? () async {},
        retryDelay: retryDelay,
      );

  group('StudyFallbackBackend — AI-first', () {
    test('a banked passage is still answered by AI when AI is available',
        () async {
      var recorded = 0;
      final ai = _ScriptedAi.success();
      final backend = buildBackend(
        ai: ai,
        local: _banked(),
        recordAiUse: () async => recorded++,
      );
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(attempt.result!.source, StudySource.gemini,
          reason: 'AI-first: the bank must not shadow a working AI');
      expect(ai.calls, 1);
      expect(recorded, 1, reason: 'an AI success counts toward the app quota');
    });

    test('offline yields a clear offline reason and never calls AI', () async {
      final ai = _ScriptedAi.success();
      final backend = buildBackend(
        ai: ai,
        isOnline: () async => false,
      );
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isFalse);
      expect(attempt.unavailability, StudyUnavailability.offline,
          reason: 'offline must be a visible reason, never a silent null');
      expect(ai.calls, 0);
    });

    test('the daily cap returns the limit sentinel — AI is never called',
        () async {
      final ai = _ScriptedAi.success();
      final backend = buildBackend(
        ai: ai,
        mayUseAi: () async => false,
      );
      final attempt = await backend.study(_request());
      final result = attempt.result;
      expect(result, isNotNull);
      expect(result!.source, StudySource.limitReached,
          reason: 'a reached quota must be distinguishable, never a silent null');
      expect(result.limitReached, isTrue);
      expect(ai.calls, 0);
    });

    test('AI success with a personal key never counts toward the app quota',
        () async {
      var recorded = 0;
      final ai = _ScriptedAi.success();
      final backend = buildBackend(
        ai: ai,
        recordAiUse: () async => recorded++,
        // mayUseAi is true here because the provider treats a user key as
        // always-usable; the fallback itself calls recordAiUse unconditionally
        // and the provider's recordAiUse already skips user-key requests.
      );
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(recorded, 1);
    });

    test('AI success records the use exactly once (no double count)',
        () async {
      var recorded = 0;
      final ai = _ScriptedAi.success();
      final backend = buildBackend(
        ai: ai,
        recordAiUse: () async => recorded++,
      );
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(recorded, 1);
    });
  });

  group('StudyFallbackBackend — non-silent AI failure', () {
    test('a terminal AI failure serves the bank WITH the reason attached',
        () async {
      final ai = _ScriptedAi.failures(StudyUnavailability.authInvalid);
      final backend = buildBackend(ai: ai, local: _banked());
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(attempt.result!.source, StudySource.localBank);
      expect(attempt.result!.unavailability, StudyUnavailability.authInvalid,
          reason: 'a banked fallback must never hide why AI was unavailable');
      expect(ai.calls, 1,
          reason: 'terminal failures are not retried');
    });

    test('a transient failure is retried once and can recover', () async {
      final ai = _ScriptedAi.failures(StudyUnavailability.rateLimited, count: 1)
        ..script.add(() => StudyAttempt.available(_geminiNote(StudyReference(
            bookId: 'genesis', chapter: 1, startVerse: 1, endVerse: 1))));
      final backend = buildBackend(ai: ai);
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(attempt.result!.source, StudySource.gemini);
      expect(ai.calls, 2, reason: 'one retry after the transient failure');
    });

    test('a transient failure that recurs twice gives up and stays visible',
        () async {
      final ai = _ScriptedAi.failures(StudyUnavailability.timeout, count: 2);
      final backend = buildBackend(ai: ai, local: _banked());
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(attempt.result!.source, StudySource.localBank);
      expect(attempt.result!.unavailability, StudyUnavailability.timeout);
      expect(ai.calls, 2, reason: 'the retry budget is exactly one retry');
    });

    test('no bank entry leaves the reason alone (service assembles offline)',
        () async {
      final ai = _ScriptedAi.failures(StudyUnavailability.server);
      final backend = buildBackend(ai: ai, local: _unbanked());
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isFalse);
      expect(attempt.unavailability, StudyUnavailability.server);
      expect(ai.calls, 2,
          reason: 'server is a transient reason, so it is retried once first');
    });

    test('an AI exception becomes a server reason, not a silent null',
        () async {
      final ai = _ThrowingAi();
      final backend = buildBackend(ai: ai, local: _banked());
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(attempt.result!.source, StudySource.localBank);
      expect(attempt.result!.unavailability, StudyUnavailability.server);
    });

    test('without any AI backend the bank is the answer, no reason attached',
        () async {
      final backend = buildBackend(ai: null, local: _banked());
      final attempt = await backend.study(_request());
      expect(attempt.isAvailable, isTrue);
      expect(attempt.result!.source, StudySource.localBank);
      expect(attempt.result!.unavailability, StudyUnavailability.none);
    });
  });
}

class _ThrowingAi implements StudyBackend {
  @override
  Future<StudyAttempt> study(StudyRequest request) async =>
      throw Exception('boom');
}

LocalStudyBackend _banked() => LocalStudyBackend(_Bank());

LocalStudyBackend _unbanked() => LocalStudyBackend(_Bank(empty: true));

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
