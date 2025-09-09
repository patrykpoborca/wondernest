# Content Creation Technical Architecture

## System Overview
The content creation system consists of three distinct but integrated pathways that share common infrastructure while maintaining appropriate separation of concerns and security boundaries.

## Core Architecture Principles

### 1. Separation of Concerns
- Admin systems completely isolated from family systems
- Creator accounts as a bridge between admin and family domains
- Parent publishing integrated with existing family infrastructure

### 2. Security by Design
- Role-based access control at API gateway level
- Content validation at multiple layers
- Signed URLs for all content delivery
- Audit logging for all content operations

### 3. Scalability First
- Asynchronous processing for heavy operations
- CDN-first content delivery
- Microservices architecture for creator tools
- Event-driven architecture for cross-system communication

## System Components

### Authentication & Authorization Layer

```rust
// Separate authentication contexts
pub enum AuthContext {
    Family(FamilyAuth),      // Parents and children
    Admin(AdminAuth),        // Platform administrators
    Creator(CreatorAuth),    // Content creators
}

pub struct FamilyAuth {
    pub user_id: Uuid,
    pub family_id: Uuid,
    pub role: FamilyRole,    // Parent or Child
    pub permissions: Vec<Permission>,
}

pub struct AdminAuth {
    pub admin_id: Uuid,
    pub role: AdminRole,     // Root, Platform, Content, Analytics, Support
    pub permissions: Vec<AdminPermission>,
    pub ip_address: IpAddr,
    pub mfa_verified: bool,
}

pub struct CreatorAuth {
    pub creator_id: Uuid,
    pub user_id: Option<Uuid>,  // Linked family account if parent
    pub tier: CreatorTier,       // Verified, Community, Parent
    pub permissions: Vec<CreatorPermission>,
}
```

### Content Model Architecture

```rust
// Unified content pack model with source tracking
pub struct ContentPack {
    pub id: Uuid,
    pub title: String,
    pub description: String,
    pub source: ContentSource,
    pub status: ContentStatus,
    pub metadata: ContentMetadata,
    pub files: Vec<FileReference>,
    pub pricing: Option<Pricing>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

pub enum ContentSource {
    Admin {
        admin_id: Uuid,
        is_official: bool,
    },
    Creator {
        creator_id: Uuid,
        tier: CreatorTier,
    },
    Parent {
        user_id: Uuid,
        family_id: Uuid,
    },
}

pub enum ContentStatus {
    Draft,
    PendingReview,
    InReview,
    Approved,
    Published,
    Suspended,
    Archived,
}

pub struct ContentMetadata {
    pub age_range: AgeRange,
    pub subjects: Vec<Subject>,
    pub learning_objectives: Vec<String>,
    pub duration_minutes: Option<u32>,
    pub difficulty_level: DifficultyLevel,
    pub tags: Vec<String>,
    pub coppa_compliant: bool,
    pub content_warnings: Vec<String>,
}
```

### File Management Integration

```rust
// Extended file reference for content packs
pub struct ContentFile {
    pub file_reference_id: Uuid,
    pub content_pack_id: Uuid,
    pub file_type: ContentFileType,
    pub display_order: i32,
    pub is_preview: bool,
    pub platform_compatibility: Vec<Platform>,
}

pub enum ContentFileType {
    MainContent,
    Preview,
    Thumbnail,
    Documentation,
    Asset,
    Metadata,
}

// Secure content delivery
pub struct ContentDelivery {
    pub async fn generate_signed_url(
        &self,
        file_id: Uuid,
        user_context: AuthContext,
        expiry_duration: Duration,
    ) -> Result<SignedUrl, Error> {
        // Verify user has access to content
        self.verify_access(&user_context, &file_id)?;
        
        // Generate time-limited signed URL
        let signed_url = self.storage.generate_signed_url(
            file_id,
            expiry_duration,
            vec![
                ("user_id", user_context.get_user_id()),
                ("content_pack_id", self.get_pack_id(file_id)?),
            ],
        )?;
        
        Ok(signed_url)
    }
}
```

### API Gateway Design

```yaml
# API routes by authentication context
api:
  v1:
    # Admin routes (separate auth)
    admin:
      auth:
        login: POST /api/v1/admin/auth/login
        mfa: POST /api/v1/admin/auth/mfa
        logout: POST /api/v1/admin/auth/logout
      content:
        upload: POST /api/v1/admin/content/upload
        bulk_upload: POST /api/v1/admin/content/bulk-upload
        update: PUT /api/v1/admin/content/{id}
        publish: POST /api/v1/admin/content/{id}/publish
        badge: POST /api/v1/admin/content/{id}/official
      creators:
        list: GET /api/v1/admin/creators
        approve: POST /api/v1/admin/creators/{id}/approve
        suspend: POST /api/v1/admin/creators/{id}/suspend
    
    # Creator routes (creator auth)
    creator:
      auth:
        apply: POST /api/v1/creator/apply
        login: POST /api/v1/creator/auth/login
        logout: POST /api/v1/creator/auth/logout
      content:
        create: POST /api/v1/creator/content
        update: PUT /api/v1/creator/content/{id}
        submit: POST /api/v1/creator/content/{id}/submit
        analytics: GET /api/v1/creator/content/{id}/analytics
      earnings:
        summary: GET /api/v1/creator/earnings
        withdraw: POST /api/v1/creator/earnings/withdraw
        history: GET /api/v1/creator/earnings/history
    
    # Family routes (family auth)
    marketplace:
      browse: GET /api/v1/marketplace/browse
      search: GET /api/v1/marketplace/search
      details: GET /api/v1/marketplace/content/{id}
      purchase: POST /api/v1/marketplace/purchase
      library: GET /api/v1/marketplace/library/{child_id}
    
    # Parent publisher routes (family auth + publisher flag)
    parent:
      publish:
        create: POST /api/v1/parent/publish
        update: PUT /api/v1/parent/publish/{id}
        share: POST /api/v1/parent/publish/{id}/share
        monetize: POST /api/v1/parent/publish/{id}/monetize
```

### Database Schema Design

```sql
-- Core schema extensions for content creation
CREATE SCHEMA IF NOT EXISTS content;

-- Content packs with source tracking
CREATE TABLE content.packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    source_type VARCHAR(50) NOT NULL, -- 'admin', 'creator', 'parent'
    source_id UUID NOT NULL, -- References appropriate table based on source_type
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    is_official BOOLEAN DEFAULT false,
    metadata JSONB NOT NULL DEFAULT '{}',
    pricing JSONB,
    view_count INTEGER DEFAULT 0,
    purchase_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    published_at TIMESTAMP,
    INDEX idx_source (source_type, source_id),
    INDEX idx_status (status),
    INDEX idx_published (published_at) WHERE published_at IS NOT NULL
);

-- Creator accounts (separate from family accounts)
CREATE TABLE content.creator_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    tier VARCHAR(50) NOT NULL, -- 'verified', 'community', 'parent_publisher'
    linked_user_id UUID, -- For parent publishers
    status VARCHAR(50) DEFAULT 'pending',
    profile JSONB DEFAULT '{}',
    verification JSONB,
    revenue_share_percentage INTEGER NOT NULL,
    total_earnings DECIMAL(10,2) DEFAULT 0,
    withdrawable_balance DECIMAL(10,2) DEFAULT 0,
    quality_score DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT NOW(),
    verified_at TIMESTAMP,
    suspended_at TIMESTAMP,
    FOREIGN KEY (linked_user_id) REFERENCES auth.users(id)
);

-- Admin accounts (completely separate system)
CREATE TABLE content.admin_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    permissions JSONB NOT NULL DEFAULT '[]',
    mfa_secret VARCHAR(255),
    allowed_ips JSONB DEFAULT '[]',
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    created_by UUID,
    is_active BOOLEAN DEFAULT true,
    FOREIGN KEY (created_by) REFERENCES content.admin_accounts(id)
);

-- Content review queue
CREATE TABLE content.review_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_pack_id UUID NOT NULL,
    priority INTEGER DEFAULT 5,
    review_type VARCHAR(50) NOT NULL, -- 'automated', 'manual', 'expedited'
    assigned_to UUID,
    review_status VARCHAR(50) DEFAULT 'pending',
    automated_checks JSONB DEFAULT '{}',
    manual_review JSONB,
    decision VARCHAR(50), -- 'approved', 'rejected', 'needs_changes'
    feedback TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    assigned_at TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (content_pack_id) REFERENCES content.packs(id),
    FOREIGN KEY (assigned_to) REFERENCES content.admin_accounts(id)
);

-- Content file associations
CREATE TABLE content.pack_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_pack_id UUID NOT NULL,
    file_reference_id UUID NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_preview BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (content_pack_id) REFERENCES content.packs(id) ON DELETE CASCADE,
    FOREIGN KEY (file_reference_id) REFERENCES storage.file_references(id),
    UNIQUE(content_pack_id, file_reference_id)
);

-- Creator analytics
CREATE TABLE content.creator_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL,
    date DATE NOT NULL,
    metrics JSONB NOT NULL DEFAULT '{}',
    -- Stored as: {views: 0, clicks: 0, purchases: 0, revenue: 0, ratings: []}
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (creator_id) REFERENCES content.creator_accounts(id),
    UNIQUE(creator_id, date)
);

-- Audit log for all content operations
CREATE TABLE content.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_type VARCHAR(50) NOT NULL, -- 'admin', 'creator', 'parent', 'system'
    actor_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID NOT NULL,
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_actor (actor_type, actor_id),
    INDEX idx_resource (resource_type, resource_id),
    INDEX idx_created (created_at)
);
```

### Content Processing Pipeline

```rust
// Asynchronous content processing
pub struct ContentProcessor {
    pub async fn process_upload(
        &self,
        files: Vec<UploadedFile>,
        metadata: ContentMetadata,
        source: ContentSource,
    ) -> Result<ContentPack, Error> {
        // Step 1: Validate files
        let validated_files = self.validate_files(files).await?;
        
        // Step 2: Scan for security issues
        self.security_scan(&validated_files).await?;
        
        // Step 3: Generate thumbnails and previews
        let processed_files = self.generate_assets(&validated_files).await?;
        
        // Step 4: Create content pack
        let content_pack = self.create_content_pack(
            processed_files,
            metadata,
            source,
        ).await?;
        
        // Step 5: Queue for review if needed
        if self.requires_review(&source) {
            self.queue_for_review(&content_pack).await?;
        }
        
        // Step 6: Send notifications
        self.notify_stakeholders(&content_pack).await?;
        
        Ok(content_pack)
    }
    
    fn requires_review(&self, source: &ContentSource) -> bool {
        match source {
            ContentSource::Admin { .. } => false,
            ContentSource::Creator { tier, .. } => {
                matches!(tier, CreatorTier::Community | CreatorTier::ParentPublisher)
            }
            ContentSource::Parent { .. } => true,
        }
    }
}
```

### Event-Driven Architecture

```rust
// Events for cross-system communication
#[derive(Debug, Serialize, Deserialize)]
pub enum ContentEvent {
    ContentCreated {
        pack_id: Uuid,
        source: ContentSource,
        created_at: DateTime<Utc>,
    },
    ContentPublished {
        pack_id: Uuid,
        publisher_id: Uuid,
        published_at: DateTime<Utc>,
    },
    ContentPurchased {
        pack_id: Uuid,
        buyer_id: Uuid,
        child_ids: Vec<Uuid>,
        amount: Decimal,
        purchased_at: DateTime<Utc>,
    },
    ContentReviewed {
        pack_id: Uuid,
        reviewer_id: Uuid,
        decision: ReviewDecision,
        reviewed_at: DateTime<Utc>,
    },
    CreatorApproved {
        creator_id: Uuid,
        tier: CreatorTier,
        approved_at: DateTime<Utc>,
    },
}

// Event bus for publishing events
pub struct EventBus {
    pub async fn publish(&self, event: ContentEvent) -> Result<(), Error> {
        // Publish to Redis for real-time updates
        self.redis.publish("content_events", &event).await?;
        
        // Store in event log for audit
        self.store_event(&event).await?;
        
        // Trigger webhooks for integrations
        self.trigger_webhooks(&event).await?;
        
        Ok(())
    }
}
```

### Caching Strategy

```rust
// Multi-level caching for performance
pub struct ContentCache {
    redis: RedisClient,
    local: Arc<RwLock<LruCache<String, CachedContent>>>,
    
    pub async fn get_content_pack(
        &self,
        pack_id: Uuid,
    ) -> Result<ContentPack, Error> {
        let key = format!("content:pack:{}", pack_id);
        
        // L1: Check local cache
        if let Some(cached) = self.local.read().await.get(&key) {
            if !cached.is_expired() {
                return Ok(cached.content.clone());
            }
        }
        
        // L2: Check Redis
        if let Some(cached) = self.redis.get::<ContentPack>(&key).await? {
            self.update_local_cache(&key, cached.clone()).await;
            return Ok(cached);
        }
        
        // L3: Load from database
        let content = self.load_from_db(pack_id).await?;
        
        // Update caches
        self.redis.set(&key, &content, Duration::from_secs(3600)).await?;
        self.update_local_cache(&key, content.clone()).await;
        
        Ok(content)
    }
}
```

## Integration Points

### 1. File Storage System
- All content files stored via existing file_references system
- Signed URLs generated for secure access
- CDN integration for global content delivery

### 2. Payment System
- Stripe integration for creator payouts
- Revenue calculation and distribution
- Tax document generation

### 3. Analytics System
- Real-time metrics collection
- Aggregated reporting for creators
- Platform-wide content insights

### 4. Notification System
- Email notifications for creators
- In-app notifications for families
- Admin alerts for content issues

## Security Considerations

### Input Validation
- File type restrictions
- Size limits per creator tier
- Content scanning for malware
- COPPA compliance checking

### Access Control
- JWT-based authentication
- Role-based permissions
- IP restrictions for admins
- Rate limiting per tier

### Data Protection
- Encryption at rest
- Encryption in transit
- PII handling compliance
- Audit logging

## Performance Optimization

### Database Optimization
- Proper indexing strategy
- Materialized views for analytics
- Partitioning for large tables
- Connection pooling

### Caching Strategy
- Redis for hot content
- CDN for static assets
- Local caching for frequently accessed data
- Cache invalidation on updates

### Async Processing
- Queue-based file processing
- Background thumbnail generation
- Deferred analytics aggregation
- Batch notification sending

## Monitoring & Observability

### Metrics to Track
- Upload success rates
- Processing times
- Review queue depth
- Content quality scores
- Creator engagement
- Revenue metrics

### Logging Strategy
- Structured logging with correlation IDs
- Audit logs for compliance
- Error tracking with Sentry
- Performance monitoring with APM

### Alerting Rules
- Failed uploads > threshold
- Review queue backup
- Suspicious content patterns
- Payment processing failures
- System performance degradation