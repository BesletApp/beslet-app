class MoodEntry {
  final String en;
  final String am;
  const MoodEntry(this.en, this.am);
}

class MoodContent {
  /// Z1 — Whisper acknowledgment after mood selection
  static const Map<int, MoodEntry> whisper = {
    1: MoodEntry('God sees your heaviness.', 'እግዚአብሔር ሕመምህን ያያል።'),
    2: MoodEntry('You are safe in His presence.', 'በመገኘቱ ውስጥ ደህና ነህ።'),
    3: MoodEntry('He is with you in this moment.', 'በዚህ ጊዜ ከአንተ ጋር ነው።'),
    4: MoodEntry('This joy is a gift.', 'ይህ ደስታ ስጦታ ነው።'),
    5: MoodEntry('Rejoice — this is from Him.', 'ደስ ይበልህ — ይህ ከእርሱ ነው።'),
  };

  /// Z2 — Living sentence below scripture reference
  static const Map<int, MoodEntry> livingSentence = {
    1: MoodEntry('Today, rest in His presence.', 'ዛሬ በመገኘቱ ውስጥ እረፍ።'),
    2: MoodEntry('Today, receive His peace.', 'ዛሬ ሰላሙን ተቀበል።'),
    3: MoodEntry('Today, walk with Him.', 'ዛሬ ከእርሱ ጋር ሂድ።'),
    4: MoodEntry('Today, give thanks.', 'ዛሬ አመስግን።'),
    5: MoodEntry('Today, rejoice in Him.', 'ዛሬ በእርሱ ደስ ይበልህ።'),
  };

  /// Z4 — Identity line after response
  static const Map<int, MoodEntry> identity = {
    1: MoodEntry('You are being formed in peace.', 'በሰላም ውስጥ እየተቀረጽክ ነህ።'),
    2: MoodEntry('You are learning trust.', 'መታመንን እየተማርክ ነህ።'),
    3: MoodEntry('You are walking in light.', 'በብርሃን ውስጥ እየተመላለስክ ነህ።'),
    4: MoodEntry('You are becoming gratitude.', 'ምስጋና እየሆንክ ነህ።'),
    5: MoodEntry('You are growing in joy.', 'በደስታ ውስጥ እያደግክ ነህ።'),
  };
}
