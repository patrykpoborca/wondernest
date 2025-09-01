import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/games/game_plugin.dart';
import '../../core/services/api_service.dart';
import '../../core/services/timber_wrapper.dart';
import '../../models/child_profile.dart';
import 'models/story_models.dart';
import 'services/story_adventure_service.dart';
import 'screens/story_selection_screen.dart';
import 'screens/enhanced_story_selection_screen.dart';

/// Story Adventure Plugin - Interactive storytelling for vocabulary and reading development
class StoryAdventurePlugin extends GamePlugin {
  StoryAdventureService? _service;
  bool _isInitialized = false;

  @override
  String get gameId => 'story-adventure';

  @override
  String get gameName => 'Story Adventure';

  @override
  String get gameDescription => 
      'Interactive storytelling that builds vocabulary, reading comprehension, and language skills through engaging narratives';

  @override
  String get gameVersion => '1.0.0';

  @override
  GameCategory get category => GameCategory.language;

  @override
  List<String> get educationalTopics => [
    'reading',
    'vocabulary',
    'comprehension', 
    'storytelling',
    'language_development',
  ];

  @override
  int get minAge => 3;

  @override
  int get maxAge => 12;

  @override
  int get estimatedPlayTimeMinutes => 15;

  @override
  bool get requiresParentApproval => false;

  @override
  bool get supportsOfflinePlay => true; // Stories can be downloaded

  @override
  IconData get gameIcon => Icons.menu_book;

  @override
  String? get thumbnailAssetPath => 'assets/games/story_adventure_thumbnail.png';

  @override
  String? get thumbnailUrl => null;

  @override
  Widget createGameWidget({
    required ChildProfile child,
    required GameSession session,
    required WidgetRef ref,
  }) {
    Timber.d('Creating Story Adventure game widget for child: ${child.id}');
    
    // Use the enhanced story selection screen to show web-created stories
    return EnhancedStorySelectionScreen(
      childProfile: child,
      gameSession: session,
    );
  }

  @override
  Widget? createSettingsWidget({
    required ChildProfile child,
    required WidgetRef ref,
  }) {
    // TODO: Create settings widget for Story Adventure preferences
    return null;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Timber.d('Initializing Story Adventure plugin...');
      
      // Note: We don't initialize the service here since we need API service from the app
      // The service will be initialized lazily when needed
      
      _isInitialized = true;
      Timber.d('Story Adventure plugin initialized successfully');
    } catch (e) {
      Timber.e('Failed to initialize Story Adventure plugin: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      Timber.d('Disposing Story Adventure plugin...');
      _service = null;
      _isInitialized = false;
    } catch (e) {
      Timber.e('Error disposing Story Adventure plugin: $e');
    }
  }

  @override
  bool isAppropriateForChild(ChildProfile child) {
    final ageInMonths = child.age * 12; // Convert years to months  
    return ageInMonths >= (minAge * 12) && ageInMonths <= (maxAge * 12);
  }

  @override
  Map<String, dynamic> getGameDataSchema() {
    return {
      'type': 'story-adventure',
      'version': '1.0.0',
      'dataKeys': {
        'progress': {
          'type': 'object',
          'description': 'Child progress in Story Adventure',
          'properties': {
            'storiesCompleted': {'type': 'integer'},
            'totalReadingTimeMinutes': {'type': 'integer'},
            'completedStoryIds': {'type': 'array', 'items': {'type': 'string'}},
            'vocabularyMastery': {'type': 'object'},
            'preferences': {'type': 'object'},
            'lastPlayed': {'type': 'string', 'format': 'date-time'},
          }
        },
        'story_instance': {
          'type': 'object',
          'description': 'Active story reading sessions',
          'properties': {
            'sessionId': {'type': 'string'},
            'templateId': {'type': 'string'},
            'currentPage': {'type': 'integer'},
            'isCompleted': {'type': 'boolean'},
            'startTime': {'type': 'string', 'format': 'date-time'},
            'wordsRead': {'type': 'integer'},
            'vocabularyEncounters': {'type': 'integer'},
          }
        },
        'vocabulary_progress': {
          'type': 'object',
          'description': 'Vocabulary learning progress',
          'properties': {
            'masteredWords': {'type': 'array', 'items': {'type': 'string'}},
            'wordEncounters': {'type': 'object'},
            'difficultyProgression': {'type': 'object'},
          }
        }
      }
    };
  }

  @override
  bool validateSaveData(Map<String, dynamic> data) {
    try {
      // Basic validation for Story Adventure save data
      if (!data.containsKey('type') || data['type'] != 'story-adventure') {
        return false;
      }

      // Validate progress data if present
      if (data.containsKey('progress')) {
        final progress = data['progress'] as Map<String, dynamic>;
        if (!progress.containsKey('storiesCompleted') || 
            !progress.containsKey('totalReadingTimeMinutes')) {
          return false;
        }
      }

      return true;
    } catch (e) {
      Timber.e('Error validating Story Adventure save data: $e');
      return false;
    }
  }

  @override
  Future<void> handleGameEvent(GameEvent event) async {
    try {
      Timber.d('Handling game event: ${event.eventType}');
      
      // Handle Story Adventure specific events
      switch (event.eventType) {
        case 'story_completed':
          await _handleStoryCompleted(event);
          break;
        case 'vocabulary_encountered':
          await _handleVocabularyEncounter(event);
          break;
        case 'reading_progress':
          await _handleReadingProgress(event);
          break;
        default:
          Timber.d('Unhandled event type: ${event.eventType}');
      }
    } catch (e) {
      Timber.e('Error handling game event: $e');
    }
  }

  @override
  List<GameAchievement> getAvailableAchievements() {
    return [
      GameAchievement(
        id: 'first_story',
        name: 'First Adventure',
        description: 'Complete your first story!',
        icon: Icons.auto_stories,
        virtualCurrencyReward: 50,
        criteria: {'storiesCompleted': 1},
      ),
      GameAchievement(
        id: 'vocabulary_master',
        name: 'Word Explorer', 
        description: 'Learn 20 new vocabulary words',
        icon: Icons.school,
        virtualCurrencyReward: 100,
        criteria: {'vocabularyWordsLearned': 20},
      ),
      GameAchievement(
        id: 'speed_reader',
        name: 'Speed Reader',
        description: 'Complete 5 stories in one week',
        icon: Icons.flash_on,
        virtualCurrencyReward: 150,
        criteria: {'storiesPerWeek': 5},
      ),
      GameAchievement(
        id: 'library_card',
        name: 'Library Card',
        description: 'Spend 60 minutes reading stories',
        icon: Icons.library_books,
        virtualCurrencyReward: 75,
        criteria: {'totalReadingMinutes': 60},
      ),
    ];
  }

  @override
  List<VirtualCurrencyReward> getVirtualCurrencyRewards() {
    return [
      VirtualCurrencyReward(
        actionId: 'complete_story',
        actionName: 'Complete a story',
        amount: 25,
        conditions: {'storyCompleted': true},
      ),
      VirtualCurrencyReward(
        actionId: 'vocabulary_correct',
        actionName: 'Correctly identify vocabulary word',
        amount: 5,
        conditions: {'vocabularyInteraction': 'correct'},
      ),
      VirtualCurrencyReward(
        actionId: 'reading_time',
        actionName: 'Reading time bonus',
        amount: 1,
        conditions: {'perMinuteReading': true},
      ),
      VirtualCurrencyReward(
        actionId: 'daily_reading',
        actionName: 'Daily reading streak',
        amount: 15,
        conditions: {'consecutiveDaysReading': 1},
      ),
    ];
  }

  /// Get the Story Adventure service (lazy initialization)
  StoryAdventureService getService(ApiService apiService) {
    _service ??= StoryAdventureService(apiService);
    return _service!;
  }

  /// Handle story completion event
  Future<void> _handleStoryCompleted(GameEvent event) async {
    // Record achievement progress
    // Update child progress data
    // Award virtual currency
    Timber.d('Story completed for child ${event.childId}');
  }

  /// Handle vocabulary encounter event  
  Future<void> _handleVocabularyEncounter(GameEvent event) async {
    // Track vocabulary learning
    // Update mastery levels
    // Award points for correct interactions
    Timber.d('Vocabulary encounter recorded for child ${event.childId}');
  }

  /// Handle reading progress event
  Future<void> _handleReadingProgress(GameEvent event) async {
    // Update reading statistics
    // Track time spent reading
    // Monitor comprehension progress
    Timber.d('Reading progress updated for child ${event.childId}');
  }
}

/// Riverpod provider for the Story Adventure plugin instance
final storyAdventurePluginProvider = Provider<StoryAdventurePlugin>((ref) {
  return StoryAdventurePlugin();
});

/// Provider for the Story Adventure service
final storyAdventureServiceProvider = Provider<StoryAdventureService>((ref) {
  final plugin = ref.watch(storyAdventurePluginProvider);
  final apiService = ApiService(); // Use singleton instance
  return plugin.getService(apiService);
});