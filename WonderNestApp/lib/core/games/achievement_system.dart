import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_plugin.dart';
import 'game_persistence.dart';

/// Achievement tracking and management system
class AchievementManager {
  static final AchievementManager _instance = AchievementManager._internal();
  factory AchievementManager() => _instance;
  AchievementManager._internal();

  final GamePersistenceManager _persistence = GamePersistenceManager();
  final Map<String, Set<String>> _childAchievements = {};
  final List<AchievementUnlockListener> _listeners = [];

  /// Add a listener for achievement unlocks
  void addListener(AchievementUnlockListener listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(AchievementUnlockListener listener) {
    _listeners.remove(listener);
  }

  /// Check and potentially unlock achievements based on a game event
  Future<List<GameAchievement>> checkAchievements({
    required String gameId,
    required String childId,
    required GameEvent event,
    required Map<String, dynamic> gameData,
    required List<GameAchievement> availableAchievements,
  }) async {
    final unlockedAchievements = <GameAchievement>[];
    final childKey = '${gameId}_$childId';
    final currentAchievements = _childAchievements[childKey] ?? <String>{};

    for (final achievement in availableAchievements) {
      if (currentAchievements.contains(achievement.id)) {
        continue; // Already unlocked
      }

      if (await _checkAchievementCriteria(achievement, event, gameData, childId)) {
        await _unlockAchievement(gameId, childId, achievement);
        unlockedAchievements.add(achievement);
        currentAchievements.add(achievement.id);
      }
    }

    _childAchievements[childKey] = currentAchievements;
    return unlockedAchievements;
  }

  /// Get all unlocked achievements for a child and game
  Future<List<GameAchievement>> getUnlockedAchievements(String gameId, String childId) async {
    return await _persistence.loadAchievements(gameId, childId);
  }

  /// Get achievement progress statistics
  Future<AchievementStats> getAchievementStats(String gameId, String childId) async {
    final unlockedAchievements = await getUnlockedAchievements(gameId, childId);
    
    // This would typically come from the game plugin
    final totalAchievements = 10; // Placeholder
    
    final totalPoints = unlockedAchievements
        .fold<int>(0, (sum, achievement) => sum + achievement.virtualCurrencyReward);
    
    return AchievementStats(
      totalAchievements: totalAchievements,
      unlockedCount: unlockedAchievements.length,
      totalPointsEarned: totalPoints,
      completionPercentage: (unlockedAchievements.length / totalAchievements * 100).round(),
      recentUnlocks: unlockedAchievements
          .take(5)
          .toList(),
    );
  }

  /// Check if a specific achievement is unlocked
  Future<bool> isAchievementUnlocked(String gameId, String childId, String achievementId) async {
    final achievements = await getUnlockedAchievements(gameId, childId);
    return achievements.any((a) => a.id == achievementId);
  }

  /// Get achievement unlock date
  Future<DateTime?> getAchievementUnlockDate(String gameId, String childId, String achievementId) async {
    // This would require storing unlock dates in persistence
    // For now, return null
    return null;
  }

  /// Private methods

  Future<bool> _checkAchievementCriteria(
    GameAchievement achievement,
    GameEvent event,
    Map<String, dynamic> gameData,
    String childId,
  ) async {
    final criteria = achievement.criteria;
    
    // Score-based achievements
    if (criteria['type'] == 'score_threshold') {
      final threshold = criteria['value'] as int;
      final currentScore = gameData['score'] as int? ?? 0;
      return currentScore >= threshold;
    }
    
    // Level-based achievements
    if (criteria['type'] == 'level_reached') {
      final targetLevel = criteria['value'] as int;
      final currentLevel = gameData['level'] as int? ?? 1;
      return currentLevel >= targetLevel;
    }
    
    // Play time achievements
    if (criteria['type'] == 'total_play_time') {
      final targetMinutes = criteria['value'] as int;
      final totalPlayTime = gameData['totalPlayTimeMinutes'] as int? ?? 0;
      return totalPlayTime >= targetMinutes;
    }
    
    // Session-based achievements
    if (criteria['type'] == 'sessions_played') {
      final targetSessions = criteria['value'] as int;
      final sessionsPlayed = gameData['sessionsPlayed'] as int? ?? 0;
      return sessionsPlayed >= targetSessions;
    }
    
    // Perfect score achievements
    if (criteria['type'] == 'perfect_score') {
      final maxScore = criteria['maxScore'] as int;
      final currentScore = gameData['score'] as int? ?? 0;
      return currentScore >= maxScore;
    }
    
    // Streak achievements
    if (criteria['type'] == 'win_streak') {
      final targetStreak = criteria['value'] as int;
      final currentStreak = gameData['winStreak'] as int? ?? 0;
      return currentStreak >= targetStreak;
    }
    
    // Daily play achievements
    if (criteria['type'] == 'daily_play_streak') {
      final targetDays = criteria['value'] as int;
      final currentStreak = gameData['dailyPlayStreak'] as int? ?? 0;
      return currentStreak >= targetDays;
    }
    
    // Completion achievements
    if (criteria['type'] == 'game_completion') {
      final completed = gameData['completed'] as bool? ?? false;
      return completed;
    }
    
    // Event-specific achievements
    if (event is ScoreUpdateEvent && criteria['type'] == 'score_in_single_game') {
      final targetScore = criteria['value'] as int;
      return event.newScore >= targetScore;
    }
    
    if (event is LevelProgressEvent && criteria['type'] == 'level_completed_in_time') {
      final targetTime = criteria['maxTimeMinutes'] as int;
      final sessionDuration = gameData['sessionDurationMinutes'] as int? ?? 0;
      return event.newLevel > event.previousLevel && sessionDuration <= targetTime;
    }
    
    // Multiple games achievements (cross-game)
    if (criteria['type'] == 'multiple_games_played') {
      final targetGames = criteria['value'] as int;
      // This would require checking across all games for the child
      return false; // Placeholder
    }
    
    return false;
  }

  Future<void> _unlockAchievement(String gameId, String childId, GameAchievement achievement) async {
    await _persistence.saveAchievementUnlock(gameId, childId, achievement);
    
    // Notify listeners
    for (final listener in _listeners) {
      try {
        await listener.onAchievementUnlocked(gameId, childId, achievement);
      } catch (e) {
        print('Error in achievement unlock listener: $e');
      }
    }
  }
}

/// Statistics about a child's achievements
class AchievementStats {
  final int totalAchievements;
  final int unlockedCount;
  final int totalPointsEarned;
  final int completionPercentage;
  final List<GameAchievement> recentUnlocks;

  const AchievementStats({
    required this.totalAchievements,
    required this.unlockedCount,
    required this.totalPointsEarned,
    required this.completionPercentage,
    required this.recentUnlocks,
  });

  bool get isCompleted => unlockedCount >= totalAchievements;
  int get remainingAchievements => totalAchievements - unlockedCount;
}

/// Listener interface for achievement unlocks
abstract class AchievementUnlockListener {
  Future<void> onAchievementUnlocked(String gameId, String childId, GameAchievement achievement);
}

/// Virtual currency management system
class VirtualCurrencyManager {
  static final VirtualCurrencyManager _instance = VirtualCurrencyManager._internal();
  factory VirtualCurrencyManager() => _instance;
  VirtualCurrencyManager._internal();

  final GamePersistenceManager _persistence = GamePersistenceManager();
  final List<CurrencyUpdateListener> _listeners = [];

  /// Add a listener for currency updates
  void addListener(CurrencyUpdateListener listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(CurrencyUpdateListener listener) {
    _listeners.remove(listener);
  }

  /// Award currency for a game event
  Future<int> awardCurrency({
    required String childId,
    required GameEvent event,
    required List<VirtualCurrencyReward> rewards,
    required Map<String, dynamic> gameData,
  }) async {
    int totalAwarded = 0;

    for (final reward in rewards) {
      if (_checkRewardConditions(reward, event, gameData)) {
        await _persistence.updateVirtualCurrency(
          childId,
          reward.amount,
          '${reward.actionName} in ${event.gameId}',
        );
        totalAwarded += reward.amount;
      }
    }

    if (totalAwarded > 0) {
      // Notify listeners
      for (final listener in _listeners) {
        try {
          await listener.onCurrencyUpdated(childId, totalAwarded, 'Game rewards');
        } catch (e) {
          print('Error in currency update listener: $e');
        }
      }
    }

    return totalAwarded;
  }

  /// Get current balance for a child
  Future<int> getBalance(String childId) async {
    return await _persistence.getVirtualCurrencyBalance(childId);
  }

  /// Spend currency
  Future<bool> spendCurrency({
    required String childId,
    required int amount,
    required String reason,
  }) async {
    final currentBalance = await getBalance(childId);
    
    if (currentBalance < amount) {
      return false; // Insufficient funds
    }

    await _persistence.updateVirtualCurrency(childId, -amount, reason);
    
    // Notify listeners
    for (final listener in _listeners) {
      try {
        await listener.onCurrencyUpdated(childId, -amount, reason);
      } catch (e) {
        print('Error in currency update listener: $e');
      }
    }

    return true;
  }

  /// Add currency (for purchases, bonuses, etc.)
  Future<void> addCurrency({
    required String childId,
    required int amount,
    required String reason,
  }) async {
    await _persistence.updateVirtualCurrency(childId, amount, reason);
    
    // Notify listeners
    for (final listener in _listeners) {
      try {
        await listener.onCurrencyUpdated(childId, amount, reason);
      } catch (e) {
        print('Error in currency update listener: $e');
      }
    }
  }

  /// Get transaction history
  Future<List<CurrencyTransaction>> getTransactionHistory(String childId) async {
    final transactions = await _persistence.getVirtualCurrencyTransactions(childId);
    
    return transactions.map((t) => CurrencyTransaction(
      amount: t['amount'],
      reason: t['reason'],
      timestamp: DateTime.parse(t['timestamp']),
      balanceAfter: t['balanceAfter'],
    )).toList();
  }

  /// Get currency earning statistics
  Future<CurrencyStats> getCurrencyStats(String childId) async {
    final transactions = await getTransactionHistory(childId);
    final currentBalance = await getBalance(childId);
    
    final earned = transactions
        .where((t) => t.amount > 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
    
    final spent = transactions
        .where((t) => t.amount < 0)
        .fold<int>(0, (sum, t) => sum + t.amount.abs());
    
    return CurrencyStats(
      currentBalance: currentBalance,
      totalEarned: earned,
      totalSpent: spent,
      transactionCount: transactions.length,
      averageEarningPerTransaction: transactions.isEmpty ? 0 : (earned / transactions.where((t) => t.amount > 0).length).round(),
    );
  }

  /// Private methods

  bool _checkRewardConditions(
    VirtualCurrencyReward reward,
    GameEvent event,
    Map<String, dynamic> gameData,
  ) {
    final conditions = reward.conditions;
    
    // Score increase rewards
    if (reward.actionId == 'score_increase' && event is ScoreUpdateEvent) {
      final minIncrease = conditions['min_increase'] as int? ?? 0;
      return (event.newScore - event.previousScore) >= minIncrease;
    }
    
    // Level completion rewards
    if (reward.actionId == 'level_complete' && event is LevelProgressEvent) {
      return event.newLevel > event.previousLevel;
    }
    
    // Achievement unlock rewards
    if (reward.actionId == 'achievement_unlock' && event is AchievementUnlockedEvent) {
      return true;
    }
    
    // Game completion rewards
    if (reward.actionId == 'game_complete' && event is GameCompletionEvent) {
      return event.completed;
    }
    
    // Daily play bonus
    if (reward.actionId == 'daily_play') {
      // Check if this is the first play of the day
      final lastPlayDate = gameData['lastPlayDate'] as String?;
      final today = DateTime.now();
      
      if (lastPlayDate == null) return true;
      
      final lastPlay = DateTime.tryParse(lastPlayDate);
      if (lastPlay == null) return true;
      
      return !_isSameDay(lastPlay, today);
    }
    
    // Perfect score bonus
    if (reward.actionId == 'perfect_score') {
      final maxPossibleScore = conditions['max_score'] as int? ?? 100;
      final currentScore = gameData['score'] as int? ?? 0;
      return currentScore >= maxPossibleScore;
    }
    
    return false;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

/// Currency transaction record
class CurrencyTransaction {
  final int amount;
  final String reason;
  final DateTime timestamp;
  final int balanceAfter;

  const CurrencyTransaction({
    required this.amount,
    required this.reason,
    required this.timestamp,
    required this.balanceAfter,
  });

  bool get isEarning => amount > 0;
  bool get isSpending => amount < 0;
}

/// Currency statistics
class CurrencyStats {
  final int currentBalance;
  final int totalEarned;
  final int totalSpent;
  final int transactionCount;
  final int averageEarningPerTransaction;

  const CurrencyStats({
    required this.currentBalance,
    required this.totalEarned,
    required this.totalSpent,
    required this.transactionCount,
    required this.averageEarningPerTransaction,
  });

  int get netEarned => totalEarned - totalSpent;
  double get earningRate => transactionCount == 0 ? 0 : totalEarned / transactionCount;
}

/// Listener interface for currency updates
abstract class CurrencyUpdateListener {
  Future<void> onCurrencyUpdated(String childId, int amount, String reason);
}

/// Predefined achievement templates
class AchievementTemplates {
  static List<GameAchievement> getDefaultAchievements() {
    return [
      GameAchievement(
        id: 'first_play',
        name: 'Getting Started',
        description: 'Play your first game!',
        icon: Icons.play_arrow,
        virtualCurrencyReward: 10,
        criteria: {'type': 'sessions_played', 'value': 1},
      ),
      GameAchievement(
        id: 'score_100',
        name: 'Century Club',
        description: 'Reach a score of 100 points',
        icon: Icons.emoji_events,
        virtualCurrencyReward: 25,
        criteria: {'type': 'score_threshold', 'value': 100},
      ),
      GameAchievement(
        id: 'level_5',
        name: 'Level Master',
        description: 'Reach level 5',
        icon: Icons.trending_up,
        virtualCurrencyReward: 50,
        criteria: {'type': 'level_reached', 'value': 5},
      ),
      GameAchievement(
        id: 'play_30_minutes',
        name: 'Dedicated Player',
        description: 'Play for 30 minutes total',
        icon: Icons.access_time,
        virtualCurrencyReward: 30,
        criteria: {'type': 'total_play_time', 'value': 30},
      ),
      GameAchievement(
        id: 'daily_streak_7',
        name: 'Week Warrior',
        description: 'Play for 7 days in a row',
        icon: Icons.calendar_today,
        virtualCurrencyReward: 100,
        criteria: {'type': 'daily_play_streak', 'value': 7},
      ),
      GameAchievement(
        id: 'complete_game',
        name: 'Finisher',
        description: 'Complete a full game',
        icon: Icons.check_circle,
        virtualCurrencyReward: 75,
        criteria: {'type': 'game_completion'},
      ),
    ];
  }
}

/// Predefined currency reward templates
class CurrencyRewardTemplates {
  static List<VirtualCurrencyReward> getDefaultRewards() {
    return [
      VirtualCurrencyReward(
        actionId: 'score_increase',
        actionName: 'Score Increase',
        amount: 1,
        conditions: {'min_increase': 10},
      ),
      VirtualCurrencyReward(
        actionId: 'level_complete',
        actionName: 'Level Completed',
        amount: 5,
      ),
      VirtualCurrencyReward(
        actionId: 'achievement_unlock',
        actionName: 'Achievement Unlocked',
        amount: 10,
      ),
      VirtualCurrencyReward(
        actionId: 'game_complete',
        actionName: 'Game Completed',
        amount: 20,
      ),
      VirtualCurrencyReward(
        actionId: 'daily_play',
        actionName: 'Daily Play Bonus',
        amount: 15,
      ),
      VirtualCurrencyReward(
        actionId: 'perfect_score',
        actionName: 'Perfect Score Bonus',
        amount: 50,
        conditions: {'max_score': 100},
      ),
    ];
  }
}

/// Providers for Riverpod integration

final achievementManagerProvider = Provider<AchievementManager>((ref) {
  return AchievementManager();
});

final virtualCurrencyManagerProvider = Provider<VirtualCurrencyManager>((ref) {
  return VirtualCurrencyManager();
});

final childAchievementsProvider = FutureProvider.family<List<GameAchievement>, ({String gameId, String childId})>((ref, params) async {
  final manager = ref.read(achievementManagerProvider);
  return await manager.getUnlockedAchievements(params.gameId, params.childId);
});

final childCurrencyBalanceProvider = FutureProvider.family<int, String>((ref, childId) async {
  final manager = ref.read(virtualCurrencyManagerProvider);
  return await manager.getBalance(childId);
});

final achievementStatsProvider = FutureProvider.family<AchievementStats, ({String gameId, String childId})>((ref, params) async {
  final manager = ref.read(achievementManagerProvider);
  return await manager.getAchievementStats(params.gameId, params.childId);
});

final currencyStatsProvider = FutureProvider.family<CurrencyStats, String>((ref, childId) async {
  final manager = ref.read(virtualCurrencyManagerProvider);
  return await manager.getCurrencyStats(childId);
});