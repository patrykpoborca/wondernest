-- =============================================================================
-- WonderNest Marketplace & Library System
-- Migration V8: Comprehensive marketplace, library, and creator ecosystem
-- =============================================================================

-- =============================================================================
-- ENHANCED MARKETPLACE FEATURES
-- =============================================================================

-- Extend existing marketplace_listings with richer features
ALTER TABLE games.marketplace_listings 
    ADD COLUMN IF NOT EXISTS content_type VARCHAR(50) DEFAULT 'story' 
        CHECK (content_type IN ('story', 'game', 'activity', 'educational_video', 'interactive_book')),
    ADD COLUMN IF NOT EXISTS licensing_model VARCHAR(50) DEFAULT 'single_child'
        CHECK (licensing_model IN ('single_child', 'family', 'classroom', 'unlimited')),
    ADD COLUMN IF NOT EXISTS subscription_eligible BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS bundle_ids UUID[],
    ADD COLUMN IF NOT EXISTS creator_tier VARCHAR(30),
    ADD COLUMN IF NOT EXISTS educational_alignment JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS accessibility_features JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS localization_available VARCHAR(10)[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS demo_available BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS refund_policy VARCHAR(30) DEFAULT 'standard_7_day'
        CHECK (refund_policy IN ('no_refund', 'standard_7_day', 'extended_30_day', 'satisfaction_guarantee'));

-- =============================================================================
-- CREATOR ECOSYSTEM
-- =============================================================================

-- Creator profiles for content creators and publishers
CREATE TABLE IF NOT EXISTS games.creator_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE, -- References core.users(id)
    
    -- Creator information
    display_name VARCHAR(100) NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    cover_image_url TEXT,
    website_url TEXT,
    social_links JSONB DEFAULT '{}',
    
    -- Credentials and verification
    verified_educator BOOLEAN DEFAULT false,
    educator_credentials JSONB DEFAULT '{}',
    content_specialties TEXT[] DEFAULT '{}',
    languages_supported VARCHAR(10)[] DEFAULT '{}',
    
    -- Creator tier and status
    tier VARCHAR(30) CHECK (tier IN (
        'hobbyist', 
        'emerging', 
        'professional', 
        'verified_educator', 
        'partner_studio'
    )) DEFAULT 'hobbyist',
    tier_updated_at TIMESTAMP WITH TIME ZONE,
    
    -- Performance metrics
    total_sales INTEGER DEFAULT 0,
    total_revenue DECIMAL(12,2) DEFAULT 0.00,
    average_rating DECIMAL(3,2) DEFAULT 0.00 CHECK (average_rating >= 0 AND average_rating <= 5),
    total_ratings INTEGER DEFAULT 0,
    content_count INTEGER DEFAULT 0,
    follower_count INTEGER DEFAULT 0,
    
    -- Monthly metrics (for tier evaluation)
    monthly_sales INTEGER DEFAULT 0,
    monthly_revenue DECIMAL(10,2) DEFAULT 0.00,
    last_metrics_update TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Payment information (encrypted in application layer)
    payment_method VARCHAR(50) CHECK (payment_method IN (
        'stripe_connect', 'paypal', 'direct_deposit', 'check'
    )),
    payment_details JSONB DEFAULT '{}', -- Encrypted
    tax_information JSONB DEFAULT '{}', -- Encrypted
    w9_on_file BOOLEAN DEFAULT false,
    
    -- Platform relationship
    revenue_share_percentage DECIMAL(5,2) DEFAULT 70.00 CHECK (
        revenue_share_percentage >= 0 AND revenue_share_percentage <= 100
    ),
    custom_contract BOOLEAN DEFAULT false,
    featured_creator BOOLEAN DEFAULT false,
    featured_until TIMESTAMP WITH TIME ZONE,
    
    -- Account status
    account_status VARCHAR(30) DEFAULT 'pending_verification' CHECK (account_status IN (
        'pending_verification', 'active', 'suspended', 'banned', 'inactive'
    )),
    suspension_reason TEXT,
    suspension_until TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    creator_since TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_content_published TIMESTAMP WITH TIME ZONE,
    last_payout_at TIMESTAMP WITH TIME ZONE,
    next_payout_eligible TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Creator payout history
CREATE TABLE IF NOT EXISTS games.creator_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES games.creator_profiles(id) ON DELETE CASCADE,
    
    -- Payout details
    payout_amount DECIMAL(10,2) NOT NULL CHECK (payout_amount > 0),
    currency VARCHAR(3) DEFAULT 'USD',
    payout_method VARCHAR(50) NOT NULL,
    
    -- Transaction references
    transaction_id VARCHAR(255) UNIQUE,
    payment_processor VARCHAR(50),
    
    -- Payout period
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Status tracking
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'completed', 'failed', 'cancelled'
    )),
    failure_reason TEXT,
    
    -- Metadata
    invoice_number VARCHAR(50),
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- CHILD'S LIBRARY SYSTEM
-- =============================================================================

-- Child's personal library of acquired content
CREATE TABLE IF NOT EXISTS games.child_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL, -- References family.child_profiles(id)
    
    -- Content reference (polymorphic)
    content_id UUID NOT NULL,
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN (
        'story', 'game', 'activity', 'educational_video', 'interactive_book'
    )),
    
    -- Acquisition details
    acquisition_type VARCHAR(30) NOT NULL CHECK (acquisition_type IN (
        'purchased', 'gifted', 'free', 'subscription', 
        'promotional', 'parent_created', 'bundled', 'shared'
    )),
    acquired_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    acquired_by UUID, -- Parent who acquired it
    purchase_id UUID, -- References games.story_purchases(id) if applicable
    gift_from UUID, -- If gifted, who gifted it
    
    -- Access control
    is_available BOOLEAN DEFAULT true,
    available_until TIMESTAMP WITH TIME ZONE, -- For time-limited content
    requires_online BOOLEAN DEFAULT false,
    download_count INTEGER DEFAULT 0,
    last_downloaded_at TIMESTAMP WITH TIME ZONE,
    offline_expiry TIMESTAMP WITH TIME ZONE,
    
    -- Usage tracking
    first_accessed_at TIMESTAMP WITH TIME ZONE,
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    total_access_count INTEGER DEFAULT 0,
    
    -- Organization
    collection_ids UUID[] DEFAULT '{}',
    is_favorite BOOLEAN DEFAULT false,
    is_hidden BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    custom_tags TEXT[] DEFAULT '{}',
    
    -- Progress tracking
    completion_percentage INTEGER DEFAULT 0 CHECK (
        completion_percentage >= 0 AND completion_percentage <= 100
    ),
    total_time_minutes INTEGER DEFAULT 0,
    times_completed INTEGER DEFAULT 0,
    last_position JSONB, -- For resuming (page number, timestamp, etc.)
    achievements_earned JSONB DEFAULT '[]',
    
    -- Ratings and feedback
    child_rating INTEGER CHECK (child_rating BETWEEN 1 AND 5),
    child_feedback TEXT,
    parent_rating INTEGER CHECK (parent_rating BETWEEN 1 AND 5),
    parent_notes TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_child_content UNIQUE(child_id, content_id, content_type)
);

-- Library collections for organizing content
CREATE TABLE IF NOT EXISTS games.library_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL, -- References family.families(id)
    
    -- Collection details
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(7) CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),
    cover_image_url TEXT,
    
    -- Collection type
    collection_type VARCHAR(30) CHECK (collection_type IN (
        'custom', 'smart', 'seasonal', 'curriculum', 
        'age_based', 'skill_based', 'themed'
    )) DEFAULT 'custom',
    
    -- Smart collection rules (for automatic population)
    smart_rules JSONB, -- e.g., {"age_range": [3,5], "skills": ["reading"], "min_rating": 4}
    auto_update BOOLEAN DEFAULT false,
    
    -- Sharing settings
    is_shared BOOLEAN DEFAULT false,
    shared_with_children UUID[] DEFAULT '{}',
    is_public BOOLEAN DEFAULT false, -- Shareable with other families
    public_share_code VARCHAR(20) UNIQUE,
    
    -- Collection metadata
    item_count INTEGER DEFAULT 0,
    last_modified TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sort_order INTEGER DEFAULT 0,
    is_default BOOLEAN DEFAULT false,
    is_archived BOOLEAN DEFAULT false,
    
    -- Ownership
    created_by UUID NOT NULL, -- References core.users(id)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Collection items junction table
CREATE TABLE IF NOT EXISTS games.collection_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES games.library_collections(id) ON DELETE CASCADE,
    
    -- Content reference
    content_id UUID NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    
    -- Organization within collection
    sort_order INTEGER DEFAULT 0,
    added_by UUID, -- References core.users(id)
    notes TEXT,
    
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_collection_item UNIQUE(collection_id, content_id, content_type)
);

-- =============================================================================
-- CONTENT BUNDLES & PACKAGES
-- =============================================================================

-- Content bundles for package deals
CREATE TABLE IF NOT EXISTS games.content_bundles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Bundle information
    title VARCHAR(255) NOT NULL,
    description TEXT,
    creator_id UUID NOT NULL REFERENCES games.creator_profiles(id),
    
    -- Bundle composition
    content_items JSONB NOT NULL DEFAULT '[]', -- Array of {content_id, content_type, order}
    total_items INTEGER NOT NULL CHECK (total_items > 1),
    
    -- Pricing
    bundle_price DECIMAL(10,2) NOT NULL CHECK (bundle_price > 0),
    individual_price_total DECIMAL(10,2) NOT NULL,
    discount_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN individual_price_total > 0 
            THEN ((individual_price_total - bundle_price) / individual_price_total * 100)
            ELSE 0 
        END
    ) STORED,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Bundle metadata
    bundle_type VARCHAR(30) CHECK (bundle_type IN (
        'series', 'theme', 'curriculum', 'seasonal', 
        'starter_pack', 'complete_collection', 'custom'
    )),
    tags TEXT[] DEFAULT '{}',
    age_range_min INTEGER,
    age_range_max INTEGER,
    
    -- Marketing
    featured_image_url TEXT,
    promotional_text TEXT,
    badges TEXT[] DEFAULT '{}', -- e.g., ['bestseller', 'new', 'limited_time']
    
    -- Availability
    is_active BOOLEAN DEFAULT true,
    available_from TIMESTAMP WITH TIME ZONE,
    available_until TIMESTAMP WITH TIME ZONE,
    max_purchases INTEGER, -- Limit total sales if desired
    
    -- Performance metrics
    purchase_count INTEGER DEFAULT 0,
    revenue_total DECIMAL(12,2) DEFAULT 0.00,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- SUBSCRIPTION SYSTEM
-- =============================================================================

-- Subscription tiers configuration
CREATE TABLE IF NOT EXISTS games.subscription_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Tier information
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Pricing
    monthly_price DECIMAL(10,2),
    annual_price DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Trial settings
    trial_days INTEGER DEFAULT 0,
    trial_price DECIMAL(10,2) DEFAULT 0.00,
    
    -- Content access
    content_access_level VARCHAR(30) CHECK (content_access_level IN (
        'basic', 'standard', 'premium', 'unlimited'
    )),
    included_content_ids UUID[] DEFAULT '{}',
    excluded_content_ids UUID[] DEFAULT '{}',
    content_categories_included TEXT[] DEFAULT '{}',
    
    -- Benefits
    monthly_credit_amount DECIMAL(10,2) DEFAULT 0.00,
    rollover_credits BOOLEAN DEFAULT false,
    discount_percentage DECIMAL(5,2) DEFAULT 0.00,
    early_access BOOLEAN DEFAULT false,
    exclusive_content BOOLEAN DEFAULT false,
    
    -- Features
    features JSONB DEFAULT '{}', -- e.g., {"offline_downloads": 10, "family_profiles": 5}
    max_children INTEGER DEFAULT 3,
    
    -- Display
    badge_text VARCHAR(50),
    badge_color VARCHAR(7),
    sort_order INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    available_from TIMESTAMP WITH TIME ZONE,
    available_until TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Family subscription records
CREATE TABLE IF NOT EXISTS games.family_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL, -- References family.families(id)
    tier_id UUID NOT NULL REFERENCES games.subscription_tiers(id),
    
    -- Subscription details
    status VARCHAR(30) NOT NULL CHECK (status IN (
        'trialing', 'active', 'past_due', 'cancelled', 
        'expired', 'paused', 'pending'
    )) DEFAULT 'pending',
    
    -- Billing cycle
    billing_cycle VARCHAR(20) CHECK (billing_cycle IN ('monthly', 'annual')),
    current_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    next_billing_date TIMESTAMP WITH TIME ZONE,
    
    -- Trial information
    trial_start TIMESTAMP WITH TIME ZONE,
    trial_end TIMESTAMP WITH TIME ZONE,
    
    -- Payment
    payment_method_id VARCHAR(255), -- Stripe payment method ID
    last_payment_amount DECIMAL(10,2),
    last_payment_date TIMESTAMP WITH TIME ZONE,
    failed_payment_count INTEGER DEFAULT 0,
    
    -- Usage tracking
    monthly_credits_remaining DECIMAL(10,2) DEFAULT 0.00,
    credits_expire_at TIMESTAMP WITH TIME ZONE,
    content_accessed_this_period INTEGER DEFAULT 0,
    downloads_this_period INTEGER DEFAULT 0,
    
    -- Cancellation
    cancel_at_period_end BOOLEAN DEFAULT false,
    cancellation_reason TEXT,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID, -- References core.users(id)
    
    -- Metadata
    stripe_subscription_id VARCHAR(255) UNIQUE,
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_active_subscription UNIQUE(family_id) 
        WHERE status IN ('trialing', 'active', 'past_due')
);

-- Subscription usage history
CREATE TABLE IF NOT EXISTS games.subscription_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID NOT NULL REFERENCES games.family_subscriptions(id) ON DELETE CASCADE,
    
    -- Usage details
    usage_type VARCHAR(50) NOT NULL CHECK (usage_type IN (
        'content_access', 'download', 'credit_used', 'feature_access'
    )),
    
    -- Content accessed (if applicable)
    content_id UUID,
    content_type VARCHAR(50),
    
    -- Credit usage (if applicable)
    credits_used DECIMAL(10,2),
    credits_remaining DECIMAL(10,2),
    
    -- User information
    child_id UUID, -- References family.child_profiles(id)
    parent_id UUID, -- References core.users(id)
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    used_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- ANALYTICS & RECOMMENDATIONS
-- =============================================================================

-- Content engagement metrics for analytics
CREATE TABLE IF NOT EXISTS games.content_engagement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    
    -- Engagement metrics
    view_count INTEGER DEFAULT 0,
    unique_child_count INTEGER DEFAULT 0,
    unique_family_count INTEGER DEFAULT 0,
    
    -- Time-based metrics
    average_session_minutes DECIMAL(10,2) DEFAULT 0.00,
    total_time_minutes INTEGER DEFAULT 0,
    
    -- Completion metrics
    start_count INTEGER DEFAULT 0,
    completion_count INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN start_count > 0 
            THEN (completion_count::DECIMAL / start_count * 100)
            ELSE 0 
        END
    ) STORED,
    
    -- Repeat engagement
    repeat_view_count INTEGER DEFAULT 0,
    repeat_rate DECIMAL(5,2) DEFAULT 0.00,
    
    -- Educational outcomes
    vocabulary_words_learned_avg DECIMAL(10,2) DEFAULT 0.00,
    skill_improvement_rate DECIMAL(5,2) DEFAULT 0.00,
    quiz_score_average DECIMAL(5,2) DEFAULT 0.00,
    
    -- Ratings
    average_child_rating DECIMAL(3,2) DEFAULT 0.00,
    average_parent_rating DECIMAL(3,2) DEFAULT 0.00,
    
    -- Time period
    metrics_date DATE NOT NULL,
    week_number INTEGER,
    month_number INTEGER,
    year_number INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_content_metrics_date UNIQUE(content_id, content_type, metrics_date)
);

-- Recommendation engine data
CREATE TABLE IF NOT EXISTS games.content_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL, -- References family.child_profiles(id)
    
    -- Recommendation details
    content_id UUID NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    
    -- Recommendation metadata
    recommendation_score DECIMAL(5,4) NOT NULL CHECK (
        recommendation_score >= 0 AND recommendation_score <= 1
    ),
    recommendation_reason VARCHAR(100), -- e.g., 'similar_to_favorites', 'trending', 'age_appropriate'
    recommendation_factors JSONB DEFAULT '{}', -- Detailed scoring breakdown
    
    -- Recommendation source
    algorithm_version VARCHAR(20),
    model_id VARCHAR(50),
    
    -- Interaction tracking
    was_shown BOOLEAN DEFAULT false,
    shown_at TIMESTAMP WITH TIME ZONE,
    was_clicked BOOLEAN DEFAULT false,
    clicked_at TIMESTAMP WITH TIME ZONE,
    was_purchased BOOLEAN DEFAULT false,
    purchased_at TIMESTAMP WITH TIME ZONE,
    was_dismissed BOOLEAN DEFAULT false,
    dismissed_at TIMESTAMP WITH TIME ZONE,
    
    -- Feedback
    feedback_rating INTEGER CHECK (feedback_rating BETWEEN -1 AND 1), -- -1: bad, 0: neutral, 1: good
    feedback_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
    
    CONSTRAINT unique_active_recommendation UNIQUE(child_id, content_id, content_type)
        WHERE expires_at > CURRENT_TIMESTAMP AND was_dismissed = false
);

-- Creator follower relationships
CREATE TABLE IF NOT EXISTS games.creator_followers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES games.creator_profiles(id) ON DELETE CASCADE,
    follower_id UUID NOT NULL, -- References core.users(id)
    
    -- Notification preferences
    notify_new_content BOOLEAN DEFAULT true,
    notify_sales BOOLEAN DEFAULT false,
    notify_updates BOOLEAN DEFAULT true,
    
    followed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_creator_follower UNIQUE(creator_id, follower_id)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Creator profiles indexes
CREATE INDEX IF NOT EXISTS idx_creator_profiles_user ON games.creator_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_creator_profiles_tier ON games.creator_profiles(tier, account_status);
CREATE INDEX IF NOT EXISTS idx_creator_profiles_featured ON games.creator_profiles(featured_creator, featured_until);
CREATE INDEX IF NOT EXISTS idx_creator_profiles_rating ON games.creator_profiles(average_rating DESC, total_ratings DESC);

-- Child library indexes
CREATE INDEX IF NOT EXISTS idx_child_library_child ON games.child_library(child_id, is_available);
CREATE INDEX IF NOT EXISTS idx_child_library_content ON games.child_library(content_id, content_type);
CREATE INDEX IF NOT EXISTS idx_child_library_favorites ON games.child_library(child_id, is_favorite) WHERE is_favorite = true;
CREATE INDEX IF NOT EXISTS idx_child_library_acquisition ON games.child_library(acquisition_type, acquired_at DESC);
CREATE INDEX IF NOT EXISTS idx_child_library_collections ON games.child_library USING GIN(collection_ids);
CREATE INDEX IF NOT EXISTS idx_child_library_progress ON games.child_library(child_id, completion_percentage);

-- Library collections indexes
CREATE INDEX IF NOT EXISTS idx_library_collections_family ON games.library_collections(family_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_library_collections_public ON games.library_collections(public_share_code) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_library_collections_smart ON games.library_collections(collection_type) WHERE collection_type = 'smart';

-- Content bundles indexes
CREATE INDEX IF NOT EXISTS idx_content_bundles_creator ON games.content_bundles(creator_id, is_active);
CREATE INDEX IF NOT EXISTS idx_content_bundles_type ON games.content_bundles(bundle_type, is_active);
CREATE INDEX IF NOT EXISTS idx_content_bundles_availability ON games.content_bundles(available_from, available_until);

-- Subscription indexes
CREATE INDEX IF NOT EXISTS idx_subscription_tiers_active ON games.subscription_tiers(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_family_subscriptions_family ON games.family_subscriptions(family_id, status);
CREATE INDEX IF NOT EXISTS idx_family_subscriptions_billing ON games.family_subscriptions(next_billing_date) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_subscription_usage_subscription ON games.subscription_usage(subscription_id, used_at DESC);

-- Engagement and recommendations indexes
CREATE INDEX IF NOT EXISTS idx_content_engagement_content ON games.content_engagement(content_id, content_type, metrics_date DESC);
CREATE INDEX IF NOT EXISTS idx_content_engagement_date ON games.content_engagement(metrics_date, content_type);
CREATE INDEX IF NOT EXISTS idx_content_recommendations_child ON games.content_recommendations(child_id, expires_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_recommendations_score ON games.content_recommendations(recommendation_score DESC);
CREATE INDEX IF NOT EXISTS idx_creator_followers_creator ON games.creator_followers(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_followers_follower ON games.creator_followers(follower_id);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Update creator metrics on new sale
CREATE OR REPLACE FUNCTION games.update_creator_metrics()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE games.creator_profiles
    SET 
        total_sales = total_sales + 1,
        total_revenue = total_revenue + NEW.price_paid,
        monthly_sales = monthly_sales + 1,
        monthly_revenue = monthly_revenue + NEW.price_paid,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = (
        SELECT seller_id 
        FROM games.marketplace_listings 
        WHERE id = NEW.listing_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_creator_metrics
AFTER INSERT ON games.story_purchases
FOR EACH ROW
EXECUTE FUNCTION games.update_creator_metrics();

-- Update collection item count
CREATE OR REPLACE FUNCTION games.update_collection_item_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE games.library_collections
        SET item_count = item_count + 1,
            last_modified = CURRENT_TIMESTAMP
        WHERE id = NEW.collection_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE games.library_collections
        SET item_count = item_count - 1,
            last_modified = CURRENT_TIMESTAMP
        WHERE id = OLD.collection_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_collection_count
AFTER INSERT OR DELETE ON games.collection_items
FOR EACH ROW
EXECUTE FUNCTION games.update_collection_item_count();

-- Update child library on access
CREATE OR REPLACE FUNCTION games.update_library_access()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_accessed_at = CURRENT_TIMESTAMP;
    NEW.total_access_count = OLD.total_access_count + 1;
    NEW.updated_at = CURRENT_TIMESTAMP;
    
    IF NEW.first_accessed_at IS NULL THEN
        NEW.first_accessed_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_library_access
BEFORE UPDATE OF last_accessed_at ON games.child_library
FOR EACH ROW
WHEN (NEW.last_accessed_at IS DISTINCT FROM OLD.last_accessed_at)
EXECUTE FUNCTION games.update_library_access();

-- Auto-update timestamps
CREATE OR REPLACE FUNCTION games.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update timestamp trigger to new tables
CREATE TRIGGER update_creator_profiles_updated_at
    BEFORE UPDATE ON games.creator_profiles
    FOR EACH ROW EXECUTE FUNCTION games.update_updated_at_column();

CREATE TRIGGER update_child_library_updated_at
    BEFORE UPDATE ON games.child_library
    FOR EACH ROW EXECUTE FUNCTION games.update_updated_at_column();

CREATE TRIGGER update_library_collections_updated_at
    BEFORE UPDATE ON games.library_collections
    FOR EACH ROW EXECUTE FUNCTION games.update_updated_at_column();

CREATE TRIGGER update_content_bundles_updated_at
    BEFORE UPDATE ON games.content_bundles
    FOR EACH ROW EXECUTE FUNCTION games.update_updated_at_column();

CREATE TRIGGER update_subscription_tiers_updated_at
    BEFORE UPDATE ON games.subscription_tiers
    FOR EACH ROW EXECUTE FUNCTION games.update_updated_at_column();

CREATE TRIGGER update_family_subscriptions_updated_at
    BEFORE UPDATE ON games.family_subscriptions
    FOR EACH ROW EXECUTE FUNCTION games.update_updated_at_column();

CREATE TRIGGER update_content_engagement_updated_at
    BEFORE UPDATE ON games.content_engagement
    FOR EACH ROW EXECUTE FUNCTION games.update_updated_at_column();

-- =============================================================================
-- INITIAL DATA SETUP
-- =============================================================================

-- Insert default subscription tiers
INSERT INTO games.subscription_tiers (
    name, display_name, description, 
    monthly_price, annual_price, 
    content_access_level, trial_days,
    features, max_children, sort_order
) VALUES 
(
    'basic',
    'WonderNest Basic',
    'Perfect for getting started with curated educational content',
    4.99, 49.99,
    'basic', 7,
    '{"offline_downloads": 5, "family_profiles": 2, "monthly_reports": true}',
    2, 1
),
(
    'premium',
    'WonderNest Premium',
    'Full access to our growing library with exclusive content',
    9.99, 99.99,
    'premium', 14,
    '{"offline_downloads": 20, "family_profiles": 4, "monthly_reports": true, "early_access": true, "creator_content": true}',
    4, 2
),
(
    'family',
    'WonderNest Family',
    'Unlimited access for the whole family with all premium features',
    14.99, 149.99,
    'unlimited', 14,
    '{"offline_downloads": -1, "family_profiles": 6, "monthly_reports": true, "early_access": true, "creator_content": true, "exclusive_content": true, "priority_support": true}',
    6, 3
)
ON CONFLICT (name) DO NOTHING;

-- Create default library collections for new families (via function)
CREATE OR REPLACE FUNCTION games.create_default_collections()
RETURNS TRIGGER AS $$
BEGIN
    -- Create default collections for new family
    INSERT INTO games.library_collections (
        family_id, name, description, collection_type, 
        is_default, created_by, icon, color
    ) VALUES 
    (
        NEW.id,
        'Favorites',
        'Your family''s favorite content',
        'custom',
        true,
        NEW.created_by,
        'star',
        '#FFD700'
    ),
    (
        NEW.id,
        'Recently Added',
        'Newly acquired content',
        'smart',
        true,
        NEW.created_by,
        'clock',
        '#4169E1'
    ),
    (
        NEW.id,
        'Educational',
        'Learning-focused content',
        'custom',
        true,
        NEW.created_by,
        'graduation-cap',
        '#228B22'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: This trigger should be added to the family.families table
-- CREATE TRIGGER trigger_create_default_collections
-- AFTER INSERT ON family.families
-- FOR EACH ROW
-- EXECUTE FUNCTION games.create_default_collections();

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant necessary permissions to application role
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA games TO wondernest_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA games TO wondernest_app;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- Add migration comment
COMMENT ON SCHEMA games IS 'WonderNest marketplace, library, and content ecosystem - Enhanced with V8 migration';

-- Table comments
COMMENT ON TABLE games.creator_profiles IS 'Creator profiles for content publishers and educators';
COMMENT ON TABLE games.creator_payouts IS 'Payout history and transaction records for creators';
COMMENT ON TABLE games.child_library IS 'Personal library of content for each child';
COMMENT ON TABLE games.library_collections IS 'Organized collections of content within libraries';
COMMENT ON TABLE games.collection_items IS 'Items within library collections';
COMMENT ON TABLE games.content_bundles IS 'Bundled content packages for discounted sales';
COMMENT ON TABLE games.subscription_tiers IS 'Available subscription plans and their features';
COMMENT ON TABLE games.family_subscriptions IS 'Active family subscription records';
COMMENT ON TABLE games.subscription_usage IS 'Detailed usage tracking for subscriptions';
COMMENT ON TABLE games.content_engagement IS 'Aggregated engagement metrics for content';
COMMENT ON TABLE games.content_recommendations IS 'ML-powered content recommendations for children';
COMMENT ON TABLE games.creator_followers IS 'Creator-follower relationships for updates';