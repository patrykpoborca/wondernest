import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_story.dart';
import 'auth_provider.dart';
import 'content_pack_provider.dart';

final aiStoryProvider = StateNotifierProvider<AIStoryNotifier, AIStoryState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final contentPackNotifier = ref.watch(contentPackProvider.notifier);
  return AIStoryNotifier(apiService, contentPackNotifier);
});

class AIStoryState {
  final bool isLoading;
  final AIStory? currentStory;
  final List<AIStory> storyHistory;
  final AIQuota? quota;
  final String? error;

  AIStoryState({
    this.isLoading = false,
    this.currentStory,
    this.storyHistory = const [],
    this.quota,
    this.error,
  });

  AIStoryState copyWith({
    bool? isLoading,
    AIStory? currentStory,
    List<AIStory>? storyHistory,
    AIQuota? quota,
    String? error,
  }) {
    return AIStoryState(
      isLoading: isLoading ?? this.isLoading,
      currentStory: currentStory ?? this.currentStory,
      storyHistory: storyHistory ?? this.storyHistory,
      quota: quota ?? this.quota,
      error: error,
    );
  }
}

class AIStoryNotifier extends StateNotifier<AIStoryState> {
  final ApiService _apiService;
  final ContentPackNotifier _contentPackNotifier;

  AIStoryNotifier(this._apiService, this._contentPackNotifier) : super(AIStoryState());

  Future<AIStory?> generateStory({
    required String prompt,
    String? title,
    List<String>? imageIds,
    String? childId,
    String? ageRange,
    List<String>? educationalGoals,
    List<String>? characterPackIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.generateAIStory(
        prompt: prompt,
        title: title,
        imageIds: imageIds ?? [],
        childId: childId,
        targetAge: ageRange ?? '3-5',
        educationalGoals: educationalGoals ?? [],
        characterPackIds: characterPackIds ?? [],
      );

      if (response != null) {
        final story = AIStory.fromJson(response);
        state = state.copyWith(
          isLoading: false,
          currentStory: story,
          storyHistory: [story, ...state.storyHistory],
        );
        
        // Record pack usage for each character pack used
        if (characterPackIds != null && characterPackIds.isNotEmpty) {
          for (final packId in characterPackIds) {
            await _contentPackNotifier.recordPackUsage(
              packId: packId,
              usedInFeature: 'ai_story_generation',
              childId: childId,
              sessionId: story.id,
              metadata: {
                'storyId': story.id,
                'storyTitle': story.title,
                'prompt': prompt,
              },
            );
          }
        }
        
        return story;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to generate story',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<void> loadStoryHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getAIStoryHistory();
      
      if (response != null && response['stories'] != null) {
        final stories = (response['stories'] as List)
            .map((json) => AIStory.fromJson(json))
            .toList();
        
        state = state.copyWith(
          isLoading: false,
          storyHistory: stories,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load story history',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadQuota() async {
    try {
      final response = await _apiService.getAIQuota();
      
      if (response != null) {
        final quota = AIQuota.fromJson(response);
        state = state.copyWith(quota: quota);
      }
    } catch (e) {
      // Silently fail for quota loading
    }
  }

  Future<void> saveStoryToLibrary(AIStory story) async {
    try {
      await _apiService.saveStoryToLibrary(story.id);
      // Could update state to reflect saved status
    } catch (e) {
      state = state.copyWith(error: 'Failed to save story: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearCurrentStory() {
    state = state.copyWith(currentStory: null);
  }
}

class AIQuota {
  final int dailyUsed;
  final int dailyLimit;
  final int monthlyUsed;
  final int monthlyLimit;
  final DateTime? dailyResetAt;
  final DateTime? monthlyResetAt;

  AIQuota({
    required this.dailyUsed,
    required this.dailyLimit,
    required this.monthlyUsed,
    required this.monthlyLimit,
    this.dailyResetAt,
    this.monthlyResetAt,
  });

  factory AIQuota.fromJson(Map<String, dynamic> json) {
    return AIQuota(
      dailyUsed: json['dailyUsed'] ?? 0,
      dailyLimit: json['dailyLimit'] ?? 5,
      monthlyUsed: json['monthlyUsed'] ?? 0,
      monthlyLimit: json['monthlyLimit'] ?? 50,
      dailyResetAt: json['dailyResetAt'] != null 
          ? DateTime.parse(json['dailyResetAt'])
          : null,
      monthlyResetAt: json['monthlyResetAt'] != null
          ? DateTime.parse(json['monthlyResetAt'])
          : null,
    );
  }

  bool get canGenerate => dailyUsed < dailyLimit && monthlyUsed < monthlyLimit;
  int get dailyRemaining => dailyLimit - dailyUsed;
  int get monthlyRemaining => monthlyLimit - monthlyUsed;
}