// WonderNest Marketplace Repository Implementation
// Provides offline-first pattern with caching and error resilience

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/timber_wrapper.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../sources/marketplace_api_service.dart';
import '../models/marketplace_models.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceApiService _apiService;
  late final Box _cacheBox;
  
  static const String _featuredContentKey = 'featured_content';
  static const String _newReleasesKey = 'new_releases';
  static const String _childLibraryPrefix = 'child_library_';
  static const String _collectionsPrefix = 'collections_';
  static const String _libraryStatsPrefix = 'library_stats_';
  static const String _marketplaceItemPrefix = 'marketplace_item_';
  static const String _creatorProfileKey = 'creator_profile';
  
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const Duration _libraryStatsExpiry = Duration(minutes: 10);

  MarketplaceRepositoryImpl(this._apiService) {
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    try {
      _cacheBox = await Hive.openBox('marketplace_cache');
      Timber.i('[MarketplaceRepo] Cache initialized successfully');
    } catch (e) {
      Timber.e('[MarketplaceRepo] Failed to initialize cache: $e');
      // Continue without cache if it fails
    }
  }

  // ============================================================================
  // MARKETPLACE BROWSING
  // ============================================================================

  @override
  Future<MarketplaceBrowseResponse> browseMarketplace(MarketplaceBrowseRequest request) async {
    try {
      Timber.i('[MarketplaceRepo] Browsing marketplace with filters');
      
      // Try API first
      final response = await _apiService.browseMarketplace(request);
      
      // Cache the response for offline use
      await _cacheWithExpiry('browse_${_requestToKey(request)}', response.toJson(), _cacheExpiry);
      
      return response;
    } catch (e) {
      Timber.w('[MarketplaceRepo] API failed, trying cache: $e');
      
      // Fallback to cache
      final cached = await _getCachedData<MarketplaceBrowseResponse>(
        'browse_${_requestToKey(request)}',
        (json) => MarketplaceBrowseResponse.fromJson(json),
      );
      
      if (cached != null) {
        Timber.i('[MarketplaceRepo] Returning cached browse results');
        return cached;
      }
      
      // If no cache available, return empty results
      Timber.w('[MarketplaceRepo] No cache available, returning empty results');
      return MarketplaceBrowseResponse(
        items: [],
        totalCount: 0,
        page: request.page ?? 1,
        totalPages: 0,
      );
    }
  }

  @override
  Future<MarketplaceListing> getMarketplaceItem(String itemId) async {
    try {
      Timber.i('[MarketplaceRepo] Fetching marketplace item: $itemId');
      
      // Try API first
      final item = await _apiService.getMarketplaceItem(itemId);
      
      // Cache the item
      await _cacheWithExpiry('$_marketplaceItemPrefix$itemId', item.toJson(), _cacheExpiry);
      
      return item;
    } catch (e) {
      Timber.w('[MarketplaceRepo] API failed for item $itemId, trying cache: $e');
      
      // Fallback to cache
      final cached = await _getCachedData<MarketplaceListing>(
        '$_marketplaceItemPrefix$itemId',
        (json) => MarketplaceListing.fromJson(json),
      );
      
      if (cached != null) {
        Timber.i('[MarketplaceRepo] Returning cached marketplace item');
        return cached;
      }
      
      rethrow; // No fallback for specific items
    }
  }

  @override
  Future<MarketplaceBrowseResponse> getFeaturedContent({int limit = 20}) async {
    try {
      Timber.i('[MarketplaceRepo] Fetching featured content');
      
      // Try API first
      final response = await _apiService.getFeaturedContent(limit: limit);
      
      // Cache featured content
      await _cacheWithExpiry(_featuredContentKey, response.toJson(), _cacheExpiry);
      
      return response;
    } catch (e) {
      Timber.w('[MarketplaceRepo] API failed for featured content, trying cache: $e');
      
      // Fallback to cache
      final cached = await _getCachedData<MarketplaceBrowseResponse>(
        _featuredContentKey,
        (json) => MarketplaceBrowseResponse.fromJson(json),
      );
      
      if (cached != null) {
        Timber.i('[MarketplaceRepo] Returning cached featured content');
        return cached;
      }
      
      // Return empty if no cache
      return MarketplaceBrowseResponse(
        items: [],
        totalCount: 0,
        page: 1,
        totalPages: 0,
      );
    }
  }

  @override
  Future<MarketplaceBrowseResponse> getNewReleases({int limit = 20}) async {
    try {
      Timber.i('[MarketplaceRepo] Fetching new releases');
      
      // Try API first
      final response = await _apiService.getNewReleases(limit: limit);
      
      // Cache new releases
      await _cacheWithExpiry(_newReleasesKey, response.toJson(), _cacheExpiry);
      
      return response;
    } catch (e) {
      Timber.w('[MarketplaceRepo] API failed for new releases, trying cache: $e');
      
      // Fallback to cache
      final cached = await _getCachedData<MarketplaceBrowseResponse>(
        _newReleasesKey,
        (json) => MarketplaceBrowseResponse.fromJson(json),
      );
      
      if (cached != null) {
        Timber.i('[MarketplaceRepo] Returning cached new releases');
        return cached;
      }
      
      // Return empty if no cache
      return MarketplaceBrowseResponse(
        items: [],
        totalCount: 0,
        page: 1,
        totalPages: 0,
      );
    }
  }

  // ============================================================================
  // CHILD LIBRARY MANAGEMENT
  // ============================================================================

  @override
  Future<List<ChildLibrary>> getChildLibrary(String childId) async {
    try {
      Timber.i('[MarketplaceRepo] Fetching library for child: $childId');
      
      // Try API first
      final library = await _apiService.getChildLibrary(childId);
      
      // Cache the library
      final libraryJson = library.map((item) => item.toJson()).toList();
      await _cacheListWithExpiry('$_childLibraryPrefix$childId', libraryJson, _cacheExpiry);
      
      return library;
    } catch (e) {
      Timber.w('[MarketplaceRepo] API failed for child library, trying cache: $e');
      
      // Fallback to cache
      try {
        final cachedData = await _getCachedList('$_childLibraryPrefix$childId');
        if (cachedData != null) {
          final library = cachedData.map((json) => ChildLibrary.fromJson(json)).toList();
          Timber.i('[MarketplaceRepo] Returning cached child library (${library.length} items)');
          return library;
        }
      } catch (cacheError) {
        Timber.e('[MarketplaceRepo] Cache error: $cacheError');
      }
      
      // Return empty library if no cache
      Timber.w('[MarketplaceRepo] No cache available, returning empty library');
      return [];
    }
  }

  @override
  Future<LibraryStatsResponse> getLibraryStats(String childId) async {
    try {
      Timber.i('[MarketplaceRepo] Fetching library stats for child: $childId');
      
      // Try API first
      final stats = await _apiService.getLibraryStats(childId);
      
      // Cache stats with shorter expiry
      await _cacheWithExpiry('$_libraryStatsPrefix$childId', stats.toJson(), _libraryStatsExpiry);
      
      return stats;
    } catch (e) {
      Timber.w('[MarketplaceRepo] API failed for library stats, trying cache: $e');
      
      // Fallback to cache
      final cached = await _getCachedData<LibraryStatsResponse>(
        '$_libraryStatsPrefix$childId',
        (json) => LibraryStatsResponse.fromJson(json),
      );
      
      if (cached != null) {
        Timber.i('[MarketplaceRepo] Returning cached library stats');
        return cached;
      }
      
      // Return empty stats if no cache
      return LibraryStatsResponse(
        totalItems: 0,
        favoritesCount: 0,
        totalPlayTimeHours: 0.0,
        completionRate: 0.0,
        recentActivities: [],
      );
    }
  }

  // ============================================================================
  // COLLECTION MANAGEMENT
  // ============================================================================

  @override
  Future<List<ChildCollection>> getChildCollections(String childId) async {
    try {
      Timber.i('[MarketplaceRepo] Fetching collections for child: $childId');
      
      // Try API first
      final collections = await _apiService.getChildCollections(childId);
      
      // Cache collections
      final collectionsJson = collections.map((collection) => collection.toJson()).toList();
      await _cacheListWithExpiry('$_collectionsPrefix$childId', collectionsJson, _cacheExpiry);
      
      return collections;
    } catch (e) {
      Timber.w('[MarketplaceRepo] API failed for child collections, trying cache: $e');
      
      // Fallback to cache
      try {
        final cachedData = await _getCachedList('$_collectionsPrefix$childId');
        if (cachedData != null) {
          final collections = cachedData.map((json) => ChildCollection.fromJson(json)).toList();
          Timber.i('[MarketplaceRepo] Returning cached collections (${collections.length} items)');
          return collections;
        }
      } catch (cacheError) {
        Timber.e('[MarketplaceRepo] Cache error: $cacheError');
      }
      
      // Return empty collections if no cache
      return [];
    }
  }

  @override
  Future<ChildCollection> createCollection(CreateCollectionRequest request) async {
    try {
      Timber.i('[MarketplaceRepo] Creating collection: ${request.name}');
      
      final collection = await _apiService.createCollection(request);
      
      // Invalidate collections cache for this child
      await _invalidateCache('$_collectionsPrefix${request.childId}');
      
      return collection;
    } catch (e) {
      Timber.e('[MarketplaceRepo] Failed to create collection: $e');
      rethrow; // No offline fallback for mutations
    }
  }

  // ============================================================================
  // PURCHASE OPERATIONS
  // ============================================================================

  @override
  Future<PurchaseResponse> purchaseItem(PurchaseRequest request) async {
    try {
      Timber.i('[MarketplaceRepo] Processing purchase for item: ${request.marketplaceItemId}');
      
      final response = await _apiService.purchaseItem(request);
      
      // Invalidate relevant caches after successful purchase
      for (final childId in request.targetChildren) {
        await _invalidateCache('$_childLibraryPrefix$childId');
        await _invalidateCache('$_libraryStatsPrefix$childId');
      }
      
      return response;
    } catch (e) {
      Timber.e('[MarketplaceRepo] Failed to process purchase: $e');
      rethrow; // No offline fallback for purchases
    }
  }

  // ============================================================================
  // CREATOR OPERATIONS
  // ============================================================================

  @override
  Future<CreatorProfile> createCreatorProfile(CreateCreatorProfileRequest request) async {
    try {
      Timber.i('[MarketplaceRepo] Creating creator profile');
      
      final profile = await _apiService.createCreatorProfile(request);
      
      // Cache the new profile
      await _cacheWithExpiry(_creatorProfileKey, profile.toJson(), _cacheExpiry);
      
      return profile;
    } catch (e) {
      Timber.e('[MarketplaceRepo] Failed to create creator profile: $e');
      rethrow; // No offline fallback for mutations
    }
  }

  @override
  Future<CreatorProfile> getCreatorProfile() async {
    try {
      Timber.i('[MarketplaceRepo] Fetching creator profile');
      
      // Try API first
      final profile = await _apiService.getCreatorProfile();
      
      // Cache the profile
      await _cacheWithExpiry(_creatorProfileKey, profile.toJson(), _cacheExpiry);
      
      return profile;
    } catch (e) {
      Timber.w('[MarketplaceRepo] API failed for creator profile, trying cache: $e');
      
      // Fallback to cache
      final cached = await _getCachedData<CreatorProfile>(
        _creatorProfileKey,
        (json) => CreatorProfile.fromJson(json),
      );
      
      if (cached != null) {
        Timber.i('[MarketplaceRepo] Returning cached creator profile');
        return cached;
      }
      
      rethrow; // No fallback for creator profile
    }
  }

  // ============================================================================
  // REVIEW OPERATIONS
  // ============================================================================

  @override
  Future<void> createReview(CreateReviewRequest request) async {
    try {
      await _apiService.createReview(request);
      
      // Invalidate item cache to refresh ratings
      await _invalidateCache('$_marketplaceItemPrefix${request.marketplaceItemId}');
    } catch (e) {
      Timber.e('[MarketplaceRepo] Failed to create review: $e');
      rethrow; // No offline fallback for mutations
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getItemReviews(String itemId) async {
    try {
      return await _apiService.getItemReviews(itemId);
    } catch (e) {
      Timber.e('[MarketplaceRepo] Failed to fetch reviews: $e');
      return []; // Return empty reviews on error
    }
  }

  // ============================================================================
  // CONVENIENCE METHODS
  // ============================================================================

  @override
  Future<bool> isItemInLibrary(String childId, String itemId) async {
    try {
      final library = await getChildLibrary(childId);
      return library.any((item) => item.marketplaceItemId == itemId);
    } catch (e) {
      Timber.w('[MarketplaceRepo] Could not check library status: $e');
      return false;
    }
  }

  @override
  Future<void> refreshCache() async {
    try {
      Timber.i('[MarketplaceRepo] Refreshing marketplace cache');
      await _cacheBox.clear();
      Timber.i('[MarketplaceRepo] Cache refreshed successfully');
    } catch (e) {
      Timber.e('[MarketplaceRepo] Failed to refresh cache: $e');
    }
  }

  // ============================================================================
  // PRIVATE CACHE METHODS
  // ============================================================================

  Future<void> _cacheWithExpiry(String key, Map<String, dynamic> data, Duration expiry) async {
    try {
      if (_cacheBox.isOpen) {
        final cacheEntry = {
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'expiry': expiry.inMilliseconds,
        };
        await _cacheBox.put(key, jsonEncode(cacheEntry));
      }
    } catch (e) {
      Timber.w('[MarketplaceRepo] Failed to cache data: $e');
    }
  }

  Future<void> _cacheListWithExpiry(String key, List<Map<String, dynamic>> data, Duration expiry) async {
    try {
      if (_cacheBox.isOpen) {
        final cacheEntry = {
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'expiry': expiry.inMilliseconds,
        };
        await _cacheBox.put(key, jsonEncode(cacheEntry));
      }
    } catch (e) {
      Timber.w('[MarketplaceRepo] Failed to cache list data: $e');
    }
  }

  Future<T?> _getCachedData<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      if (!_cacheBox.isOpen) return null;
      
      final cached = _cacheBox.get(key);
      if (cached == null) return null;
      
      final cacheEntry = jsonDecode(cached);
      final timestamp = cacheEntry['timestamp'] as int;
      final expiry = cacheEntry['expiry'] as int;
      
      // Check if cache is still valid
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > expiry) {
        await _cacheBox.delete(key);
        return null;
      }
      
      return fromJson(cacheEntry['data']);
    } catch (e) {
      Timber.w('[MarketplaceRepo] Failed to read cached data: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _getCachedList(String key) async {
    try {
      if (!_cacheBox.isOpen) return null;
      
      final cached = _cacheBox.get(key);
      if (cached == null) return null;
      
      final cacheEntry = jsonDecode(cached);
      final timestamp = cacheEntry['timestamp'] as int;
      final expiry = cacheEntry['expiry'] as int;
      
      // Check if cache is still valid
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > expiry) {
        await _cacheBox.delete(key);
        return null;
      }
      
      return List<Map<String, dynamic>>.from(cacheEntry['data']);
    } catch (e) {
      Timber.w('[MarketplaceRepo] Failed to read cached list: $e');
      return null;
    }
  }

  Future<void> _invalidateCache(String key) async {
    try {
      if (_cacheBox.isOpen) {
        await _cacheBox.delete(key);
        Timber.d('[MarketplaceRepo] Invalidated cache key: $key');
      }
    } catch (e) {
      Timber.w('[MarketplaceRepo] Failed to invalidate cache: $e');
    }
  }

  String _requestToKey(MarketplaceBrowseRequest request) {
    final params = request.toQueryParameters();
    final sortedKeys = params.keys.toList()..sort();
    return sortedKeys.map((key) => '${key}_${params[key]}').join('_');
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  Future<void> dispose() async {
    try {
      if (_cacheBox.isOpen) {
        await _cacheBox.close();
        Timber.i('[MarketplaceRepo] Repository disposed successfully');
      }
    } catch (e) {
      Timber.e('[MarketplaceRepo] Error during disposal: $e');
    }
  }
}