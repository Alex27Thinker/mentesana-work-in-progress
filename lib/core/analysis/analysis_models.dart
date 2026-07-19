// Mentesana — shared analysis result models.
// Pure data classes with no UI or persistence dependencies.
// Finished statistical result objects expose defensive unmodifiable views.
// InsightParts is a documented mutable compatibility builder/result.

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

/// Time-of-day distribution. The [slots] map is an unmodifiable view
/// at construction time so external code cannot mutate the analyzer's
/// state.
class TimePattern {
  TimePattern(Map<String, int> slots, this.dominant)
      : slots = Map<String, int>.unmodifiable(slots);
  final Map<String, int> slots;
  final String? dominant;
}

class MoodAnalysis {
  static const Map<String, double> _emptyQuadrant = <String, double>{};
  static const List<WordCount> _emptyFrequentWords = <WordCount>[];

  MoodAnalysis({
    required this.hasData,
    required this.count,
    this.totalEntries = 0,
    required this.days,
    this.avgV = 0,
    this.avgA = 0,
    this.volatility = 0,
    Map<String, double>? quadrantDistribution,
    this.dominantQuadrant,
    this.trajectory,
    List<WordCount>? frequentWords,
    this.timePattern,
    this.shift,
  })  : quadrantDistribution = quadrantDistribution == null
            ? _emptyQuadrant
            : Map<String, double>.unmodifiable(quadrantDistribution),
        frequentWords = frequentWords == null
            ? _emptyFrequentWords
            : List<WordCount>.unmodifiable(frequentWords);

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
  TextEntryAnalysis(List<WordCount> keywords, this.sentiment,
      List<ThemeHits> themes, this.wordCount)
      : keywords = List<WordCount>.unmodifiable(keywords),
        themes = List<ThemeHits>.unmodifiable(themes);

  final List<WordCount> keywords;
  final Sentiment sentiment;
  final List<ThemeHits> themes;
  final int wordCount;
}

class TextAnalysis {
  static const List<WordCount> _emptyKeywords = <WordCount>[];
  static const List<ThemeHits> _emptyThemes = <ThemeHits>[];

  TextAnalysis({
    required this.hasData,
    required this.count,
    this.totalWords = 0,
    this.avgWordsPerEntry = 0,
    List<WordCount>? topKeywords,
    List<ThemeHits>? topThemes,
    this.avgSentiment = 0,
    this.sentimentLabel = 'mixed',
  })  : topKeywords = topKeywords == null
            ? _emptyKeywords
            : List<WordCount>.unmodifiable(topKeywords),
        topThemes = topThemes == null
            ? _emptyThemes
            : List<ThemeHits>.unmodifiable(topThemes);

  final bool hasData;
  final int count;
  final int totalWords;
  final int avgWordsPerEntry;
  final List<WordCount> topKeywords;
  final List<ThemeHits> topThemes;
  final double avgSentiment;
  final String sentimentLabel;
}

/// Mutable weekly-insight builder/result retained for compatibility with the
/// prototype's JS-style generation pipeline. Unlike the other analysis result
/// objects, [PromptEngine] builds this object incrementally. Callers that need
/// a stable collection snapshot should read [patternsView].
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
  }) : patterns = patterns == null ? <String>[] : List<String>.of(patterns);

  String headline;
  String count;
  List<String> patterns;
  List<String> get patternsView => List<String>.unmodifiable(patterns);
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
