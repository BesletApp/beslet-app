import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The immutable registry of curated sources the study content can draw on.
/// A section's `sourceIds` reference entries here by id; the registry maps
/// each id to its display title in both languages. It is shipped with the
/// app, never edited at runtime, and validated at load time — a reference to
/// an unknown source fails closed rather than surfacing an unattributed
/// claim to a reader.

/// One curated source the study content can cite.
class StudySourceInfo {
  final String id;
  final String en;
  final String am;

  const StudySourceInfo({
    required this.id,
    required this.en,
    required this.am,
  });

  /// The display title in the reader's language.
  String titleFor(bool isAm) => isAm ? am : en;
}

/// The immutable, bundled source registry. Loaded once and shared; mirrors
/// the deterministic canon pattern (`StudyCanon`) so the app fails closed
/// rather than validating references against unknown data.
class StudySourceRegistry {
  static const int expectedVersion = 1;

  final int version;
  final Map<String, StudySourceInfo> sources;

  const StudySourceRegistry({
    required this.version,
    required this.sources,
  });

  /// Loads the bundled registry. Throws if the asset is missing, malformed,
  /// or carries an unexpected version.
  static Future<StudySourceRegistry> load() async {
    final raw =
        await rootBundle.loadString('assets/data/study_sources.json');
    return StudySourceRegistry.fromJsonString(raw);
  }

  static StudySourceRegistry fromJsonString(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['version'] != expectedVersion) {
      throw FormatException('unexpected study_sources version');
    }
    final sources = <String, StudySourceInfo>{};
    for (final rawSource in data['sources'] as List<dynamic>) {
      final s = rawSource as Map<String, dynamic>;
      final id = s['id'] as String;
      final info = StudySourceInfo(
        id: id,
        en: s['en'] as String,
        am: s['am'] as String,
      );
      if (info.en.trim().isEmpty || info.am.trim().isEmpty) {
        throw FormatException('study source $id needs both languages');
      }
      sources[id] = info;
    }
    if (sources.isEmpty) {
      throw FormatException('study_sources must contain at least one source');
    }
    return StudySourceRegistry(version: data['version'] as int, sources: sources);
  }

  StudySourceInfo? sourceFor(String id) => sources[id];

  /// Whether every id is known. Used to fail closed at bank load.
  List<String> unknownIn(Iterable<String> ids) =>
      [for (final id in ids) if (!sources.containsKey(id)) id];
}
