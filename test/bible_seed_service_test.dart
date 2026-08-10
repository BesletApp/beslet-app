import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:beslet_app/core/services/bible_seed_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ByteData gzipBundle(Map<String, List<Map<String, dynamic>>> chapters) {
    final bytes = gzip.encode(utf8.encode(jsonEncode(chapters)));
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  test('seedIfNeeded writes the bundled chapters into the text cache',
      () async {
    final tmp = await Directory.systemTemp.createTemp('bible_seed_test');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final bundles = <String, ByteData>{
      BibleSeedService.enAsset: gzipBundle({
        'genesis_1': [
          {'verse': 1, 'text': 'In the beginning, God created the heavens and the earth.'},
        ],
        'john_3': [
          {'verse': 16, 'text': 'For God so loved the world...'},
        ],
      }),
      BibleSeedService.amAsset: gzipBundle({
        'genesis_1': [
          {'verse': 1, 'text': 'በመጀመሪያ እግዚአብሔር ሰማይንና ምድርን ፈጠረ።'},
        ],
      }),
    };

    await BibleSeedService.seedIfNeeded(
      assetLoader: (asset) async => bundles[asset]!,
      cacheDirProvider: () async => tmp,
    );

    expect(File('${tmp.path}/genesis_1.json').existsSync(), isTrue);
    expect(File('${tmp.path}/genesis_1_am.json').existsSync(), isTrue);
    expect(File('${tmp.path}/john_3.json').existsSync(), isTrue);

    final en = jsonDecode(
            File('${tmp.path}/genesis_1.json').readAsStringSync()) as List;
    expect(en, hasLength(1));
    expect(en.first['verse'], 1);
    expect(en.first['text'], contains('In the beginning'));

    final am = jsonDecode(
            File('${tmp.path}/genesis_1_am.json').readAsStringSync()) as List;
    expect(am.first['text'], contains('ፈጠረ'));
    expect(await BibleSeedService.isSeeded(), isTrue);
  });

  test('seedIfNeeded is idempotent and never clobbers an existing cache file',
      () async {
    final tmp = await Directory.systemTemp.createTemp('bible_seed_test2');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final bundles = <String, ByteData>{
      BibleSeedService.enAsset: gzipBundle({
        'genesis_1': [
          {'verse': 1, 'text': 'BUNDLE VERSION'},
        ],
      }),
      BibleSeedService.amAsset: gzipBundle({}),
    };
    final cacheDir = Directory('${tmp.path}/bible_text_cache');
    cacheDir.createSync(recursive: true);
    File('${cacheDir.path}/genesis_1.json')
        .writeAsStringSync(jsonEncode([
      {'verse': 1, 'text': 'USER CACHE VERSION'},
    ]));

    await BibleSeedService.seedIfNeeded(
      assetLoader: (asset) async => bundles[asset]!,
      cacheDirProvider: () async => cacheDir,
    );

    final kept = jsonDecode(
        File('${cacheDir.path}/genesis_1.json').readAsStringSync()) as List;
    expect(kept.first['text'], 'USER CACHE VERSION');

    await BibleSeedService.seedIfNeeded(
      assetLoader: (asset) async => bundles[asset]!,
      cacheDirProvider: () async => cacheDir,
    );
    expect(
      File('${cacheDir.path}/genesis_1.json').readAsStringSync(),
      contains('USER CACHE VERSION'),
    );
  });

  test('isSeeded stays false when seeding throws mid-way', () async {
    final tmp = await Directory.systemTemp.createTemp('bible_seed_test3');
    addTearDown(() => tmp.deleteSync(recursive: true));

    await BibleSeedService.seedIfNeeded(
      assetLoader: (_) async => throw Exception('asset missing'),
      cacheDirProvider: () async => tmp,
    );
    expect(await BibleSeedService.isSeeded(), isFalse);
  });
}
