import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_model.dart';
import '../models/family_member.dart';
import 'family_provider.dart';

// Content API service provider
final contentApiServiceProvider = Provider<ContentApiService>((ref) {
  return ContentApiService();
});

// Search query provider
final contentSearchQueryProvider = StateProvider<String>((ref) => '');

// Content type filter provider
final contentTypeFilterProvider = StateProvider<ContentType?>((ref) => null);

// Content category filter provider
final contentCategoryFilterProvider =
    StateProvider<List<ContentCategory>>((ref) => []);

// View mode provider (grid vs list)
final contentViewModeProvider = StateProvider<ContentViewMode>((ref) => ContentViewMode.grid);

enum ContentViewMode { grid, list }

// Content filter settings provider
final contentFilterProvider =
    StateNotifierProvider<ContentFilterNotifier, ContentFilter>((ref) {
  return ContentFilterNotifier();
});

class ContentFilterNotifier extends StateNotifier<ContentFilter> {
  ContentFilterNotifier() : super(ContentFilter());

  void updateAllowedTypes(List<ContentType> types) {
    state = state.copyWith(allowedTypes: types);
  }

  void updateAgeRange(int minAge, int maxAge) {
    state = state.copyWith(minAge: minAge, maxAge: maxAge);
  }

  void updateMaxRating(ContentRating rating) {
    state = state.copyWith(maxRating: rating);
  }

  void toggleCategory(ContentCategory category, bool isBlocked) {
    final blockedCategories = [...state.blockedCategories];
    if (isBlocked) {
      if (!blockedCategories.contains(category)) {
        blockedCategories.add(category);
      }
    } else {
      blockedCategories.remove(category);
    }
    state = state.copyWith(blockedCategories: blockedCategories);
  }

  void blockContent(String contentId) {
    final blockedIds = [...state.blockedContentIds, contentId];
    state = state.copyWith(blockedContentIds: blockedIds);
  }

  void unblockContent(String contentId) {
    final blockedIds = state.blockedContentIds
        .where((id) => id != contentId)
        .toList();
    state = state.copyWith(blockedContentIds: blockedIds);
  }

  void setRequireEducational(bool require) {
    state = state.copyWith(requireEducational: require);
  }

  void setMaxDuration(int? minutes) {
    state = state.copyWith(maxDurationMinutes: minutes);
  }

  void reset() {
    state = ContentFilter();
  }
}

// Content library notifier
class ContentLibraryNotifier extends AsyncNotifier<List<ContentModel>> {
  @override
  Future<List<ContentModel>> build() async {
    return await _fetchContent();
  }

  Future<List<ContentModel>> _fetchContent() async {
    final service = ref.read(contentApiServiceProvider);
    final searchQuery = ref.read(contentSearchQueryProvider);
    final typeFilter = ref.read(contentTypeFilterProvider);
    final categoryFilters = ref.read(contentCategoryFilterProvider);
    final contentFilter = ref.read(contentFilterProvider);
    final selectedChild = ref.read(selectedChildProvider);

    final allContent = await service.getContentLibrary(
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      type: typeFilter,
      categories: categoryFilters.isEmpty ? null : categoryFilters,
    );

    // Apply content filter
    final filteredContent = allContent.where((content) {
      // Apply general filter
      if (!contentFilter.isContentAllowed(content)) {
        return false;
      }

      // Apply child-specific age filter if a child is selected
      if (selectedChild != null && selectedChild.age != null) {
        if (!content.isAppropriateForAge(selectedChild.age!)) {
          return false;
        }
      }

      return true;
    }).toList();

    return filteredContent;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchContent();
    });
  }

  Future<void> toggleFavorite(String contentId) async {
    final service = ref.read(contentApiServiceProvider);
    await service.toggleFavorite(contentId);
    
    // Update the specific content item
    state.whenData((contents) {
      final updatedContents = contents.map((content) {
        if (content.id == contentId) {
          return content.copyWith(isFavorite: !content.isFavorite);
        }
        return content;
      }).toList();
      state = AsyncValue.data(updatedContents);
    });
  }

  Future<void> search(String query) async {
    ref.read(contentSearchQueryProvider.notifier).state = query;
    await refresh();
  }

  void filterByType(ContentType? type) {
    ref.read(contentTypeFilterProvider.notifier).state = type;
    refresh();
  }

  void filterByCategories(List<ContentCategory> categories) {
    ref.read(contentCategoryFilterProvider.notifier).state = categories;
    refresh();
  }
}

// Content library provider
final contentLibraryProvider =
    AsyncNotifierProvider<ContentLibraryNotifier, List<ContentModel>>(() {
  return ContentLibraryNotifier();
});

// Favorite content provider
final favoriteContentProvider = FutureProvider<List<ContentModel>>((ref) async {
  final allContent = await ref.watch(contentLibraryProvider.future);
  return allContent.where((content) => content.isFavorite).toList();
});

// Recently watched content provider
final recentlyWatchedProvider = FutureProvider<List<ContentModel>>((ref) async {
  final allContent = await ref.watch(contentLibraryProvider.future);
  final recentContent = allContent
      .where((content) => content.lastWatched != null)
      .toList()
    ..sort((a, b) => b.lastWatched!.compareTo(a.lastWatched!));
  return recentContent.take(10).toList();
});

// Mock Content API Service
class ContentApiService {
  // Simulated database
  static final List<ContentModel> _mockContent = _generateMockContent();

  Future<List<ContentModel>> getContentLibrary({
    String? searchQuery,
    ContentType? type,
    List<ContentCategory>? categories,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    var content = [..._mockContent];

    // Apply filters
    if (searchQuery != null && searchQuery.isNotEmpty) {
      content = content
          .where((c) =>
              c.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              c.description.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    if (type != null) {
      content = content.where((c) => c.type == type).toList();
    }

    if (categories != null && categories.isNotEmpty) {
      content = content
          .where((c) => c.categories.any((cat) => categories.contains(cat)))
          .toList();
    }

    return content;
  }

  Future<void> toggleFavorite(String contentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _mockContent.indexWhere((c) => c.id == contentId);
    if (index != -1) {
      _mockContent[index] = _mockContent[index].copyWith(
        isFavorite: !_mockContent[index].isFavorite,
      );
    }
  }

  Future<void> updateProgress(String contentId, double progress) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final index = _mockContent.indexWhere((c) => c.id == contentId);
    if (index != -1) {
      _mockContent[index] = _mockContent[index].copyWith(
        progress: progress,
        lastWatched: DateTime.now(),
      );
    }
  }

  static List<ContentModel> _generateMockContent() {
    return [
      ContentModel(
        id: 'content_001',
        title: 'Learn ABCs with Fun Animals',
        description: 'An interactive video teaching the alphabet with animated animals',
        type: ContentType.video,
        thumbnailUrl: 'https://picsum.photos/seed/abc/400/225',
        contentUrl: 'https://example.com/abc-video.mp4',
        durationMinutes: 15,
        rating: ContentRating.preschool,
        categories: [ContentCategory.educational, ContentCategory.language],
        tags: ['alphabet', 'animals', 'preschool'],
        minAge: 3,
        maxAge: 5,
        rating_score: 4.8,
        viewCount: 15000,
        creator: 'KidsLearnHub',
        educationalTopics: ['Alphabet', 'Animal Names', 'Phonics'],
      ),
      ContentModel(
        id: 'content_002',
        title: 'Math Adventure: Numbers 1-10',
        description: 'Learn counting and basic math through exciting adventures',
        type: ContentType.game,
        thumbnailUrl: 'https://picsum.photos/seed/math/400/225',
        contentUrl: 'https://example.com/math-game',
        durationMinutes: 20,
        rating: ContentRating.preschool,
        categories: [ContentCategory.educational, ContentCategory.math],
        tags: ['counting', 'numbers', 'math'],
        minAge: 4,
        maxAge: 6,
        rating_score: 4.6,
        viewCount: 8500,
        creator: 'MathWizards',
        educationalTopics: ['Counting', 'Number Recognition', 'Basic Addition'],
      ),
      ContentModel(
        id: 'content_003',
        title: 'The Magic Forest Story',
        description: 'A magical bedtime story about friendship and adventure',
        type: ContentType.audio,
        thumbnailUrl: 'https://picsum.photos/seed/story/400/225',
        contentUrl: 'https://example.com/magic-forest.mp3',
        durationMinutes: 12,
        rating: ContentRating.all,
        categories: [ContentCategory.stories, ContentCategory.entertainment],
        tags: ['bedtime', 'story', 'adventure'],
        minAge: 3,
        maxAge: 8,
        rating_score: 4.9,
        viewCount: 22000,
        isFavorite: true,
        creator: 'StoryTime',
        lastWatched: DateTime.now().subtract(const Duration(days: 2)),
        progress: 0.75,
      ),
      ContentModel(
        id: 'content_004',
        title: 'Science Experiments for Kids',
        description: 'Safe and fun science experiments you can do at home',
        type: ContentType.video,
        thumbnailUrl: 'https://picsum.photos/seed/science/400/225',
        contentUrl: 'https://example.com/science-experiments.mp4',
        durationMinutes: 25,
        rating: ContentRating.elementary,
        categories: [ContentCategory.educational, ContentCategory.science],
        tags: ['experiments', 'science', 'STEM'],
        minAge: 6,
        maxAge: 10,
        rating_score: 4.7,
        viewCount: 18000,
        creator: 'ScienceKids',
        educationalTopics: ['Chemistry', 'Physics', 'Scientific Method'],
      ),
      ContentModel(
        id: 'content_005',
        title: 'Yoga for Kids',
        description: 'Fun yoga exercises designed specially for children',
        type: ContentType.video,
        thumbnailUrl: 'https://picsum.photos/seed/yoga/400/225',
        contentUrl: 'https://example.com/kids-yoga.mp4',
        durationMinutes: 18,
        rating: ContentRating.all,
        categories: [ContentCategory.physical, ContentCategory.educational],
        tags: ['exercise', 'yoga', 'health'],
        minAge: 4,
        maxAge: 12,
        rating_score: 4.5,
        viewCount: 12000,
        creator: 'HealthyKids',
        lastWatched: DateTime.now().subtract(const Duration(days: 5)),
        progress: 0.3,
      ),
      ContentModel(
        id: 'content_006',
        title: 'Drawing Tutorial: Animals',
        description: 'Step-by-step guide to drawing your favorite animals',
        type: ContentType.video,
        thumbnailUrl: 'https://picsum.photos/seed/drawing/400/225',
        contentUrl: 'https://example.com/drawing-animals.mp4',
        durationMinutes: 22,
        rating: ContentRating.all,
        categories: [ContentCategory.art, ContentCategory.educational],
        tags: ['drawing', 'art', 'creativity'],
        minAge: 5,
        maxAge: 12,
        rating_score: 4.6,
        viewCount: 9500,
        isFavorite: true,
        creator: 'ArtForKids',
        educationalTopics: ['Drawing Techniques', 'Shapes', 'Creativity'],
      ),
      ContentModel(
        id: 'content_007',
        title: 'Musical Instruments Introduction',
        description: 'Learn about different musical instruments and their sounds',
        type: ContentType.audio,
        thumbnailUrl: 'https://picsum.photos/seed/music/400/225',
        contentUrl: 'https://example.com/instruments.mp3',
        durationMinutes: 15,
        rating: ContentRating.all,
        categories: [ContentCategory.music, ContentCategory.educational],
        tags: ['music', 'instruments', 'sounds'],
        minAge: 3,
        maxAge: 10,
        rating_score: 4.8,
        viewCount: 14000,
        creator: 'MusicMakers',
        educationalTopics: ['Musical Instruments', 'Sound Recognition', 'Rhythm'],
      ),
      ContentModel(
        id: 'content_008',
        title: 'Geography Quiz: Countries',
        description: 'Test your knowledge about countries around the world',
        type: ContentType.game,
        thumbnailUrl: 'https://picsum.photos/seed/geography/400/225',
        contentUrl: 'https://example.com/geography-quiz',
        durationMinutes: 30,
        rating: ContentRating.elementary,
        categories: [ContentCategory.educational],
        tags: ['geography', 'countries', 'quiz'],
        minAge: 8,
        maxAge: 13,
        rating_score: 4.4,
        viewCount: 7500,
        creator: 'GeoExplorers',
        educationalTopics: ['World Geography', 'Countries', 'Capitals'],
      ),
    ];
  }
}