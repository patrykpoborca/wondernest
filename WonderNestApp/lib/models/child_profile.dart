import 'package:json_annotation/json_annotation.dart';

part 'child_profile.g.dart';

@JsonSerializable()
class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String? avatarUrl;
  final DateTime birthDate;
  final String gender;
  final List<String> interests;
  final ContentSettings contentSettings;
  final TimeRestrictions timeRestrictions;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.avatarUrl,
    required this.birthDate,
    required this.gender,
    required this.interests,
    required this.contentSettings,
    required this.timeRestrictions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) =>
      _$ChildProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ChildProfileToJson(this);
}

@JsonSerializable()
class ContentSettings {
  final int maxAgeRating;
  final List<String> blockedCategories;
  final List<String> allowedDomains;
  final bool subtitlesEnabled;
  final bool audioMonitoringEnabled;
  final bool educationalContentOnly;

  ContentSettings({
    required this.maxAgeRating,
    required this.blockedCategories,
    required this.allowedDomains,
    required this.subtitlesEnabled,
    required this.audioMonitoringEnabled,
    required this.educationalContentOnly,
  });

  factory ContentSettings.fromJson(Map<String, dynamic> json) =>
      _$ContentSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ContentSettingsToJson(this);
}

@JsonSerializable()
class TimeRestrictions {
  final Map<String, TimeSlot> weekdayLimits;
  final Map<String, TimeSlot> weekendLimits;
  final int dailyScreenTimeMinutes;
  final bool bedtimeEnabled;
  final String? bedtimeStart;
  final String? bedtimeEnd;

  TimeRestrictions({
    required this.weekdayLimits,
    required this.weekendLimits,
    required this.dailyScreenTimeMinutes,
    required this.bedtimeEnabled,
    this.bedtimeStart,
    this.bedtimeEnd,
  });

  factory TimeRestrictions.fromJson(Map<String, dynamic> json) =>
      _$TimeRestrictionsFromJson(json);

  Map<String, dynamic> toJson() => _$TimeRestrictionsToJson(this);
}

@JsonSerializable()
class TimeSlot {
  final String startTime;
  final String endTime;
  final int maxMinutes;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.maxMinutes,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSlotToJson(this);
}