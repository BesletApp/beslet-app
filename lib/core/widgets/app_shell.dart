import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined, color: AppColors.textMuted), selectedIcon: const Icon(Icons.home, color: AppColors.primary), label: l.home),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined, color: AppColors.textMuted), selectedIcon: const Icon(Icons.menu_book, color: AppColors.primary), label: l.bible),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined, color: AppColors.textMuted), selectedIcon: const Icon(Icons.bar_chart, color: AppColors.primary), label: l.progress),
          NavigationDestination(icon: const Icon(Icons.people_outline, color: AppColors.textMuted), selectedIcon: const Icon(Icons.people, color: AppColors.primary), label: l.community),
          NavigationDestination(icon: const Icon(Icons.person_outline, color: AppColors.textMuted), selectedIcon: const Icon(Icons.person, color: AppColors.primary), label: l.profile),
        ],
      ),
    );
  }
}
