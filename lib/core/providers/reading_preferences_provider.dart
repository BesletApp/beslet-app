import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fontSizeKey = 'reading_font_size';
const _lineSpacingKey = 'reading_line_spacing';
const _lastOpenPageKey = 'last_open_page';

final fontSizeProvider = StateProvider<double>((ref) => 15.0);

final lineSpacingProvider = StateProvider<double>((ref) => 1.6);

class HighlightedVerse {
  final String bookId;
  final int chapter;
  final int verse;
  final String text;
  final bool isAm;
  final String colorId;

  const HighlightedVerse({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.isAm,
    this.colorId = 'yellow',
  });

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'chapter': chapter,
    'verse': verse,
    'text': text,
    'isAm': isAm,
    'colorId': colorId,
  };

  factory HighlightedVerse.fromJson(Map<String, dynamic> j) => HighlightedVerse(
    bookId: j['bookId'] as String,
    chapter: j['chapter'] as int,
    verse: j['verse'] as int,
    text: j['text'] as String,
    isAm: j['isAm'] as bool,
    colorId: (j['colorId'] as String?) ?? 'yellow',
  );
}

const List<({String id, Color color})> highlightColors = [
  (id: 'yellow', color: Color(0xFFFFC107)),
  (id: 'green', color: Color(0xFF4CAF50)),
  (id: 'blue', color: Color(0xFF42A5F5)),
  (id: 'orange', color: Color(0xFFFF9800)),
  (id: 'pink', color: Color(0xFFEC407A)),
  (id: 'purple', color: Color(0xFFAB47BC)),
];

Color highlightColorFor(String id) {
  for (final h in highlightColors) {
    if (h.id == id) return h.color;
  }
  return highlightColors.first.color;
}

const _highlightsKey = 'all_highlights';
const _legacyKeptKey = 'all_kept_verses';

final highlightsProvider = StateProvider<List<HighlightedVerse>>((ref) => []);

class ReadingPreferences {
  static Future<void> loadFontSize(Ref ref) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_fontSizeKey) ?? 15.0;
    ref.read(fontSizeProvider.notifier).state = saved;
    final spacing = prefs.getDouble(_lineSpacingKey) ?? 1.6;
    ref.read(lineSpacingProvider.notifier).state = spacing;
  }

  static Future<void> saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  static Future<void> saveLineSpacing(double spacing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lineSpacingKey, spacing);
  }

  static Future<void> saveOpenPage(String bookId, int chapter, String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenPageKey, jsonEncode({
      'bookId': bookId,
      'chapter': chapter,
      'language': language,
    }));
  }

  static Future<({String? bookId, int? chapter, String? language})> loadOpenPage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastOpenPageKey);
    if (raw == null) return (bookId: null, chapter: null, language: null);
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (
        bookId: j['bookId'] as String?,
        chapter: j['chapter'] as int?,
        language: j['language'] as String?,
      );
    } catch (_) {
      return (bookId: null, chapter: null, language: null);
    }
  }

  static Future<void> saveJournalText(String verseId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('journal_$verseId', text);
  }

  static Future<String?> loadJournalText(String verseId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('journal_$verseId');
  }

  static Future<List<HighlightedVerse>> loadAllHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    final j = prefs.getString(_highlightsKey);
    if (j != null) {
      try {
        final list = jsonDecode(j) as List;
        return list
            .map((e) => HighlightedVerse.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
    final legacy = prefs.getString(_legacyKeptKey);
    if (legacy != null) {
      try {
        final list = jsonDecode(legacy) as List;
        final migrated = <HighlightedVerse>[];
        for (final e in list) {
          final m = e as Map<String, dynamic>;
          migrated.add(HighlightedVerse(
            bookId: m['bookId'] as String,
            chapter: m['chapter'] as int,
            verse: m['verse'] as int,
            text: m['text'] as String,
            isAm: m['isAm'] as bool,
            colorId: 'yellow',
          ));
        }
        if (migrated.isNotEmpty) {
          await prefs.setString(
              _highlightsKey, jsonEncode(migrated.map((e) => e.toJson()).toList()));
        }
        return migrated;
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  static Future<void> saveAllHighlights(List<HighlightedVerse> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_highlightsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
