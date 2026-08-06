import 'package:beslet_app/core/services/summer_service.dart';
import 'package:beslet_app/core/widgets/zone_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SummerService.seasonFor', () {
    test('before summer speaks of rest, with no numerals', () {
      final s = SummerService.seasonFor(DateTime(2026, 6, 1));
      expect(s.en, contains('rest'));
      expect(_hasDigit(s.en), isFalse);
      expect(_hasDigit(s.am), isFalse);
    });

    test('after summer speaks of a closed season, with no numerals', () {
      final s = SummerService.seasonFor(DateTime(2026, 9, 20));
      expect(s.en, contains('harvest'));
      expect(_hasDigit(s.en), isFalse);
      expect(_hasDigit(s.am), isFalse);
    });

    test('early summer names early summer', () {
      final s = SummerService.seasonFor(DateTime(2026, 6, 20));
      expect(s.en, contains('early summer'));
    });

    test('mid summer names mid-summer', () {
      final s = SummerService.seasonFor(DateTime(2026, 7, 20));
      expect(s.en, contains('mid-summer'));
    });

    test('late summer names late summer', () {
      final s = SummerService.seasonFor(DateTime(2026, 9, 5));
      expect(s.en, contains('late summer'));
    });

    test('seasonFor never renders a numeral in either language', () {
      final samples = [
        DateTime(2026, 1, 1),
        DateTime(2026, 6, 8),
        DateTime(2026, 7, 1),
        DateTime(2026, 8, 15),
        DateTime(2026, 9, 11),
        DateTime(2027, 3, 3),
      ];
      for (final sample in samples) {
        final s = SummerService.seasonFor(sample);
        expect(_hasDigit(s.en), isFalse, reason: 'en for $sample');
        expect(_hasDigit(s.am), isFalse, reason: 'am for $sample');
      }
    });
  });

  group('Profile zone layout', () {
    testWidgets('ZoneLayout renders its four zones in order', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ZoneLayout(
                orientation: _tag('orientation'),
                primary: _tag('primary'),
                support: _tag('support'),
                anchor: _tag('anchor'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('orientation'), findsOneWidget);
      expect(find.text('primary'), findsOneWidget);
      expect(find.text('support'), findsOneWidget);
      expect(find.text('anchor'), findsOneWidget);
    });
  });
}

bool _hasDigit(String s) => s.contains(RegExp(r'[0-9]'));

Widget _tag(String label) => Center(child: Text(label));
