import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beslet_app/app.dart';
import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/user_provider.dart';
import 'package:beslet_app/core/widgets/brand_mark.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots to splash then navigates to onboarding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith(
            (ref) async => User(
              id: 1,
              name: 'Friend',
              goals: '[]',
              onboarded: false,
              lang: 'en',
              biblePlan: 'nt',
              createdAt: DateTime.now().toIso8601String(),
              sabbathDay: -1,
              avatarColor: 'gold',
            ),
          ),
          isOnboardedProvider.overrideWith((ref) async => false),
        ],
        child: const BesletApp(),
      ),
    );

    // Splash shows the shared brand mark and the wordmark.
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.text('ብስለት'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('ብስለት'), findsNothing);
    expect(find.text('OPEN THE WORD'), findsOneWidget);
    expect(find.text('አማርኛ'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('reduced-motion splash shows a static mark and navigates quickly', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ProviderScope(
          overrides: [
            userProvider.overrideWith(
              (ref) async => User(
                id: 1,
                name: 'Friend',
                goals: '[]',
                onboarded: false,
                lang: 'en',
                biblePlan: 'nt',
                createdAt: DateTime.now().toIso8601String(),
                sabbathDay: -1,
                avatarColor: 'gold',
              ),
            ),
            isOnboardedProvider.overrideWith((ref) async => false),
          ],
          child: const BesletApp(),
        ),
      ),
    );

    expect(find.byType(BrandMark), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('OPEN THE WORD'), findsOneWidget);
  });
}
