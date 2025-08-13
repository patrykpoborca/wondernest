import 'package:json_annotation/json_annotation.dart';

part 'content_model.g.dart';

enum ContentType { video, audio, game, book, activity }

enum ContentCategory {
  educational,
  entertainment,
  music,
  stories,
  science,
  math,
  language,
  art,
  physical,
  social
}

enum ContentRating { all, preschool, elementary, preteen }

@JsonSerializable()
class ContentModel {
  final String id;
  final String title;
  final String description;
  final ContentType type;
  final String? thumbnailUrl;
  final String contentUrl;
  final int durationMinutes;
  final ContentRating rating;
  final List<ContentCategory> categories;
  final List<String> tags;
  final int minAge;
  final int maxAge;
  final double? rating_score;
  final int? viewCount;
  final bool isFavorite;
  final bool isDownloaded;
  final DateTime? lastWatched;
  final double? progress;
  final String? creator;
  final List<String>? educationalTopics;
  final Map<String, dynamic>? metadata;

  ContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.thumbnailUrl,
    required this.contentUrl,
    required this.durationMinutes,
    required this.rating,
    List<ContentCategory>? categories,
    List<String>? tags,
    required this.minAge,
    required this.maxAge,
    this.rating_score,
    this.viewCount,
    this.isFavorite = false,
    this.isDownloaded = false,
    this.lastWatched,
    this.progress,
    this.creator,
    this.educationalTopics,
    this.metadata,
  })  : categories = categories ?? [],
        tags = tags ?? [];

  factory ContentModel.fromJson(Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContentModelToJson(this);

  String get typeDisplay {
    switch (type) {
      case ContentType.video:
        return 'Video';
      case ContentType.audio:
        return 'Audio';
      case ContentType.game:
        return 'Game';
      case ContentType.book:
        return 'Book';
      case ContentType.activity:
        return 'Activity';
    }
  }

  String get durationDisplay {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  String get ageRangeDisplay => '$minAge-$maxAge years';

  bool isAppropriateForAge(int age) {
    return age >= minAge && age <= maxAge;
  }

  ContentModel copyWith({
    String? id,
    String? title,
    String? description,
    ContentType? type,
    String? thumbnailUrl,
    String? contentUrl,
    int? durationMinutes,
    ContentRating? rating,
    List<ContentCategory>? categories,
    List<String>? tags,
    int? minAge,
    int? maxAge,
    double? rating_score,
    int? viewCount,
    bool? isFavorite,
    bool? isDownloaded,
    DateTime? lastWatched,
    double? progress,
    String? creator,
    List<String>? educationalTopics,
    Map<String, dynamic>? metadata,
  }) {
    return ContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      contentUrl: contentUrl ?? this.contentUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      rating: rating ?? this.rating,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      rating_score: rating_score ?? this.rating_score,
      viewCount: viewCount ?? this.viewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      lastWatched: lastWatched ?? this.lastWatched,
      progress: progress ?? this.progress,
      creator: creator ?? this.creator,
      educationalTopics: educationalTopics ?? this.educationalTopics,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class ContentFilter {
  final List<ContentType> allowedTypes;
  final List<ContentCategory> allowedCategories;
  final List<ContentCategory> blockedCategories;
  final int minAge;
  final int maxAge;
  final ContentRating maxRating;
  final List<String> blockedContentIds;
  final List<String> blockedCreators;
  final bool requireEducational;
  final int? maxDurationMinutes;
  final Map<String, dynamic>? customSettings;

  ContentFilter({
    List<ContentType>? allowedTypes,
    List<ContentCategory>? allowedCategories,
    List<ContentCategory>? blockedCategories,
    this.minAge = 0,
    this.maxAge = 18,
    this.maxRating = ContentRating.all,
    List<String>? blockedContentIds,
    List<String>? blockedCreators,
    this.requireEducational = false,
    this.maxDurationMinutes,
    this.customSettings,
  })  : allowedTypes = allowedTypes ?? ContentType.values,
        allowedCategories = allowedCategories ?? ContentCategory.values,
        blockedCategories = blockedCategories ?? [],
        blockedContentIds = blockedContentIds ?? [],
        blockedCreators = blockedCreators ?? [];

  factory ContentFilter.fromJson(Map<String, dynamic> json) =>
      _$ContentFilterFromJson(json);

  Map<String, dynamic> toJson() => _$ContentFilterToJson(this);

  bool isContentAllowed(ContentModel content) {
    // Check content type
    if (!allowedTypes.contains(content.type)) {
      return false;
    }

    // Check if content is blocked
    if (blockedContentIds.contains(content.id)) {
      return false;
    }

    // Check creator
    if (content.creator != null &&
        blockedCreators.contains(content.creator)) {
      return false;
    }

    // Check age appropriateness
    if (content.minAge < minAge || content.maxAge > maxAge) {
      return false;
    }

    // Check rating
    if (content.rating.index > maxRating.index) {
      return false;
    }

    // Check categories
    final hasBlockedCategory = content.categories
        .any((category) => blockedCategories.contains(category));
    if (hasBlockedCategory) {
      return false;
    }

    // Check if educational requirement is met
    if (requireEducational) {
      final hasEducationalCategory =
          content.categories.contains(ContentCategory.educational);
      final hasEducationalTopics =
          content.educationalTopics?.isNotEmpty ?? false;
      if (!hasEducationalCategory && !hasEducationalTopics) {
        return false;
      }
    }

    // Check duration limit
    if (maxDurationMinutes != null &&
        content.durationMinutes > maxDurationMinutes!) {
      return false;
    }

    return true;
  }

  ContentFilter copyWith({
    List<ContentType>? allowedTypes,
    List<ContentCategory>? allowedCategories,
    List<ContentCategory>? blockedCategories,
    int? minAge,
    int? maxAge,
    ContentRating? maxRating,
    List<String>? blockedContentIds,
    List<String>? blockedCreators,
    bool? requireEducational,
    int? maxDurationMinutes,
    Map<String, dynamic>? customSettings,
  }) {
    return ContentFilter(
      allowedTypes: allowedTypes ?? this.allowedTypes,
      allowedCategories: allowedCategories ?? this.allowedCategories,
      blockedCategories: blockedCategories ?? this.blockedCategories,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxRating: maxRating ?? this.maxRating,
      blockedContentIds: blockedContentIds ?? this.blockedContentIds,
      blockedCreators: blockedCreators ?? this.blockedCreators,
      requireEducational: requireEducational ?? this.requireEducational,
      maxDurationMinutes: maxDurationMinutes ?? this.maxDurationMinutes,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}