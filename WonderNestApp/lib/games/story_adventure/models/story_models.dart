import 'package:json_annotation/json_annotation.dart';

part 'story_models.g.dart';

/// Story template from the backend
@JsonSerializable()
class StoryTemplate {
  final String id;
  final String title;
  final String description;
  final String? creatorId;
  final String ageGroup;
  final String difficulty;
  final Map<String, dynamic> content;
  final List<String> vocabularyWords;
  final int pageCount;
  final int estimatedReadTime;
  final String language;
  final String version;
  final bool isPremium;
  final bool isMarketplace;
  final bool isActive;
  final bool isPrivate;
  final List<String> educationalGoals;
  final List<String> themes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoryTemplate({
    required this.id,
    required this.title,
    required this.description,
    this.creatorId,
    required this.ageGroup,
    required this.difficulty,
    required this.content,
    required this.vocabularyWords,
    required this.pageCount,
    required this.estimatedReadTime,
    required this.language,
    required this.version,
    required this.isPremium,
    required this.isMarketplace,
    required this.isActive,
    required this.isPrivate,
    required this.educationalGoals,
    required this.themes,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoryTemplate.fromJson(Map<String, dynamic> json) => _$StoryTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$StoryTemplateToJson(this);

  /// Create a simple template for testing
  static StoryTemplate createSample({
    String id = 'sample-story',
    String title = 'The Magic Garden',
    String description = 'A story about a magical garden where flowers sing and butterflies paint',
  }) {
    return StoryTemplate(
      id: id,
      title: title,
      description: description,
      ageGroup: '6-8',
      difficulty: 'easy',
      content: {
        'pages': [
          {
            'pageNumber': 1,
            'text': 'Once upon a time, in a magical garden, there lived singing flowers.',
            'image': 'assets/story_adventure/sample/page1.png',
            'audioUrl': null,
          },
          {
            'pageNumber': 2,
            'text': 'The butterflies would paint beautiful pictures on the leaves.',
            'image': 'assets/story_adventure/sample/page2.png',
            'audioUrl': null,
          },
          {
            'pageNumber': 3,
            'text': 'And they all lived happily ever after in their magical home.',
            'image': 'assets/story_adventure/sample/page3.png',
            'audioUrl': null,
          }
        ]
      },
      vocabularyWords: ['magical', 'garden', 'singing', 'butterflies', 'beautiful'],
      pageCount: 3,
      estimatedReadTime: 5,
      language: 'en',
      version: '1.0.0',
      isPremium: false,
      isMarketplace: false,
      isActive: true,
      isPrivate: false,
      educationalGoals: ['vocabulary_building', 'reading_comprehension'],
      themes: ['nature', 'magic', 'friendship'],
      tags: ['beginner', 'illustrated', 'short'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

/// Represents a single page in a story
@JsonSerializable()
class StoryPage {
  final int pageNumber;
  final String text;
  final String? image;
  final String? audioUrl;
  final List<VocabularyWord> vocabularyWords;

  StoryPage({
    required this.pageNumber,
    required this.text,
    this.image,
    this.audioUrl,
    this.vocabularyWords = const [],
  });

  factory StoryPage.fromJson(Map<String, dynamic> json) => _$StoryPageFromJson(json);
  Map<String, dynamic> toJson() => _$StoryPageToJson(this);
}

/// Vocabulary word with definition and pronunciation
@JsonSerializable()
class VocabularyWord {
  final String word;
  final String definition;
  final String? pronunciation;
  final String? audioUrl;
  final int difficultyLevel;

  VocabularyWord({
    required this.word,
    required this.definition,
    this.pronunciation,
    this.audioUrl,
    required this.difficultyLevel,
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) => _$VocabularyWordFromJson(json);
  Map<String, dynamic> toJson() => _$VocabularyWordToJson(this);
}

/// Child's reading session for a story
@JsonSerializable()
class StorySession {
  final String sessionId;
  final String childId;
  final String templateId;
  final int currentPage;
  final bool isCompleted;
  final DateTime startTime;
  final DateTime? endTime;
  final int wordsRead;
  final int vocabularyEncounters;
  final Map<String, dynamic> preferences;

  StorySession({
    required this.sessionId,
    required this.childId,
    required this.templateId,
    required this.currentPage,
    required this.isCompleted,
    required this.startTime,
    this.endTime,
    required this.wordsRead,
    required this.vocabularyEncounters,
    this.preferences = const {},
  });

  factory StorySession.fromJson(Map<String, dynamic> json) => _$StorySessionFromJson(json);
  Map<String, dynamic> toJson() => _$StorySessionToJson(this);

  Duration? get readingTime => endTime?.difference(startTime);

  StorySession copyWith({
    String? sessionId,
    String? childId,
    String? templateId,
    int? currentPage,
    bool? isCompleted,
    DateTime? startTime,
    DateTime? endTime,
    int? wordsRead,
    int? vocabularyEncounters,
    Map<String, dynamic>? preferences,
  }) {
    return StorySession(
      sessionId: sessionId ?? this.sessionId,
      childId: childId ?? this.childId,
      templateId: templateId ?? this.templateId,
      currentPage: currentPage ?? this.currentPage,
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      wordsRead: wordsRead ?? this.wordsRead,
      vocabularyEncounters: vocabularyEncounters ?? this.vocabularyEncounters,
      preferences: preferences ?? this.preferences,
    );
  }
}

/// Child's progress in Story Adventure
@JsonSerializable()
class StoryAdventureProgress {
  final String childId;
  final int storiesCompleted;
  final int totalReadingTimeMinutes;
  final List<String> completedStoryIds;
  final Map<String, int> vocabularyMastery;
  final Map<String, dynamic> preferences;
  final DateTime lastPlayed;

  StoryAdventureProgress({
    required this.childId,
    required this.storiesCompleted,
    required this.totalReadingTimeMinutes,
    required this.completedStoryIds,
    required this.vocabularyMastery,
    this.preferences = const {},
    required this.lastPlayed,
  });

  factory StoryAdventureProgress.fromJson(Map<String, dynamic> json) => _$StoryAdventureProgressFromJson(json);
  Map<String, dynamic> toJson() => _$StoryAdventureProgressToJson(this);

  /// Create initial progress for a new child
  factory StoryAdventureProgress.initial(String childId) {
    return StoryAdventureProgress(
      childId: childId,
      storiesCompleted: 0,
      totalReadingTimeMinutes: 0,
      completedStoryIds: [],
      vocabularyMastery: {},
      preferences: {
        'autoNarration': true,
        'vocabularyHints': true,
        'readingLevel': 'auto',
      },
      lastPlayed: DateTime.now(),
    );
  }

  StoryAdventureProgress copyWith({
    String? childId,
    int? storiesCompleted,
    int? totalReadingTimeMinutes,
    List<String>? completedStoryIds,
    Map<String, int>? vocabularyMastery,
    Map<String, dynamic>? preferences,
    DateTime? lastPlayed,
  }) {
    return StoryAdventureProgress(
      childId: childId ?? this.childId,
      storiesCompleted: storiesCompleted ?? this.storiesCompleted,
      totalReadingTimeMinutes: totalReadingTimeMinutes ?? this.totalReadingTimeMinutes,
      completedStoryIds: completedStoryIds ?? this.completedStoryIds,
      vocabularyMastery: vocabularyMastery ?? this.vocabularyMastery,
      preferences: preferences ?? this.preferences,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }
}

/// Reading settings/preferences for Story Adventure
@JsonSerializable()
class ReadingPreferences {
  final bool autoNarration;
  final bool vocabularyHints;
  final bool subtitlesEnabled;
  final double narrationSpeed;
  final String readingLevel; // 'auto', 'easy', 'medium', 'hard'
  final bool parentalGuidance;

  ReadingPreferences({
    this.autoNarration = true,
    this.vocabularyHints = true,
    this.subtitlesEnabled = false,
    this.narrationSpeed = 1.0,
    this.readingLevel = 'auto',
    this.parentalGuidance = false,
  });

  factory ReadingPreferences.fromJson(Map<String, dynamic> json) => _$ReadingPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$ReadingPreferencesToJson(this);

  ReadingPreferences copyWith({
    bool? autoNarration,
    bool? vocabularyHints,
    bool? subtitlesEnabled,
    double? narrationSpeed,
    String? readingLevel,
    bool? parentalGuidance,
  }) {
    return ReadingPreferences(
      autoNarration: autoNarration ?? this.autoNarration,
      vocabularyHints: vocabularyHints ?? this.vocabularyHints,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      narrationSpeed: narrationSpeed ?? this.narrationSpeed,
      readingLevel: readingLevel ?? this.readingLevel,
      parentalGuidance: parentalGuidance ?? this.parentalGuidance,
    );
  }
}