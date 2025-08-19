import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import 'game_plugin.dart';

/// Manages local persistence and cloud sync for game data
class GamePersistenceManager {
  static const String _gameDataBoxName = 'game_data';
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _achievementsBoxName = 'achievements';
  static const String _virtualCurrencyBoxName = 'virtual_currency';
  
  static final GamePersistenceManager _instance = GamePersistenceManager._internal();
  factory GamePersistenceManager() => _instance;
  GamePersistenceManager._internal();

  late Box<Map<dynamic, dynamic>> _gameDataBox;
  late Box<Map<dynamic, dynamic>> _syncQueueBox;
  late Box<Map<dynamic, dynamic>> _achievementsBox;
  late Box<Map<dynamic, dynamic>> _virtualCurrencyBox;

  ApiService? _apiService;
  bool _initialized = false;
  bool _syncInProgress = false;

  /// Initialize the persistence manager
  Future<void> initialize({ApiService? apiService}) async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();
      
      _gameDataBox = await Hive.openBox<Map<dynamic, dynamic>>(_gameDataBoxName);
      _syncQueueBox = await Hive.openBox<Map<dynamic, dynamic>>(_syncQueueBoxName);
      _achievementsBox = await Hive.openBox<Map<dynamic, dynamic>>(_achievementsBoxName);
      _virtualCurrencyBox = await Hive.openBox<Map<dynamic, dynamic>>(_virtualCurrencyBoxName);

      _apiService = apiService;
      _initialized = true;

      // Start periodic sync
      _startPeriodicSync();

      debugPrint('GamePersistenceManager initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize GamePersistenceManager: $e');
      rethrow;
    }
  }

  /// Save game data locally
  Future<void> saveGameData(String gameId, String childId, Map<String, dynamic> data) async {
    _ensureInitialized();
    
    final key = '${gameId}_$childId';
    final gameData = {
      'gameId': gameId,
      'childId': childId,
      'data': data,
      'lastModified': DateTime.now().toIso8601String(),
      'synced': false,
    };

    await _gameDataBox.put(key, gameData);
    
    // Queue for sync
    await _queueForSync('game_data', gameData);
    
    debugPrint('Saved game data for $gameId (child: $childId)');
  }

  /// Load game data locally
  Future<Map<String, dynamic>?> loadGameData(String gameId, String childId) async {
    _ensureInitialized();
    
    final key = '${gameId}_$childId';
    final gameData = _gameDataBox.get(key);
    
    if (gameData != null) {
      return Map<String, dynamic>.from(gameData['data'] ?? {});
    }
    
    return null;
  }

  /// Save game event to sync queue
  Future<void> saveGameEvent(GameEvent event) async {
    _ensureInitialized();
    
    final eventData = {
      'event': event.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    };

    final key = '${event.gameId}_${event.sessionId}_${event.timestamp.millisecondsSinceEpoch}';
    await _syncQueueBox.put(key, eventData);
    
    debugPrint('Queued game event: ${event.eventType}');
  }

  /// Save achievement unlock
  Future<void> saveAchievementUnlock(String gameId, String childId, GameAchievement achievement) async {
    _ensureInitialized();
    
    final key = '${gameId}_${childId}_${achievement.id}';
    final achievementData = {
      'gameId': gameId,
      'childId': childId,
      'achievement': achievement.toJson(),
      'unlockedAt': DateTime.now().toIso8601String(),
      'synced': false,
    };

    await _achievementsBox.put(key, achievementData);
    await _queueForSync('achievement', achievementData);
    
    debugPrint('Saved achievement unlock: ${achievement.name}');
  }

  /// Load achievements for a child and game
  Future<List<GameAchievement>> loadAchievements(String gameId, String childId) async {
    _ensureInitialized();
    
    final achievements = <GameAchievement>[];
    
    for (final key in _achievementsBox.keys) {
      final data = _achievementsBox.get(key);
      if (data != null && 
          data['gameId'] == gameId && 
          data['childId'] == childId) {
        try {
          final achievement = GameAchievement.fromJson(
            Map<String, dynamic>.from(data['achievement'])
          );
          achievements.add(achievement);
        } catch (e) {
          debugPrint('Error loading achievement from $key: $e');
        }
      }
    }
    
    return achievements;
  }

  /// Update virtual currency
  Future<void> updateVirtualCurrency(String childId, int amount, String reason) async {
    _ensureInitialized();
    
    final key = childId;
    final currentData = _virtualCurrencyBox.get(key) ?? {'balance': 0, 'transactions': []};
    
    final currentBalance = currentData['balance'] as int? ?? 0;
    final newBalance = currentBalance + amount;
    
    final transaction = {
      'amount': amount,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
      'balanceAfter': newBalance,
    };
    
    final transactions = List<Map<dynamic, dynamic>>.from(currentData['transactions'] ?? []);
    transactions.add(transaction);
    
    final updatedData = {
      'childId': childId,
      'balance': newBalance,
      'transactions': transactions,
      'lastModified': DateTime.now().toIso8601String(),
      'synced': false,
    };
    
    await _virtualCurrencyBox.put(key, updatedData);
    await _queueForSync('virtual_currency', updatedData);
    
    debugPrint('Updated virtual currency for $childId: $amount ($reason)');
  }

  /// Get virtual currency balance
  Future<int> getVirtualCurrencyBalance(String childId) async {
    _ensureInitialized();
    
    final data = _virtualCurrencyBox.get(childId);
    return data?['balance'] as int? ?? 0;
  }

  /// Get virtual currency transaction history
  Future<List<Map<String, dynamic>>> getVirtualCurrencyTransactions(String childId) async {
    _ensureInitialized();
    
    final data = _virtualCurrencyBox.get(childId);
    final transactions = data?['transactions'] as List<dynamic>? ?? [];
    
    return transactions
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
  }

  /// Sync all pending data with the server
  Future<void> syncToServer() async {
    if (_syncInProgress || _apiService == null) return;
    
    _syncInProgress = true;
    
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        debugPrint('No internet connection, sync skipped');
        return;
      }

      await _syncGameData();
      await _syncGameEvents();
      await _syncAchievements();
      await _syncVirtualCurrency();
      
      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      _syncInProgress = false;
    }
  }

  /// Load initial data from server
  Future<void> loadFromServer(String childId) async {
    if (_apiService == null) return;
    
    try {
      // Load game progress data
      final response = await _apiService.getChildGameData(childId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final serverData = response.data['data'] as Map<String, dynamic>;
        
        // Merge server data with local data
        await _mergeServerGameData(serverData);
      }
      
      debugPrint('Loaded game data from server for child: $childId');
    } catch (e) {
      debugPrint('Failed to load data from server: $e');
    }
  }

  /// Clear all local data for a child
  Future<void> clearChildData(String childId) async {
    _ensureInitialized();
    
    // Clear game data
    final gameDataKeysToRemove = <String>[];
    for (final key in _gameDataBox.keys) {
      final data = _gameDataBox.get(key);
      if (data != null && data['childId'] == childId) {
        gameDataKeysToRemove.add(key.toString());
      }
    }
    
    for (final key in gameDataKeysToRemove) {
      await _gameDataBox.delete(key);
    }
    
    // Clear achievements
    final achievementKeysToRemove = <String>[];
    for (final key in _achievementsBox.keys) {
      final data = _achievementsBox.get(key);
      if (data != null && data['childId'] == childId) {
        achievementKeysToRemove.add(key.toString());
      }
    }
    
    for (final key in achievementKeysToRemove) {
      await _achievementsBox.delete(key);
    }
    
    // Clear virtual currency
    await _virtualCurrencyBox.delete(childId);
    
    debugPrint('Cleared all data for child: $childId');
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    _ensureInitialized();
    
    final unsyncedGameData = _gameDataBox.values
        .where((data) => data['synced'] != true)
        .length;
    
    final unsyncedEvents = _syncQueueBox.values
        .where((data) => data['synced'] != true)
        .length;
    
    final unsyncedAchievements = _achievementsBox.values
        .where((data) => data['synced'] != true)
        .length;
    
    final unsyncedCurrency = _virtualCurrencyBox.values
        .where((data) => data['synced'] != true)
        .length;
    
    return {
      'unsyncedGameData': unsyncedGameData,
      'unsyncedEvents': unsyncedEvents,
      'unsyncedAchievements': unsyncedAchievements,
      'unsyncedCurrency': unsyncedCurrency,
      'totalUnsynced': unsyncedGameData + unsyncedEvents + unsyncedAchievements + unsyncedCurrency,
    };
  }

  /// Private methods

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('GamePersistenceManager not initialized');
    }
  }

  Future<void> _queueForSync(String type, Map<String, dynamic> data) async {
    final syncItem = {
      'type': type,
      'data': data,
      'queuedAt': DateTime.now().toIso8601String(),
      'synced': false,
    };
    
    final key = '${type}_${DateTime.now().millisecondsSinceEpoch}';
    await _syncQueueBox.put(key, syncItem);
  }

  void _startPeriodicSync() {
    // Start a periodic sync every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      syncToServer();
    });
  }

  Future<void> _syncGameData() async {
    if (_apiService == null) return;
    
    final unsyncedItems = <String, Map<dynamic, dynamic>>{};
    
    for (final key in _gameDataBox.keys) {
      final data = _gameDataBox.get(key);
      if (data != null && data['synced'] != true) {
        unsyncedItems[key.toString()] = data;
      }
    }
    
    for (final entry in unsyncedItems.entries) {
      try {
        await _apiService.saveGameProgress(
          gameId: entry.value['gameId'],
          childId: entry.value['childId'],
          score: entry.value['data']['score'] ?? 0,
          level: entry.value['data']['level'] ?? 1,
          playTimeMinutes: entry.value['data']['playTimeMinutes'] ?? 0,
        );
        
        // Mark as synced
        final updatedData = Map<dynamic, dynamic>.from(entry.value);
        updatedData['synced'] = true;
        await _gameDataBox.put(entry.key, updatedData);
        
      } catch (e) {
        debugPrint('Failed to sync game data ${entry.key}: $e');
      }
    }
  }

  Future<void> _syncGameEvents() async {
    if (_apiService == null) return;
    
    final unsyncedItems = <String, Map<dynamic, dynamic>>{};
    
    for (final key in _syncQueueBox.keys) {
      final data = _syncQueueBox.get(key);
      if (data != null && data['synced'] != true) {
        unsyncedItems[key.toString()] = data;
      }
    }
    
    for (final entry in unsyncedItems.entries) {
      try {
        await _apiService.saveGameEvent(
          Map<String, dynamic>.from(entry.value['event'])
        );
        
        // Mark as synced
        final updatedData = Map<dynamic, dynamic>.from(entry.value);
        updatedData['synced'] = true;
        await _syncQueueBox.put(entry.key, updatedData);
        
      } catch (e) {
        debugPrint('Failed to sync game event ${entry.key}: $e');
      }
    }
  }

  Future<void> _syncAchievements() async {
    if (_apiService == null) return;
    
    final unsyncedItems = <String, Map<dynamic, dynamic>>{};
    
    for (final key in _achievementsBox.keys) {
      final data = _achievementsBox.get(key);
      if (data != null && data['synced'] != true) {
        unsyncedItems[key.toString()] = data;
      }
    }
    
    for (final entry in unsyncedItems.entries) {
      try {
        await _apiService.unlockAchievement(
          gameId: entry.value['gameId'],
          childId: entry.value['childId'],
          achievementId: entry.value['achievement']['id'],
        );
        
        // Mark as synced
        final updatedData = Map<dynamic, dynamic>.from(entry.value);
        updatedData['synced'] = true;
        await _achievementsBox.put(entry.key, updatedData);
        
      } catch (e) {
        debugPrint('Failed to sync achievement ${entry.key}: $e');
      }
    }
  }

  Future<void> _syncVirtualCurrency() async {
    if (_apiService == null) return;
    
    final unsyncedItems = <String, Map<dynamic, dynamic>>{};
    
    for (final key in _virtualCurrencyBox.keys) {
      final data = _virtualCurrencyBox.get(key);
      if (data != null && data['synced'] != true) {
        unsyncedItems[key.toString()] = data;
      }
    }
    
    for (final entry in unsyncedItems.entries) {
      try {
        await _apiService.updateVirtualCurrency(
          childId: entry.value['childId'],
          balance: entry.value['balance'],
          transactions: List<Map<String, dynamic>>.from(
            entry.value['transactions'] ?? []
          ),
        );
        
        // Mark as synced
        final updatedData = Map<dynamic, dynamic>.from(entry.value);
        updatedData['synced'] = true;
        await _virtualCurrencyBox.put(entry.key, updatedData);
        
      } catch (e) {
        debugPrint('Failed to sync virtual currency ${entry.key}: $e');
      }
    }
  }

  Future<void> _mergeServerGameData(Map<String, dynamic> serverData) async {
    // Implement merge logic for server data
    // This would handle conflicts between local and server data
    
    final gameProgress = serverData['gameProgress'] as List<dynamic>? ?? [];
    
    for (final progress in gameProgress) {
      final gameId = progress['gameId'] as String;
      final childId = progress['childId'] as String;
      final key = '${gameId}_$childId';
      
      final localData = _gameDataBox.get(key);
      final serverTimestamp = DateTime.tryParse(progress['lastModified'] ?? '');
      
      if (localData == null || 
          (serverTimestamp != null && 
           DateTime.parse(localData['lastModified']).isBefore(serverTimestamp))) {
        
        // Server data is newer, use it
        await _gameDataBox.put(key, {
          'gameId': gameId,
          'childId': childId,
          'data': progress['data'] ?? {},
          'lastModified': progress['lastModified'],
          'synced': true,
        });
      }
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (!_initialized) return;
    
    await _gameDataBox.close();
    await _syncQueueBox.close();
    await _achievementsBox.close();
    await _virtualCurrencyBox.close();
    
    _initialized = false;
  }
}

