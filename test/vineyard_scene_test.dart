import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:beslet_app/core/services/scene_event_bus.dart';
import 'package:beslet_app/features/growth/widgets/vine_painter.dart';
import 'package:beslet_app/features/growth/widgets/vineyard_scene.dart';

void main() {
  const size = Size(360, 300);

  group('buildVine', () {
    test('is deterministic for the same seed and inputs', () {
      final a = buildVine(seed: 42, growth01: 0.8, branches: 8, size: size);
      final b = buildVine(seed: 42, growth01: 0.8, branches: 8, size: size);
      expect(a.tips, b.tips);
      expect(a.segments.length, b.segments.length);
    });

    test('different seeds produce different vines', () {
      final a = buildVine(seed: 1, growth01: 0.8, branches: 8, size: size);
      final b = buildVine(seed: 2, growth01: 0.8, branches: 8, size: size);
      expect(a.tips, isNot(equals(b.tips)));
    });

    test('a planted journey (branches > 0) has 2^depth tips', () {
      for (final branches in [2, 4, 8]) {
        final g = buildVine(seed: 7, growth01: 0.5, branches: branches, size: size);
        expect(g.tips.length, branches);
      }
    });

    test('a seed (branches 0) has only the trunk, no branches', () {
      final g = buildVine(seed: 7, growth01: 0.0, branches: 0, size: size);
      expect(g.tips.length, 1);
      expect(g.segments.length, 1);
    });

    test('sway does not change structure, only tip positions', () {
      final still = buildVine(seed: 5, growth01: 0.7, branches: 4, size: size);
      final moving = buildVine(seed: 5, growth01: 0.7, branches: 4, size: size, sway: 0.5);
      expect(moving.segments.length, still.segments.length);
      expect(moving.tips.length, still.tips.length);
    });

    test('segments stay within the canvas', () {
      final g = buildVine(seed: 3, growth01: 1.0, branches: 8, size: size);
      for (final s in g.segments) {
        expect(s.to.dy, greaterThanOrEqualTo(-24));
        expect(s.to.dy, lessThanOrEqualTo(size.height));
        expect(s.to.dx, greaterThanOrEqualTo(0));
        expect(s.to.dx, lessThanOrEqualTo(size.width));
      }
    });
  });

  group('VineyardScene', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: VineyardScene(
                seed: 42,
                growth01: 0.5,
                branches: 4,
                fruitCount: 2,
                fruitColor: Color(0xFFE8C53A),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(VineyardScene), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(VineyardScene), findsOneWidget);
    });

    testWidgets('renders in the dark and reduced-motion modes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          theme: ThemeData(brightness: Brightness.dark),
          home: const Scaffold(
            body: VineyardScene(
              seed: 9,
              growth01: 1,
              branches: 8,
              fruitCount: 3,
              fruitColor: Color(0xFFE8C53A),
              mood: 1,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('animates the vine then settles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VineyardScene(
              seed: 11,
              growth01: 0.9,
              branches: 8,
              fruitCount: 3,
              fruitColor: Color(0xFFE8C53A),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts vitality values with the default eventSource', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VineyardScene(
              seed: 5,
              growth01: 0.7,
              branches: 6,
              fruitCount: 3,
              fruitColor: Color(0xFFE8C53A),
              hydration: 0.35,
              leafGlow: 0.9,
              branchOpen: 1,
              ripen: 0.5,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('plays a burst when the eventSource emits', (tester) async {
      final bus = SceneEventBus();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VineyardScene(
              seed: 5,
              growth01: 0.7,
              branches: 6,
              fruitCount: 3,
              fruitColor: const Color(0xFFE8C53A),
              eventSource: bus,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      bus.emit(SceneEventType.water);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      expect(tester.takeException(), isNull);
      bus.dispose();
    });
  });
}
