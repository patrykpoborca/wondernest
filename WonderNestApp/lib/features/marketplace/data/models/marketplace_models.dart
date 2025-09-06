// WonderNest Marketplace Models - Flutter
// Matches Rust backend structures for seamless API integration

import 'package:json_annotation/json_annotation.dart';

part 'marketplace_models.g.dart';

// ============================================================================
// CREATOR PROFILE MODELS
// ============================================================================

@JsonSerializable()
class CreatorProfile {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  
  // Creator information
  @JsonKey(name: 'display_name')
  final String displayName;
  final String? bio;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;
  @JsonKey(name: 'website_url')
  final String? websiteUrl;
  @JsonKey(name: 'social_links')
  final Map<String, dynamic>? socialLinks;
  
  // Credentials and verification
  @JsonKey(name: 'verified_educator')
  final bool verifiedEducator;
  @JsonKey(name: 'educator_credentials')
  final Map<String, dynamic>? educatorCredentials;
  @JsonKey(name: 'content_specialties')
  final List<String> contentSpecialties;
  @JsonKey(name: 'languages_supported')
  final List<String> languagesSupported;
  
  // Creator tier and status
  final String tier;
  @JsonKey(name: 'tier_updated_at')
  final DateTime? tierUpdatedAt;
  
  // Performance metrics
  @JsonKey(name: 'total_sales')
  final int totalSales;
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'average_rating')
  final double averageRating;
  @JsonKey(name: 'total_ratings')
  final int totalRatings;
  @JsonKey(name: 'content_count')
  final int contentCount;
  @JsonKey(name: 'follower_count')
  final int followerCount;
  
  // Monthly metrics
  @JsonKey(name: 'monthly_sales')
  final int monthlySales;
  @JsonKey(name: 'monthly_revenue')
  final double monthlyRevenue;
  @JsonKey(name: 'last_metrics_update')
  final DateTime lastMetricsUpdate;
  
  // Platform relationship
  @JsonKey(name: 'revenue_share_percentage')
  final double revenueSharePercentage;
  @JsonKey(name: 'custom_contract')
  final bool customContract;
  @JsonKey(name: 'featured_creator')
  final bool featuredCreator;
  @JsonKey(name: 'featured_until')
  final DateTime? featuredUntil;
  
  // Account status
  @JsonKey(name: 'account_status')
  final String accountStatus;
  
  // Timestamps
  @JsonKey(name: 'creator_since')
  final DateTime creatorSince;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  CreatorProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverImageUrl,
    this.websiteUrl,
    this.socialLinks,
    required this.verifiedEducator,
    this.educatorCredentials,
    required this.contentSpecialties,
    required this.languagesSupported,
    required this.tier,
    this.tierUpdatedAt,
    required this.totalSales,
    required this.totalRevenue,
    required this.averageRating,
    required this.totalRatings,
    required this.contentCount,
    required this.followerCount,
    required this.monthlySales,
    required this.monthlyRevenue,
    required this.lastMetricsUpdate,
    required this.revenueSharePercentage,
    required this.customContract,
    required this.featuredCreator,
    this.featuredUntil,
    required this.accountStatus,
    required this.creatorSince,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CreatorProfile.fromJson(Map<String, dynamic> json) => _$CreatorProfileFromJson(json);
  Map<String, dynamic> toJson() => _$CreatorProfileToJson(this);
}

@JsonSerializable()
class CreateCreatorProfileRequest {
  @JsonKey(name: 'display_name')
  final String displayName;
  final String? bio;
  @JsonKey(name: 'content_specialties')
  final List<String> contentSpecialties;
  @JsonKey(name: 'languages_supported')
  final List<String> languagesSupported;
  @JsonKey(name: 'website_url')
  final String? websiteUrl;
  @JsonKey(name: 'social_links')
  final Map<String, dynamic>? socialLinks;

  CreateCreatorProfileRequest({
    required this.displayName,
    this.bio,
    required this.contentSpecialties,
    required this.languagesSupported,
    this.websiteUrl,
    this.socialLinks,
  });

  factory CreateCreatorProfileRequest.fromJson(Map<String, dynamic> json) => _$CreateCreatorProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCreatorProfileRequestToJson(this);
}

// ============================================================================
// MARKETPLACE LISTING MODELS  
// ============================================================================

@JsonSerializable()
class MarketplaceListing {
  final String id;
  @JsonKey(name: 'template_id')
  final String templateId;
  @JsonKey(name: 'seller_id')
  final String sellerId;
  final double price;
  @JsonKey(name: 'original_price')
  final double? originalPrice;
  final String? currency;
  final String? status;
  final double? rating;
  @JsonKey(name: 'review_count')
  final int? reviewCount;
  @JsonKey(name: 'purchase_count')
  final int? purchaseCount;
  @JsonKey(name: 'marketing_title')
  final String? marketingTitle;
  @JsonKey(name: 'marketing_description')
  final String? marketingDescription;
  @JsonKey(name: 'featured_image_url')
  final String? featuredImageUrl;
  @JsonKey(name: 'search_keywords')
  final List<String>? searchKeywords;
  @JsonKey(name: 'featured_start')
  final DateTime? featuredStart;
  @JsonKey(name: 'featured_end')
  final DateTime? featuredEnd;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  MarketplaceListing({
    required this.id,
    required this.templateId,
    required this.sellerId,
    required this.price,
    this.originalPrice,
    this.currency,
    this.status,
    this.rating,
    this.reviewCount,
    this.purchaseCount,
    this.marketingTitle,
    this.marketingDescription,
    this.featuredImageUrl,
    this.searchKeywords,
    this.featuredStart,
    this.featuredEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) => _$MarketplaceListingFromJson(json);
  Map<String, dynamic> toJson() => _$MarketplaceListingToJson(this);
}

// ============================================================================
// MARKETPLACE BROWSING MODELS
// ============================================================================

@JsonSerializable()
class MarketplaceBrowseRequest {
  @JsonKey(name: 'content_type')
  final List<String>? contentType;
  @JsonKey(name: 'age_range_min')
  final int? ageRangeMin;
  @JsonKey(name: 'age_range_max')
  final int? ageRangeMax;
  @JsonKey(name: 'price_min')
  final double? priceMin;
  @JsonKey(name: 'price_max')
  final double? priceMax;
  @JsonKey(name: 'creator_tiers')
  final List<String>? creatorTiers;
  @JsonKey(name: 'sort_by')
  final String? sortBy; // "popularity", "rating", "price", "newest"
  final int? page;
  final int? limit;

  MarketplaceBrowseRequest({
    this.contentType,
    this.ageRangeMin,
    this.ageRangeMax,
    this.priceMin,
    this.priceMax,
    this.creatorTiers,
    this.sortBy,
    this.page,
    this.limit,
  });

  factory MarketplaceBrowseRequest.fromJson(Map<String, dynamic> json) => _$MarketplaceBrowseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MarketplaceBrowseRequestToJson(this);

  // Helper method to convert to query parameters
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    
    if (contentType != null && contentType!.isNotEmpty) {
      params['content_type'] = contentType!.join(',');
    }
    if (ageRangeMin != null) params['age_range_min'] = ageRangeMin.toString();
    if (ageRangeMax != null) params['age_range_max'] = ageRangeMax.toString();
    if (priceMin != null) params['price_min'] = priceMin.toString();
    if (priceMax != null) params['price_max'] = priceMax.toString();
    if (creatorTiers != null && creatorTiers!.isNotEmpty) {
      params['creator_tiers'] = creatorTiers!.join(',');
    }
    if (sortBy != null) params['sort_by'] = sortBy!;
    if (page != null) params['page'] = page.toString();
    if (limit != null) params['limit'] = limit.toString();
    
    return params;
  }
}

@JsonSerializable()
class MarketplaceBrowseResponse {
  final List<MarketplaceItemSummary> items;
  @JsonKey(name: 'total_count')
  final int totalCount;
  final int page;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  MarketplaceBrowseResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.totalPages,
  });

  factory MarketplaceBrowseResponse.fromJson(Map<String, dynamic> json) => _$MarketplaceBrowseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MarketplaceBrowseResponseToJson(this);
}

@JsonSerializable()
class MarketplaceItemSummary {
  final String id;
  final String title;
  final double price;
  final double? rating;
  @JsonKey(name: 'review_count')
  final int? reviewCount;
  @JsonKey(name: 'featured_image_url')
  final String? featuredImageUrl;
  @JsonKey(name: 'creator_name')
  final String creatorName;
  @JsonKey(name: 'creator_tier')
  final String creatorTier;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'age_range')
  final String ageRange;

  MarketplaceItemSummary({
    required this.id,
    required this.title,
    required this.price,
    this.rating,
    this.reviewCount,
    this.featuredImageUrl,
    required this.creatorName,
    required this.creatorTier,
    required this.contentType,
    required this.ageRange,
  });

  factory MarketplaceItemSummary.fromJson(Map<String, dynamic> json) => _$MarketplaceItemSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$MarketplaceItemSummaryToJson(this);
}

// ============================================================================
// CHILD LIBRARY MODELS
// ============================================================================

@JsonSerializable()
class ChildLibrary {
  final String id;
  @JsonKey(name: 'child_id')
  final String childId;
  @JsonKey(name: 'marketplace_item_id')
  final String marketplaceItemId;
  
  // Purchase tracking
  @JsonKey(name: 'purchased_by')
  final String purchasedBy;
  @JsonKey(name: 'purchase_date')
  final DateTime purchaseDate;
  @JsonKey(name: 'purchase_price')
  final double purchasePrice;
  @JsonKey(name: 'licensing_type')
  final String licensingType;
  
  // Access and progress
  @JsonKey(name: 'first_accessed')
  final DateTime? firstAccessed;
  @JsonKey(name: 'last_accessed')
  final DateTime? lastAccessed;
  @JsonKey(name: 'total_play_time_minutes')
  final int totalPlayTimeMinutes;
  @JsonKey(name: 'completion_percentage')
  final double completionPercentage;
  final bool favorite;
  
  // Organization
  @JsonKey(name: 'custom_collections')
  final List<String> customCollections;
  final List<String> tags;
  @JsonKey(name: 'parent_rating')
  final int? parentRating;
  @JsonKey(name: 'parent_notes')
  final String? parentNotes;
  
  // Offline and sync
  final bool downloaded;
  @JsonKey(name: 'download_date')
  final DateTime? downloadDate;
  @JsonKey(name: 'offline_available')
  final bool offlineAvailable;
  @JsonKey(name: 'sync_status')
  final String syncStatus;
  
  // Usage tracking
  @JsonKey(name: 'session_count')
  final int sessionCount;
  @JsonKey(name: 'average_session_minutes')
  final double averageSessionMinutes;
  @JsonKey(name: 'skill_progress')
  final Map<String, dynamic>? skillProgress;
  @JsonKey(name: 'vocabulary_learned')
  final List<String> vocabularyLearned;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  ChildLibrary({
    required this.id,
    required this.childId,
    required this.marketplaceItemId,
    required this.purchasedBy,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.licensingType,
    this.firstAccessed,
    this.lastAccessed,
    required this.totalPlayTimeMinutes,
    required this.completionPercentage,
    required this.favorite,
    required this.customCollections,
    required this.tags,
    this.parentRating,
    this.parentNotes,
    required this.downloaded,
    this.downloadDate,
    required this.offlineAvailable,
    required this.syncStatus,
    required this.sessionCount,
    required this.averageSessionMinutes,
    this.skillProgress,
    required this.vocabularyLearned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildLibrary.fromJson(Map<String, dynamic> json) => _$ChildLibraryFromJson(json);
  Map<String, dynamic> toJson() => _$ChildLibraryToJson(this);
}

// ============================================================================
// COLLECTION MODELS
// ============================================================================

@JsonSerializable()
class ChildCollection {
  final String id;
  @JsonKey(name: 'child_id')
  final String childId;
  final String name;
  final String? description;
  @JsonKey(name: 'color_theme')
  final String colorTheme;
  @JsonKey(name: 'icon_name')
  final String iconName;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'is_system_collection')
  final bool isSystemCollection;
  @JsonKey(name: 'parent_created')
  final bool parentCreated;
  @JsonKey(name: 'shared_with_siblings')
  final bool sharedWithSiblings;
  final bool collaborative;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  ChildCollection({
    required this.id,
    required this.childId,
    required this.name,
    this.description,
    required this.colorTheme,
    required this.iconName,
    required this.displayOrder,
    required this.isSystemCollection,
    required this.parentCreated,
    required this.sharedWithSiblings,
    required this.collaborative,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildCollection.fromJson(Map<String, dynamic> json) => _$ChildCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$ChildCollectionToJson(this);
}

@JsonSerializable()
class CreateCollectionRequest {
  @JsonKey(name: 'child_id')
  final String childId;
  final String name;
  final String? description;
  @JsonKey(name: 'color_theme')
  final String? colorTheme;
  @JsonKey(name: 'icon_name')
  final String? iconName;

  CreateCollectionRequest({
    required this.childId,
    required this.name,
    this.description,
    this.colorTheme,
    this.iconName,
  });

  factory CreateCollectionRequest.fromJson(Map<String, dynamic> json) => _$CreateCollectionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCollectionRequestToJson(this);
}

// ============================================================================
// PURCHASE MODELS
// ============================================================================

@JsonSerializable()
class PurchaseRequest {
  @JsonKey(name: 'marketplace_item_id')
  final String marketplaceItemId;
  @JsonKey(name: 'target_children')
  final List<String> targetChildren;
  @JsonKey(name: 'payment_method_id')
  final String paymentMethodId;
  @JsonKey(name: 'billing_address')
  final Map<String, dynamic>? billingAddress;

  PurchaseRequest({
    required this.marketplaceItemId,
    required this.targetChildren,
    required this.paymentMethodId,
    this.billingAddress,
  });

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) => _$PurchaseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PurchaseRequestToJson(this);
}

@JsonSerializable()
class PurchaseResponse {
  @JsonKey(name: 'transaction_id')
  final String transactionId;
  final String status;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'library_items_created')
  final List<String> libraryItemsCreated;

  PurchaseResponse({
    required this.transactionId,
    required this.status,
    required this.totalAmount,
    required this.libraryItemsCreated,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) => _$PurchaseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PurchaseResponseToJson(this);
}

// ============================================================================
// REVIEW MODELS
// ============================================================================

@JsonSerializable()
class CreateReviewRequest {
  @JsonKey(name: 'marketplace_item_id')
  final String marketplaceItemId;
  final int rating;
  final String? title;
  @JsonKey(name: 'review_text')
  final String? reviewText;
  @JsonKey(name: 'educational_value')
  final int? educationalValue;
  @JsonKey(name: 'age_appropriateness')
  final int? ageAppropriateness;
  @JsonKey(name: 'engagement_level')
  final int? engagementLevel;
  @JsonKey(name: 'technical_quality')
  final int? technicalQuality;
  @JsonKey(name: 'child_age_when_reviewed')
  final int? childAgeWhenReviewed;
  @JsonKey(name: 'would_recommend')
  final bool? wouldRecommend;

  CreateReviewRequest({
    required this.marketplaceItemId,
    required this.rating,
    this.title,
    this.reviewText,
    this.educationalValue,
    this.ageAppropriateness,
    this.engagementLevel,
    this.technicalQuality,
    this.childAgeWhenReviewed,
    this.wouldRecommend,
  });

  factory CreateReviewRequest.fromJson(Map<String, dynamic> json) => _$CreateReviewRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateReviewRequestToJson(this);
}

// ============================================================================
// LIBRARY STATS MODELS
// ============================================================================

@JsonSerializable()
class LibraryStatsResponse {
  @JsonKey(name: 'total_items')
  final int totalItems;
  @JsonKey(name: 'favorites_count')
  final int favoritesCount;
  @JsonKey(name: 'total_play_time_hours')
  final double totalPlayTimeHours;
  @JsonKey(name: 'completion_rate')
  final double completionRate;
  @JsonKey(name: 'recent_activities')
  final List<LibraryActivity> recentActivities;

  LibraryStatsResponse({
    required this.totalItems,
    required this.favoritesCount,
    required this.totalPlayTimeHours,
    required this.completionRate,
    required this.recentActivities,
  });

  factory LibraryStatsResponse.fromJson(Map<String, dynamic> json) => _$LibraryStatsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LibraryStatsResponseToJson(this);
}

@JsonSerializable()
class LibraryActivity {
  @JsonKey(name: 'item_title')
  final String itemTitle;
  @JsonKey(name: 'activity_type')
  final String activityType; // "purchased", "completed", "favorite_added"
  final DateTime timestamp;
  @JsonKey(name: 'play_time_minutes')
  final int? playTimeMinutes;

  LibraryActivity({
    required this.itemTitle,
    required this.activityType,
    required this.timestamp,
    this.playTimeMinutes,
  });

  factory LibraryActivity.fromJson(Map<String, dynamic> json) => _$LibraryActivityFromJson(json);
  Map<String, dynamic> toJson() => _$LibraryActivityToJson(this);
}