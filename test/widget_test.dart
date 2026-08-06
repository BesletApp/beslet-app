import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beslet_app/app.dart';
import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/user_provider.dart';

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

    expect(find.text('ብስለት'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('ብስለት'), findsNothing);
    expect(find.text('Start'), findsOneWidget);
  });
}
