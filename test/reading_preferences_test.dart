import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beslet_app/core/providers/reading_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('highlightColorFor', () {
    test('returns the matching color for a known id', () {
      expect(highlightColorFor('yellow'), const Color(0xFFFFC107));
      expect(highlightColorFor('purple'), const Color(0xFFAB47BC));
    });

    test('falls back to the first color for unknown ids', () {
      expect(highlightColorFor('bogus'), const Color(0xFFFFC107));
      expect(highlightColorFor(''), const Color(0xFFFFC107));
    });
  });

  group('loadAllHighlights migration', () {
    test('converts legacy kept verses into yellow highlights', () async {
      SharedPreferences.setMockInitialValues({
        'all_kept_verses': jsonEncode([
          {
            'bookId': 'philippians',
            'chapter': 4,
            'verse': 13,
            'text': 'I can do all things.',
            'isAm': false,
          },
        ]),
      });

      final highlights = await ReadingPreferences.loadAllHighlights();
      expect(highlights, hasLength(1));
      expect(highlights.first.colorId, 'yellow');
      expect(highlights.first.bookId, 'philippians');
      expect(highlights.first.verse, 13);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('all_highlights'), isNotNull);
    });

    test('returns empty when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final highlights = await ReadingPreferences.loadAllHighlights();
      expect(highlights, isEmpty);
    });
  });
}
