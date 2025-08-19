import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child_profile.dart';

/// Base interface for all game plugins in the WonderNest platform
abstract class GamePlugin {
  /// Unique identifier for this game plugin
  String get gameId;
  
  /// Display name of the game
  String get gameName;
  
  /// Short description of the game
  String get gameDescription;
  
  /// Game version for compatibility tracking
  String get gameVersion;
  
  /// Category of the game (e.g., 'puzzle', 'creative', 'educational')
  GameCategory get category;
  
  /// Educational topics this game covers
  List<String> get educationalTopics;
  
  /// Minimum age for this game
  int get minAge;
  
  /// Maximum age for this game
  int get maxAge;
  
  /// Estimated play time in minutes
  int get estimatedPlayTimeMinutes;
  
  /// Whether this game requires parent approval to play
  bool get requiresParentApproval;
  
  /// Whether this game can be played offline
  bool get supportsOfflinePlay;
  
  /// Icon to display for this game
  IconData get gameIcon;
  
  /// Asset path for game thumbnail
  String? get thumbnailAssetPath;
  
  /// Network URL for game thumbnail (optional)
  String? get thumbnailUrl;
  
  /// Create the main game widget for this plugin
  Widget createGameWidget({
    required ChildProfile child,
    required GameSession session,
    required WidgetRef ref,
  });
  
  /// Create configuration/settings widget for this game
  Widget? createSettingsWidget({
    required ChildProfile child,
    required WidgetRef ref,
  });
  
  /// Initialize the game plugin (called when first registered)
  Future<void> initialize();
  
  /// Cleanup resources when plugin is disposed
  Future<void> dispose();
  
  /// Check if this game is appropriate for the given child
  bool isAppropriateForChild(ChildProfile child);
  
  /// Get the save data structure for this game
  Map<String, dynamic> getGameDataSchema();
  
  /// Validate save data format
  bool validateSaveData(Map<String, dynamic> data);
  
  /// Handle game events (score updates, achievements, etc.)
  Future<void> handleGameEvent(GameEvent event);
  
  /// Get available achievements for this game
  List<GameAchievement> getAvailableAchievements();
  
  /// Get virtual currency rewards for this game
  List<VirtualCurrencyReward> getVirtualCurrencyRewards();
}

/// Different categories of games
enum GameCategory {
  puzzle,
  creative, 
  educational,
  adventure,
  strategy,
  memory,
  language,
  math,
  science,
  art,
}

/// Represents an active game session
class GameSession {
  final String sessionId;
  final String gameId;
  final String childId;
  final DateTime startTime;
  final Map<String, dynamic> sessionData;
  
  GameSession({
    required this.sessionId,
    required this.gameId,
    required this.childId,
    required this.startTime,
    this.sessionData = const {},
  });
  
  Duration get duration => DateTime.now().difference(startTime);
  
  GameSession copyWith({
    String? sessionId,
    String? gameId,
    String? childId,
    DateTime? startTime,
    Map<String, dynamic>? sessionData,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      gameId: gameId ?? this.gameId,
      childId: childId ?? this.childId,
      startTime: startTime ?? this.startTime,
      sessionData: sessionData ?? this.sessionData,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'gameId': gameId,
      'childId': childId,
      'startTime': startTime.toIso8601String(),
      'sessionData': sessionData,
    };
  }
  
  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      sessionId: json['sessionId'],
      gameId: json['gameId'],
      childId: json['childId'],
      startTime: DateTime.parse(json['startTime']),
      sessionData: json['sessionData'] ?? {},
    );
  }
}

/// Base class for game events
abstract class GameEvent {
  final String gameId;
  final String childId;
  final String sessionId;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  
  GameEvent({
    required this.gameId,
    required this.childId,
    required this.sessionId,
    required this.data,
  }) : timestamp = DateTime.now();
  
  String get eventType;
  
  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'childId': childId,
      'sessionId': sessionId,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'data': data,
    };
  }
}

/// Score update event
class ScoreUpdateEvent extends GameEvent {
  final int newScore;
  final int previousScore;
  
  ScoreUpdateEvent({
    required super.gameId,
    required super.childId,
    required super.sessionId,
    required this.newScore,
    required this.previousScore,
  }) : super(data: {
    'newScore': newScore,
    'previousScore': previousScore,
    'scoreDelta': newScore - previousScore,
  });
  
  @override
  String get eventType => 'score_update';
}

/// Level progression event
class LevelProgressEvent extends GameEvent {
  final int newLevel;
  final int previousLevel;
  
  LevelProgressEvent({
    required super.gameId,
    required super.childId,
    required super.sessionId,
    required this.newLevel,
    required this.previousLevel,
  }) : super(data: {
    'newLevel': newLevel,
    'previousLevel': previousLevel,
    'levelDelta': newLevel - previousLevel,
  });
  
  @override
  String get eventType => 'level_progress';
}

/// Achievement unlocked event
class AchievementUnlockedEvent extends GameEvent {
  final String achievementId;
  final String achievementName;
  
  AchievementUnlockedEvent({
    required super.gameId,
    required super.childId,
    required super.sessionId,
    required this.achievementId,
    required this.achievementName,
  }) : super(data: {
    'achievementId': achievementId,
    'achievementName': achievementName,
  });
  
  @override
  String get eventType => 'achievement_unlocked';
}

/// Game completion event
class GameCompletionEvent extends GameEvent {
  final int finalScore;
  final int finalLevel;
  final Duration playTime;
  final bool completed;
  
  GameCompletionEvent({
    required super.gameId,
    required super.childId,
    required super.sessionId,
    required this.finalScore,
    required this.finalLevel,
    required this.playTime,
    required this.completed,
  }) : super(data: {
    'finalScore': finalScore,
    'finalLevel': finalLevel,
    'playTimeMinutes': playTime.inMinutes,
    'completed': completed,
  });
  
  @override
  String get eventType => 'game_completion';
}

/// Game achievement definition
class GameAchievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int virtualCurrencyReward;
  final Map<String, dynamic> criteria;
  final bool isSecret;
  
  GameAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.virtualCurrencyReward = 0,
    this.criteria = const {},
    this.isSecret = false,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'virtualCurrencyReward': virtualCurrencyReward,
      'criteria': criteria,
      'isSecret': isSecret,
    };
  }
  
  factory GameAchievement.fromJson(Map<String, dynamic> json) {
    return GameAchievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: Icons.star, // Default icon, could be customized
      virtualCurrencyReward: json['virtualCurrencyReward'] ?? 0,
      criteria: json['criteria'] ?? {},
      isSecret: json['isSecret'] ?? false,
    );
  }
}

/// Virtual currency reward for game actions
class VirtualCurrencyReward {
  final String actionId;
  final String actionName;
  final int amount;
  final Map<String, dynamic> conditions;
  
  VirtualCurrencyReward({
    required this.actionId,
    required this.actionName,
    required this.amount,
    this.conditions = const {},
  });
  
  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'actionName': actionName,
      'amount': amount,
      'conditions': conditions,
    };
  }
  
  factory VirtualCurrencyReward.fromJson(Map<String, dynamic> json) {
    return VirtualCurrencyReward(
      actionId: json['actionId'],
      actionName: json['actionName'],
      amount: json['amount'],
      conditions: json['conditions'] ?? {},
    );
  }
}

/// Extension methods for game categories
extension GameCategoryExtension on GameCategory {
  String get displayName {
    switch (this) {
      case GameCategory.puzzle:
        return 'Puzzle';
      case GameCategory.creative:
        return 'Creative';
      case GameCategory.educational:
        return 'Educational';
      case GameCategory.adventure:
        return 'Adventure';
      case GameCategory.strategy:
        return 'Strategy';
      case GameCategory.memory:
        return 'Memory';
      case GameCategory.language:
        return 'Language';
      case GameCategory.math:
        return 'Math';
      case GameCategory.science:
        return 'Science';
      case GameCategory.art:
        return 'Art';
    }
  }
  
  IconData get icon {
    switch (this) {
      case GameCategory.puzzle:
        return Icons.extension;
      case GameCategory.creative:
        return Icons.palette;
      case GameCategory.educational:
        return Icons.school;
      case GameCategory.adventure:
        return Icons.explore;
      case GameCategory.strategy:
        return Icons.psychology;
      case GameCategory.memory:
        return Icons.memory;
      case GameCategory.language:
        return Icons.translate;
      case GameCategory.math:
        return Icons.calculate;
      case GameCategory.science:
        return Icons.science;
      case GameCategory.art:
        return Icons.brush;
    }
  }
  
  Color get color {
    switch (this) {
      case GameCategory.puzzle:
        return Colors.purple;
      case GameCategory.creative:
        return Colors.pink;
      case GameCategory.educational:
        return Colors.blue;
      case GameCategory.adventure:
        return Colors.green;
      case GameCategory.strategy:
        return Colors.orange;
      case GameCategory.memory:
        return Colors.indigo;
      case GameCategory.language:
        return Colors.teal;
      case GameCategory.math:
        return Colors.red;
      case GameCategory.science:
        return Colors.cyan;
      case GameCategory.art:
        return Colors.amber;
    }
  }
}