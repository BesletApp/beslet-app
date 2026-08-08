import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../personalization/personalization_providers.dart';
import '../../features/spiritual/widgets/mini_player_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final currentIndex = widget.navigationShell.currentIndex;
    final sessionCtrl = ref.watch(sessionControllerProvider);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: widget.navigationShell),
          const MiniPlayerBar(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index != currentIndex) {
            widget.navigationShell.goBranch(index);
          }
        },
        backgroundColor: c.card,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        animationDuration: sessionCtrl.transition(AppDurations.normal),
        destinations: [
          NavigationDestination(icon: Icon(Icons.today_outlined, color: c.textMuted), selectedIcon: Icon(Icons.today, color: AppColors.primary), label: l.today),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined, color: c.textMuted), selectedIcon: Icon(Icons.menu_book, color: AppColors.primary), label: l.bible),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined, color: c.textMuted), selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary), label: l.growth),
          NavigationDestination(icon: Icon(Icons.person_outline, color: c.textMuted), selectedIcon: Icon(Icons.person, color: AppColors.primary), label: l.profile),
        ],
      ),
    );
  }
}
