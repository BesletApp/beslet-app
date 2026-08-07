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
    testWidgets('never says "that is enough" or "complete" for any voice',
        (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      for (final voice in ['quiet', 'warm', 'still']) {
        final engine = await PersonalizationEngine.init();
        await engine.setVoice(voice);
        final tone = ToneService(engine);
        final msg = tone.completionMessage(l, 'Friend');
        expect(msg.toLowerCase(), isNot(contains('enough')),
            reason: 'voice=$voice gave: $msg');
        expect(msg.toLowerCase(), isNot(contains('complete')),
            reason: 'voice=$voice gave: $msg');
      }
    });

    testWidgets('all voices are forward-moving', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      for (final voice in ['quiet', 'warm', 'still']) {
        final engine = await PersonalizationEngine.init();
        await engine.setVoice(voice);
        final tone = ToneService(engine);
        final msg = tone.completionMessage(l, 'Friend');
        expect(msg.toLowerCase(), contains('keep walking'),
            reason: 'voice=$voice gave: $msg');
      }
    });
  });
}
