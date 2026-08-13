import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/user_provider.dart';
import 'epigraph_door.dart';

/// The doorway to Beslet — one screen, three things and three things only:
///   1. What is this app?      → the epigraph (John 15:5) + one identity line
///   2. Which language?        → አማርኛ / English, persisted the moment it is tapped
///   3. What should I do next? → Open the Word
///
/// The language chosen here is written to the database in real time — the
/// whole app follows (via [userProvider] → [localeProvider]) — so the door
/// itself speaks the tongue the person will live in. Completion finalizes the
/// row and opens the Bible.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// Persists the dialect the moment it is tapped. If the user row already
  /// exists (created by [userProvider] during the splash) it is updated and
  /// [userProvider] is invalidated so the app locale follows immediately.
  Future<void> _setLanguage(bool isAm) async {
    final lang = isAm ? 'am' : 'en';
    final db = ref.read(databaseProvider);
    final users = await db.select(db.users).get();
    if (users.isNotEmpty && users.first.lang == lang) return;
    if (users.isNotEmpty) {
      await db.update(db.users).replace(users.first.copyWith(lang: lang));
    } else {
      await db.into(db.users).insert(UsersCompanion.insert(
        createdAt: DateTime.now().toIso8601String(),
        lang: Value(lang),
      ));
    }
    if (!mounted) return;
    ref.invalidate(userProvider);
  }

  Future<void> _complete() async {
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode == 'am' ? 'am' : 'en';
    final db = ref.read(databaseProvider);
    final users = await db.select(db.users).get();
    final now = DateTime.now().toIso8601String();
    if (users.isNotEmpty) {
      await db.update(db.users).replace(users.first.copyWith(
        // The name stays empty until the user intentionally fills it in
        // Profile (the app never assigns a label or a default name).
        name: '',
        lang: lang,
        onboarded: true,
      ));
    } else {
      await db.into(db.users).insert(UsersCompanion.insert(
        createdAt: now,
        name: const Value(''),
        lang: Value(lang),
        onboarded: Value(true),
      ));
    }
    if (!mounted) return;
    ref.invalidate(userProvider);
    // READ first: the first action in Beslet is opening Scripture. Home (the
    // READ → PRAY → PLAN surface) is one tab away.
    context.go('/bible');
  }

  @override
  Widget build(BuildContext context) {
    return EpigraphDoor(onLanguage: _setLanguage, onOpen: _complete);
  }
}