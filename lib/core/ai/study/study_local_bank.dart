import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../services/scripture_service.dart';
import 'study_models.dart';

/// A curated, hand-written study note for one passage in the bundled bank.
class StudyBankEntry {
  final String id;
  final String bookId;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final List<StudySection> sections;

  const StudyBankEntry({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.sections,
  });

  /// The entry anchors on a start verse: a request matches when it starts at
  /// the same verse of the same chapter. Notes describe the whole passage the
  /// entry was written for, so a sub-selection still gets the right note.
  bool covers(String bookId, int chapter, int startVerse) =>
      this.bookId == bookId && this.chapter == chapter && this.startVerse == startVerse;
}

/// The curated, canon-verified study bank. Every entry is checked against
/// `ScriptureService.bookMap` at load time — a note that cannot exist never
/// reaches a reader. Every visible word comes from here (Phase 1); a model
/// only ever *selects* which existing note fits, never writes one.
class StudyLocalBank {
  final int version;
  final List<StudyBankEntry> entries;

  const StudyLocalBank({required this.version, required this.entries});

  StudyBankEntry? entryFor(String bookId, int chapter, int startVerse) {
    for (final entry in entries) {
      if (entry.covers(bookId, chapter, startVerse)) return entry;
    }
    return null;
  }

  /// Loads the bundled bank. Throws if the asset is missing or malformed —
  /// the app fails closed rather than serving uncurated content.
  static Future<StudyLocalBank> load() async {
    final raw = await rootBundle.loadString('assets/data/study.json');
    return StudyLocalBank.fromJsonString(raw);
  }

  static StudyLocalBank fromJsonString(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final version = data['version'] as int;
    final entries = (data['entries'] as List<dynamic>).map((e) {
      final entry = e as Map<String, dynamic>;
      final sections = (entry['sections'] as List<dynamic>)
          .map(StudySection.tryParse)
          .whereType<StudySection>()
          .toList();
      return StudyBankEntry(
        id: entry['id'] as String,
        bookId: entry['bookId'] as String,
        chapter: entry['chapter'] as int,
        startVerse: entry['startVerse'] as int,
        endVerse: entry['endVerse'] as int,
        sections: sections,
      );
    }).toList();
    return StudyLocalBank(version: version, entries: entries);
  }

  /// Returns a list of content problems (empty when the bank is clean).
  /// Called at load and asserted in tests so a bad edit cannot ship.
  List<String> validate() {
    final issues = <String>[];
    if (version != 1) issues.add('bank version must be 1, found $version');
    final seen = <String>{};
    for (final entry in entries) {
      if (!seen.add(entry.id)) issues.add('duplicate entry id ${entry.id}');
      final book = ScriptureService.bookMap[entry.bookId];
      if (book == null) {
        issues.add('entry ${entry.id}: unknown book ${entry.bookId}');
        continue;
      }
      if (entry.chapter < 1 || entry.chapter > book.chapters) {
        issues.add(
            'entry ${entry.id}: chapter ${entry.chapter} out of range for ${entry.bookId} (${book.chapters})');
      }
      if (entry.startVerse < 1) issues.add('entry ${entry.id}: startVerse must be >= 1');
      if (entry.endVerse < entry.startVerse) {
        issues.add('entry ${entry.id}: endVerse before startVerse');
      }
      final kinds = entry.sections.map((s) => s.kind).toSet();
      if (kinds.length != StudySectionKind.values.length) {
        issues.add('entry ${entry.id}: must contain all six sections, got ${kinds.length}');
      }
      for (final section in entry.sections) {
        _validateSection(entry.id, section, issues);
      }
    }
    if (entries.isEmpty) issues.add('bank must contain at least one entry');
    return issues;
  }

  void _validateSection(String entryId, StudySection section, List<String> issues) {
    if (section.kind == StudySectionKind.crossReferences) {
      if (section.references.isEmpty) {
        issues.add('entry $entryId crossReferences: at least one reference required');
      }
      for (final ref in section.references) {
        if (ref.en.trim().isEmpty || ref.am.trim().isEmpty) {
          issues.add(
              'entry $entryId crossReference ${ref.referenceFor(false)}: reason needs both languages');
        }
        final book = ScriptureService.bookMap[ref.bookId];
        if (book == null) {
          issues.add('entry $entryId crossReference: unknown book ${ref.bookId}');
        } else {
          if (ref.chapter < 1 || ref.chapter > book.chapters) {
            issues.add('entry $entryId crossReference ${ref.bookId}: chapter ${ref.chapter} out of range (${book.chapters})');
          }
        }
        if (ref.startVerse < 1) {
          issues.add('entry $entryId crossReference: startVerse must be >= 1');
        }
        if (ref.endVerse < ref.startVerse) {
          issues.add('entry $entryId crossReference: endVerse before startVerse');
        }
      }
      return;
    }

    if (section.en.trim().isEmpty || section.am.trim().isEmpty) {
      issues.add('entry $entryId ${section.kind.name}: both languages required');
    }
    if (section.kind == StudySectionKind.context) {
      final subEn = section.enSub?.trim() ?? '';
      final subAm = section.amSub?.trim() ?? '';
      if (subEn.isEmpty || subAm.isEmpty) {
        issues.add('entry $entryId context: both "in the text" parts required');
      }
    }
  }
}
