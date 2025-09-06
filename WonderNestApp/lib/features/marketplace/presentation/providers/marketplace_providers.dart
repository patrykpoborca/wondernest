// WonderNest Marketplace Riverpod Providers
// State management for marketplace features

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/timber_wrapper.dart';
import '../../data/models/marketplace_models.dart';
import '../../data/sources/marketplace_api_service.dart';
import '../../data/repositories/marketplace_repository_impl.dart';
import '../../domain/repositories/marketplace_repository.dart';

// ============================================================================
// CORE PROVIDERS
// ============================================================================

/// Provides the MarketplaceApiService instance
final marketplaceApiServiceProvider = Provider<MarketplaceApiService>((ref) {
  // Create Dio instance with marketplace base URL
  final dio = Dio(BaseOptions(
    baseUrl: '${ApiService.baseUrl}/marketplace',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));
  
  return MarketplaceApiService(dio);
});

/// Provides the MarketplaceRepository implementation
final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  final apiService = ref.watch(marketplaceApiServiceProvider);
  return MarketplaceRepositoryImpl(apiService);
});

// ============================================================================
// MARKETPLACE BROWSING STATE
// ============================================================================

/// State for marketplace browsing
class MarketplaceBrowseState {
  final bool isLoading;
  final MarketplaceBrowseResponse? browseResponse;
  final MarketplaceBrowseRequest? lastRequest;
  final String? error;
  final List<MarketplaceItemSummary> featuredItems;
  final List<MarketplaceItemSummary> newReleases;
  final bool hasMore;

  const MarketplaceBrowseState({
    this.isLoading = false,
    this.browseResponse,
    this.lastRequest,
    this.error,
    this.featuredItems = const [],
    this.newReleases = const [],
    this.hasMore = true,
  });

  MarketplaceBrowseState copyWith({
    bool? isLoading,
    MarketplaceBrowseResponse? browseResponse,
    MarketplaceBrowseRequest? lastRequest,
    String? error,
    List<MarketplaceItemSummary>? featuredItems,
    List<MarketplaceItemSummary>? newReleases,
    bool? hasMore,
  }) {
    return MarketplaceBrowseState(
      isLoading: isLoading ?? this.isLoading,
      browseResponse: browseResponse ?? this.browseResponse,
      lastRequest: lastRequest ?? this.lastRequest,
      error: error,
      featuredItems: featuredItems ?? this.featuredItems,
      newReleases: newReleases ?? this.newReleases,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class MarketplaceBrowseNotifier extends StateNotifier<MarketplaceBrowseState> {
  final MarketplaceRepository _repository;

  MarketplaceBrowseNotifier(this._repository) : super(const MarketplaceBrowseState());

  /// Load featured content for discovery hub
  Future<void> loadFeaturedContent() async {
    try {
      Timber.i('[MarketplaceBrowse] Loading featured content');
      state = state.copyWith(isLoading: true, error: null);

      final response = await _repository.getFeaturedContent(limit: 10);
      
      state = state.copyWith(
        isLoading: false,
        featuredItems: response.items,
      );
    } catch (e) {
      Timber.e('[MarketplaceBrowse] Failed to load featured content: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load featured content',
      );
    }
  }

  /// Load new releases
  Future<void> loadNewReleases() async {
    try {
      Timber.i('[MarketplaceBrowse] Loading new releases');
      
      final response = await _repository.getNewReleases(limit: 10);
      
      state = state.copyWith(
        newReleases: response.items,
      );
    } catch (e) {
      Timber.e('[MarketplaceBrowse] Failed to load new releases: $e');
      // Don't update error state for secondary content
    }
  }

  /// Browse marketplace with filters
  Future<void> browseMarketplace(MarketplaceBrowseRequest request) async {
    try {
      Timber.i('[MarketplaceBrowse] Browsing marketplace with request: $request');
      state = state.copyWith(isLoading: true, error: null);

      final response = await _repository.browseMarketplace(request);
      
      state = state.copyWith(
        isLoading: false,
        browseResponse: response,
        lastRequest: request,
        hasMore: response.page < response.totalPages,
      );
    } catch (e) {
      Timber.e('[MarketplaceBrowse] Failed to browse marketplace: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to browse marketplace',
      );
    }
  }

  /// Load more items (pagination)
  Future<void> loadMoreItems() async {
    if (state.isLoading || !state.hasMore || state.lastRequest == null) return;

    try {
      final nextPage = (state.lastRequest?.page ?? 1) + 1;
      final request = MarketplaceBrowseRequest(
        contentType: state.lastRequest?.contentType,
        ageRangeMin: state.lastRequest?.ageRangeMin,
        ageRangeMax: state.lastRequest?.ageRangeMax,
        priceMin: state.lastRequest?.priceMin,
        priceMax: state.lastRequest?.priceMax,
        creatorTiers: state.lastRequest?.creatorTiers,
        sortBy: state.lastRequest?.sortBy,
        page: nextPage,
        limit: state.lastRequest?.limit,
      );

      final response = await _repository.browseMarketplace(request);
      
      // Append items to existing list
      final List<MarketplaceItemSummary> allItems = [
        ...state.browseResponse?.items ?? <MarketplaceItemSummary>[],
        ...response.items,
      ];

      state = state.copyWith(
        browseResponse: MarketplaceBrowseResponse(
          items: allItems,
          totalCount: response.totalCount,
          page: response.page,
          totalPages: response.totalPages,
        ),
        lastRequest: request,
        hasMore: response.page < response.totalPages,
      );
    } catch (e) {
      Timber.e('[MarketplaceBrowse] Failed to load more items: $e');
    }
  }

  /// Clear current search/browse results
  void clearResults() {
    state = const MarketplaceBrowseState();
  }
}

final marketplaceBrowseProvider = StateNotifierProvider<MarketplaceBrowseNotifier, MarketplaceBrowseState>((ref) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return MarketplaceBrowseNotifier(repository);
});

// ============================================================================
// MARKETPLACE ITEM DETAIL STATE
// ============================================================================

/// State for individual marketplace item details
class MarketplaceItemState {
  final bool isLoading;
  final MarketplaceListing? item;
  final String? error;
  final List<Map<String, dynamic>> reviews;
  final bool reviewsLoading;

  const MarketplaceItemState({
    this.isLoading = false,
    this.item,
    this.error,
    this.reviews = const [],
    this.reviewsLoading = false,
  });

  MarketplaceItemState copyWith({
    bool? isLoading,
    MarketplaceListing? item,
    String? error,
    List<Map<String, dynamic>>? reviews,
    bool? reviewsLoading,
  }) {
    return MarketplaceItemState(
      isLoading: isLoading ?? this.isLoading,
      item: item ?? this.item,
      error: error,
      reviews: reviews ?? this.reviews,
      reviewsLoading: reviewsLoading ?? this.reviewsLoading,
    );
  }
}

class MarketplaceItemNotifier extends StateNotifier<MarketplaceItemState> {
  final MarketplaceRepository _repository;

  MarketplaceItemNotifier(this._repository) : super(const MarketplaceItemState());

  /// Load marketplace item details
  Future<void> loadItem(String itemId) async {
    try {
      Timber.i('[MarketplaceItem] Loading item: $itemId');
      state = state.copyWith(isLoading: true, error: null);

      final item = await _repository.getMarketplaceItem(itemId);
      
      state = state.copyWith(
        isLoading: false,
        item: item,
      );

      // Load reviews in background
      _loadReviews(itemId);
    } catch (e) {
      Timber.e('[MarketplaceItem] Failed to load item: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load item details',
      );
    }
  }

  /// Load reviews for current item
  Future<void> _loadReviews(String itemId) async {
    try {
      state = state.copyWith(reviewsLoading: true);
      
      final reviews = await _repository.getItemReviews(itemId);
      
      state = state.copyWith(
        reviews: reviews,
        reviewsLoading: false,
      );
    } catch (e) {
      Timber.e('[MarketplaceItem] Failed to load reviews: $e');
      state = state.copyWith(reviewsLoading: false);
    }
  }

  /// Clear current item data
  void clearItem() {
    state = const MarketplaceItemState();
  }
}

final marketplaceItemProvider = StateNotifierProvider<MarketplaceItemNotifier, MarketplaceItemState>((ref) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return MarketplaceItemNotifier(repository);
});

// ============================================================================
// CHILD LIBRARY STATE
// ============================================================================

/// State for child library management
class ChildLibraryState {
  final bool isLoading;
  final List<ChildLibrary> items;
  final LibraryStatsResponse? stats;
  final String? error;
  final List<ChildCollection> collections;
  final bool collectionsLoading;

  const ChildLibraryState({
    this.isLoading = false,
    this.items = const [],
    this.stats,
    this.error,
    this.collections = const [],
    this.collectionsLoading = false,
  });

  ChildLibraryState copyWith({
    bool? isLoading,
    List<ChildLibrary>? items,
    LibraryStatsResponse? stats,
    String? error,
    List<ChildCollection>? collections,
    bool? collectionsLoading,
  }) {
    return ChildLibraryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      stats: stats ?? this.stats,
      error: error,
      collections: collections ?? this.collections,
      collectionsLoading: collectionsLoading ?? this.collectionsLoading,
    );
  }
}

class ChildLibraryNotifier extends StateNotifier<ChildLibraryState> {
  final MarketplaceRepository _repository;
  String? _currentChildId;

  ChildLibraryNotifier(this._repository) : super(const ChildLibraryState());

  /// Load library for a specific child
  Future<void> loadChildLibrary(String childId) async {
    try {
      Timber.i('[ChildLibrary] Loading library for child: $childId');
      _currentChildId = childId;
      state = state.copyWith(isLoading: true, error: null);

      // Load library items and stats in parallel
      final futures = await Future.wait([
        _repository.getChildLibrary(childId),
        _repository.getLibraryStats(childId),
      ]);

      final items = futures[0] as List<ChildLibrary>;
      final stats = futures[1] as LibraryStatsResponse;

      state = state.copyWith(
        isLoading: false,
        items: items,
        stats: stats,
      );

      // Load collections in background
      _loadCollections(childId);
    } catch (e) {
      Timber.e('[ChildLibrary] Failed to load child library: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load library',
      );
    }
  }

  /// Load collections for current child
  Future<void> _loadCollections(String childId) async {
    try {
      state = state.copyWith(collectionsLoading: true);
      
      final collections = await _repository.getChildCollections(childId);
      
      state = state.copyWith(
        collections: collections,
        collectionsLoading: false,
      );
    } catch (e) {
      Timber.e('[ChildLibrary] Failed to load collections: $e');
      state = state.copyWith(collectionsLoading: false);
    }
  }

  /// Create a new collection
  Future<void> createCollection(CreateCollectionRequest request) async {
    try {
      Timber.i('[ChildLibrary] Creating collection: ${request.name}');
      
      final newCollection = await _repository.createCollection(request);
      
      // Add to current collections
      final updatedCollections = [...state.collections, newCollection];
      
      state = state.copyWith(collections: updatedCollections);
    } catch (e) {
      Timber.e('[ChildLibrary] Failed to create collection: $e');
      throw Exception('Failed to create collection');
    }
  }

  /// Refresh current child's library
  Future<void> refreshLibrary() async {
    if (_currentChildId != null) {
      await loadChildLibrary(_currentChildId!);
    }
  }

  /// Clear library state
  void clearLibrary() {
    _currentChildId = null;
    state = const ChildLibraryState();
  }

  /// Get favorite items from library
  List<ChildLibrary> get favoriteItems {
    return state.items.where((item) => item.favorite).toList();
  }

  /// Get recently accessed items
  List<ChildLibrary> get recentItems {
    final sortedItems = [...state.items];
    sortedItems.sort((a, b) {
      final aLastAccessed = a.lastAccessed ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bLastAccessed = b.lastAccessed ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bLastAccessed.compareTo(aLastAccessed);
    });
    return sortedItems.take(10).toList();
  }
}

final childLibraryProvider = StateNotifierProvider<ChildLibraryNotifier, ChildLibraryState>((ref) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return ChildLibraryNotifier(repository);
});

// ============================================================================
// PURCHASE STATE
// ============================================================================

/// State for purchase operations
class PurchaseState {
  final bool isProcessing;
  final PurchaseResponse? lastPurchase;
  final String? error;

  const PurchaseState({
    this.isProcessing = false,
    this.lastPurchase,
    this.error,
  });

  PurchaseState copyWith({
    bool? isProcessing,
    PurchaseResponse? lastPurchase,
    String? error,
  }) {
    return PurchaseState(
      isProcessing: isProcessing ?? this.isProcessing,
      lastPurchase: lastPurchase ?? this.lastPurchase,
      error: error,
    );
  }
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final MarketplaceRepository _repository;

  PurchaseNotifier(this._repository) : super(const PurchaseState());

  /// Process a purchase
  Future<bool> purchaseItem(PurchaseRequest request) async {
    try {
      Timber.i('[Purchase] Processing purchase for item: ${request.marketplaceItemId}');
      state = state.copyWith(isProcessing: true, error: null);

      final response = await _repository.purchaseItem(request);
      
      state = state.copyWith(
        isProcessing: false,
        lastPurchase: response,
      );

      Timber.i('[Purchase] Purchase completed: ${response.transactionId}');
      return true;
    } catch (e) {
      Timber.e('[Purchase] Failed to process purchase: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Purchase failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear purchase state
  void clearPurchaseState() {
    state = const PurchaseState();
  }
}

final purchaseProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return PurchaseNotifier(repository);
});

// ============================================================================
// CREATOR PROFILE STATE
// ============================================================================

/// State for creator profile management
class CreatorProfileState {
  final bool isLoading;
  final CreatorProfile? profile;
  final String? error;

  const CreatorProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
  });

  CreatorProfileState copyWith({
    bool? isLoading,
    CreatorProfile? profile,
    String? error,
  }) {
    return CreatorProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

class CreatorProfileNotifier extends StateNotifier<CreatorProfileState> {
  final MarketplaceRepository _repository;

  CreatorProfileNotifier(this._repository) : super(const CreatorProfileState());

  /// Load creator profile
  Future<void> loadCreatorProfile() async {
    try {
      Timber.i('[CreatorProfile] Loading creator profile');
      state = state.copyWith(isLoading: true, error: null);

      final profile = await _repository.getCreatorProfile();
      
      state = state.copyWith(
        isLoading: false,
        profile: profile,
      );
    } catch (e) {
      Timber.e('[CreatorProfile] Failed to load creator profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load creator profile',
      );
    }
  }

  /// Create creator profile
  Future<bool> createCreatorProfile(CreateCreatorProfileRequest request) async {
    try {
      Timber.i('[CreatorProfile] Creating creator profile: ${request.displayName}');
      state = state.copyWith(isLoading: true, error: null);

      final profile = await _repository.createCreatorProfile(request);
      
      state = state.copyWith(
        isLoading: false,
        profile: profile,
      );

      return true;
    } catch (e) {
      Timber.e('[CreatorProfile] Failed to create creator profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create creator profile',
      );
      return false;
    }
  }

  /// Clear creator profile state
  void clearProfile() {
    state = const CreatorProfileState();
  }
}

final creatorProfileProvider = StateNotifierProvider<CreatorProfileNotifier, CreatorProfileState>((ref) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return CreatorProfileNotifier(repository);
});

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

/// Check if item is in child's library
final isItemInLibraryProvider = FutureProvider.family<bool, ({String childId, String itemId})>((ref, params) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.isItemInLibrary(params.childId, params.itemId);
});