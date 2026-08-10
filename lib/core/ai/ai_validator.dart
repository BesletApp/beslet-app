import 'ai_content.dart';
import 'ai_models.dart';

/// Turns a raw selector output into a validated [AiChoice].
///
/// This is the airtight gate: the model may only *name an existing item* from
/// the curated bank. A pointer that is not in the bank, a question id that is
/// unknown, or any other shape of output is rejected. A rejected output can
/// never reach a user — the caller falls back to a local choice or silence.
class AiOutputValidator {
  final AiContentBank bank;

  const AiOutputValidator(this.bank);

  AiChoice? validate(AiOutput output) {
    final mode = output.mode?.trim().toLowerCase();
    switch (mode) {
      case 'silence':
        return const AiChoice(mode: AiMode.silence);
      case 'scripturepointer':
        final pointer = _pointerFor(output.itemId);
        if (pointer == null) return null;
        return AiChoice(
          mode: AiMode.scripturePointer,
          itemId: pointer.id,
          reference: pointer.toReference(),
        );
      case 'reflectiveguidance':
        final question = _questionFor(output.itemId);
        if (question == null) return null;
        return AiChoice(mode: AiMode.reflectiveGuidance, itemId: question.id);
      default:
        return null;
    }
  }

  AiBankPointer? _pointerFor(String? itemId) {
    if (itemId == null) return null;
    return bank.pointerById[itemId];
  }

  AiBankQuestion? _questionFor(String? itemId) {
    if (itemId == null) return null;
    return bank.questionById[itemId];
  }
}
