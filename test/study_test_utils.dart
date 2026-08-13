import 'dart:io';

import 'package:beslet_app/core/ai/study/book_meta.dart';
import 'package:beslet_app/core/ai/study/study_cross_refs.dart';
import 'package:beslet_app/core/ai/study/study_intro.dart';
import 'package:beslet_app/core/ai/study/study_sources.dart';

/// Loads the shipped deterministic canon from disk (tests run from the
/// project root, so the assets resolve directly).
StudyCanon loadTestCanon() => StudyCanon.fromJsonString(
      File('assets/data/book_meta.json').readAsStringSync(),
      File('assets/data/chapter_verse_counts.json').readAsStringSync(),
    );

/// Loads the shipped curated-source registry from disk.
StudySourceRegistry loadTestSources() => StudySourceRegistry.fromJsonString(
      File('assets/data/study_sources.json').readAsStringSync(),
    );

/// Loads the shipped per-book knowledge layer from disk.
StudyIntroLibrary loadTestIntros() => StudyIntroLibrary.fromJsonString(
      File('assets/data/study_intros.json').readAsStringSync(),
    );

/// Loads the shipped offline cross-reference index from disk.
StudyCrossRefIndex loadTestCrossRefs() => StudyCrossRefIndex.fromJsonString(
      File('assets/data/cross_references.json').readAsStringSync(),
    );
