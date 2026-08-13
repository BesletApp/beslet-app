import 'dart:convert';
import 'dart:io';

import 'package:beslet_app/core/services/bundled_bible_reader.dart';
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:beslet_app/features/onboarding/epigraph_door.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guard rail: the Epigraph (the permanent doorway) must resolve John 15:5 —
/// the vine saying — to EXACTLY the text of the bundled Bible, in both
/// languages, and the chips/CTA must report the dialact choice. If the bundle
/// drifts or the door stops resolving offline, this fails.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repoRoot = Directory.current.path;
  late Map<String, dynamic> en;
  late Map<String, dynamic> am;

  setUpAll(() {
    en = _loadBundle('$repoRoot/assets/data/bible_en.gzip');
    am = _loadBundle('$repoRoot/assets/data/bible_am.gzip');
    BundledBibleReader.instance.assetBytesLoader = (asset) async {
      final path = asset == 'assets/data/bible_am.gzip'
          ? '$repoRoot/assets/data/bible_am.gzip'
          : '$repoRoot/assets/data/bible_en.gzip';
      return File(path).readAsBytes();
    };
  });

  String _bundleText(Map<String, dynamic> bundle, String reference) {
    final range = ScriptureService.referenceRange(reference)!;
    return (bundle['${range.bookId}_${range.chapter}'] as List)
        .where((v) => range.verses.contains((v as Map)['verse']))
        .map((v) => ((v as Map)['text'] as String).trim())
        .join(' ');
  }

  Widget _wrap({required bool am, ValueChanged<bool>? onLanguage, VoidCallback? onOpen}) {
    return MaterialApp(
      locale: Locale(am ? 'am' : 'en'),
      supportedLocales: const [Locale('en'), Locale('am')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: EpigraphDoor(
        onLanguage: onLanguage ?? (_) {},
        onOpen: onOpen ?? () {},
      ),
    );
  }

  testWidgets('the epigraph resolves John 15:5 from the bundle, in each language',
      (tester) async {
    final expectedEn = _bundleText(en, 'John 15:5');
    final expectedAm = _bundleText(am, 'John 15:5');
    expect(expectedEn, isNotEmpty);
    expect(expectedAm, isNotEmpty);

        // Build and let the bundle decode inside runAsync so the whole I/O chain
    // lives in the real-async zone (widget-test fake timers don't drive File I/O).
    await tester.runAsync(() async {
      await tester.pumpWidget(_wrap(am: false));
      await Future<void>.delayed(const Duration(seconds: 4));
    });
    await tester.pump();
    expect(find.text('John 15:5'), findsOneWidget, reason: 'English reference label');
    expect(find.text(expectedEn), findsOneWidget, reason: 'English verse renders');

    await tester.runAsync(() async {
      await tester.pumpWidget(_wrap(am: true));
      await Future<void>.delayed(const Duration(seconds: 4));
    });
    await tester.pump();
    expect(find.text('ዮሐንስ 15:5'), findsOneWidget, reason: 'Amharic reference label');
    expect(find.text(expectedAm), findsOneWidget, reason: 'Amharic verse renders');
  });

  testWidgets('chips report the dialect and the CTA opens the door',
      (tester) async {
    final langs = <bool>[];
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('am')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: EpigraphDoor(onLanguage: langs.add, onOpen: () => opened = true),
    ));

    await tester.tap(find.text('አማርኛ'));
    await tester.pumpAndSettle();
    expect(langs, [true], reason: 'Amharic chip reports cried=true');

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(langs, [true, false], reason: 'English chip reports isAm=false');

    await tester.tap(find.text('OPEN THE WORD'));
    await tester.pumpAndSettle();
    expect(opened, isTrue, reason: 'CTA opens the doorway');
  });
}

Map<String, dynamic> _loadBundle(String path) {
  final bytes = gzip.decode(File(path).readAsBytesSync());
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}