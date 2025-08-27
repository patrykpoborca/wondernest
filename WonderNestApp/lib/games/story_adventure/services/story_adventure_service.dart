import '../../../core/services/timber_wrapper.dart';
import '../../../core/services/api_service.dart';
import '../models/story_models.dart';

/// Service for interacting with Story Adventure backend
class StoryAdventureService {
  final ApiService _apiService;

  StoryAdventureService(this._apiService);

  /// Get available story templates for a child
  Future<List<StoryTemplate>> getAvailableStories({
    String? ageGroup,
    String? difficulty,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      Timber.d('Fetching available stories for child');
      
      // For now, return sample stories since we need to work with the existing API patterns
      // TODO: Implement proper API integration when Story Adventure backend endpoints are integrated
      return _getSampleStories();
    } catch (e) {
      Timber.e('Error fetching story templates: $e');
      // Return sample stories for offline/mock mode
      return _getSampleStories();
    }
  }

  /// Get specific story template by ID
  Future<StoryTemplate?> getStoryTemplate(String templateId) async {
    try {
      Timber.d('Fetching story template: $templateId');
      
      // For now, return sample story if it matches
      if (templateId.startsWith('sample-story')) {
        return StoryTemplate.createSample(id: templateId);
      }
      return null;
    } catch (e) {
      Timber.e('Error fetching story template $templateId: $e');
      return null;
    }
  }

  /// Initialize Story Adventure for a child using the plugin architecture
  Future<bool> initializeForChild(String childId) async {
    try {
      Timber.d('Initializing Story Adventure for child: $childId');
      
      // Use existing saveGameEvent method to initialize
      await _apiService.saveGameEvent({
        'gameType': 'story-adventure',
        'eventType': 'initialize',
        'childId': childId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      Timber.e('Error initializing Story Adventure for child $childId: $e');
      return false;
    }
  }

  /// Get child's Story Adventure data (follows plugin architecture)
  Future<StoryAdventureProgress?> getChildProgress(String childId) async {
    try {
      Timber.d('Fetching Story Adventure progress for child: $childId');
      
      final response = await _apiService.getChildGameData(childId);
      final data = response.data['data'] ?? response.data;
      
      // Look for story adventure progress in the game data
      if (data != null && data is Map<String, dynamic> && data.containsKey('story_adventure_progress')) {
        return StoryAdventureProgress.fromJson(data['story_adventure_progress'] as Map<String, dynamic>);
      }
      
      // Return initial progress if none found
      return StoryAdventureProgress.initial(childId);
    } catch (e) {
      Timber.e('Error fetching child progress: $e');
      return StoryAdventureProgress.initial(childId);
    }
  }

  /// Start a new story reading session
  Future<StorySession?> startStory({
    required String childId,
    required String templateId,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      Timber.d('Starting story session for child $childId, template $templateId');
      
      // Save game event for story start
      await _apiService.saveGameEvent({
        'gameType': 'story-adventure',
        'eventType': 'story_started',
        'childId': childId,
        'templateId': templateId,
        'customizations': customizations ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Return mock session
      return StorySession(
        sessionId: 'session-${DateTime.now().millisecondsSinceEpoch}',
        childId: childId,
        templateId: templateId,
        currentPage: 1,
        isCompleted: false,
        startTime: DateTime.now(),
        wordsRead: 0,
        vocabularyEncounters: 0,
      );
    } catch (e) {
      Timber.e('Error starting story session: $e');
      // Return mock session for offline mode
      return StorySession(
        sessionId: 'mock-session-${DateTime.now().millisecondsSinceEpoch}',
        childId: childId,
        templateId: templateId,
        currentPage: 1,
        isCompleted: false,
        startTime: DateTime.now(),
        wordsRead: 0,
        vocabularyEncounters: 0,
      );
    }
  }

  /// Update reading progress
  Future<bool> updateProgress({
    required String childId,
    required String sessionId,
    required int currentPage,
    int? wordsRead,
    int? vocabularyEncounters,
  }) async {
    try {
      Timber.d('Updating story progress for child $childId');
      
      // Save progress event
      await _apiService.saveGameEvent({
        'gameType': 'story-adventure',
        'eventType': 'progress_update',
        'childId': childId,
        'sessionId': sessionId,
        'currentPage': currentPage,
        'wordsRead': wordsRead,
        'vocabularyEncounters': vocabularyEncounters,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      Timber.e('Error updating story progress: $e');
      return false; // Fail silently in offline mode
    }
  }

  /// Complete a story reading session
  Future<bool> completeStory({
    required String sessionId,
    required int finalPage,
    required Duration readingTime,
    Map<String, dynamic>? completionData,
  }) async {
    try {
      Timber.d('Completing story session: $sessionId');
      
      await _apiService.saveGameEvent({
        'gameType': 'story-adventure',
        'eventType': 'story_completed',
        'sessionId': sessionId,
        'finalPage': finalPage,
        'readingTimeMinutes': readingTime.inMinutes,
        'completionData': completionData ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      Timber.e('Error completing story session: $e');
      return false;
    }
  }

  /// Record vocabulary word encounter
  Future<bool> recordVocabularyEncounter({
    required String childId,
    required String word,
    String? templateId,
    String interactionType = 'encountered',
  }) async {
    try {
      Timber.d('Recording vocabulary encounter for child $childId: $word');
      
      await _apiService.saveGameEvent({
        'gameType': 'story-adventure',
        'eventType': 'vocabulary_encounter',
        'childId': childId,
        'word': word,
        'templateId': templateId,
        'interactionType': interactionType,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      Timber.e('Error recording vocabulary encounter: $e');
      return false;
    }
  }

  /// Update child preferences
  Future<bool> updatePreferences({
    required String childId,
    required ReadingPreferences preferences,
  }) async {
    try {
      Timber.d('Updating Story Adventure preferences for child $childId');
      
      await _apiService.saveGameEvent({
        'gameType': 'story-adventure',
        'eventType': 'preferences_update',
        'childId': childId,
        'preferences': preferences.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      Timber.e('Error updating preferences: $e');
      return false;
    }
  }

  /// Get child's progress report
  Future<Map<String, dynamic>?> getProgressReport(String childId) async {
    try {
      Timber.d('Fetching progress report for child: $childId');
      
      // For now, return a simple mock report
      return {
        'childId': childId,
        'storiesCompleted': 0,
        'totalReadingTime': 0,
        'vocabularyWordsLearned': 0,
        'averageSessionLength': 0,
      };
    } catch (e) {
      Timber.e('Error fetching progress report: $e');
      return null;
    }
  }

  /// Get sample stories for offline/demo mode
  List<StoryTemplate> _getSampleStories() {
    return [
      StoryTemplate.createSample(
        id: 'sample-story',
        title: 'The Magic Garden',
        description: 'A story about a magical garden where flowers sing and butterflies paint',
      ),
      StoryTemplate.createSample(
        id: 'sample-story-2',
        title: 'The Friendly Dragon',
        description: 'A tale about a dragon who loves to bake cookies and make friends',
      ),
      StoryTemplate.createSample(
        id: 'sample-story-3', 
        title: 'The Curious Cat',
        description: 'An adventure of a cat who discovers a world inside a library book',
      ),
    ];
  }
}