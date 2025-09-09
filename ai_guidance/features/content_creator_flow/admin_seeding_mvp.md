# Admin Content Seeding MVP - 2 Week Sprint

## Executive Summary
A streamlined admin-first approach to populate the WonderNest marketplace with high-quality content. This MVP focuses exclusively on enabling the WonderNest team to quickly seed the marketplace, deferring creator onboarding and complex workflows to later phases.

## Core Objective
Enable WonderNest admins to immediately start populating the marketplace with curated content while maintaining quality and organization standards.

## Week 1: Admin Tools Foundation (Days 1-7)

### Day 1-2: Database & Basic Infrastructure
```sql
-- Simplified creator profile for admins
CREATE TABLE games.admin_creators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    creator_type VARCHAR(50) DEFAULT 'admin', -- admin, staff, invited, parent
    avatar_url TEXT,
    bio TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID, -- Admin who created this account
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Simplified content staging
CREATE TABLE content.admin_content_staging (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES games.admin_creators(id),
    content_type VARCHAR(50) NOT NULL, -- story, sticker_pack, game, activity
    
    -- Core content data
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content_data JSONB NOT NULL,
    
    -- Marketplace fields
    price DECIMAL(10,2),
    age_range INT4RANGE,
    tags TEXT[],
    
    -- Status
    status VARCHAR(30) DEFAULT 'draft', -- draft, ready, published
    published_at TIMESTAMP WITH TIME ZONE,
    marketplace_listing_id UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Day 3-4: Admin API Endpoints
```rust
// Minimal viable endpoints for admin seeding
pub fn admin_content_routes() -> Router {
    Router::new()
        // Creator management (admin only)
        .route("/admin/creators/quick-create", post(quick_create_creator))
        .route("/admin/creators/list", get(list_admin_creators))
        
        // Content staging
        .route("/admin/content/upload", post(upload_content))
        .route("/admin/content/list", get(list_staged_content))
        .route("/admin/content/:id", get(get_content))
        .route("/admin/content/:id", put(update_content))
        .route("/admin/content/:id/publish", post(publish_to_marketplace))
        
        // Bulk operations
        .route("/admin/content/bulk-upload", post(bulk_upload))
        .route("/admin/content/bulk-publish", post(bulk_publish))
}
```

### Day 5-6: Simple Admin UI
```typescript
// Streamlined admin panel pages
interface AdminContentPanel {
  pages: {
    '/admin/seed': QuickUploadForm,        // Single page upload
    '/admin/seed/bulk': BulkUploadTool,    // CSV/JSON import
    '/admin/seed/manage': ContentGrid,      // View & publish
    '/admin/seed/creators': CreatorList,    // Manage creator accounts
  }
}

// Quick upload form for single items
interface QuickUploadForm {
  fields: {
    contentType: 'story' | 'sticker_pack' | 'activity',
    title: string,
    description: string,
    price: number,
    ageRange: [number, number],
    files: File[],
    tags: string[],
    creatorAccount: string, // Select or create new
  },
  actions: {
    saveAsDraft: () => void,
    publishNow: () => void,
  }
}
```

### Day 7: File Storage & CDN
- Set up S3 bucket with simple structure: `/content/{type}/{id}/`
- Configure CloudFront for immediate content delivery
- Implement direct file upload with pre-signed URLs
- Basic image optimization pipeline

## Week 2: Publishing & Polish (Days 8-14)

### Day 8-9: Marketplace Integration
```rust
// Direct publishing to existing marketplace
async fn publish_to_marketplace(
    content_id: Uuid,
    db: &Database,
) -> Result<MarketplaceListing> {
    // Get staged content
    let content = get_staged_content(content_id, db).await?;
    
    // Create marketplace listing
    let listing = MarketplaceListing {
        creator_id: content.creator_id,
        listing_type: content.content_type,
        title: content.title,
        description: content.description,
        price: content.price,
        content_url: generate_cdn_url(&content),
        metadata: content.content_data,
        age_range: content.age_range,
        tags: content.tags,
        status: "active",
        ..Default::default()
    };
    
    // Insert and return
    create_marketplace_listing(listing, db).await
}
```

### Day 10-11: Bulk Operations
```typescript
// CSV/JSON bulk import for rapid seeding
interface BulkImportSchema {
  stories: {
    title: string,
    description: string,
    price: number,
    ageMin: number,
    ageMax: number,
    tags: string,
    contentFile: string, // Path to content file
    thumbnailFile: string,
  }[],
  
  stickerPacks: {
    title: string,
    stickerCount: number,
    price: number,
    category: string,
    zipFile: string, // Path to zip with SVGs
  }[]
}

// Bulk operations UI
const BulkUploadTool = () => {
  // Drag & drop CSV/JSON
  // Progress indicator
  // Error handling with partial success
  // Publish all or selective
}
```

### Day 12-13: Admin Analytics Dashboard
```sql
-- Simple metrics for seeded content
CREATE OR REPLACE VIEW content.admin_seeding_metrics AS
SELECT 
    DATE(created_at) as seed_date,
    content_type,
    COUNT(*) as items_added,
    COUNT(CASE WHEN status = 'published' THEN 1 END) as published,
    AVG(price) as avg_price,
    ARRAY_AGG(DISTINCT creator_id) as creators_used
FROM content.admin_content_staging
GROUP BY DATE(created_at), content_type;
```

### Day 14: Testing & Deployment
- Test bulk upload with 100+ items
- Verify CDN delivery
- Ensure marketplace display
- Create admin documentation
- Deploy to production

## Phased Rollout Plan

### Phase 1: Admin Seeding (Weeks 1-2) ✅
**Goal**: Get 500+ items in marketplace
- Admin-only creator accounts
- Direct content upload
- Bulk import tools
- Immediate publishing

### Phase 2: Invited Creators (Weeks 3-4)
**Goal**: Onboard 10-20 trusted creators
- Basic creator accounts (no onboarding flow)
- Admin creates accounts manually
- Simple content upload interface
- Manual review by admin team

### Phase 3: Creator Self-Service (Weeks 5-6)
**Goal**: Open to 50+ creators
- Self-registration with approval
- Basic profile management
- Content guidelines
- Automated + manual review

### Phase 4: Parent Contributions (Weeks 7-8)
**Goal**: Enable parent-generated content
- Integrate with story book app
- Parent content submission
- Community moderation
- Revenue sharing for parents

## Simplified Data Models

### Admin Creator Types
```typescript
enum CreatorType {
  ADMIN = 'admin',           // WonderNest team
  STAFF = 'staff',           // Internal content team
  VERIFIED = 'verified',     // Invited/verified creators
  PARENT = 'parent',         // Parents contributing via apps
  PARTNER = 'partner'        // Strategic partners
}

interface AdminCreator {
  id: string;
  email: string;
  displayName: string;
  type: CreatorType;
  canPublishDirectly: boolean; // Admins/Staff = true
  requiresReview: boolean;     // Others = true
}
```

### Content Staging Model
```typescript
interface StagedContent {
  id: string;
  creatorId: string;
  
  // Simplified content
  type: 'story' | 'sticker_pack' | 'activity';
  title: string;
  description: string;
  files: {
    main: string;      // S3 URL
    thumbnail: string; // S3 URL
    additional: string[];
  };
  
  // Marketplace data
  price: number;
  ageRange: [number, number];
  tags: string[];
  
  // Simple status
  status: 'draft' | 'ready' | 'published';
  marketplaceId?: string;
}
```

## Admin Tools UI Mockup

```
┌─────────────────────────────────────────────────────────┐
│  WonderNest Admin - Content Seeding Dashboard           │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Quick Stats:                                           │
│  📦 Total Content: 523                                  │
│  ✅ Published: 456                                      │
│  📝 Drafts: 67                                         │
│                                                          │
│  ┌─────────────────────────┐  ┌──────────────────────┐ │
│  │   📤 Quick Upload       │  │  📚 Bulk Import      │ │
│  │                         │  │                      │ │
│  │  [Select Type ▼]        │  │  Drop CSV/JSON here  │ │
│  │  [Title.............]   │  │  or browse           │ │
│  │  [Price: $___]          │  │                      │ │
│  │  [Upload Files]         │  │  [Import]            │ │
│  │                         │  │                      │ │
│  │  [Save] [Publish Now]   │  │                      │ │
│  └─────────────────────────┘  └──────────────────────┘ │
│                                                          │
│  Recent Uploads:                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Title          Type      Status    Actions       │  │
│  ├──────────────────────────────────────────────────┤  │
│  │ Dino Stickers  Stickers  Draft     [Publish]     │  │
│  │ Space Story    Story      Published [View]       │  │
│  │ Math Game      Activity   Ready     [Publish]    │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Implementation Checklist - Week 1

### Monday (Day 1)
- [ ] Create simplified database tables
- [ ] Set up S3 bucket
- [ ] Configure CDN

### Tuesday (Day 2)
- [ ] Implement admin creator accounts
- [ ] Create content staging table
- [ ] Set up file upload service

### Wednesday (Day 3)
- [ ] Build admin API endpoints
- [ ] Implement quick create creator
- [ ] Add content upload endpoint

### Thursday (Day 4)
- [ ] Create bulk upload endpoint
- [ ] Implement publish to marketplace
- [ ] Add content listing endpoint

### Friday (Day 5)
- [ ] Build admin UI quick upload form
- [ ] Implement file upload frontend
- [ ] Create content grid view

### Weekend (Days 6-7)
- [ ] Complete admin UI
- [ ] Test end-to-end flow
- [ ] Fix critical issues

## Implementation Checklist - Week 2

### Monday (Day 8)
- [ ] Integrate with marketplace
- [ ] Test publishing flow
- [ ] Verify content display

### Tuesday (Day 9)
- [ ] Implement bulk import
- [ ] Create CSV parser
- [ ] Add progress tracking

### Wednesday (Day 10)
- [ ] Build analytics dashboard
- [ ] Add metrics tracking
- [ ] Create reports

### Thursday (Day 11)
- [ ] Polish UI
- [ ] Add error handling
- [ ] Improve UX

### Friday (Day 12)
- [ ] Performance testing
- [ ] Load testing with 500+ items
- [ ] CDN optimization

### Weekend (Days 13-14)
- [ ] Final testing
- [ ] Documentation
- [ ] Production deployment

## Success Metrics

### Week 1 Goals
- ✅ Admin can create creator accounts in <30 seconds
- ✅ Admin can upload content in <2 minutes
- ✅ 50+ test items uploaded
- ✅ Basic UI functional

### Week 2 Goals
- ✅ 500+ items in marketplace
- ✅ Bulk import of 100+ items works
- ✅ Content displays correctly in app
- ✅ CDN serving all content
- ✅ Admin dashboard shows metrics

### Overall MVP Success
- **Time to First Content**: <5 minutes from start
- **Bulk Import Speed**: 100 items in <10 minutes
- **Publishing Speed**: Instant for admin content
- **System Stability**: Zero downtime during seeding
- **Content Quality**: 100% of seeded content displays correctly

## Technical Decisions for Speed

### What We're Building
1. Direct database writes (no complex workflows)
2. Simple file upload to S3
3. Minimal UI (forms and tables only)
4. Admin-only authentication
5. No review process for admins

### What We're NOT Building (Yet)
1. Creator onboarding flow
2. Payment/payout system
3. Complex review workflow
4. Creator analytics
5. A/B testing
6. Promotional tools
7. Community features
8. Support system

### Using Existing Infrastructure
- Leverage existing marketplace tables
- Use current CDN setup
- Reuse authentication system
- Build on top of admin portal

## Risk Mitigation

### Technical Risks
- **File Upload Issues**: Pre-signed URLs with retry logic
- **Database Performance**: Indexes on all query fields
- **CDN Propagation**: Use cache invalidation sparingly

### Content Risks
- **Quality Control**: Admin-only for now
- **Organization**: Strong tagging system from start
- **Versioning**: Simple version number in staging

### Timeline Risks
- **Scope Creep**: Strictly enforce MVP boundaries
- **Integration Issues**: Test marketplace integration early
- **UI Complexity**: Use existing admin portal components

## Next Steps

### Immediate (Today)
1. Review and approve this plan
2. Assign 1-2 developers
3. Set up infrastructure (S3, CDN)
4. Create database migrations

### Tomorrow
1. Start Day 1 implementation
2. Daily standups at 10am
3. End-of-day progress reports
4. Continuous deployment to staging

### End of Week 1
1. Demo admin tools to team
2. Start seeding test content
3. Gather feedback for Week 2

### End of Week 2
1. Launch to production
2. Begin seeding real content
3. Plan Phase 2 (invited creators)

## Conclusion

This admin-first MVP strips away all complexity to focus on one goal: **enable the WonderNest team to populate the marketplace immediately**. By deferring creator onboarding, payment systems, and complex workflows, we can deliver a functional content seeding system in just 2 weeks.

The phased approach then allows us to gradually add creator features based on real needs and feedback, rather than building speculative features upfront. This ensures we build exactly what's needed, when it's needed, while maintaining momentum in content creation.