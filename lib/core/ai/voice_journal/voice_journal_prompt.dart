import 'voice_journal_models.dart';

/// Length ceilings the voice-journal prompt promises and the validator
/// enforces. The AI is an editor, so the organized journal must stay close to
/// the transcript's own size — it reorganizes the reader's words, it never
/// expands them into something bigger. "Preserve silence": a section that has
/// no honest material is omitted, never padded.
class VoiceJournalLengthBudget {
  /// A section is rejected outright when it exceeds this multiple of its
  /// ceiling (an overrun that large is violation, not style).
  static const double hardRejectFactor = 2.0;

  /// The "one sentence to remember" is a quote — one sentence, drawn verbatim
  /// (or near-verbatim) from the reader's words.
  static const int sentenceToRememberMaxWords = 40;

  /// The organized journal as a whole must never dwarf the transcript: this is
  /// the multiplier applied over the transcript word count as a hard ceiling.
  static const double overallExpandFactor = 1.4;
  static const int overallFloorWords = 60;

  /// Per-section word ceiling for the grouped sections.
  static const int sectionFloorWords = 24;

  /// The word ceiling the transcript supports (per section).
  static int sectionCeilingFor(int transcriptWords) {
    final overall =
        (transcriptWords * overallExpandFactor).ceil().clamp(overallFloorWords, 1 << 30);
    return (overall ~/ 4).clamp(sectionFloorWords, 1 << 30);
  }

  /// The whole organized journal word ceiling.
  static int overallCeilingFor(int transcriptWords) =>
      (transcriptWords * overallExpandFactor).ceil().clamp(overallFloorWords, 1 << 30);
}

/// Builds the versioned voice-journal prompt for a single request. The
/// organized journal is generated *on demand only* — the user pressed
/// "Organize".
///
/// The hardest rule is the editorial contract: the model must move and tidy the
/// reader's own words, never author new content. Every non-negotiable in the
/// prompt exists to keep the AI an editor rather than an author.
class VoiceJournalPromptBuilder {
  const VoiceJournalPromptBuilder();

  String build(VoiceJournalRequest request) {
    final isAm = request.isAmharic;
    final language = isAm ? 'amharic' : 'english';
    final transcriptWords = _wordCount(request.transcript);
    final sectionCeiling = VoiceJournalLengthBudget.sectionCeilingFor(transcriptWords);
    final overallCeiling = VoiceJournalLengthBudget.overallCeilingFor(transcriptWords);
    final quoteMax = VoiceJournalLengthBudget.sentenceToRememberMaxWords;

    return '''
You are a careful EDITOR inside a personal journaling app — never an author,
never a coach, never a preacher. A reader dictated a private voice note and
asked you to organize THEIR words into a tidy daily journal. You do exactly that
and nothing more.

THE READER'S VOICE NOTE (transcript below). Treat every word as the reader's own
and treat this text as the ONLY source of truth:
----- TRANSCRIPT -----
${request.transcript}
----- END TRANSCRIPT -----

The transcript is in $language.

YOUR ONLY JOB — edit, do not author:
Group and lightly tidy the reader's own sentences into five sections. Remove
filler ("um", "uh", "you know", "so yeah", repeated false starts) and fix
harmless transcription slips, but KEEP the reader's words \u2014 their sentences,
their phrases, their order of telling. You may join or split sentences and
merge repeated points, but you must never:
  - invent information, events, or details the reader never said;
  - add emotions the reader never expressed;
  - add spiritual content the reader never shared;
  - generate revelations, lessons, or "God is saying" content;
  - preach, command, or advise ("you should", "you need to");
  - replace the reader's own words with your paraphrase of something new;
  - reorder events (preserve the chronology of what happened);
  - change the reader's tone or frame of mind.
When the reader used a word or phrase, reuse it. When the reader told a story,
keep the story. The more your output sounds like the reader, the better.

THE FIVE SECTIONS (output every section that has honest material in the
transcript; OMIT any section that has nothing — never pad, never invent):
  "whatHappened"        — what happened today, in the reader's own order.
  "emotions"            — only emotions the reader actually expressed.
  "spiritualMoments"    — only spiritual moments the reader actually shared.
  "insights"            — the reader's own insights, stated in their own words.
  "sentenceToRemember"  — ONE sentence to remember, taken VERBATIM (or nearly
                          verbatim) from the reader's own words. A direct
                          excerpt from the transcript, in quotation marks of
                          the target language — never a new sentence you wrote.

RULES FOR THE EDIT
Length: the organized journal must stay close to the size of the transcript —
it edits, it never inflates. At most $overallCeiling words total. Each section
(at most $sectionCeiling words; the quote at most $quoteMax
words). Filler removed does not count.
Language: write every section in the reader's language ($language), in natural,
ordinary, educated style. When the requested language is Amharic, write fresh,
natural Amharic — never a mechanical translation of English — but keep the
reader's exact words wherever the reader's wording was already good Amharic.
Tone: preserve the reader's voice and frame of mind exactly.
Honesty: when a sentence is unclear in the transcript, keep it faithful to the
words as written; never "fix" it by inventing a meaning.

OUTPUT — Reply with ONLY the JSON below. Include only sections that have honest
material; omit sections the transcript does not support. No commentary around
the JSON, no markdown fences.
{
  "whatHappened": "...",
  "emotions": "...",
  "spiritualMoments": "...",
  "insights": "...",
  "sentenceToRemember": "..."
}
''';
  }

  int _wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}