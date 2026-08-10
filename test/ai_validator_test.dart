import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/ai/ai_content.dart';
import 'package:beslet_app/core/ai/ai_models.dart';
import 'package:beslet_app/core/ai/ai_validator.dart';

void main() {
  late AiContentBank bank;
  late AiOutputValidator validator;

  setUpAll(() {
    final raw = File('assets/data/ai_bank.json').readAsStringSync();
    bank = AiContentBank.fromJsonString(raw);
    validator = AiOutputValidator(bank);
  });

  group('AiOutputValidator', () {
    test('accepts silence', () {
      final choice = validator.validate(const AiOutput(mode: 'silence'));
      expect(choice, isNotNull);
      expect(choice!.mode, AiMode.silence);
      expect(choice.isSilent, isTrue);
    });

    test('accepts a known pointer id', () {
      final p = bank.pointers.first;
      final choice = validator.validate(
          AiOutput(mode: 'scripturePointer', itemId: p.id));
      expect(choice, isNotNull);
      expect(choice!.mode, AiMode.scripturePointer);
      expect(choice.reference!.bookId, p.bookId);
      expect(choice.reference!.chapter, p.chapter);
    });

    test('accepts a known question id', () {
      final q = bank.questions.first;
      final choice = validator.validate(
          AiOutput(mode: 'reflectiveGuidance', itemId: q.id));
      expect(choice, isNotNull);
      expect(choice!.mode, AiMode.reflectiveGuidance);
      expect(choice.itemId, q.id);
    });

    test('rejects an unknown pointer id', () {
      final choice = validator.validate(
          const AiOutput(mode: 'scripturePointer', itemId: 'ptr_nope'));
      expect(choice, isNull);
    });

    test('rejects an unknown question id', () {
      final choice = validator.validate(
          const AiOutput(mode: 'reflectiveGuidance', itemId: 'q_nope'));
      expect(choice, isNull);
    });

    test('rejects a pointer without an id', () {
      final choice = validator.validate(const AiOutput(mode: 'scripturePointer'));
      expect(choice, isNull);
    });

    test('rejects an unknown mode', () {
      final choice = validator.validate(const AiOutput(mode: 'writeDevotional'));
      expect(choice, isNull);
    });

    test('rejects a null mode', () {
      expect(validator.validate(const AiOutput()), isNull);
    });

    test('mode comparison is case-insensitive', () {
      final p = bank.pointers.first;
      final choice = validator.validate(
          AiOutput(mode: 'SCRIPTUREPOINTER', itemId: p.id));
      expect(choice, isNotNull);
      expect(choice!.mode, AiMode.scripturePointer);
    });
  });
}
