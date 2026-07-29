import 'package:go_router/go_router.dart';
import '../../features/spiritual/bible_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const BibleScreen(),
    routes: [
      GoRoute(path: '/', builder: (context, state) {
        final book = state.uri.queryParameters['book'];
        final chStr = state.uri.queryParameters['chapter'];
        final chapter = chStr != null ? int.tryParse(chStr) : null;
        return BibleScreen(initialBookId: book, initialChapter: chapter);
      }),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
