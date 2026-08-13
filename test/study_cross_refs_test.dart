import 'dart:io';

import 'package:beslet_app/core/ai/study/study_cross_refs.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

void main() {
  group('StudyCrossRefIndex (shipped asset)', () {
    late StudyCrossRefIndex index;

    setUpAll(() {
      final raw = File('assets/data/cross_references.json').readAsStringSync();
      index = StudyCrossRefIndex.fromJsonString(raw);
    });

    test('passes full content validation (fail-closed gate)', () {
      final issues = index.validate(canon: loadTestCanon());
      expect(issues, isEmpty,
          reason: 'the shipped cross-reference index must be canon-clean:\n${issues.join('\n')}');
    });

    test('every connection is bidirectional with a bilingual reason', () {
      expect(index.connections, isNotEmpty);
      for (final conn in index.connections) {
        expect(conn.a, isNotNull, reason: 'connection must have side a');
        expect(conn.b, isNotNull, reason: 'connection must have side b');
        expect(conn.en.trim(), isNotEmpty, reason: 'connection needs an English reason');
        expect(conn.am.trim(), isNotEmpty, reason: 'connection needs an Amharic reason');
      }
    });

    test('no duplicate connections in either direction', () {
      final seen = <String>{};
      for (final conn in index.connections) {
        final a = conn.a!;
        final b = conn.b!;
        final key = ['${a.bookId} ${a.chapter}:${a.startVerse}',
                '${b.bookId} ${b.chapter}:${b.startVerse}']
          ..sort();
        final joined = key.join(' <-> ');
        expect(seen.add(joined), isTrue, reason: 'duplicate connection $joined');
      }
    });

    test('spiritual-boundary lint: no second-person or God-in-your-life framing',
        () {
      final banned = [
        'god wants you',
        'god is telling you',
        'god told you',
        'god will speak to you',
        'you should',
        'you need to',
        'you must',
        'i am speaking to you',
        'pray this prayer',
      ];
      for (final conn in index.connections) {
        for (final phrase in banned) {
          expect(conn.en.toLowerCase().contains(phrase), isFalse,
              reason: 'connection ${conn.a!.bookId} ${conn.a!.chapter}:${conn.a!.startVerse} '
                  'contains banned English phrase "$phrase"');
        }
      }
    });

    test('lookup returns the other passage with priority ordering', () {
      final results = index.crossReferencesFor('psalms', 23, 1);
      expect(results, isNotEmpty, reason: 'psalm 23:1 must have curated cross-references');
      final refs = results.map((r) => '${r.bookId} ${r.chapter}:${r.startVerse}').toSet();
      expect(refs, contains('john 10:11'));
      expect(refs, contains('1peter 5:7'));
      expect(refs, contains('revelation 7:17'));
      for (var i = 0; i + 1 < results.length; i++) {
        expect(results[i].priority <= results[i + 1].priority, isTrue,
            reason: 'results must be priority-ordered');
      }
    });

    test('lookup is bidirectional (reading John 10:11 surfaces Psalm 23)', () {
      final fromJohn = index.crossReferencesFor('john', 10, 11);
      expect(fromJohn.any((r) =>
              r.bookId == 'psalms' && r.chapter == 23 && r.startVerse == 1),
          isTrue,
          reason: 'john 10:11 must link back to psalm 23:1');
      final fromPsalm = index.crossReferencesFor('psalms', 23, 1);
      expect(fromPsalm.any((r) =>
              r.bookId == 'john' && r.chapter == 10 && r.startVerse == 11),
          isTrue,
          reason: 'psalm 23:1 must link forward to john 10:11');
    });

    test('seeds every banked study passage with its biblical connections', () {
      // Every entry in the curated study bank must be findable through the
      // index, so the offline path never regresses behind the AI path.
      final seeds = {
        'psalms 23:1': 'psalms',
        'john 3:16': 'john',
        'romans 8:28': 'romans',
        'philippians 4:13': 'philippians',
        'matthew 6:33': 'matthew',
        'isaiah 40:31': 'isaiah',
        'ephesians 2:8': 'ephesians',
        '1corinthians 13:4': '1corinthians',
      };
      for (final seed in seeds.entries) {
        final parts = seed.key.split(' ');
        final chapterVerse = parts[1].split(':');
        final results = index.crossReferencesFor(
          seed.value,
          int.parse(chapterVerse[0]),
          int.parse(chapterVerse[1]),
        );
        expect(results, isNotEmpty,
            reason: 'banked passage ${seed.key} must have offline cross-references');
      }
    });

    test('lookup for an unconnected passage returns empty', () {
      expect(index.crossReferencesFor('philemon', 1, 1), isEmpty);
    });

    test('rejects a wrong version (fail closed)', () {
      expect(() => StudyCrossRefIndex.fromJsonString('{"version":9,"connections":[]}'),
          throwsA(isA<FormatException>()));
    });

    test('flags a non-canonical endpoint (fail closed)', () {
      final canon = loadTestCanon();
      final bad = '{"version":1,"connections":['
          '{"a":{"bookId":"psalms","chapter":23,"startVerse":1,"endVerse":1},'
          '"b":{"bookId":"notabook","chapter":1,"startVerse":1,"endVerse":1},'
          '"en":"reason one","am":"ምክንያት አንድ"}]}';
      final issues = StudyCrossRefIndex.fromJsonString(bad).validate(canon: canon);
      expect(issues.any((i) => i.contains('does not exist')), isTrue,
          reason: issues.join('\n'));
    });

    test('flags a verse beyond the canon (fail closed)', () {
      final canon = loadTestCanon();
      final bad = '{"version":1,"connections":['
          '{"a":{"bookId":"obadiah","chapter":1,"startVerse":1,"endVerse":1},'
          '"b":{"bookId":"psalms","chapter":23,"startVerse":151,"endVerse":151},'
          '"en":"reason one","am":"ምክንያት አንድ"}]}';
      final issues = StudyCrossRefIndex.fromJsonString(bad).validate(canon: canon);
      expect(issues.any((i) => i.contains('does not exist')), isTrue,
          reason: issues.join('\n'));
    });

    test('flags a self-connection (fail closed)', () {
      final issues = StudyCrossRefIndex.fromJsonString(
        '{"version":1,"connections":['
        '{"a":{"bookId":"psalms","chapter":23,"startVerse":1,"endVerse":1},'
        '"b":{"bookId":"psalms","chapter":23,"startVerse":1,"endVerse":1},'
        '"en":"reason one","am":"ምክንያት አንድ"}]}',
      ).validate();
      expect(issues.any((i) => i.contains('to itself')), isTrue,
          reason: issues.join('\n'));
    });

    test('flags a duplicate pair (fail closed)', () {
      final issues = StudyCrossRefIndex.fromJsonString(
        '{"version":1,"connections":['
        '{"a":{"bookId":"psalms","chapter":23,"startVerse":1,"endVerse":1},'
        '"b":{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11},'
        '"en":"reason one","am":"ምክንያት አንድ"},'
        '{"a":{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11},'
        '"b":{"bookId":"psalms","chapter":23,"startVerse":1,"endVerse":1},'
        '"en":"reason two","am":"ምክንያት ሁለት"}]}',
      ).validate();
      expect(issues.any((i) => i.contains('duplicate connection')), isTrue,
          reason: issues.join('\n'));
    });

    test('flags both-languages requirement (fail closed)', () {
      final issues = StudyCrossRefIndex.fromJsonString(
        '{"version":1,"connections":['
        '{"a":{"bookId":"psalms","chapter":23,"startVerse":1,"endVerse":1},'
        '"b":{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11},'
        '"en":"english only","am":""}]}',
      ).validate();
      expect(issues.any((i) => i.contains('both languages')), isTrue,
          reason: issues.join('\n'));
    });

    test('flags banned framing (fail closed)', () {
      final issues = StudyCrossRefIndex.fromJsonString(
        '{"version":1,"connections":['
        '{"a":{"bookId":"psalms","chapter":23,"startVerse":1,"endVerse":1},'
        '"b":{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11},'
        '"en":"you must obey this","am":"ምክንያት አንድ"}]}',
      ).validate();
      expect(issues.any((i) => i.contains('banned')), isTrue,
          reason: issues.join('\n'));
    });

    test('resolves reasons in both languages', () {
      final conn = index.connections.first;
      expect(conn.reasonFor(false), conn.en.trim());
      expect(conn.reasonFor(true), conn.am.trim());
    });

    test('resolved references are canonical StudyCrossReference objects', () {
      final results = index.crossReferencesFor('romans', 8, 28);
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r, isA<StudyCrossReference>());
        expect(r.referenceFor(false), isNotEmpty);
      }
    });
  });
}