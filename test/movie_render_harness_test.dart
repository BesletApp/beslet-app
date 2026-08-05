import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beslet_app/core/services/growth_content.dart' as lib_growth;
import 'package:beslet_app/core/services/widget_service.dart' as lib_widget;
import 'package:beslet_app/features/growth/widgets/movie_backdrop_painter.dart' as lib_bp;
import 'package:beslet_app/features/growth/widgets/movie_vine_painter.dart' as lib_vp;
import 'package:beslet_app/features/growth/widgets/vine_painter.dart' as lib_vp2;

void main() {
  const dir = 'C:/Users/pc/AppData/Local/Temp/opencode/vine_preview';
  Directory(dir).createSync(recursive: true);

  test('render movie-style previews', () async {
    Future<void> save(
      String name,
      Size size,
      DateTime dt,
      double growth,
      double hydration, {
      int? mood,
      bool dark = false,
    }) async {
      final light = lib_widget.WidgetService.lightStateFor(dt);
      final atmosphere = lib_growth.GrowthContent.atmosphereFor(mood, light);
      final palette = dark ? lib_vp2.VinePalette.dark : lib_vp2.VinePalette.light;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      lib_bp.MovieBackdropPainter(
        skyTop: atmosphere.skyTop,
        skyBottom: atmosphere.skyBottom,
        light: light,
        isDark: dark,
        soil: palette.soil,
        seed: 1234,
      ).paint(canvas, size);
      final leafGlow = hydration;
      final branchOpen = hydration;
      final ripen = hydration;
      final dew = switch (light) {
        lib_widget.LampLight.dawn => 0.9,
        lib_widget.LampLight.dusk => 0.5,
        lib_widget.LampLight.noon => 0.15,
        lib_widget.LampLight.night => 0.0,
      };
      final fruitColor = Color.lerp(
          const Color(0xFF7FB36A), const Color(0xFFE8C53A), growth)!;
      lib_vp.MovieVinePainter(
        seed: 1234,
        growth01: growth,
        branches: (2 + (growth * 6).round()).clamp(2, 8),
        fruitCount: growth < 0.2 ? 1 : (growth < 0.45 ? 2 : (growth < 0.7 ? 3 : 5)),
        fruitColor: fruitColor,
        palette: palette,
        sway: 1.0,
        showBlossoms: growth > 0.4,
        hydration: hydration,
        leafGlow: leafGlow,
        branchOpen: branchOpen,
        ripen: ripen,
        droop: mood != null && mood <= 2 ? 0.4 : 0.0,
        blossomOpen: mood != null && mood >= 4 ? 1.0 : 0.7,
        bend: 0,
        lifeT: 3.2,
        flutterAmt: 1,
        dew: dew,
        wilt: (0.65 - (hydration + leafGlow)).clamp(0.0, 1.0),
        fullness: 1,
      ).paint(canvas, size);
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.round(), size.height.round());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      debugPrint('wrote $dir/$name.png');
    }

    const big = Size(360, 440);
    const small = Size(360, 280);
    await save('dawn_seed', big, DateTime(2026, 8, 6, 6, 0), 0.05, 0.5);
    await save('noon_full', big, DateTime(2026, 8, 6, 13, 0), 1.0, 1.0);
    await save('dusk_mid', big, DateTime(2026, 8, 6, 18, 0), 0.5, 0.7);
    await save('night_neglected', big, DateTime(2026, 8, 6, 22, 0), 1.0, 0.3,
        dark: true);
    await save('noon_full_small', small, DateTime(2026, 8, 6, 13, 0), 1.0, 1.0);
  });
}
