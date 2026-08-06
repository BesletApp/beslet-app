import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

/// The user's stored identity — one row, never derived from behavior.
/// Name, language, avatar color, and the one Word they carry.
class Identity {
  final String name;
  final String language;
  final String avatarColor;
  final String? keptWord;
  final String? keptWordRef;
  final DateTime joinedAt;

  const Identity({
    required this.name,
    required this.language,
    required this.avatarColor,
    this.keptWord,
    this.keptWordRef,
    required this.joinedAt,
  });

  factory Identity.fromUser(User user) {
    return Identity(
      name: user.name,
      language: user.lang,
      avatarColor: user.avatarColor,
      keptWord: user.keptWord,
      keptWordRef: user.keptWordRef,
      joinedAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }
}

final identityProvider = FutureProvider<Identity>((ref) async {
  final db = ref.watch(databaseProvider);
  final users = await db.select(db.users).get();
  if (users.isEmpty) {
    final now = DateTime.now().toIso8601String();
    await db.into(db.users).insert(
      UsersCompanion.insert(createdAt: now),
      mode: InsertMode.insertOrReplace,
    );
    return Identity.fromUser((await db.select(db.users).get()).first);
  }
  return Identity.fromUser(users.first);
});

class IdentityNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateName(String name) async {
    final db = ref.read(databaseProvider);
    final user = await _single(db);
    await db.update(db.users).replace(user.copyWith(name: name));
    ref.invalidate(identityProvider);
  }

  Future<void> setAvatarColor(String color) async {
    final db = ref.read(databaseProvider);
    final user = await _single(db);
    await db.update(db.users).replace(user.copyWith(avatarColor: color));
    ref.invalidate(identityProvider);
  }

  Future<void> setKeptWord({String? text, String? reference}) async {
    final db = ref.read(databaseProvider);
    final user = await _single(db);
    await db.update(db.users).replace(
      user.copyWith(keptWord: Value(text), keptWordRef: Value(reference)),
    );
    ref.invalidate(identityProvider);
  }

  Future<User> _single(AppDatabase db) async {
    final users = await db.select(db.users).get();
    if (users.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.into(db.users).insert(
        UsersCompanion.insert(createdAt: now),
        mode: InsertMode.insertOrReplace,
      );
      return (await db.select(db.users).get()).first;
    }
    return users.first;
  }
}

final identityNotifierProvider =
    AsyncNotifierProvider<IdentityNotifier, void>(IdentityNotifier.new);
