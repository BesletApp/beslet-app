import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/page_transition.dart' show FadeTransitionPage;
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/spiritual/prayer_screen.dart';
import '../../features/spiritual/bible_screen.dart';
import '../../features/threshold/threshold_screen.dart';
import '../../features/skills/skills_screen.dart';
import '../../features/growth/growth_screen.dart';
import '../../features/reflection/reflection_screen.dart';
import '../../features/reflection/daily_journal_screen.dart';
import '../../features/fellowship/fellowship_screen.dart';
import '../../features/tasks/daily_todo_screen.dart';
import '../../features/tasks/goals_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/word_challenge/word_challenge_screen.dart';
import '../../features/word_challenge/memory_garden_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) {
      final l = AppLocalizations.of(context)!;
      final c = AppColors.of(context);
      final t = AppTextStyles.of(context);
      return Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🙏', style: TextStyle(fontSize: 64)),
              SizedBox(height: AppSpacing.md),
              Text(l.pageNotFound, style: t.displaySmall),
              SizedBox(height: AppSpacing.sm),
              Text(state.error?.message ?? 'The page you\'re looking for doesn\'t exist.', style: t.bodyMedium.copyWith(color: c.textSecondary)),
              SizedBox(height: AppSpacing.lg),
              ElevatedButton(onPressed: () => context.go('/home'), child: Text(l.goHome)),
            ]),
          ),
        ),
      );
    },
    routes: [
      GoRoute(path: '/splash', pageBuilder: (context, state) => _buildPage(state, const SplashScreen())),
      GoRoute(path: '/onboarding', pageBuilder: (context, state) => _buildPage(state, const OnboardingScreen())),
      GoRoute(path: '/threshold', pageBuilder: (context, state) => _buildPage(state, const ThresholdScreen())),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', pageBuilder: (context, state) => _buildPage(state, const HomeScreen())),
            GoRoute(path: '/word-challenge', pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return _buildPage(
                state,
                WordChallengeScreen(reviewId: extra?['reviewId'] as String?),
              );
            }),
            GoRoute(path: '/memory-garden', pageBuilder: (context, state) => _buildPage(state, const MemoryGardenScreen())),
            GoRoute(path: '/habits', pageBuilder: (context, state) => _buildPage(state, const HabitsScreen())),
            GoRoute(path: '/prayer', pageBuilder: (context, state) => _buildPage(state, const PrayerScreen())),
            GoRoute(path: '/skills', pageBuilder: (context, state) => _buildPage(state, const SkillsScreen())),
            GoRoute(path: '/reflection', pageBuilder: (context, state) => _buildPage(state, const ReflectionScreen())),
            GoRoute(path: '/fellowship', pageBuilder: (context, state) => _buildPage(state, const FellowshipScreen())),
            GoRoute(path: '/daily-todo', pageBuilder: (context, state) => _buildPage(state, const DailyTodoScreen())),
            GoRoute(path: '/journal', pageBuilder: (context, state) => _buildPage(state, const DailyJournalScreen())),
            GoRoute(path: '/goals', pageBuilder: (context, state) => _buildPage(state, const GoalsScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/bible', pageBuilder: (context, state) {
              final book = state.uri.queryParameters['book'];
              final chStr = state.uri.queryParameters['chapter'];
              final chapter = chStr != null ? int.tryParse(chStr) : null;
              return _buildPage(state, BibleScreen(initialBookId: book, initialChapter: chapter));
            }),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/progress', pageBuilder: (context, state) => _buildPage(state, const GrowthScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', pageBuilder: (context, state) => _buildPage(state, const ProfileScreen())),
            GoRoute(path: '/settings', pageBuilder: (context, state) => _buildPage(state, SettingsScreen(section: state.uri.queryParameters['section']))),
          ]),
        ],
      ),
    ],
  );

  static Page _buildPage(GoRouterState state, Widget child) {
    return FadeTransitionPage(child: child, duration: const Duration(milliseconds: 350), key: ValueKey(state.uri.toString()));
  }
}
