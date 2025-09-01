import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wonder_nest/core/services/api_service.dart';
import 'package:wonder_nest/models/story/enhanced_story_models.dart';
import 'package:wonder_nest/providers/auth_provider.dart';
import 'package:wonder_nest/core/services/timber_wrapper.dart';

/// Service for fetching and managing enhanced stories from the story builder
class EnhancedStoryService {
  final ApiService _apiService;

  EnhancedStoryService(this._apiService);

  /// Fetch all stories (drafts and published) for a child from game data
  Future<List<EnhancedStory>> getStoriesForChild(String childId) async {
    try {
      // Stories are saved as game data under the story_adventure game type
      // For now, always use the test child ID that the web app is using
      // TODO: In production, stories should be associated with actual child profiles
      const testChildId = '50cb1b31-bd85-4604-8cd1-efc1a73c9359';
      
      Timber.i('Fetching stories for child: $childId (using test ID: $testChildId)');
      
      final response = await _apiService.getGameData(
        testChildId,
        gameType: 'story_adventure',
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['gameData'] != null) {
          final gameDataList = responseData['gameData'] as List;
          final stories = <EnhancedStory>[];
          
          for (final gameData in gameDataList) {
          // Check if this is a story draft or published story
          final dataKey = gameData['dataKey'] as String?;
          if (dataKey != null && (dataKey.startsWith('story_draft_') || dataKey.startsWith('story_published_'))) {
            try {
              // Parse the story data from the game data value
              final dataValue = gameData['dataValue'];
              Map<String, dynamic> storyJson;
              
              if (dataValue != null && dataValue['data'] != null) {
                // Data is stored as JSON string in 'data' key
                final dataString = dataValue['data'];
                storyJson = dataString is String 
                    ? jsonDecode(dataString) as Map<String, dynamic>
                    : dataValue['data'] as Map<String, dynamic>;
              } else {
                // Fallback to direct dataValue
                storyJson = dataValue as Map<String, dynamic>? ?? {};
              }
              
              // Transform to EnhancedStory format
              final story = EnhancedStory(
                id: dataKey.replaceAll('story_draft_', '').replaceAll('story_published_', ''),
                title: storyJson['title'] ?? 'Untitled Story',
                description: storyJson['description'],
                content: storyJson['content'] != null 
                    ? StoryContent.fromJson(storyJson['content'])
                    : StoryContent(version: '1.0', pages: []),
                metadata: storyJson['metadata'] != null
                    ? StoryMetadata.fromJson(storyJson['metadata'])
                    : StoryMetadata(
                        targetAge: [4, 8],
                        educationalGoals: [],
                        estimatedReadTime: 60,
                        vocabularyList: [],
                      ),
                status: dataKey.startsWith('story_published_') ? 'published' : 'draft',
                pageCount: (storyJson['content']?['pages'] as List?)?.length ?? 0,
                lastModified: DateTime.parse(gameData['updatedAt'] ?? DateTime.now().toIso8601String()),
                createdAt: DateTime.parse(gameData['createdAt'] ?? DateTime.now().toIso8601String()),
                thumbnail: storyJson['thumbnail'],
                collaborators: (storyJson['collaborators'] as List?)?.cast<String>() ?? [],
                version: storyJson['version'] ?? 1,
              );
              
              stories.add(story);
              Timber.i('Loaded story: ${story.title} (${story.id})');
            } catch (e) {
              Timber.e('Error parsing story from game data: $e');
            }
          }
        }
          
          Timber.i('Fetched ${stories.length} stories from game data');
          return stories;
        }
      }
      
      return _getMockStories();
    } catch (e) {
      Timber.e('Error fetching stories from game data: $e');
      // Return mock data for development
      return _getMockStories();
    }
  }

  /// Fetch a specific story by ID
  Future<EnhancedStory?> getStoryById(String storyId) async {
    try {
      // For now, fetch all stories and find the specific one
      // In future, we could add a specific endpoint for this
      final stories = await getStoriesForChild('50cb1b31-bd85-4604-8cd1-efc1a73c9359');
      return stories.firstWhere(
        (story) => story.id == storyId,
        orElse: () => _getMockStory(),
      );
    } catch (e) {
      Timber.e('Error fetching story $storyId: $e');
      // Return mock story for development
      return _getMockStory();
    }
  }

  /// Track reading progress for a story
  Future<void> updateReadingProgress({
    required String storyId,
    required String childId,
    required int currentPage,
    required int totalPages,
    required int readingTimeSeconds,
  }) async {
    try {
      // TODO: Implement progress tracking via game data API
      // For now, just log the progress
      Timber.d('Updated reading progress for story $storyId - Page $currentPage/$totalPages');
    } catch (e) {
      Timber.e('Error updating reading progress: $e');
    }
  }

  /// Mark a story as completed
  Future<void> markStoryCompleted({
    required String storyId,
    required String childId,
    required int totalReadingTimeSeconds,
    required List<String> vocabularyEncountered,
  }) async {
    try {
      // TODO: Implement completion tracking via game data API
      // For now, just log the completion
      Timber.i('Story $storyId marked as completed - Reading time: ${totalReadingTimeSeconds}s');
    } catch (e) {
      Timber.e('Error marking story as completed: $e');
    }
  }

  /// Get mock stories for development
  List<EnhancedStory> _getMockStories() {
    return [
      _getMockStory(),
    ];
  }

  /// Create a mock story for development
  EnhancedStory _getMockStory() {
    return EnhancedStory(
      id: 'mock-story-1',
      title: 'The Brave Little Bunny',
      description: 'A story about courage and friendship',
      content: StoryContent(
        version: '1.0',
        pages: [
          EnhancedStoryPage(
            pageNumber: 1,
            background: 'https://via.placeholder.com/800x600/87CEEB/ffffff?text=Forest+Background',
            textBlocks: [
              TextBlock(
                id: 'text-1',
                position: Position(x: 100, y: 100),
                size: Size(width: 600, height: 100),
                variants: [
                  TextVariant(
                    id: 'variant-1',
                    content: 'Once upon a time, in a magical forest, there lived a brave little bunny named Benny.',
                    type: 'primary',
                    metadata: VariantMetadata(
                      targetAge: 6,
                      ageRange: [4, 8],
                      vocabularyDifficulty: 'simple',
                      vocabularyLevel: 3,
                      readingTime: 10,
                      wordCount: 15,
                      characterCount: 78,
                    ),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                  TextVariant(
                    id: 'variant-2',
                    content: 'In an enchanted woodland, a courageous rabbit named Benjamin made his home among the ancient trees.',
                    type: 'alternate',
                    metadata: VariantMetadata(
                      targetAge: 9,
                      ageRange: [7, 11],
                      vocabularyDifficulty: 'moderate',
                      vocabularyLevel: 5,
                      readingTime: 12,
                      wordCount: 16,
                      characterCount: 95,
                    ),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ],
                style: TextBlockStyle(
                  background: BackgroundStyle(
                    type: 'solid',
                    color: '#FFFFFF',
                    opacity: 0.9,
                    padding: BoxSpacing(top: 10, right: 15, bottom: 10, left: 15),
                    borderRadius: BorderRadius(
                      topLeft: 8,
                      topRight: 8,
                      bottomLeft: 8,
                      bottomRight: 8,
                    ),
                  ),
                  text: TextStyleConfig(
                    color: '#333333',
                    fontSize: 18,
                    fontWeight: 400,
                    textAlign: 'center',
                  ),
                ),
                vocabularyWords: ['brave', 'magical', 'forest'],
              ),
            ],
            popupImages: [],
          ),
          EnhancedStoryPage(
            pageNumber: 2,
            background: 'https://via.placeholder.com/800x600/90EE90/ffffff?text=Garden+Scene',
            textBlocks: [
              TextBlock(
                id: 'text-2',
                position: Position(x: 100, y: 400),
                size: Size(width: 600, height: 100),
                variants: [
                  TextVariant(
                    id: 'variant-3',
                    content: 'One day, Benny heard a cry for help coming from the garden.',
                    type: 'primary',
                    metadata: VariantMetadata(
                      targetAge: 6,
                      ageRange: [4, 8],
                      vocabularyDifficulty: 'simple',
                      vocabularyLevel: 3,
                      readingTime: 8,
                      wordCount: 11,
                      characterCount: 58,
                    ),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ],
                style: TextBlockStyle(
                  background: BackgroundStyle(
                    type: 'gradient',
                    gradient: GradientStyle(
                      type: 'linear',
                      colors: [
                        GradientStop(color: '#FFE4B5', position: 0),
                        GradientStop(color: '#FFDAB9', position: 100),
                      ],
                      angle: 45,
                    ),
                    opacity: 0.95,
                    padding: BoxSpacing(top: 12, right: 18, bottom: 12, left: 18),
                    borderRadius: BorderRadius(
                      topLeft: 12,
                      topRight: 12,
                      bottomLeft: 12,
                      bottomRight: 12,
                    ),
                  ),
                  text: TextStyleConfig(
                    color: '#2C3E50',
                    fontSize: 20,
                    fontWeight: 500,
                    textAlign: 'left',
                  ),
                ),
                vocabularyWords: ['garden', 'help'],
              ),
            ],
            popupImages: [
              PopupImage(
                id: 'img-1',
                triggerWord: 'bunny',
                imageUrl: 'https://via.placeholder.com/150x150/FFB6C1/000000?text=Bunny',
                position: Position(x: 325, y: 200),
                size: Size(width: 150, height: 150),
                rotation: 0,
                animation: 'fadeIn',
              ),
            ],
          ),
          EnhancedStoryPage(
            pageNumber: 3,
            background: 'https://via.placeholder.com/800x600/FFE4B5/000000?text=Happy+Ending',
            textBlocks: [
              TextBlock(
                id: 'text-3',
                position: Position(x: 100, y: 250),
                size: Size(width: 600, height: 100),
                variants: [
                  TextVariant(
                    id: 'variant-4',
                    content: 'Benny saved the day and made a new friend. They lived happily ever after!',
                    type: 'primary',
                    metadata: VariantMetadata(
                      targetAge: 6,
                      ageRange: [4, 8],
                      vocabularyDifficulty: 'simple',
                      vocabularyLevel: 3,
                      readingTime: 10,
                      wordCount: 13,
                      characterCount: 72,
                    ),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ],
                style: TextBlockStyle(
                  text: TextStyleConfig(
                    color: '#FF6B6B',
                    fontSize: 24,
                    fontWeight: 600,
                    textAlign: 'center',
                  ),
                  effects: TextEffects(
                    glow: GlowEffect(
                      color: '#FFD700',
                      radius: 10,
                      intensity: 0.5,
                    ),
                  ),
                ),
                vocabularyWords: ['friend', 'happily'],
              ),
            ],
            popupImages: [],
          ),
        ],
      ),
      metadata: StoryMetadata(
        targetAge: [4, 8],
        educationalGoals: ['vocabulary', 'courage', 'friendship'],
        estimatedReadTime: 180,
        vocabularyList: ['brave', 'magical', 'forest', 'garden', 'help', 'friend', 'happily'],
      ),
      status: 'published',
      pageCount: 3,
      lastModified: DateTime.now(),
      createdAt: DateTime.now(),
      thumbnail: 'https://via.placeholder.com/300x200/87CEEB/ffffff?text=Brave+Bunny',
      collaborators: [],
      version: 1,
    );
  }
}

/// Provider for the enhanced story service
final enhancedStoryServiceProvider = Provider<EnhancedStoryService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EnhancedStoryService(apiService);
});

/// Provider for fetching stories for a specific child
final childStoriesProvider = FutureProvider.family<List<EnhancedStory>, String>((ref, childId) async {
  final service = ref.watch(enhancedStoryServiceProvider);
  return service.getStoriesForChild(childId);
});

/// Provider for fetching a specific story
final storyProvider = FutureProvider.family<EnhancedStory?, String>((ref, storyId) async {
  final service = ref.watch(enhancedStoryServiceProvider);
  return service.getStoryById(storyId);
});