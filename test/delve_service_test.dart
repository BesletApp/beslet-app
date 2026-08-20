import 'package:beslet_app/core/ai/delve/delve_backend.dart';
import 'package:beslet_app/core/ai/delve/delve_models.dart';
import 'package:beslet_app/core/ai/delve/delve_service.dart';
import 'package:beslet_app/core/ai/delve/delve_validator.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

const _raw = '{"expandedHistory":{"text":"The psalm uses shepherd imagery."},'
    '"literaryAnalysis":{"text":"It moves from trust through the valley."},'
    '"expandedCrossReferences":{"items":[{"bookId":"john","chapter":10,'
    '"startVerse":11,"endVerse":11,"priority":0,'
    '"reason":"Jesus the good Shepherd."}]}}';

DelveRequest _request({bool am = false}) => DelveRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 2),
      isAmharic: am,
      verseTexts: const ['a', 'b'],
    );

DelveBackend _countingBackend(
  void Function() onCall, {
  String raw = _raw,
  DelveUnavailability? failWith,
}) {
  return DelveBackend(
    transport: (prompt) async {
      onCall();
      if (failWith != null) throw DelveGeminiException(failWith);
      return raw;
    },
    validator: DelveValidator(canon: loadTestCanon()),
  );
}

void main() {
  DelveService serviceWith({
    Map<String, String>? cache,
    DelveBackend? backend,
    Future<bool> Function()? isOnline,
    Future<bool> Function()? mayDelve,
    Future<void> Function()? recordUse,
  }) =>
      DelveService(
        backend: backend ?? _countingBackend(() {}),
        readCache: (k) async => cache?[k],
        writeCache: (k, v) async => cache?[k] = v,
        removeCache: (k) async => cache?.remove(k),
        isOnline: isOnline ?? () async => true,
        mayDelve: mayDelve ?? () async => true,
        recordDelveUse: recordUse ?? () async {},
      );

  group('DelveService.delve', () {
    test('generates and serves a real deep note', () async {
      final result = await serviceWith().delve(_request());
      expect(result.isAvailable, isTrue);
      expect(result.source, DelveSource.gemini);
      expect(result.sections, isNotEmpty);
      expect(result.reference.referenceFor(false), 'Psalms 23:1–2');
    });

    test('an unavailable result is never cached', () async {
      final cache = <String, String>{};
      final service = serviceWith(
        cache: cache,
        backend: _countingBackend(
          () {},
          failWith: DelveUnavailability.server,
        ),
      );
      final result = await service.delve(_request());
      expect(result.isAvailable, isFalse);
      expect(result.unavailability, DelveUnavailability.server);
      expect(cache, isEmpty);
    });

    test('re-opening the same passage reuses the cached deep note', () async {
      final cache = <String, String>{};
      var calls = 0;
      final service = serviceWith(
        cache: cache,
        backend: _countingBackend(() => calls++),
      );
      await service.delve(_request());
      final second = await service.delve(_request());
      expect(second.isAvailable, isTrue);
      expect(calls, 1); // memory cache served the second call
    });

    test('a disk-cached note is served without calling the backend', () async {
      final cache = <String, String>{};
      final seeded = DelveResult(
        reference: _request().reference,
        source: DelveSource.gemini,
        sections: const [
          DelveSection(kind: DelveSectionKind.literaryAnalysis, en: 'cached'),
        ],
        cachedAt: DateTime.now(),
        isAvailable: true,
      );
      cache['delve_v${delvePromptVersion}_'
          '${_request().reference.cacheKey}_en'] = seeded.toJsonString();
      var calls = 0;
      final service = serviceWith(
        cache: cache,
        backend: _countingBackend(() => calls++),
      );
      final result = await service.delve(_request());
      expect(result.isAvailable, isTrue);
      expect(calls, 0);
    });

    test('offline returns the offline reason without touching the backend',
        () async {
      var calls = 0;
      final result = await serviceWith(
        backend: _countingBackend(() => calls++),
        isOnline: () async => false,
      ).delve(_request());
      expect(result.isAvailable, isFalse);
      expect(result.unavailability, DelveUnavailability.offline);
      expect(calls, 0);
    });

    test('an exhausted free allowance surfaces the limit sentinel', () async {
      var calls = 0;
      final result = await serviceWith(
        backend: _countingBackend(() => calls++),
        mayDelve: () async => false,
      ).delve(_request());
      expect(result.isAvailable, isFalse);
      expect(result.limitReached, isTrue);
      expect(result.unavailability, DelveUnavailability.capped);
      expect(calls, 0);
    });

    test('a successful bundled-key run records its use', () async {
      var recorded = 0;
      await serviceWith(
        recordUse: () async => recorded++,
      ).delve(_request());
      expect(recorded, 1);
    });

    test('refresh bypasses the memory cache and disk cache', () async {
      final cache = <String, String>{};
      var calls = 0;
      final service = serviceWith(
        cache: cache,
        backend: _countingBackend(() => calls++),
      );
      await service.delve(_request());
      await service.refresh(_request(), bypassDisk: true);
      expect(calls, 2); // the disk note was cleared and regenerated fresh
      expect(
        cache['delve_v${delvePromptVersion}_'
            '${_request().reference.cacheKey}_en'],
        isNotNull,
      );
    });

    test('a transient AI failure retries once and still explains', () async {
      var calls = 0;
      final backend = DelveBackend(
        transport: (prompt) async {
          calls++;
          if (calls == 1) throw DelveGeminiException(DelveUnavailability.timeout);
          return _raw;
        },
        validator: DelveValidator(canon: loadTestCanon()),
      );
      final result = await serviceWith(backend: backend).delve(_request());
      expect(result.isAvailable, isTrue);
      expect(calls, 2);
    });
  });
}