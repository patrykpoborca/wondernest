-- V25: Add Marketplace and Creator Economy Tables
-- This migration adds support for the community marketplace where creators can publish and sell content

-- Create marketplace schema if not exists
CREATE SCHEMA IF NOT EXISTS marketplace;

-- Set search path
SET search_path TO marketplace, public;

-- Creator profiles for content publishers
CREATE TABLE IF NOT EXISTS marketplace.creator_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(id) ON DELETE CASCADE,
    display_name VARCHAR(100) NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    cover_image_url TEXT,
    website_url TEXT,
    social_links JSONB DEFAULT '{}',
    
    -- Creator tier and verification
    tier VARCHAR(30) DEFAULT 'HOBBYIST' CHECK (tier IN ('HOBBYIST', 'EMERGING', 'PROFESSIONAL', 'VERIFIED_EDUCATOR', 'PARTNER_STUDIO')),
    verified BOOLEAN DEFAULT FALSE,
    verification_date TIMESTAMP WITH TIME ZONE,
    
    -- Metrics
    total_sales INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    content_count INTEGER DEFAULT 0,
    follower_count INTEGER DEFAULT 0,
    
    -- Account status
    account_status VARCHAR(30) DEFAULT 'PENDING_VERIFICATION' CHECK (account_status IN ('PENDING_VERIFICATION', 'ACTIVE', 'SUSPENDED', 'BANNED', 'INACTIVE')),
    suspension_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_creator UNIQUE(user_id)
);

-- Marketplace listings for content items
CREATE TABLE IF NOT EXISTS marketplace.listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES marketplace.creator_profiles(id) ON DELETE CASCADE,
    
    -- Content details
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    full_description TEXT,
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('STORY', 'GAME', 'ACTIVITY', 'EDUCATIONAL_VIDEO', 'INTERACTIVE_BOOK')),
    
    -- Files and media
    thumbnail_url TEXT,
    preview_url TEXT,
    content_url TEXT,
    screenshots TEXT[], -- Array of screenshot URLs
    file_size_mb DECIMAL(10,2),
    
    -- Educational metadata
    age_range VARCHAR(20) NOT NULL,
    educational_goals TEXT[],
    subjects TEXT[],
    skills_developed TEXT[],
    
    -- Pricing and licensing
    price DECIMAL(8,2) NOT NULL CHECK (price >= 0),
    original_price DECIMAL(8,2),
    licensing_model VARCHAR(30) DEFAULT 'SINGLE_CHILD' CHECK (licensing_model IN ('SINGLE_CHILD', 'FAMILY', 'CLASSROOM', 'UNLIMITED')),
    
    -- AI generation metadata
    is_ai_generated BOOLEAN DEFAULT FALSE,
    ai_provider VARCHAR(50),
    ai_model VARCHAR(100),
    
    -- Categorization
    tags TEXT[],
    language VARCHAR(10) DEFAULT 'en',
    supported_languages TEXT[],
    
    -- Metrics
    view_count INTEGER DEFAULT 0,
    purchase_count INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    
    -- Status
    status VARCHAR(30) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'PUBLISHED', 'REJECTED', 'ARCHIVED')),
    rejection_reason TEXT,
    published_at TIMESTAMP WITH TIME ZONE,
    
    -- Search optimization
    search_vector tsvector,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create full-text search index
CREATE INDEX idx_listings_search_vector ON marketplace.listings USING gin(search_vector);

-- Trigger to update search vector
CREATE OR REPLACE FUNCTION marketplace.update_listing_search_vector()
RETURNS trigger AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(array_to_string(NEW.tags, ' '), '')), 'C') ||
        setweight(to_tsvector('english', coalesce(array_to_string(NEW.educational_goals, ' '), '')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_listing_search_vector
    BEFORE INSERT OR UPDATE ON marketplace.listings
    FOR EACH ROW
    EXECUTE FUNCTION marketplace.update_listing_search_vector();

-- Purchases table
CREATE TABLE IF NOT EXISTS marketplace.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(id),
    listing_id UUID NOT NULL REFERENCES marketplace.listings(id),
    family_id UUID NOT NULL REFERENCES family.families(id),
    
    -- Purchase details
    amount DECIMAL(8,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method VARCHAR(50),
    transaction_id VARCHAR(200),
    
    -- Licensing
    license_type VARCHAR(30),
    license_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    status VARCHAR(30) DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'COMPLETED', 'REFUNDED', 'FAILED')),
    refund_reason TEXT,
    refunded_at TIMESTAMP WITH TIME ZONE,
    
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_listing_purchase UNIQUE(user_id, listing_id)
);

-- Reviews and ratings
CREATE TABLE IF NOT EXISTS marketplace.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES marketplace.listings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES core.users(id),
    purchase_id UUID REFERENCES marketplace.purchases(id),
    
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    
    -- Review metadata
    verified_purchase BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    reported_count INTEGER DEFAULT 0,
    
    -- Status
    status VARCHAR(30) DEFAULT 'PUBLISHED' CHECK (status IN ('PENDING', 'PUBLISHED', 'HIDDEN', 'REMOVED')),
    moderation_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_listing_review UNIQUE(user_id, listing_id)
);

-- Creator followers
CREATE TABLE IF NOT EXISTS marketplace.creator_followers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES marketplace.creator_profiles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES core.users(id) ON DELETE CASCADE,
    
    followed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_creator_follower UNIQUE(creator_id, user_id)
);

-- Creator earnings and payouts
CREATE TABLE IF NOT EXISTS marketplace.creator_earnings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES marketplace.creator_profiles(id),
    purchase_id UUID NOT NULL REFERENCES marketplace.purchases(id),
    
    -- Earnings details
    gross_amount DECIMAL(10,2) NOT NULL,
    platform_fee DECIMAL(10,2) NOT NULL,
    processing_fee DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(10,2) NOT NULL,
    
    -- Status
    status VARCHAR(30) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'AVAILABLE', 'PAID_OUT', 'HELD', 'REFUNDED')),
    payout_id UUID,
    
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    available_at TIMESTAMP WITH TIME ZONE,
    paid_at TIMESTAMP WITH TIME ZONE
);

-- Payout requests
CREATE TABLE IF NOT EXISTS marketplace.payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES marketplace.creator_profiles(id),
    
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Payment details
    payment_method VARCHAR(50),
    payment_details JSONB,
    transaction_id VARCHAR(200),
    
    -- Status
    status VARCHAR(30) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED')),
    failure_reason TEXT,
    
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Child library (purchased and created content)
CREATE TABLE IF NOT EXISTS marketplace.child_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES family.families(id),
    
    -- Content reference (either purchased or parent-created)
    listing_id UUID REFERENCES marketplace.listings(id),
    purchase_id UUID REFERENCES marketplace.purchases(id),
    ai_story_id UUID REFERENCES ai_story_generations(id),
    
    -- Content metadata
    content_type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    thumbnail_url TEXT,
    
    -- Access control
    is_favorite BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    access_count INTEGER DEFAULT 0,
    
    -- Progress tracking
    progress_data JSONB DEFAULT '{}',
    completed BOOLEAN DEFAULT FALSE,
    
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT check_content_source CHECK (
        (listing_id IS NOT NULL AND purchase_id IS NOT NULL AND ai_story_id IS NULL) OR
        (listing_id IS NULL AND purchase_id IS NULL AND ai_story_id IS NOT NULL)
    )
);

-- Content recommendations
CREATE TABLE IF NOT EXISTS marketplace.recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES family.child_profiles(id),
    family_id UUID REFERENCES family.families(id),
    listing_id UUID NOT NULL REFERENCES marketplace.listings(id),
    
    -- Recommendation metadata
    score DECIMAL(5,4) NOT NULL,
    reason VARCHAR(100),
    algorithm_version VARCHAR(20),
    
    -- Interaction tracking
    shown_count INTEGER DEFAULT 0,
    clicked BOOLEAN DEFAULT FALSE,
    purchased BOOLEAN DEFAULT FALSE,
    dismissed BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT unique_child_listing_recommendation UNIQUE(child_id, listing_id)
);

-- Featured content collections
CREATE TABLE IF NOT EXISTS marketplace.featured_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    name VARCHAR(100) NOT NULL,
    description TEXT,
    collection_type VARCHAR(50) CHECK (collection_type IN ('SPOTLIGHT', 'NEW_RELEASES', 'TOP_RATED', 'EDITORS_PICKS', 'TRENDING', 'SEASONAL')),
    
    -- Display properties
    banner_url TEXT,
    position INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timing
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Collection items
CREATE TABLE IF NOT EXISTS marketplace.collection_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES marketplace.featured_collections(id) ON DELETE CASCADE,
    listing_id UUID NOT NULL REFERENCES marketplace.listings(id) ON DELETE CASCADE,
    
    position INTEGER DEFAULT 0,
    custom_description TEXT,
    
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_collection_listing UNIQUE(collection_id, listing_id)
);

-- Indexes for performance
CREATE INDEX idx_listings_creator ON marketplace.listings(creator_id);
CREATE INDEX idx_listings_status ON marketplace.listings(status) WHERE status = 'PUBLISHED';
CREATE INDEX idx_listings_content_type ON marketplace.listings(content_type);
CREATE INDEX idx_listings_age_range ON marketplace.listings(age_range);
CREATE INDEX idx_listings_price ON marketplace.listings(price);
CREATE INDEX idx_listings_rating ON marketplace.listings(rating DESC);
CREATE INDEX idx_listings_created ON marketplace.listings(created_at DESC);

CREATE INDEX idx_purchases_user ON marketplace.purchases(user_id);
CREATE INDEX idx_purchases_listing ON marketplace.purchases(listing_id);
CREATE INDEX idx_purchases_family ON marketplace.purchases(family_id);

CREATE INDEX idx_reviews_listing ON marketplace.reviews(listing_id);
CREATE INDEX idx_reviews_user ON marketplace.reviews(user_id);

CREATE INDEX idx_child_library_child ON marketplace.child_library(child_id);
CREATE INDEX idx_child_library_family ON marketplace.child_library(family_id);

CREATE INDEX idx_recommendations_child ON marketplace.recommendations(child_id);
CREATE INDEX idx_recommendations_family ON marketplace.recommendations(family_id);

-- Update triggers for updated_at
CREATE OR REPLACE FUNCTION marketplace.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_creator_profiles_updated_at
    BEFORE UPDATE ON marketplace.creator_profiles
    FOR EACH ROW
    EXECUTE FUNCTION marketplace.update_updated_at_column();

CREATE TRIGGER update_listings_updated_at
    BEFORE UPDATE ON marketplace.listings
    FOR EACH ROW
    EXECUTE FUNCTION marketplace.update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON marketplace.reviews
    FOR EACH ROW
    EXECUTE FUNCTION marketplace.update_updated_at_column();