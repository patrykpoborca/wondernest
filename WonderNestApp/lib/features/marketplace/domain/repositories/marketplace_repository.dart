// WonderNest Marketplace Repository Interface
// Domain layer contract for marketplace operations

import '../../data/models/marketplace_models.dart';

abstract class MarketplaceRepository {
  // ============================================================================
  // MARKETPLACE BROWSING
  // ============================================================================
  
  /// Browse marketplace with optional filters and pagination
  Future<MarketplaceBrowseResponse> browseMarketplace(MarketplaceBrowseRequest request);
  
  /// Get detailed information for a specific marketplace item
  Future<MarketplaceListing> getMarketplaceItem(String itemId);
  
  /// Get featured content for discovery hub
  Future<MarketplaceBrowseResponse> getFeaturedContent({int limit = 20});
  
  /// Get newly released content
  Future<MarketplaceBrowseResponse> getNewReleases({int limit = 20});

  // ============================================================================
  // CHILD LIBRARY MANAGEMENT
  // ============================================================================
  
  /// Get all library items for a specific child
  Future<List<ChildLibrary>> getChildLibrary(String childId);
  
  /// Get library statistics and analytics for a child
  Future<LibraryStatsResponse> getLibraryStats(String childId);
  
  /// Check if a specific item is already in child's library
  Future<bool> isItemInLibrary(String childId, String itemId);

  // ============================================================================
  // COLLECTION MANAGEMENT
  // ============================================================================
  
  /// Get all collections for a specific child
  Future<List<ChildCollection>> getChildCollections(String childId);
  
  /// Create a new collection for organizing content
  Future<ChildCollection> createCollection(CreateCollectionRequest request);

  // ============================================================================
  // PURCHASE OPERATIONS
  // ============================================================================
  
  /// Purchase a marketplace item for specified children
  Future<PurchaseResponse> purchaseItem(PurchaseRequest request);

  // ============================================================================
  // CREATOR OPERATIONS
  // ============================================================================
  
  /// Create a creator profile (for content creators)
  Future<CreatorProfile> createCreatorProfile(CreateCreatorProfileRequest request);
  
  /// Get current user's creator profile
  Future<CreatorProfile> getCreatorProfile();

  // ============================================================================
  // REVIEW OPERATIONS
  // ============================================================================
  
  /// Create a review for a marketplace item
  Future<void> createReview(CreateReviewRequest request);
  
  /// Get all reviews for a specific marketplace item
  Future<List<Map<String, dynamic>>> getItemReviews(String itemId);

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================
  
  /// Clear all cached data and refresh from API
  Future<void> refreshCache();
}