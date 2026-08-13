import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'book_meta.dart';
import 'study_models.dart';

/// The deterministic offline cross-reference index.
///
/// The app always ships with Scripture itself and a curated bank of study
/// notes, but a reader who is offline should still be able to "hear one
/// passage beside another" — so the index is authored, bundled, and loaded
/// exactly like the intro library. Every connection is a pair of canonical
/// passages plus a short bilingual reason stating the shared truth that links
/// them. The same reason serves both directions, so a studied passage can find
/// the passages that speak into it, and those passages can find it back.
///
/// No entry invents certainty: reasons state what the texts themselves show,
/// and carry no second-person "you" that tells the reader what God is doing in
/// their life (the validator rejects such framing).
class StudyCrossRefIndex {
  static const int expectedVersion = 1;

  final int version;
  final List<StudyCrossRefConnection> connections;

  const StudyCrossRefIndex({
    required this.version,
    required this.connections,
  });

  /// Loads the bundled index. Throws if the asset is missing, malformed, or
  /// carries an unexpected version.
  static Future<StudyCrossRefIndex> load() async {
    final raw = await rootBundle.loadString('assets/data/cross_references.json');
    return StudyCrossRefIndex.fromJsonString(raw);
  }

  static StudyCrossRefIndex fromJsonString(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['version'] != expectedVersion) {
      throw FormatException('unexpected cross_references version');
    }
    final connections = <StudyCrossRefConnection>[];
    for (final rawConn in data['connections'] as List<dynamic>) {
      final c = rawConn as Map<String, dynamic>;
      connections.add(StudyCrossRefConnection(
        a: _tryParseEndpoint(c['a']),
        b: _tryParseEndpoint(c['b']),
        en: c['en'] is String ? c['en'] as String : '',
        am: c['am'] is String ? c['am'] as String : '',
        priority: c['priority'] is int ? c['priority'] as int : 0,
      ));
    }
    return StudyCrossRefIndex(
      version: data['version'] as int,
      connections: connections,
    );
  }

  /// Returns every curated cross-reference for a studied passage, ordered by
  /// priority (core links first). The two sides of a connection are
  /// interchangeable: the studied passage may be either end, and the returned
  /// reference is always the *other* passage.
  List<StudyCrossReference> crossReferencesFor(
    String bookId,
    int chapter,
    int startVerse,
  ) {
    final results = <StudyCrossReference>[];
    for (final conn in connections) {
      final a = conn.a;
      final b = conn.b;
      StudyCrossReference? hit;
      if (a != null &&
          a.bookId == bookId &&
          a.chapter == chapter &&
          a.startVerse == startVerse) {
        hit = b != null ? _asCrossReference(b, conn) : null;
      } else if (b != null &&
          b.bookId == bookId &&
          b.chapter == chapter &&
          b.startVerse == startVerse) {
        hit = a != null ? _asCrossReference(a, conn) : null;
      }
      if (hit != null) results.add(hit);
    }
    results.sort((x, y) => x.priority.compareTo(y.priority));
    return results;
  }

  /// Returns a list of content problems (empty when the index is clean).
  /// Called at load and asserted in tests so a bad edit cannot ship.
  ///
  /// When [canon] is provided, every passage on either side of a connection
  /// must be openable in the reader's Bible in *both* languages the app ships
  /// — a cross-reference the reader cannot open is never shown.
  List<String> validate({StudyCanon? canon}) {
    final issues = <String>[];
    if (version != expectedVersion) {
      issues.add('cross-reference version must be $expectedVersion, found $version');
    }
    if (connections.isEmpty) {
      issues.add('cross-reference index must contain at least one connection');
    }
    for (final conn in connections) {
      final a = conn.a;
      final b = conn.b;
      if (a == null || b == null) {
        issues.add('connection with a null endpoint (a=${a == null ? 'missing' : 'ok'}, '
            'b=${b == null ? 'missing' : 'ok'})');
        continue;
      }
      if (a.bookId == b.bookId &&
          a.chapter == b.chapter &&
          a.startVerse == b.startVerse &&
          a.endVerse == b.endVerse) {
        issues.add(
            'connection from ${a.bookId} $a.chapter:$a.startVerse to itself adds nothing');
        continue;
      }
      if (conn.en.trim().isEmpty || conn.am.trim().isEmpty) {
        issues.add(
            'connection ${_label(a)} <-> ${_label(b)} needs reasons in both languages');
      }
      if (!_hasGeEz(conn.am)) {
        issues.add('connection ${_label(a)} <-> ${_label(b)}: Amharic reason not Amharic');
      }
      if (_hasGeEz(conn.en)) {
        issues.add('connection ${_label(a)} <-> ${_label(b)}: English reason not English');
      }
      if (_hasBannedPhrase(conn.en)) {
        issues.add(
            'connection ${_label(a)} <-> ${_label(b)}: banned English framing');
      }
      if (_hasBannedPhrase(conn.am)) {
        issues.add(
            'connection ${_label(a)} <-> ${_label(b)}: banned Amharic framing');
      }
      if (conn.priority < 0 || conn.priority > 2) {
        issues.add(
            'connection ${_label(a)} <-> ${_label(b)}: priority must be 0..2, found ${conn.priority}');
      }
      if (canon != null) {
        for (final ref in [a, b]) {
          for (final isAmharic in [false, true]) {
            if (!canon.validReference(
              bookId: ref.bookId,
              chapter: ref.chapter,
              startVerse: ref.startVerse,
              endVerse: ref.endVerse,
              isAmharic: isAmharic,
            )) {
              issues.add(
                  'connection ${_label(a)} <-> ${_label(b)}: '
                  '${_label(ref)} does not exist in the ${isAmharic ? 'Amharic' : 'English'} canon');
            }
          }
        }
      }
    }

    // A connection must be unique in either direction — the same link authored
    // twice (or swapped) is a duplicate.
    final seen = <String>{};
    for (final conn in connections) {
      final a = conn.a;
      final b = conn.b;
      if (a == null || b == null) continue;
      final key = [_label(a), _label(b)]..sort();
      final joined = key.join(' <-> ');
      if (!seen.add(joined)) {
        issues.add('duplicate connection $joined');
      }
    }
    return issues;
  }

  static StudyCrossReference _asCrossReference(
    StudyReference other,
    StudyCrossRefConnection conn,
  ) {
    return StudyCrossReference(
      bookId: other.bookId,
      chapter: other.chapter,
      startVerse: other.startVerse,
      endVerse: other.endVerse,
      en: conn.en,
      am: conn.am,
      priority: conn.priority,
    );
  }

  static StudyReference? _tryParseEndpoint(dynamic raw) {
    if (raw is! Map) return null;
    final bookId = raw['bookId'];
    final chapter = raw['chapter'];
    final startVerse = raw['startVerse'];
    final endVerse = raw['endVerse'];
    if (bookId is! String ||
        bookId.trim().isEmpty ||
        chapter is! int ||
        startVerse is! int ||
        endVerse is! int) {
      return null;
    }
    return StudyReference(
      bookId: bookId,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
    );
  }

  static String _label(StudyReference r) => '${r.bookId} ${r.chapter}:${r.startVerse}';

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

/// One bidirectional connection: two canonical passages plus the shared
/// bilingual reason that links them, and a priority for ordering only.
///
/// Endpoints are nullable only as a parse-failure sentinel; [validate] flags
/// any null endpoint so a bad edit can never ship, and lookups skip them.
class StudyCrossRefConnection {
  final StudyReference? a;
  final StudyReference? b;
  final String en;
  final String am;
  final int priority;

  const StudyCrossRefConnection({
    required this.a,
    required this.b,
    this.en = '',
    this.am = '',
    this.priority = 0,
  });

  /// The reason in the reader's language (may be empty until validated).
  String reasonFor(bool isAm) {
    final r = isAm ? am : en;
    return r.trim();
  }
}