# Content Packs Marketplace - Technical Architecture

## Database Schema Design

### Core Pack Management Tables

```sql
-- Schema: marketplace (new schema for marketplace functionality)

-- Content pack registry - master list of all available packs
CREATE TABLE marketplace.content_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Basic pack information
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL, -- URL-friendly identifier
    description TEXT NOT NULL,
    tagline VARCHAR(500), -- Short marketing description
    
    -- Categorization
    primary_category VARCHAR(100) NOT NULL, -- e.g., 'characters', 'environments', 'educational'
    subcategory VARCHAR(100), -- e.g., 'animals', 'fantasy', 'stem'
    tags TEXT[], -- Flexible tagging system
    
    -- Content metadata
    asset_count INTEGER NOT NULL DEFAULT 0, -- Total number of assets in pack
    download_size_mb DECIMAL(10,2) NOT NULL, -- Download size in MB
    content_version VARCHAR(20) NOT NULL DEFAULT '1.0.0', -- Semantic versioning
    
    -- Age and educational info
    min_age INTEGER NOT NULL CHECK (min_age >= 0 AND min_age <= 18),
    max_age INTEGER NOT NULL CHECK (max_age >= min_age AND max_age <= 18),
    educational_focus TEXT[], -- e.g., ['literacy', 'math', 'creativity']
    learning_objectives TEXT[], -- Specific learning goals
    
    -- Pricing and availability
    price_cents INTEGER NOT NULL DEFAULT 0, -- Price in cents (0 = free)
    currency_code CHAR(3) NOT NULL DEFAULT 'USD',
    is_premium BOOLEAN NOT NULL DEFAULT true,
    is_available BOOLEAN NOT NULL DEFAULT true,
    
    -- Feature compatibility
    compatible_features TEXT[] NOT NULL, -- e.g., ['sticker_book', 'ai_story', 'story_adventure']
    
    -- Publishing info
    creator_name VARCHAR(255), -- Content creator/publisher
    creator_id UUID, -- References external creator system
    
    -- Preview and marketing
    preview_image_url VARCHAR(500),
    preview_video_url VARCHAR(500),
    marketing_images TEXT[], -- Additional promotional images
    
    -- Status and lifecycle
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, deprecated, archived, recalled
    release_date DATE,
    featured_until TIMESTAMP WITH TIME ZONE, -- Featured promotion end
    
    -- Analytics and optimization
    download_count INTEGER NOT NULL DEFAULT 0,
    rating_average DECIMAL(3,2) CHECK (rating_average >= 0 AND rating_average <= 5),
    rating_count INTEGER NOT NULL DEFAULT 0,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by UUID, -- Admin user who created pack
    updated_by UUID -- Admin user who last updated pack
);

-- Indexes for performance
CREATE INDEX idx_content_packs_category ON marketplace.content_packs (primary_category, subcategory);
CREATE INDEX idx_content_packs_age ON marketplace.content_packs (min_age, max_age);
CREATE INDEX idx_content_packs_price ON marketplace.content_packs (price_cents);
CREATE INDEX idx_content_packs_status ON marketplace.content_packs (status, is_available);
CREATE INDEX idx_content_packs_featured ON marketplace.content_packs (featured_until) WHERE featured_until IS NOT NULL;

-- Individual assets within content packs
CREATE TABLE marketplace.pack_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pack_id UUID NOT NULL REFERENCES marketplace.content_packs(id) ON DELETE CASCADE,
    
    -- Asset identification
    asset_name VARCHAR(255) NOT NULL,
    asset_type VARCHAR(50) NOT NULL, -- 'sticker', 'background', 'character', 'prop', 'sound'
    file_path VARCHAR(500) NOT NULL, -- Relative path within pack
    
    -- Asset metadata
    file_size_bytes INTEGER NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    dimensions VARCHAR(20), -- e.g., '512x512' for images
    
    -- Categorization within pack
    category_tags TEXT[], -- Tags specific to this asset
    educational_value TEXT[], -- What this specific asset teaches/reinforces
    
    -- Feature usage
    sticker_book_compatible BOOLEAN NOT NULL DEFAULT false,
    ai_story_compatible BOOLEAN NOT NULL DEFAULT false,
    story_adventure_compatible BOOLEAN NOT NULL DEFAULT false,
    
    -- Display and ordering
    display_order INTEGER NOT NULL DEFAULT 0,
    is_featured BOOLEAN NOT NULL DEFAULT false, -- Featured in pack previews
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pack_assets_pack ON marketplace.pack_assets (pack_id, asset_type);
CREATE INDEX idx_pack_assets_features ON marketplace.pack_assets (sticker_book_compatible, ai_story_compatible, story_adventure_compatible);

-- User pack purchases and ownership
CREATE TABLE marketplace.user_pack_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Purchase identification
    family_id UUID NOT NULL, -- References core.families
    child_id UUID, -- References core.children (can be null for family-wide purchases)
    pack_id UUID NOT NULL REFERENCES marketplace.content_packs(id),
    
    -- Purchase details
    purchase_price_cents INTEGER NOT NULL,
    currency_code CHAR(3) NOT NULL,
    platform_transaction_id VARCHAR(255), -- App Store/Play Store transaction ID
    purchase_method VARCHAR(50) NOT NULL, -- 'in_app_purchase', 'gift', 'bundle', 'promotional'
    
    -- Gift information (if applicable)
    gift_from_family_id UUID, -- If this was a gift
    gift_message TEXT, -- Personal gift message
    
    -- Status tracking
    purchase_status VARCHAR(50) NOT NULL DEFAULT 'completed', -- pending, completed, refunded, disputed
    download_status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, downloading, completed, failed
    
    -- Usage and engagement
    first_used_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    usage_count INTEGER NOT NULL DEFAULT 0,
    
    -- Timestamps
    purchased_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    refund_deadline TIMESTAMP WITH TIME ZONE, -- 24 hours after purchase
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Ensure no duplicate purchases
CREATE UNIQUE INDEX idx_user_pack_purchases_unique ON marketplace.user_pack_purchases (family_id, child_id, pack_id) 
WHERE purchase_status = 'completed';

CREATE INDEX idx_user_pack_purchases_family ON marketplace.user_pack_purchases (family_id);
CREATE INDEX idx_user_pack_purchases_child ON marketplace.user_pack_purchases (child_id);
CREATE INDEX idx_user_pack_purchases_status ON marketplace.user_pack_purchases (purchase_status, download_status);

-- Pack bundles and collections
CREATE TABLE marketplace.pack_bundles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Bundle information
    bundle_name VARCHAR(255) NOT NULL,
    bundle_slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    
    -- Pricing
    individual_total_cents INTEGER NOT NULL, -- Sum of individual pack prices
    bundle_price_cents INTEGER NOT NULL, -- Bundle discount price
    discount_percentage DECIMAL(5,2), -- Calculated discount
    
    -- Availability
    is_available BOOLEAN NOT NULL DEFAULT true,
    available_from DATE,
    available_until DATE, -- For limited-time bundles
    
    -- Marketing
    preview_image_url VARCHAR(500),
    is_featured BOOLEAN NOT NULL DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Many-to-many relationship: bundles contain multiple packs
CREATE TABLE marketplace.bundle_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bundle_id UUID NOT NULL REFERENCES marketplace.pack_bundles(id) ON DELETE CASCADE,
    pack_id UUID NOT NULL REFERENCES marketplace.content_packs(id) ON DELETE CASCADE,
    
    -- Optional pack-specific bundle metadata
    is_primary BOOLEAN NOT NULL DEFAULT false, -- Main pack that defines bundle theme
    display_order INTEGER NOT NULL DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_bundle_packs_unique ON marketplace.bundle_packs (bundle_id, pack_id);

-- User ratings and reviews
CREATE TABLE marketplace.pack_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Review identification
    pack_id UUID NOT NULL REFERENCES marketplace.content_packs(id) ON DELETE CASCADE,
    family_id UUID NOT NULL, -- References core.families
    parent_id UUID NOT NULL, -- References core.users (must be parent)
    
    -- Review content
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_title VARCHAR(255),
    review_text TEXT,
    
    -- Educational feedback
    educational_value_rating INTEGER CHECK (educational_value_rating >= 1 AND educational_value_rating <= 5),
    child_engagement_rating INTEGER CHECK (child_engagement_rating >= 1 AND child_engagement_rating <= 5),
    would_recommend BOOLEAN,
    
    -- Child context
    child_age_at_review INTEGER, -- Child's age when reviewed
    usage_duration_days INTEGER, -- How long child used pack before review
    
    -- Moderation
    is_approved BOOLEAN NOT NULL DEFAULT false,
    moderation_notes TEXT,
    moderated_by UUID,
    moderated_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- One review per pack per family
CREATE UNIQUE INDEX idx_pack_reviews_unique ON marketplace.pack_reviews (pack_id, family_id);
CREATE INDEX idx_pack_reviews_approved ON marketplace.pack_reviews (pack_id, is_approved);

-- Pack usage analytics
CREATE TABLE marketplace.pack_usage_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Usage identification
    pack_id UUID NOT NULL REFERENCES marketplace.content_packs(id),
    family_id UUID NOT NULL,
    child_id UUID,
    
    -- Usage session details
    feature_used VARCHAR(50) NOT NULL, -- 'sticker_book', 'ai_story', etc.
    session_id UUID, -- Links to app session tracking
    assets_used TEXT[], -- Which specific assets were used
    
    -- Session metrics
    session_duration_seconds INTEGER,
    creative_outputs_created INTEGER DEFAULT 0, -- Stories created, sticker books made, etc.
    
    -- Engagement quality
    engagement_score DECIMAL(3,2), -- Calculated engagement quality (0-1)
    repeat_usage BOOLEAN NOT NULL DEFAULT false, -- Used same assets multiple times
    
    -- Timestamp
    used_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Partitioned by month for performance
CREATE INDEX idx_pack_usage_analytics_pack ON marketplace.pack_usage_analytics (pack_id, used_at);
CREATE INDEX idx_pack_usage_analytics_child ON marketplace.pack_usage_analytics (child_id, used_at);

-- Personalization and recommendations
CREATE TABLE marketplace.user_pack_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- User identification
    family_id UUID NOT NULL,
    child_id UUID, -- Can be family-wide or child-specific
    
    -- Preference data
    preferred_categories TEXT[], -- Categories child shows high engagement with
    preferred_themes TEXT[], -- Specific themes (animals, space, etc.)
    preferred_price_range VARCHAR(50), -- 'free', 'budget', 'premium'
    
    -- Learning preferences
    educational_priorities TEXT[], -- Parent-selected learning focus areas
    content_complexity VARCHAR(50), -- 'simple', 'moderate', 'complex'
    
    -- Behavioral preferences inferred from usage
    session_length_preference INTEGER, -- Typical session duration
    content_consumption_rate VARCHAR(50), -- 'slow', 'moderate', 'fast'
    feature_preferences TEXT[], -- Which app features child prefers
    
    -- Anti-preferences (what to avoid)
    disliked_categories TEXT[],
    content_to_avoid TEXT[], -- Specific content types that don't work
    
    -- Calculated scores
    exploration_tendency DECIMAL(3,2), -- How likely to try new content (0-1)
    brand_loyalty DECIMAL(3,2), -- How likely to buy from same creators (0-1)
    
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_user_pack_preferences_child ON marketplace.user_pack_preferences (family_id, child_id);

-- Administrative and operational tables

-- Content creator/publisher management
CREATE TABLE marketplace.content_creators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Creator information
    creator_name VARCHAR(255) NOT NULL,
    creator_slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    website_url VARCHAR(500),
    
    -- Business information
    contact_email VARCHAR(255) NOT NULL,
    revenue_share_percentage DECIMAL(5,2) NOT NULL DEFAULT 70.00, -- Creator's share of revenue
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_verified BOOLEAN NOT NULL DEFAULT false, -- Premium/trusted creator status
    
    -- Analytics
    total_packs_created INTEGER NOT NULL DEFAULT 0,
    total_revenue_cents INTEGER NOT NULL DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Pack promotion and marketing campaigns
CREATE TABLE marketplace.pack_promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Promotion identification
    promotion_name VARCHAR(255) NOT NULL,
    promotion_type VARCHAR(50) NOT NULL, -- 'discount', 'featured', 'bundle', 'free_trial'
    
    -- Affected content
    pack_ids UUID[], -- Array of pack IDs this promotion applies to
    category_filters TEXT[], -- Categories this promotion applies to
    
    -- Promotion details
    discount_percentage DECIMAL(5,2), -- For discount promotions
    fixed_discount_cents INTEGER, -- Alternative to percentage
    
    -- Timing
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Targeting
    target_age_min INTEGER,
    target_age_max INTEGER,
    target_user_segments TEXT[], -- 'new_users', 'high_spenders', etc.
    
    -- Limits
    max_uses INTEGER, -- Total promotion use limit
    max_uses_per_family INTEGER, -- Per-family limit
    current_uses INTEGER NOT NULL DEFAULT 0,
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by UUID NOT NULL -- Admin user who created promotion
);

CREATE INDEX idx_pack_promotions_active ON marketplace.pack_promotions (is_active, starts_at, ends_at);
```

### Integration with Existing Systems

#### Extending Current Game Tables
```sql
-- Extend existing games.child_game_data to support marketplace content
-- Add marketplace pack integration to existing game save data

ALTER TABLE games.child_game_data 
ADD COLUMN used_pack_assets JSONB DEFAULT '[]'::jsonb; -- Track which pack assets were used

-- Index for querying pack asset usage
CREATE INDEX idx_child_game_data_pack_assets 
ON games.child_game_data USING gin(used_pack_assets);

-- Example of extended game data structure:
-- {
--   "gameType": "sticker_book", 
--   "saveData": {...existing data...},
--   "usedPackAssets": [
--     {
--       "packId": "uuid", 
--       "assetId": "uuid", 
--       "assetType": "sticker",
--       "usageCount": 3
--     }
--   ]
-- }
```

#### Content Model Integration
```sql
-- Extend existing ContentModel to reference marketplace packs
-- This bridges curated content with purchasable pack content

CREATE TABLE content.pack_content_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Link content model entries to marketplace packs
    content_id VARCHAR(255) NOT NULL, -- References existing ContentModel.id
    pack_id UUID NOT NULL REFERENCES marketplace.content_packs(id),
    
    -- Integration metadata
    integration_type VARCHAR(50) NOT NULL, -- 'requires', 'enhances', 'compatible'
    asset_mapping JSONB, -- Maps content assets to pack assets
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

## API Architecture

### RESTful API Endpoints

```typescript
// Base API structure following existing patterns
interface MarketplaceAPI {
  // Pack browsing and discovery
  'GET /api/v2/marketplace/packs': {
    query: {
      category?: string;
      subcategory?: string;
      minAge?: number;
      maxAge?: number;
      priceMax?: number;
      featured?: boolean;
      search?: string;
      tags?: string[];
      page?: number;
      limit?: number;
      sortBy?: 'popular' | 'newest' | 'price_low' | 'price_high' | 'rating';
    };
    response: {
      packs: ContentPack[];
      pagination: PaginationInfo;
      filters: AvailableFilters;
    };
  };

  // Individual pack details
  'GET /api/v2/marketplace/packs/:packId': {
    response: ContentPack & {
      assets: PackAsset[];
      reviews: PackReview[];
      relatedPacks: ContentPack[];
      compatibility: FeatureCompatibility;
    };
  };

  // User's purchased packs
  'GET /api/v2/marketplace/user/packs': {
    query: {
      childId?: string;
      status?: 'all' | 'downloaded' | 'pending';
    };
    response: {
      purchases: UserPackPurchase[];
      downloadQueue: DownloadQueueItem[];
    };
  };

  // Purchase initiation
  'POST /api/v2/marketplace/packs/:packId/purchase': {
    body: {
      childId?: string; // For child-specific purchase
      paymentMethod: 'in_app_purchase' | 'family_sharing';
      giftToFamily?: string; // For gift purchases
      giftMessage?: string;
    };
    response: {
      purchaseId: string;
      status: 'pending' | 'completed' | 'failed';
      downloadUrl?: string;
      error?: string;
    };
  };

  // Bundle operations
  'GET /api/v2/marketplace/bundles': {
    response: PackBundle[];
  };

  'POST /api/v2/marketplace/bundles/:bundleId/purchase': {
    body: PurchaseRequest;
    response: PurchaseResponse;
  };

  // Pack usage tracking
  'POST /api/v2/marketplace/packs/:packId/usage': {
    body: {
      childId: string;
      feature: 'sticker_book' | 'ai_story' | 'story_adventure';
      assetsUsed: string[];
      sessionDuration: number;
      creativeOutputs: number;
    };
    response: { recorded: boolean };
  };

  // Reviews and ratings
  'POST /api/v2/marketplace/packs/:packId/reviews': {
    body: {
      rating: number; // 1-5
      title?: string;
      text?: string;
      educationalValueRating?: number;
      childEngagementRating?: number;
      wouldRecommend?: boolean;
      childAge: number;
    };
    response: PackReview;
  };

  // Personalization
  'GET /api/v2/marketplace/recommendations': {
    query: {
      childId: string;
      limit?: number;
      type?: 'similar' | 'educational' | 'trending' | 'completing_collection';
    };
    response: {
      recommendations: RecommendedPack[];
      reasoning: RecommendationReasoning[];
    };
  };
}
```

### Service Layer Architecture

```typescript
// Following existing service patterns in KTOR backend

// MarketplaceService.kt
class MarketplaceService(
    private val packRepository: PackRepository,
    private val purchaseRepository: PurchaseRepository,
    private val analyticsService: AnalyticsService,
    private val paymentService: PaymentService,
    private val downloadService: DownloadService
) {
    
    suspend fun getPackCatalog(request: PackCatalogRequest): PackCatalogResponse {
        // Implementation with filtering, pagination, and personalization
    }
    
    suspend fun purchasePack(
        familyId: String,
        packId: String,
        request: PurchaseRequest
    ): PurchaseResult {
        // COPPA-compliant purchase flow with parental approval
        return transaction {
            // 1. Validate parental approval
            // 2. Check for existing ownership
            // 3. Process payment through platform
            // 4. Create purchase record
            // 5. Initiate content download
            // 6. Send notifications
        }
    }
    
    suspend fun trackPackUsage(usage: PackUsageEvent) {
        // Analytics collection for recommendation engine
    }
}

// RecommendationEngine.kt
class RecommendationEngine(
    private val userPreferencesRepository: UserPreferencesRepository,
    private val packRepository: PackRepository,
    private val analyticsRepository: AnalyticsRepository
) {
    
    suspend fun getPersonalizedRecommendations(
        childId: String,
        type: RecommendationType
    ): List<RecommendedPack> {
        // ML-driven recommendations based on:
        // - Child's usage patterns
        // - Educational goals set by parents
        // - Similar user behaviors
        // - Content similarity
        // - Seasonal relevance
    }
    
    suspend fun updateUserPreferences(childId: String, usageData: UsageData) {
        // Continuously update preference model based on behavior
    }
}
```

## Frontend Integration Architecture

### State Management with Riverpod

```dart
// marketplace_providers.dart
// Following existing provider patterns

// Marketplace state management
final marketplaceStateProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MarketplaceNotifier(apiService);
});

class MarketplaceState {
  final List<ContentPack> packs;
  final List<ContentPack> featuredPacks;
  final List<UserPackPurchase> ownedPacks;
  final PackFilters activeFilters;
  final bool isLoading;
  final String? error;
  final Map<String, DownloadProgress> downloadProgress;

  MarketplaceState({
    this.packs = const [],
    this.featuredPacks = const [],
    this.ownedPacks = const [],
    this.activeFilters = const PackFilters(),
    this.isLoading = false,
    this.error,
    this.downloadProgress = const {},
  });

  // copyWith implementation...
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final ApiService _apiService;
  
  MarketplaceNotifier(this._apiService) : super(MarketplaceState());
  
  Future<void> loadPackCatalog({PackFilters? filters}) async {
    // Load and filter pack catalog
  }
  
  Future<PurchaseResult> purchasePack(String packId, {String? childId}) async {
    // Handle COPPA-compliant purchase flow
  }
  
  Future<void> downloadPack(String packId) async {
    // Manage pack download with progress tracking
  }
}

// Integration with existing game providers
final stickerGameProviderWithPacks = Provider((ref) {
  final stickerGameProvider = ref.watch(stickerGameProvider);
  final marketplaceState = ref.watch(marketplaceStateProvider);
  
  // Merge owned pack content with base sticker library
  final enhancedStickerLibrary = StickerLibrary.merge([
    StickerLibrary.getDefaultStickers(),
    ...marketplaceState.ownedPacks
        .where((pack) => pack.isCompatibleWith('sticker_book'))
        .map((pack) => StickerLibrary.fromPack(pack)),
  ]);
  
  return stickerGameProvider.withLibrary(enhancedStickerLibrary);
});
```

### UI Component Architecture

```dart
// marketplace_screen.dart
class MarketplaceScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  @override
  Widget build(BuildContext context) {
    final marketplaceState = ref.watch(marketplaceStateProvider);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Featured packs carousel
          SliverToBoxAdapter(
            child: FeaturedPacksCarousel(
              packs: marketplaceState.featuredPacks,
              onPackTap: _navigateToPackDetail,
            ),
          ),
          
          // Category quick access
          SliverToBoxAdapter(
            child: CategoryQuickAccess(
              onCategoryTap: _filterByCategory,
            ),
          ),
          
          // Pack grid with filters
          PackGridView(
            packs: marketplaceState.packs,
            filters: marketplaceState.activeFilters,
            onFilterChange: _updateFilters,
            onPackTap: _navigateToPackDetail,
          ),
        ],
      ),
    );
  }
}

// pack_detail_screen.dart
class PackDetailScreen extends ConsumerWidget {
  final String packId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pack detail view with purchase flow
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            PackPreviewCarousel(packId: packId),
            PackInfoSection(packId: packId),
            EducationalBenefitsSection(packId: packId),
            AssetPreviewGrid(packId: packId),
            ReviewsSection(packId: packId),
            RelatedPacksSection(packId: packId),
          ],
        ),
      ),
      bottomNavigationBar: PurchaseBar(
        packId: packId,
        onPurchase: _handlePurchase,
      ),
    );
  }
}
```

## Content Delivery Architecture

### Asset Storage and CDN

```typescript
// Content delivery strategy
interface ContentDeliveryConfig {
  // Multi-tier storage strategy
  storage: {
    // Hot storage for popular/new packs
    tier1: 'AWS S3 + CloudFront CDN';
    // Warm storage for standard catalog
    tier2: 'AWS S3 Standard';
    // Cold storage for archived content
    tier3: 'AWS Glacier';
  };
  
  // Regional distribution
  regions: [
    'us-east-1',    // North America
    'eu-west-1',    // Europe
    'ap-southeast-1' // Asia-Pacific
  ];
  
  // Content optimization
  formats: {
    images: ['WebP', 'PNG', 'SVG']; // Progressive enhancement
    videos: ['MP4 H.264', 'WebM']; // Platform compatibility
    audio: ['AAC', 'OGG']; // Sound effects and narration
  };
  
  // Delivery optimization
  compression: {
    lossless: ['SVG', 'PNG with transparency'];
    lossy: ['WebP for photos', 'AAC for audio'];
  };
  
  // Offline support
  caching: {
    strategy: 'download-on-purchase';
    fallback: 'essential-assets-only';
    storage_limit: '1GB per device';
  };
}
```

### Download Management

```dart
// download_manager.dart
class PackDownloadManager {
  static const String _downloadDirectory = 'marketplace_packs';
  
  Future<void> downloadPack(String packId) async {
    try {
      // 1. Verify purchase ownership
      await _verifyPackOwnership(packId);
      
      // 2. Check available storage
      await _checkStorageSpace(packId);
      
      // 3. Download with resume capability
      await _downloadWithProgress(packId);
      
      // 4. Verify download integrity
      await _verifyDownload(packId);
      
      // 5. Update local database
      await _updateLocalPackDatabase(packId);
      
      // 6. Notify UI of completion
      _notifyDownloadComplete(packId);
      
    } catch (e) {
      _handleDownloadError(packId, e);
    }
  }
  
  Stream<DownloadProgress> watchDownloadProgress(String packId) {
    // Real-time download progress updates
  }
  
  Future<bool> isPackAvailableOffline(String packId) async {
    // Check if pack is fully downloaded and verified
  }
}
```

## Security and Privacy Architecture

### Data Protection

```sql
-- Encryption at rest for sensitive data
-- All personal purchase data encrypted with family-specific keys

-- Data retention policies
CREATE OR REPLACE FUNCTION marketplace.cleanup_expired_data()
RETURNS void AS $$
BEGIN
    -- Remove analytics data older than 2 years
    DELETE FROM marketplace.pack_usage_analytics 
    WHERE used_at < NOW() - INTERVAL '2 years';
    
    -- Remove failed/abandoned purchases after 30 days
    DELETE FROM marketplace.user_pack_purchases 
    WHERE purchase_status = 'failed' 
    AND created_at < NOW() - INTERVAL '30 days';
    
    -- Archive old reviews but preserve aggregate ratings
    UPDATE marketplace.pack_reviews 
    SET review_text = NULL, review_title = NULL
    WHERE created_at < NOW() - INTERVAL '3 years';
END;
$$ LANGUAGE plpgsql;
```

### COPPA Compliance Integration

```dart
// coppa_purchase_handler.dart
class COPPAPurchaseHandler {
  Future<PurchaseResult> initiatePurchase({
    required String packId,
    required String childId,
    String? giftMessage,
  }) async {
    
    // 1. Verify child age and COPPA status
    final child = await _childRepository.getChild(childId);
    final coppaStatus = await _coppaService.getConsentStatus(child.familyId);
    
    if (!coppaStatus.canMakePurchases) {
      return PurchaseResult.coppaViolation();
    }
    
    // 2. Require parental approval
    final parentalApproval = await _requestParentalApproval(
      purchaseType: 'content_pack',
      amount: pack.price,
      childId: childId,
    );
    
    if (!parentalApproval.approved) {
      return PurchaseResult.parentalDecline();
    }
    
    // 3. Proceed with platform purchase
    return await _completePlatformPurchase(packId, parentalApproval.token);
  }
}
```

This technical architecture provides a comprehensive foundation for implementing the Content Packs Marketplace while integrating seamlessly with WonderNest's existing systems and maintaining COPPA compliance throughout.