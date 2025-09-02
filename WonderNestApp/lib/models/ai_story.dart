import 'package:json_annotation/json_annotation.dart';

part 'ai_story.g.dart';

@JsonSerializable()
class AIStory {
  final String id;
  final String title;
  final String content;
  final List<StoryChapter> chapters;
  final StoryMetadata metadata;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String? childId;
  final String? parentId;

  AIStory({
    required this.id,
    required this.title,
    required this.content,
    this.chapters = const [],
    required this.metadata,
    this.imageUrls = const [],
    required this.createdAt,
    this.childId,
    this.parentId,
  });

  factory AIStory.fromJson(Map<String, dynamic> json) => _$AIStoryFromJson(json);
  Map<String, dynamic> toJson() => _$AIStoryToJson(this);
  
  // Helper method to get full story text
  String get fullText {
    if (chapters.isEmpty) {
      return content;
    }
    return chapters.map((ch) => ch.content).join('\n\n');
  }
  
  // Helper to get reading time estimate
  int get estimatedReadingMinutes {
    final wordCount = fullText.split(' ').length;
    return (wordCount / 200).ceil(); // Assuming 200 words per minute
  }
}

@JsonSerializable()
class StoryChapter {
  final String title;
  final String content;
  final String? imageUrl;
  final int orderIndex;

  StoryChapter({
    required this.title,
    required this.content,
    this.imageUrl,
    required this.orderIndex,
  });

  factory StoryChapter.fromJson(Map<String, dynamic> json) => _$StoryChapterFromJson(json);
  Map<String, dynamic> toJson() => _$StoryChapterToJson(this);
}

@JsonSerializable()
class StoryMetadata {
  final String ageRange;
  final List<String> educationalGoals;
  final List<String> themes;
  final String? language;
  final int? wordCount;
  final String? readingLevel;
  final double? safetyScore;
  final Map<String, dynamic>? additionalData;

  StoryMetadata({
    required this.ageRange,
    this.educationalGoals = const [],
    this.themes = const [],
    this.language = 'en',
    this.wordCount,
    this.readingLevel,
    this.safetyScore,
    this.additionalData,
  });

  factory StoryMetadata.fromJson(Map<String, dynamic> json) => _$StoryMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$StoryMetadataToJson(this);
}