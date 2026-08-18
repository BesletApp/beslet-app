import 'package:beslet_app/core/services/provocative_question_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3 - performance verification for the frozen "Today's Heart Check".
///
/// These are generous budget gates backed by printed measurements, so the
/// suite stays deterministic on any host while still proving the feature feels
/// instant: bundled asset load, JSON parse, and the date rotation (already O(1)
/// in the service) are all measured.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asset load, parse, and rotation stay far within budget', () async {
    final loadWatch = Stopwatch()..start();
    final raw =
        await rootBundle.loadString('assets/data/provocative_questions.json');
    final loadMs = loadWatch.elapsedMilliseconds;

    final parseWatch = Stopwatch()..start();
    final library = ProvocativeQuestionService.fromJsonString(raw);
    final parseMs = parseWatch.elapsedMilliseconds;
    expect(library.questions.length, 60);

    final rotateWatch = Stopwatch()..start();
    final epoch = ProvocativeQuestionService.epoch;
    for (var i = 0; i < 100000; i++) {
      library.questionFor(epoch.add(Duration(days: i % 400)));
    }
    rotateWatch.stop();
    final rotateMs = rotateWatch.elapsedMilliseconds;

    // ignore: avoid_print
    print('asset loadString: $loadMs ms');
    // ignore: avoid_print
    print('JSON parse (60 entries): $parseMs ms');
    // ignore: avoid_print
    print('100,000 date rotations: $rotateMs ms '
        '(${rotateMs / 100} us/rotation)');

    expect(loadMs, lessThan(2000),
        reason: 'bundled JSON asset must load quickly');
    expect(parseMs, lessThan(500),
        reason: 'parsing 60 entries must stay cheap');
    expect(rotateMs, lessThan(5000),
        reason: 'the date rotation must be O(1) and fast');
  });
}