import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../../features/spiritual/widgets/mini_player_bar.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnim = CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Widget _buildIcon(IconData icon, bool selected) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (_, child) => Transform.scale(
        scale: selected ? 1.0 + _bounceAnim.value * 0.15 : 1.0,
        child: child,
      ),
      child: Icon(icon, color: selected ? AppColors.primary : c.textMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final currentIndex = widget.navigationShell.currentIndex;

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
            _bounceCtrl.forward(from: 0);
          }
        },
        backgroundColor: c.card,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: [
          NavigationDestination(icon: _buildIcon(Icons.today_outlined, currentIndex == 0), selectedIcon: _buildIcon(Icons.today, currentIndex == 0), label: l.today),
          NavigationDestination(icon: _buildIcon(Icons.menu_book_outlined, currentIndex == 1), selectedIcon: _buildIcon(Icons.menu_book, currentIndex == 1), label: l.bible),
          NavigationDestination(icon: _buildIcon(Icons.bar_chart_outlined, currentIndex == 2), selectedIcon: _buildIcon(Icons.bar_chart, currentIndex == 2), label: l.growth),
          NavigationDestination(icon: _buildIcon(Icons.person_outline, currentIndex == 3), selectedIcon: _buildIcon(Icons.person, currentIndex == 3), label: l.profile),
        ],
      ),
    );
  }
}
