// WonderNest Marketplace API Service
// Connects Flutter frontend to Rust/Axum backend endpoints

import 'package:dio/dio.dart';
import '../../../../core/services/timber_wrapper.dart';
import '../models/marketplace_models.dart';

class MarketplaceApiService {
  final Dio _dio;
  final String _baseUrl;

  MarketplaceApiService(this._dio, {String? baseUrl}) 
      : _baseUrl = baseUrl ?? '/api/v1/marketplace';

  // ============================================================================
  // CREATOR PROFILE ENDPOINTS
  // ============================================================================

  /// Create a new creator profile
  /// POST /api/v1/marketplace/creator/profile
  Future<CreatorProfile> createCreatorProfile(CreateCreatorProfileRequest request) async {
    try {
      Timber.i('[MarketplaceAPI] Creating creator profile: ${request.displayName}');
      
      final response = await _dio.post(
        '$_baseUrl/creator/profile',
        data: request.toJson(),
      );

      return CreatorProfile.fromJson(response.data);
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to create creator profile: ${e.message}');
      throw _handleDioError(e, 'Failed to create creator profile');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error creating creator profile: $e');
      rethrow;
    }
  }

  /// Get creator profile for current user
  /// GET /api/v1/marketplace/creator/profile
  Future<CreatorProfile> getCreatorProfile() async {
    try {
      Timber.i('[MarketplaceAPI] Fetching creator profile');
      
      final response = await _dio.get('$_baseUrl/creator/profile');
      return CreatorProfile.fromJson(response.data);
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to fetch creator profile: ${e.message}');
      throw _handleDioError(e, 'Failed to fetch creator profile');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error fetching creator profile: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MARKETPLACE BROWSING ENDPOINTS
  // ============================================================================

  /// Browse marketplace with filters and pagination
  /// GET /api/v1/marketplace/browse
  Future<MarketplaceBrowseResponse> browseMarketplace(MarketplaceBrowseRequest request) async {
    try {
      Timber.i('[MarketplaceAPI] Browsing marketplace with filters');
      
      final response = await _dio.get(
        '$_baseUrl/browse',
        queryParameters: request.toQueryParameters(),
      );

      return MarketplaceBrowseResponse.fromJson(response.data);
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to browse marketplace: ${e.message}');
      throw _handleDioError(e, 'Failed to browse marketplace');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error browsing marketplace: $e');
      rethrow;
    }
  }

  /// Get detailed information for a specific marketplace item
  /// GET /api/v1/marketplace/items/{itemId}
  Future<MarketplaceListing> getMarketplaceItem(String itemId) async {
    try {
      Timber.i('[MarketplaceAPI] Fetching marketplace item: $itemId');
      
      final response = await _dio.get('$_baseUrl/items/$itemId');
      return MarketplaceListing.fromJson(response.data);
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to fetch marketplace item: ${e.message}');
      throw _handleDioError(e, 'Failed to fetch marketplace item');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error fetching marketplace item: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PURCHASE ENDPOINTS
  // ============================================================================

  /// Purchase a marketplace item for specified children
  /// POST /api/v1/marketplace/purchase
  Future<PurchaseResponse> purchaseItem(PurchaseRequest request) async {
    try {
      Timber.i('[MarketplaceAPI] Processing purchase for item: ${request.marketplaceItemId}');
      Timber.i('[MarketplaceAPI] Target children: ${request.targetChildren.length}');
      
      final response = await _dio.post(
        '$_baseUrl/purchase',
        data: request.toJson(),
      );

      return PurchaseResponse.fromJson(response.data);
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to process purchase: ${e.message}');
      throw _handleDioError(e, 'Failed to process purchase');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error processing purchase: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CHILD LIBRARY ENDPOINTS
  // ============================================================================

  /// Get child's library contents
  /// GET /api/v1/marketplace/library/{childId}
  Future<List<ChildLibrary>> getChildLibrary(String childId) async {
    try {
      Timber.i('[MarketplaceAPI] Fetching library for child: $childId');
      
      final response = await _dio.get('$_baseUrl/library/$childId');
      
      final List<dynamic> libraryData = response.data;
      return libraryData.map((json) => ChildLibrary.fromJson(json)).toList();
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to fetch child library: ${e.message}');
      throw _handleDioError(e, 'Failed to fetch child library');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error fetching child library: $e');
      rethrow;
    }
  }

  /// Get library statistics for a child
  /// GET /api/v1/marketplace/library/{childId}/stats
  Future<LibraryStatsResponse> getLibraryStats(String childId) async {
    try {
      Timber.i('[MarketplaceAPI] Fetching library stats for child: $childId');
      
      final response = await _dio.get('$_baseUrl/library/$childId/stats');
      return LibraryStatsResponse.fromJson(response.data);
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to fetch library stats: ${e.message}');
      throw _handleDioError(e, 'Failed to fetch library stats');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error fetching library stats: $e');
      rethrow;
    }
  }

  // ============================================================================
  // COLLECTION ENDPOINTS
  // ============================================================================

  /// Create a new collection for a child
  /// POST /api/v1/marketplace/collections
  Future<ChildCollection> createCollection(CreateCollectionRequest request) async {
    try {
      Timber.i('[MarketplaceAPI] Creating collection: ${request.name} for child: ${request.childId}');
      
      final response = await _dio.post(
        '$_baseUrl/collections',
        data: request.toJson(),
      );

      return ChildCollection.fromJson(response.data);
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to create collection: ${e.message}');
      throw _handleDioError(e, 'Failed to create collection');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error creating collection: $e');
      rethrow;
    }
  }

  /// Get all collections for a child
  /// GET /api/v1/marketplace/collections/{childId}
  Future<List<ChildCollection>> getChildCollections(String childId) async {
    try {
      Timber.i('[MarketplaceAPI] Fetching collections for child: $childId');
      
      final response = await _dio.get('$_baseUrl/collections/$childId');
      
      final List<dynamic> collectionsData = response.data;
      return collectionsData.map((json) => ChildCollection.fromJson(json)).toList();
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to fetch child collections: ${e.message}');
      throw _handleDioError(e, 'Failed to fetch child collections');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error fetching child collections: $e');
      rethrow;
    }
  }

  // ============================================================================
  // REVIEW ENDPOINTS
  // ============================================================================

  /// Create a review for a marketplace item
  /// POST /api/v1/marketplace/reviews
  Future<void> createReview(CreateReviewRequest request) async {
    try {
      Timber.i('[MarketplaceAPI] Creating review for item: ${request.marketplaceItemId}');
      Timber.i('[MarketplaceAPI] Rating: ${request.rating}/5');
      
      await _dio.post(
        '$_baseUrl/reviews',
        data: request.toJson(),
      );
      
      Timber.i('[MarketplaceAPI] Review created successfully');
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to create review: ${e.message}');
      throw _handleDioError(e, 'Failed to create review');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error creating review: $e');
      rethrow;
    }
  }

  /// Get reviews for a marketplace item
  /// GET /api/v1/marketplace/items/{itemId}/reviews
  Future<List<Map<String, dynamic>>> getItemReviews(String itemId) async {
    try {
      Timber.i('[MarketplaceAPI] Fetching reviews for item: $itemId');
      
      final response = await _dio.get('$_baseUrl/items/$itemId/reviews');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to fetch item reviews: ${e.message}');
      throw _handleDioError(e, 'Failed to fetch item reviews');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error fetching item reviews: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CONTENT PACK CREATION (for creators)
  // ============================================================================

  /// Create a content pack (creator functionality)
  /// POST /api/v1/marketplace/content-packs
  Future<Map<String, dynamic>> createContentPack(Map<String, dynamic> request) async {
    try {
      Timber.i('[MarketplaceAPI] Creating content pack: ${request['title']}');
      
      final response = await _dio.post(
        '$_baseUrl/content-packs',
        data: request,
      );

      return response.data;
    } on DioException catch (e) {
      Timber.e('[MarketplaceAPI] Failed to create content pack: ${e.message}');
      throw _handleDioError(e, 'Failed to create content pack');
    } catch (e) {
      Timber.e('[MarketplaceAPI] Unexpected error creating content pack: $e');
      rethrow;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Handle Dio errors and convert to user-friendly messages
  Exception _handleDioError(DioException e, String defaultMessage) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Request timed out. Please check your connection.');
      
      case DioExceptionType.connectionError:
        return Exception('Unable to connect to the server. Please check your internet connection.');
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return Exception('Invalid request. Please check your input.');
          case 401:
            return Exception('You need to sign in to access this feature.');
          case 403:
            return Exception('You don\'t have permission to perform this action.');
          case 404:
            return Exception('The requested content was not found.');
          case 409:
            return Exception('This item already exists.');
          case 429:
            return Exception('Too many requests. Please try again later.');
          case 500:
          case 502:
          case 503:
          case 504:
            return Exception('Server error. Please try again later.');
          default:
            return Exception('${e.response?.data?['message'] ?? defaultMessage}');
        }
      
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      
      case DioExceptionType.unknown:
      default:
        return Exception(defaultMessage);
    }
  }

  // ============================================================================
  // CONVENIENCE METHODS FOR COMMON OPERATIONS
  // ============================================================================

  /// Get featured content for discovery hub
  Future<MarketplaceBrowseResponse> getFeaturedContent({int limit = 20}) async {
    return browseMarketplace(MarketplaceBrowseRequest(
      sortBy: 'popularity',
      limit: limit,
    ));
  }

  /// Get new releases
  Future<MarketplaceBrowseResponse> getNewReleases({int limit = 20}) async {
    return browseMarketplace(MarketplaceBrowseRequest(
      sortBy: 'newest',
      limit: limit,
    ));
  }

  /// Search marketplace by query
  Future<MarketplaceBrowseResponse> searchMarketplace(String query, {int limit = 20}) async {
    // Note: Search functionality would need to be added to the backend
    // For now, we'll use general browsing
    return browseMarketplace(MarketplaceBrowseRequest(
      sortBy: 'popularity',
      limit: limit,
    ));
  }

  /// Get content for specific age range
  Future<MarketplaceBrowseResponse> getContentForAge(int minAge, int maxAge, {int limit = 20}) async {
    return browseMarketplace(MarketplaceBrowseRequest(
      ageRangeMin: minAge,
      ageRangeMax: maxAge,
      sortBy: 'popularity',
      limit: limit,
    ));
  }

  /// Get content by category/type
  Future<MarketplaceBrowseResponse> getContentByType(List<String> contentTypes, {int limit = 20}) async {
    return browseMarketplace(MarketplaceBrowseRequest(
      contentType: contentTypes,
      sortBy: 'popularity',
      limit: limit,
    ));
  }

  /// Check if item is already in child's library
  Future<bool> isItemInLibrary(String childId, String itemId) async {
    try {
      final library = await getChildLibrary(childId);
      return library.any((item) => item.marketplaceItemId == itemId);
    } catch (e) {
      Timber.w('[MarketplaceAPI] Could not check library status: $e');
      return false;
    }
  }
}

// ============================================================================
// MARKETPLACE API ERRORS
// ============================================================================

class MarketplaceApiError extends Error {
  final String message;
  final int? statusCode;
  final String? code;

  MarketplaceApiError(this.message, {this.statusCode, this.code});

  @override
  String toString() => 'MarketplaceApiError: $message (Status: $statusCode, Code: $code)';
}

class MarketplaceNotFoundException extends MarketplaceApiError {
  MarketplaceNotFoundException(String message) : super(message, statusCode: 404, code: 'NOT_FOUND');
}

class MarketplaceUnauthorizedException extends MarketplaceApiError {
  MarketplaceUnauthorizedException(String message) : super(message, statusCode: 401, code: 'UNAUTHORIZED');
}

class MarketplaceBadRequestException extends MarketplaceApiError {
  MarketplaceBadRequestException(String message) : super(message, statusCode: 400, code: 'BAD_REQUEST');
}