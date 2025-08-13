import 'package:json_annotation/json_annotation.dart';

part 'game_model.g.dart';

@JsonSerializable()
class GameModel {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final String gameUrl;
  final GameType type;
  final int minAge;
  final int maxAge;
  final List<String> categories;
  final List<String> educationalTopics;
  final bool isWhitelisted;
  final GameProgress? progress;

  GameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailUrl,
    required this.gameUrl,
    required this.type,
    required this.minAge,
    required this.maxAge,
    required this.categories,
    required this.educationalTopics,
    required this.isWhitelisted,
    this.progress,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) =>
      _$GameModelFromJson(json);

  Map<String, dynamic> toJson() => _$GameModelToJson(this);
}

enum GameType {
  @JsonValue('web')
  web,
  @JsonValue('native')
  native,
  @JsonValue('educational')
  educational,
  @JsonValue('puzzle')
  puzzle,
  @JsonValue('creative')
  creative,
}

@JsonSerializable()
class GameProgress {
  final String gameId;
  final String childId;
  final int level;
  final int score;
  final int totalPlayTimeMinutes;
  final DateTime lastPlayed;
  final Map<String, dynamic> achievements;

  GameProgress({
    required this.gameId,
    required this.childId,
    required this.level,
    required this.score,
    required this.totalPlayTimeMinutes,
    required this.lastPlayed,
    required this.achievements,
  });

  factory GameProgress.fromJson(Map<String, dynamic> json) =>
      _$GameProgressFromJson(json);

  Map<String, dynamic> toJson() => _$GameProgressToJson(this);
}