// Mentesana — shared analysis result models.
// Pure data classes with no UI or persistence dependencies.

/// Month labels (short English) shared by SeasonSummary and PromptEngine.
const kMonthsShortAE = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

/// A month-level aggregate — a "season" the weekly letter can compare across
/// time, so month six reads deeper than week two instead of identically.
class SeasonSummary {
  const SeasonSummary({
    required this.year,
    required this.month,
    required this.entryCount,
    this.dominantQuadrant,
    this.topTheme,
    this.avgSentiment = 0,
    this.topWord,
  });

  final int year;
  final int month; // 1-12
  final int entryCount;
  final String? dominantQuadrant;
  final String? topTheme;
  final double avgSentiment;
  final String? topWord;

  String get label => '${kMonthsShortAE[month - 1]} $year';
}

class WordCount {
  const WordCount(this.word, this.count);
  final String word;
  final int count;
}

class ThemeHits {
  const ThemeHits(this.theme, this.hits, this.weight);
  final String theme;
  final int hits;
  final double weight;
}

class MoodTrajectory {
  const MoodTrajectory(this.vDir, this.aDir, this.description);
  final double vDir;
  final double aDir;
  final String description;
}

class MoodShift {
  const MoodShift(this.vShift, this.aShift, this.description);
  final double vShift;
  final double aShift;
  final String description;
}

class TimePattern {
  const TimePattern(this.slots, this.dominant);
  final Map<String, int> slots;
  final String? dominant;
}

class MoodAnalysis {
  const MoodAnalysis({
    required this.hasData,
    required this.count,
    this.totalEntries = 0,
    required this.days,
    this.avgV = 0,
    this.avgA = 0,
    this.volatility = 0,
    this.quadrantDistribution = const {},
    this.dominantQuadrant,
    this.trajectory,
    this.frequentWords = const [],
    this.timePattern,
    this.shift,
  });

  final bool hasData;
  final int count;
  final int totalEntries;
  final int days;
  final double avgV;
  final double avgA;
  final double volatility;
  final Map<String, double> quadrantDistribution;
  final String? dominantQuadrant;
  final MoodTrajectory? trajectory;
  final List<WordCount> frequentWords;
  final TimePattern? timePattern;
  final MoodShift? shift;
}

class Sentiment {
  const Sentiment(
      this.score, this.positive, this.negative, this.total, this.label);
  final double score;
  final int positive;
  final int negative;
  final int total;
  final String label;
}

class TextEntryAnalysis {
  const TextEntryAnalysis(
      this.keywords, this.sentiment, this.themes, this.wordCount);
  final List<WordCount> keywords;
  final Sentiment sentiment;
  final List<ThemeHits> themes;
  final int wordCount;
}

class TextAnalysis {
  const TextAnalysis({
    required this.hasData,
    required this.count,
    this.totalWords = 0,
    this.avgWordsPerEntry = 0,
    this.topKeywords = const [],
    this.topThemes = const [],
    this.avgSentiment = 0,
    this.sentimentLabel = 'mixed',
  });

  final bool hasData;
  final int count;
  final int totalWords;
  final int avgWordsPerEntry;
  final List<WordCount> topKeywords;
  final List<ThemeHits> topThemes;
  final double avgSentiment;
  final String sentimentLabel;
}

/// The weekly-insight shape (JS `parts`), plus the AI crisis extension.
class InsightParts {
  InsightParts({
    this.headline = '',
    this.count = '',
    List<String>? patterns,
    this.question = '',
    this.thin = false,
    this.crisis = false,
    this.crisisMessage,
    this.fromAI = false,
  }) : patterns = patterns ?? [];

  String headline;
  String count;
  List<String> patterns;
  String question;
  bool thin;
  bool crisis;
  String? crisisMessage;
  bool fromAI;
}

/// Stable sort (JS Array.sort is stable; Dart's List.sort is not).
List<T> stableSortedByDesc<T>(Iterable<T> items, num Function(T) key) {
  final indexed = items.toList().asMap().entries.toList()
    ..sort((a, b) {
      final c = key(b.value).compareTo(key(a.value));
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return indexed.map((e) => e.value).toList();
}
