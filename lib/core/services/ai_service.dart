import 'package:google_generative_ai/google_generative_ai.dart';
import '../secrets.dart';

class AiService {
  final String _key = defaultGeminiKey;

  GenerativeModel get _model => GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _key,
        systemInstruction: Content.system(_systemPrompt),
      );

  Future<String> generate({
    required String prompt,
  }) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }

  Future<String> reflectionForVerse({
    required String verseText,
    required String reference,
    required bool isAm,
    String? context,
  }) async {
    final lang = isAm ? 'Amharic' : 'English';
    final prompt = context != null
        ? 'Respond in $lang.\n\nVerse: $reference — "$verseText"\n\nContext: $context\n\nWrite a brief personal reflection on this verse (2-4 sentences). Make it feel like it was written just for this moment.'
        : 'Respond in $lang.\n\nVerse: $reference — "$verseText"\n\nWrite a brief personal reflection on this verse (2-4 sentences). Make it feel personal and thoughtful.';
    return generate(prompt: prompt);
  }

  Future<String> greeting({
    required bool isAm,
    required int hour,
    required int streakDays,
    required bool isReturningAfterAbsence,
    int? appOpenCount,
  }) async {
    final lang = isAm ? 'Amharic' : 'English';
    final timeOfDay = hour < 12 ? 'morning' : hour < 18 ? 'afternoon' : 'evening';
    final streak = streakDays > 0 ? '$streakDays day streak' : 'new user';
    final tone = isReturningAfterAbsence
        ? 'warm and welcoming, as if greeting someone who has been away'
        : 'warm and natural';
    final prompt =
        'Respond in $lang. Tone: $tone.\n\nGreet the user for this $timeOfDay. They have a $streak. Keep it brief (1 sentence) and genuine.';
    return generate(prompt: prompt);
  }

  Future<String> completionMessage({
    required bool isAm,
    required String userName,
    required String task,
  }) async {
    final lang = isAm ? 'Amharic' : 'English';
    final name = userName.isNotEmpty ? userName : 'you';
    final prompt =
        'Respond in $lang.\n\n$name just completed: $task.\n\nWrite a brief, warm acknowledgment (1-2 sentences). Celebrate the moment without being over the top.';
    return generate(prompt: prompt);
  }

  Future<String> emptyState({
    required bool isAm,
    required String area,
  }) async {
    final lang = isAm ? 'Amharic' : 'English';
    final prompt =
        'Respond in $lang.\n\nThe user is looking at an empty $area section. Write a brief, peaceful message (1 sentence) that invites rather than pressures.';
    return generate(prompt: prompt);
  }

  Future<String> studyGuideAnswer({
    required bool isAm,
    required String bookName,
    required String question,
    required String userAnswer,
  }) async {
    final lang = isAm ? 'Amharic' : 'English';
    final prompt =
        'Respond in $lang.\n\nBook: $bookName\nQuestion: $question\nUser\'s answer: $userAnswer\n\nOffer a brief, thoughtful response that engages with their answer and adds a gentle insight (2-3 sentences).';
    return generate(prompt: prompt);
  }

  Future<String> prayerSuggestion({
    required bool isAm,
    required String? context,
  }) async {
    final lang = isAm ? 'Amharic' : 'English';
    final ctx = context ?? 'a quiet moment';
    final prompt =
        'Respond in $lang.\n\nContext: $ctx\n\nWrite a brief, heartfelt prayer (2-4 sentences) that feels personal and grounded. Not formal — like someone speaking honestly.';
    return generate(prompt: prompt);
  }

  Future<String> dailyPrompt({
    required bool isAm,
    required int streakDays,
    required String? season,
    required String? recentReading,
  }) async {
    final lang = isAm ? 'Amharic' : 'English';
    final prompt =
        'Respond in $lang.\n\nStreak: $streakDays days${season != null ? ', Season: $season' : ''}${recentReading != null ? ', Recent reading: $recentReading' : ''}\n\nWrite a brief daily thought or question for reflection (1-2 sentences). Something that invites stillness and attention.';
    return generate(prompt: prompt);
  }

  static const _systemPrompt = '''
You are Beslet AI — a thoughtful spiritual companion integrated into a Christian spiritual growth app called Beslet (ብስለት). Your purpose is to help users grow in their faith through brief, personal, and meaningful responses.

Core guidelines:
1. **Bilingual**: Respond in the user's requested language — Amharic (አማርኛ) or English. Match their language naturally.
2. **Values-aligned**: Every response should encourage spiritual growth — thoughtful, reflective, grounded in Christian faith and scripture.
3. **Adaptive tone**: Gentle when they struggle. Celebratory when they thrive. Peaceful when they rest. Attentive always.
4. **Personal**: Reference their journey when context is given — streaks, reading, growth. Make it feel like you know them.
5. **Brief and weighty**: 1-4 sentences. Let each word carry meaning. Prefer depth over length.
6. **Genuine, not generic**: Avoid clichés and hollow phrases. Speak as if to a real person in a real moment.
7. **Scripture-aware**: Show understanding of Bible passages — their context, meaning, and relevance — without being academic or preachy.
8. **Never prescriptive**: Don't tell the user what to do. Offer reflections, not instructions.
9. **Non-denominational**: Stay within broad Christian orthodoxy. Avoid divisive or controversial theological positions.
10. **Hopeful**: Even in difficult reflections, leave space for hope and grace.
''';
}
