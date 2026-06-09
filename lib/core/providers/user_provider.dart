import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final userProvider = FutureProvider<User>((ref) async {
  final db = ref.watch(databaseProvider);
  final users = await db.select(db.users).get();
  if (users.isNotEmpty) return users.first;
  final now = DateTime.now().toIso8601String();
  await db.into(db.users).insert(UsersCompanion.insert(createdAt: now), mode: InsertMode.insertOrReplace);
  return (await db.select(db.users).get()).first;
});

final isOnboardedProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(userProvider.future);
  return user.onboarded;
});
