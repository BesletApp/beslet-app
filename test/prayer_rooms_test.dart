import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/database_provider.dart';
import 'package:beslet_app/core/providers/prayer_rooms_provider.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

bool _canOpenSqlite() {
  try {
    sqlite3.sqlite3.openInMemory();
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  group('schema', () {
    test('schema version is 25 (prayer rooms migration applied)', () {
      final db = AppDatabase.forTesting(LazyDatabase(() async {
        throw StateError('should not open');
      }));
      expect(db.schemaVersion, 25);
    });
  });

  group('prayer rooms (requires native sqlite3)', () {
    AppDatabase? db;
    late bool available;

    setUp(() {
      available = _canOpenSqlite();
      db = available ? AppDatabase.forTesting(NativeDatabase.memory()) : null;
    });

    tearDown(() async {
      await db?.close();
    });

    ProviderContainer container() {
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('first sight seeds the three classic rooms, then stays calm', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();

      final first = await c.read(prayerRoomsProvider.future);
      expect(first.map((r) => r.name), ['Thank', 'Ask', 'Rest']);
      expect(first.every((r) => r.lastEnteredAt == null), isTrue,
          reason: 'a brand-new room has not been entered yet');

      final again = await c.read(prayerRoomsProvider.future);
      expect(again.length, 3, reason: 'seeding must be idempotent');
    });

    test('addRoom appends at the end and persists', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      await c.read(prayerRoomsProvider.future); // seed

      final notifier = c.read(prayerRoomNotifierProvider.notifier);
      await notifier.addRoom('For my brother', PrayerRoomGroup.intercession);

      final rooms = await c.read(prayerRoomsProvider.future);
      expect(rooms.length, 4);
      final added = rooms.last;
      expect(added.name, 'For my brother');
      expect(added.group, PrayerRoomGroup.intercession);
      expect(added.sortOrder, 3);
    });

    test('rename, move, let-go, and warmth all reflect immediately', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      final seeded = await c.read(prayerRoomsProvider.future);
      final target = seeded.first;
      final notifier = c.read(prayerRoomNotifierProvider.notifier);

      await notifier.renameRoom(target.id, 'Thankfulness');
      await notifier.moveRoom(target.id, PrayerRoomGroup.struggle);

      var rooms = await c.read(prayerRoomsProvider.future);
      var updated = rooms.firstWhere((r) => r.id == target.id);
      expect(updated.name, 'Thankfulness');
      expect(updated.group, PrayerRoomGroup.struggle);
      expect(updated.lastEnteredAt, isNull);

      await notifier.touchRoom(target.id);
      rooms = await c.read(prayerRoomsProvider.future);
      updated = rooms.firstWhere((r) => r.id == target.id);
      expect(updated.lastEnteredAt, isNotNull,
          reason: 'entering a room leaves a warmth signal');

      await notifier.deleteRoom(target.id);
      rooms = await c.read(prayerRoomsProvider.future);
      expect(rooms.any((r) => r.id == target.id), isFalse,
          reason: 'letting a room go removes it');
    });

    test('a blank name never creates a room', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      await c.read(prayerRoomsProvider.future);
      final before = (await c.read(prayerRoomsProvider.future)).length;

      await c.read(prayerRoomNotifierProvider.notifier).addRoom('   ', PrayerRoomGroup.personal);

      final after = (await c.read(prayerRoomsProvider.future)).length;
      expect(after, before, reason: 'whitespace-only names are left unchanged');
    });
  });
}