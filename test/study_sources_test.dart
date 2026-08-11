import 'package:beslet_app/core/ai/study/study_sources.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

void main() {
  group('StudySourceRegistry (shipped asset)', () {
    test('loads with the expected version and both curated sources', () {
      final registry = loadTestSources();
      expect(registry.version, 1);
      expect(registry.sources.keys, containsAll(['scripture', 'tradition']));
      final scripture = registry.sourceFor('scripture');
      expect(scripture, isNotNull);
      expect(scripture!.en, isNotEmpty);
      expect(scripture.titleFor(true), scripture.am);
      expect(registry.sourceFor('not_a_source'), isNull);
    });

    test('rejects a wrong version (fail closed)', () {
      expect(
        () => StudySourceRegistry.fromJsonString(
            '{"version":2,"sources":[]}'),
        throwsFormatException,
      );
    });

    test('rejects an empty registry (fail closed)', () {
      expect(
        () => StudySourceRegistry.fromJsonString(
            '{"version":1,"sources":[]}'),
        throwsFormatException,
      );
    });

    test('unknownIn reports only the ids that are not known', () {
      final registry = loadTestSources();
      expect(registry.unknownIn(['scripture', 'tradition']), isEmpty);
      expect(registry.unknownIn(['nope', 'scripture']), ['nope']);
    });
  });
}