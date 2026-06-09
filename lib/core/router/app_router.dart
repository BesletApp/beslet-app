import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/spiritual/prayer_screen.dart';
import '../../features/spiritual/bible_screen.dart';
import '../../features/skills/skills_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/reflection/reflection_screen.dart';
import '../../features/fellowship/fellowship_screen.dart';
import '../../features/family/family_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) {
      final l = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🙏', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(l.pageNotFound, style: AppTextStyles.displaySmall),
              const SizedBox(height: 8),
              Text(state.error?.message ?? 'The page you\'re looking for doesn\'t exist.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => context.go('/home'), child: Text(l.goHome)),
            ]),
          ),
        ),
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/habits', builder: (_, __) => const HabitsScreen()),
            GoRoute(path: '/prayer', builder: (_, __) => const PrayerScreen()),
            GoRoute(path: '/skills', builder: (_, __) => const SkillsScreen()),
            GoRoute(path: '/reflection', builder: (_, __) => const ReflectionScreen()),
            GoRoute(path: '/fellowship', builder: (_, __) => const FellowshipScreen()),
            GoRoute(path: '/family', builder: (_, __) => const FamilyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/bible', builder: (_, __) => const BibleScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/community', builder: (_, __) => const CommunityScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
            GoRoute(path: '/settings', builder: (_, state) => SettingsScreen(section: state.uri.queryParameters['section'])),
          ]),
        ],
      ),
    ],
  );
}
