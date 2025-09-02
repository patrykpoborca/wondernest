import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_pack.dart';
import 'auth_provider.dart';

final contentPackProvider = StateNotifierProvider<ContentPackNotifier, ContentPackState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ContentPackNotifier(apiService);
});

class ContentPackState {
  final bool isLoading;
  final List<ContentPackCategory> categories;
  final List<ContentPack> featuredPacks;
  final List<ContentPack> ownedPacks;
  final ContentPackSearchResponse? searchResults;
  final ContentPack? currentPack;
  final String? error;

  ContentPackState({
    this.isLoading = false,
    this.categories = const [],
    this.featuredPacks = const [],
    this.ownedPacks = const [],
    this.searchResults,
    this.currentPack,
    this.error,
  });

  ContentPackState copyWith({
    bool? isLoading,
    List<ContentPackCategory>? categories,
    List<ContentPack>? featuredPacks,
    List<ContentPack>? ownedPacks,
    ContentPackSearchResponse? searchResults,
    ContentPack? currentPack,
    String? error,
  }) {
    return ContentPackState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      featuredPacks: featuredPacks ?? this.featuredPacks,
      ownedPacks: ownedPacks ?? this.ownedPacks,
      searchResults: searchResults ?? this.searchResults,
      currentPack: currentPack ?? this.currentPack,
      error: error,
    );
  }
}

class ContentPackNotifier extends StateNotifier<ContentPackState> {
  final ApiService _apiService;

  ContentPackNotifier(this._apiService) : super(ContentPackState());

  /// Load content pack categories
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getContentPackCategories();
      
      if (response != null && response['categories'] != null) {
        final categories = (response['categories'] as List)
            .map((json) => ContentPackCategory.fromJson(json))
            .toList();
        
        state = state.copyWith(
          isLoading: false,
          categories: categories,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load categories',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load featured content packs
  Future<void> loadFeaturedPacks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getFeaturedContentPacks();
      
      if (response != null && response['packs'] != null) {
        final packs = (response['packs'] as List)
            .map((json) => ContentPack.fromJson(json))
            .toList();
        
        state = state.copyWith(
          isLoading: false,
          featuredPacks: packs,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load featured packs',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load user's owned packs
  Future<void> loadOwnedPacks({String? childId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getOwnedContentPacks(childId: childId);
      
      if (response != null && response['packs'] != null) {
        final packs = (response['packs'] as List)
            .map((json) => ContentPack.fromJson(json))
            .toList();
        
        state = state.copyWith(
          isLoading: false,
          ownedPacks: packs,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load owned packs',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search content packs
  Future<void> searchPacks(ContentPackSearchRequest searchRequest) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.searchContentPacks(searchRequest.toJson());
      
      if (response != null) {
        final searchResults = ContentPackSearchResponse.fromJson(response);
        
        state = state.copyWith(
          isLoading: false,
          searchResults: searchResults,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to search packs',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get specific pack details
  Future<ContentPack?> getPackDetails(String packId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getContentPackDetails(packId);
      
      if (response != null && response['pack'] != null) {
        final pack = ContentPack.fromJson(response['pack']);
        
        state = state.copyWith(
          isLoading: false,
          currentPack: pack,
        );
        
        return pack;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Pack not found',
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

  /// Purchase a content pack
  Future<bool> purchasePack(String packId, {String? childId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _apiService.purchaseContentPack(
        packId: packId,
        childId: childId,
      );
      
      if (success) {
        state = state.copyWith(isLoading: false);
        
        // Refresh owned packs after successful purchase
        await loadOwnedPacks(childId: childId);
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Purchase failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update pack download status
  Future<void> updateDownloadStatus(
    String packId, 
    String status, 
    {int progress = 0, String? childId}
  ) async {
    try {
      await _apiService.updateContentPackDownload(
        packId: packId,
        status: status,
        progress: progress,
        childId: childId,
      );
      
      // Update local state
      final updatedOwnedPacks = state.ownedPacks.map((pack) {
        if (pack.id == packId) {
          final updatedOwnership = pack.userOwnership?.copyWith(
            downloadStatus: status,
            downloadProgress: progress,
          );
          return pack.copyWith(userOwnership: updatedOwnership);
        }
        return pack;
      }).toList();
      
      state = state.copyWith(ownedPacks: updatedOwnedPacks);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update download status: $e');
    }
  }

  /// Record pack usage
  Future<void> recordPackUsage({
    required String packId,
    required String usedInFeature,
    String? childId,
    String? assetId,
    String? sessionId,
    int? usageDurationSeconds,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _apiService.recordContentPackUsage(
        packId: packId,
        usedInFeature: usedInFeature,
        childId: childId,
        assetId: assetId,
        sessionId: sessionId,
        usageDurationSeconds: usageDurationSeconds,
        metadata: metadata,
      );
    } catch (e) {
      // Silently handle usage recording errors
      // Silently handle usage recording errors - could use proper logging here
    }
  }

  /// Get pack assets for owned pack
  Future<List<ContentPackAsset>?> getPackAssets(String packId, {String? childId}) async {
    try {
      final response = await _apiService.getContentPackAssets(
        packId: packId,
        childId: childId,
      );
      
      if (response != null && response['assets'] != null) {
        return (response['assets'] as List)
            .map((json) => ContentPackAsset.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Failed to load pack assets: $e');
      return null;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(searchResults: null);
  }

  /// Clear current pack
  void clearCurrentPack() {
    state = state.copyWith(currentPack: null);
  }
}

// Extension to add copyWith method to ContentPack
extension ContentPackCopyWith on ContentPack {
  ContentPack copyWith({
    UserPackOwnership? userOwnership,
  }) {
    return ContentPack(
      id: id,
      name: name,
      description: description,
      shortDescription: shortDescription,
      packType: packType,
      categoryId: categoryId,
      category: category,
      priceCents: priceCents,
      isFree: isFree,
      isFeatured: isFeatured,
      isPremium: isPremium,
      ageMin: ageMin,
      ageMax: ageMax,
      educationalGoals: educationalGoals,
      curriculumTags: curriculumTags,
      thumbnailUrl: thumbnailUrl,
      previewUrls: previewUrls,
      bannerImageUrl: bannerImageUrl,
      colorPalette: colorPalette,
      artStyle: artStyle,
      moodTags: moodTags,
      totalAssets: totalAssets,
      fileSizeBytes: fileSizeBytes,
      supportedPlatforms: supportedPlatforms,
      minAppVersion: minAppVersion,
      performanceTier: performanceTier,
      status: status,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      searchKeywords: searchKeywords,
      popularityScore: popularityScore,
      downloadCount: downloadCount,
      ratingAverage: ratingAverage,
      ratingCount: ratingCount,
      assets: assets,
      userOwnership: userOwnership ?? this.userOwnership,
    );
  }
}

// Extension to add copyWith method to UserPackOwnership
extension UserPackOwnershipCopyWith on UserPackOwnership {
  UserPackOwnership copyWith({
    String? downloadStatus,
    int? downloadProgress,
    DateTime? downloadedAt,
  }) {
    return UserPackOwnership(
      id: id,
      userId: userId,
      packId: packId,
      childId: childId,
      acquiredAt: acquiredAt,
      acquisitionType: acquisitionType,
      purchasePriceCents: purchasePriceCents,
      transactionId: transactionId,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastUsedAt: lastUsedAt,
      usageCount: usageCount,
      isFavorite: isFavorite,
      isHidden: isHidden,
      customTags: customTags,
    );
  }
}