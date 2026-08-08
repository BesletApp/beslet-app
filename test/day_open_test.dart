import 'package:beslet_app/core/personalization/personalization_engine.dart';
import 'package:beslet_app/core/personalization/tone_service.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ToneService.completionMessage (day stays open)', () {
    testWidgets('never says "that is enough" or "complete"', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      final engine = await PersonalizationEngine.init();
      final tone = ToneService(engine);
      final msg = tone.completionMessage(l, 'Friend');
      expect(msg.toLowerCase(), isNot(contains('enough')), reason: 'gave: $msg');
      expect(msg.toLowerCase(), isNot(contains('complete')), reason: 'gave: $msg');
    });

    testWidgets('is forward-moving', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      final engine = await PersonalizationEngine.init();
      final tone = ToneService(engine);
      final msg = tone.completionMessage(l, 'Friend');
      expect(msg.toLowerCase(), contains('keep walking'), reason: 'gave: $msg');
    });
  });
}
