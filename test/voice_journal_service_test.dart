import 'package:beslet_app/core/ai/voice_journal/voice_journal_backend.dart';
import 'package:beslet_app/core/ai/voice_journal/voice_journal_models.dart';
import 'package:beslet_app/core/ai/voice_journal/voice_journal_service.dart';
import 'package:beslet_app/core/ai/voice_journal/voice_journal_validator.dart';
import 'package:flutter_test/flutter_test.dart';

const _raw = '{"whatHappened":"went to the market with my brother",'
    '"emotions":"felt happy and tired",'
    '"spiritualMoments":"prayed in the evening and felt peace",'
    '"insights":"learned to trust God more",'
    '"sentenceToRemember":"I learned to trust God more."}';

const _transcript =
    'Today I went to the market with my brother. I felt happy and tired. '
    'I prayed in the evening and felt peace. I learned to trust God more. '
    'Keep going John.';

VoiceJournalRequest _request({bool am = false}) =>
    VoiceJournalRequest(transcript: _transcript, isAmharic: am);

VoiceJournalBackend _countingBackend(
  void Function() onCall, {
  String raw = _raw,
  VoiceJournalUnavailability? failWith,
}) {
  return VoiceJournalBackend(
    transport: (prompt) async {
      onCall();
      if (failWith != null) {
        throw VoiceJournalGeminiException(failWith);
      }
      return raw;
    },
    validator: const VoiceJournalValidator(),
  );
}

void main() {
  VoiceJournalService serviceWith({
    Map<String, String>? cache,
    VoiceJournalBackend? backend,
    Future<bool> Function()? isOnline,
    Future<bool> Function()? mayOrganize,
    Future<void> Function()? recordUse,
    Duration? retryDelay,
  }) =>
      VoiceJournalService(
        backend: backend ?? _countingBackend(() {}),
        readCache: (k) async => cache?[k],
        writeCache: (k, v) async => cache?[k] = v,
        removeCache: (k) async => cache?.remove(k),
        isOnline: isOnline ?? () async => true,
        mayOrganize: mayOrganize ?? () async => true,
        recordVoiceJournalUse: recordUse ?? () async {},
        retryDelay: retryDelay ?? const Duration(milliseconds: 1500),
      );

  group('VoiceJournalService.organize', () {
    test('organizes and serves a real journal for the exact transcript',
        () async {
      final result = await serviceWith().organize(_request());
      expect(result.isAvailable, isTrue);
      expect(result.source, VoiceJournalSource.gemini);
      expect(result.sections, hasLength(5));
    });

    test('an unavailable result is never cached', () async {
      final cache = <String, String>{};
      final service = serviceWith(
        cache: cache,
        backend: _countingBackend(
          () {},
          failWith: VoiceJournalUnavailability.server,
        ),
      );
      final result = await service.organize(_request());
      expect(result.isAvailable, isFalse);
      expect(result.unavailability, VoiceJournalUnavailability.server);
      expect(cache, isEmpty);
    });

    test('re-organizing identical text reuses the cached journal', () async {
      final cache = <String, String>{};
      var calls = 0;
      final service = serviceWith(
        cache: cache,
        backend: _countingBackend(() => calls++),
      );
      await service.organize(_request());
      final second = await service.organize(_request());
      expect(second.isAvailable, isTrue);
      expect(calls, 1); // memory cache served the second call
      expect(cache, isNotEmpty);
    });

    test('a persisted journal is served from disk without the backend',
        () async {
      final cache = <String, String>{};
      final service =
          serviceWith(cache: cache); // working backend populates disk cache
      await service.organize(_request());
      final fresh = serviceWith(
        cache: cache,
        backend: _countingBackend(() {
          fail('backend must not run on a disk cache hit');
        }),
      );
      final result = await fresh.organize(_request());
      expect(result.isAvailable, isTrue);
      expect(result.sections, hasLength(5));
    });

    test('a different transcript is never served from the first one\'s cache',
        () async {
      final cache = <String, String>{};
      var calls = 0;
      final service = serviceWith(
        cache: cache,
        backend: _countingBackend(() => calls++),
      );
      await service.organize(_request());
      await service.organize(_request(
          am: true)); // different language → different key
      expect(calls, 2);
    });

    test('definitive offline fails fast with a clear reason', () async {
      var calls = 0;
      final service = serviceWith(
        backend: _countingBackend(() => calls++),
        isOnline: () async => false,
      );
      final result = await service.organize(_request());
      expect(result.isAvailable, isFalse);
      expect(result.unavailability, VoiceJournalUnavailability.offline);
      expect(calls, 0);
    });

    test('the usage gate caps the free allowance with the limit sentinel',
        () async {
      var calls = 0;
      final service = serviceWith(
        backend: _countingBackend(() => calls++),
        mayOrganize: () async => false,
      );
      final result = await service.organize(_request());
      expect(result.isAvailable, isFalse);
      expect(result.limitReached, isTrue);
      expect(result.unavailability, VoiceJournalUnavailability.capped);
      expect(calls, 0);
    });

    test('records a bundled-key use only after a successful run', () async {
      var recorded = 0;
      final service = serviceWith(recordUse: () async => recorded++);
      await service.organize(_request());
      expect(recorded, 1);
    });

    test('retries once on a transient server failure before succeeding',
        () async {
      var calls = 0;
      final service = serviceWith(
        retryDelay: Duration.zero,
        backend: VoiceJournalBackend(
          transport: (prompt) async {
            calls++;
            if (calls == 1) {
              throw VoiceJournalGeminiException(VoiceJournalUnavailability.server);
            }
            return _raw;
          },
          validator: const VoiceJournalValidator(),
        ),
      );
      final result = await service.organize(_request());
      expect(result.isAvailable, isTrue);
      expect(calls, 2);
    });

    test('an oversized transcript fails tooLong without a backend call',
        () async {
      var calls = 0;
      final service = serviceWith(
        backend: _countingBackend(() => calls++),
      );
      final long = 'word ' * 1400; // > 6000 chars
      final result = await service
          .organize(VoiceJournalRequest(transcript: long, isAmharic: false));
      expect(result.isAvailable, isFalse);
      expect(result.unavailability, VoiceJournalUnavailability.tooLong);
      expect(calls, 0);
    });
  });
}