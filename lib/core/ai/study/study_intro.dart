import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'book_meta.dart';

/// The deterministic knowledge layer for every book of the canon: a genre in
/// the sense the Study panel uses it, and a bilingual (EN+AM) portrait of
/// background, flow, and key themes. Authored once, bundled, and validated at
/// load time so a book the reader can actually open always has context —
/// even fully offline and long before any AI call.
///
/// No entry invents certainty: each portrait is written for what the text
/// itself states and the consensus of broader scholarship, and carries no
/// second-person "you" that tells the reader what God is doing in their life.

/// The broad literary category of a book, used by the panel for genre-aware
/// reading prompts ("In the Text & Genre").
enum StudyGenre {
  narrative,
  law,
  history,
  poetry,
  wisdom,
  prophecy,
  apocalyptic,
  gospel,
  epistle;

  /// Parses a genre id from the asset; null for an unknown id (fail closed).
  static StudyGenre? tryParse(String? value) {
    for (final genre in StudyGenre.values) {
      if (genre.name == value) return genre;
    }
    return null;
  }
}

/// One book's curated portrait, in both languages the app ships.
class StudyBookIntro {
  final String id;

  /// null when the asset carried an unknown genre id — the library must never
  /// ship one (validate() flags it), and callers should never see null.
  final StudyGenre? genre;
  final String backgroundEn;
  final String backgroundAm;
  final String flowEn;
  final String flowAm;
  final String keyThemesEn;
  final String keyThemesAm;

  const StudyBookIntro({
    required this.id,
    required this.genre,
    required this.backgroundEn,
    required this.backgroundAm,
    required this.flowEn,
    required this.flowAm,
    required this.keyThemesEn,
    required this.keyThemesAm,
  });

  String backgroundFor(bool isAm) => isAm ? backgroundAm : backgroundEn;
  String flowFor(bool isAm) => isAm ? flowAm : flowEn;
  String keyThemesFor(bool isAm) => isAm ? keyThemesAm : keyThemesEn;
}

/// The immutable, bundled book-intro library. Loaded once and shared; mirrors
/// the deterministic canon pattern (`StudyCanon`) so the app fails closed
/// rather than serving a passage without context because an intro was missing.
class StudyIntroLibrary {
  static const int expectedVersion = 1;

  final int version;
  final Map<String, StudyBookIntro> intros;

  const StudyIntroLibrary({required this.version, required this.intros});

  /// Loads the bundled library. Throws if the asset is missing, malformed, or
  /// carries an unexpected version.
  static Future<StudyIntroLibrary> load() async {
    final raw = await rootBundle.loadString('assets/data/study_intros.json');
    return StudyIntroLibrary.fromJsonString(raw);
  }

  static StudyIntroLibrary fromJsonString(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['version'] != expectedVersion) {
      throw FormatException('unexpected study_intros version');
    }
    final intros = <String, StudyBookIntro>{};
    for (final rawBook in data['books'] as List<dynamic>) {
      final b = rawBook as Map<String, dynamic>;
      final id = b['id'] as String;
      final genre = StudyGenre.tryParse(b['genre'] as String?);
      final background = (b['background'] as Map<String, dynamic>?) ?? const {};
      final flow = (b['flow'] as Map<String, dynamic>?) ?? const {};
      final themes = (b['keyThemes'] as Map<String, dynamic>?) ?? const {};
      intros[id] = StudyBookIntro(
        id: id,
        genre: genre,
        backgroundEn: (background['en'] as String?) ?? '',
        backgroundAm: (background['am'] as String?) ?? '',
        flowEn: (flow['en'] as String?) ?? '',
        flowAm: (flow['am'] as String?) ?? '',
        keyThemesEn: (themes['en'] as String?) ?? '',
        keyThemesAm: (themes['am'] as String?) ?? '',
      );
    }
    return StudyIntroLibrary(version: data['version'] as int, intros: intros);
  }

  StudyBookIntro? introFor(String bookId) => intros[bookId];

  /// Returns a list of content problems (empty when the library is clean).
  /// Called at load and asserted in tests so a bad edit cannot ship.
  ///
  /// When [canon] is provided, every book the canon knows must have an intro
  /// and every intro must address a book the canon knows — the app fails
  /// closed rather than letting any passage open without its context layer.
  List<String> validate({StudyCanon? canon}) {
    final issues = <String>[];
    if (version != expectedVersion) {
      issues.add('intro library version must be $expectedVersion, found $version');
    }
    if (intros.isEmpty) {
      issues.add('intro library must contain at least one book');
    }
    for (final intro in intros.values) {
      final id = intro.id;
      if (intro.genre == null) {
        issues.add('intro $id: unknown genre id in the shipped asset');
      }
      if (intro.backgroundEn.trim().isEmpty ||
          intro.backgroundAm.trim().isEmpty) {
        issues.add('intro $id: background needs both languages');
      }
      if (intro.flowEn.trim().isEmpty || intro.flowAm.trim().isEmpty) {
        issues.add('intro $id: flow needs both languages');
      }
      if (intro.keyThemesEn.trim().isEmpty ||
          intro.keyThemesAm.trim().isEmpty) {
        issues.add('intro $id: keyThemes needs both languages');
      }
      if (!_hasGeEz(intro.backgroundAm) ||
          !_hasGeEz(intro.flowAm) ||
          !_hasGeEz(intro.keyThemesAm)) {
        issues.add('intro $id: Amharic fields must actually be Amharic');
      }
      if (_hasGeEz(intro.backgroundEn) ||
          _hasGeEz(intro.flowEn) ||
          _hasGeEz(intro.keyThemesEn)) {
        issues.add('intro $id: English fields must actually be English');
      }
      if (_hasBannedPhrase(intro.backgroundEn) ||
          _hasBannedPhrase(intro.flowEn) ||
          _hasBannedPhrase(intro.keyThemesEn)) {
        issues.add('intro $id: banned English framing');
      }
      if (_hasBannedPhrase(intro.backgroundAm) ||
          _hasBannedPhrase(intro.flowAm) ||
          _hasBannedPhrase(intro.keyThemesAm)) {
        issues.add('intro $id: banned Amharic framing');
      }
    }
    if (canon != null) {
      for (final bookId in canon.books.keys) {
        if (!intros.containsKey(bookId)) {
          issues.add('intro library missing ${canon.books[bookId]!.nameEn} ($bookId)');
        }
      }
      for (final id in intros.keys) {
        if (!canon.books.containsKey(id)) {
          issues.add('intro $id is not a book of the canon');
        }
      }
    }
    return issues;
  }

  static bool _hasBannedPhrase(String text) {
    final lower = text.toLowerCase();
    const phrases = [
      'i am speaking to you',
      'god is speaking to you',
      'god wants you to',
      'god is telling you',
      'god told you',
      'god will speak to you',
      'you should',
      'you need to',
      'you must',
      'pray this prayer',
      'come back to',
    ];
    for (final p in phrases) {
      if (lower.contains(p)) return true;
    }
    return false;
  }

  /// True when the string contains Ethiopic (Ge'ez) script characters.
  static bool _hasGeEz(String text) {
    for (final rune in text.runes) {
      if ((rune >= 0x1200 && rune <= 0x137F) ||
          (rune >= 0x2D80 && rune <= 0x2DDF) ||
          (rune >= 0xAB00 && rune <= 0xAB2F)) {
        return true;
      }
    }
    return false;
  }
}