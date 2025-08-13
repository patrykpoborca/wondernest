import 'package:json_annotation/json_annotation.dart';

part 'activity_log.g.dart';

@JsonSerializable()
class ActivityLog {
  final String id;
  final String childId;
  final ActivityType type;
  final String title;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final int durationSeconds;
  final String? contentUrl;
  final List<String> subtitlesViewed;
  final List<String> keywordsDetected;

  ActivityLog({
    required this.id,
    required this.childId,
    required this.type,
    required this.title,
    this.description,
    required this.metadata,
    required this.timestamp,
    required this.durationSeconds,
    this.contentUrl,
    required this.subtitlesViewed,
    required this.keywordsDetected,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityLogToJson(this);
}

enum ActivityType {
  @JsonValue('video')
  video,
  @JsonValue('game')
  game,
  @JsonValue('audio')
  audio,
  @JsonValue('reading')
  reading,
  @JsonValue('app')
  app,
  @JsonValue('web')
  web,
}