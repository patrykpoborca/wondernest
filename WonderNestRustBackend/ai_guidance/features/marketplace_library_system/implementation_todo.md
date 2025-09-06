# Implementation Todo: Marketplace Library System

## Current Status: Foundation Complete ✅
- [x] Database schema (V002 migration) with 12 comprehensive tables
- [x] Rust models for all marketplace entities 
- [x] MarketplaceRepository with CRUD operations
- [x] API routes connected to v1 endpoints
- [x] Authentication and authorization middleware

## Phase 1: Content Pack Creation & Integration

### File Integration (Priority 1)
- [ ] Create ContentPackService to coordinate file uploads → content packs
- [ ] Add content pack creation endpoint that accepts multiple file IDs
- [ ] Connect marketplace_listings to core.uploaded_files via file references
- [ ] Implement content pack asset manifest generation
- [ ] Add file type validation for content packs (images, audio, metadata)

### Marketplace Listing Enhancement
- [ ] Update MarketplaceRepository to use new marketplace_listings schema 
- [ ] Connect marketplace_listings.content_url to signed URL system
- [ ] Add marketplace listing creation endpoint for creators
- [ ] Implement content approval workflow (draft → pending → approved)
- [ ] Add marketplace listing search with full-text indexing

### Signed URL Integration  
- [ ] Update child library items to return signed URLs for purchased content
- [ ] Add content pack download endpoint using signed URLs
- [ ] Implement bulk signed URL generation for content pack assets
- [ ] Add signed URL validation for marketplace content access

## Phase 2: Purchase & Library Flow

### Purchase Transaction Flow
- [ ] Integrate Stripe payment processing with existing flow
- [ ] Add purchase validation (child ownership, duplicate purchase prevention)
- [ ] Implement family license vs individual child licensing
- [ ] Add purchase confirmation and receipt generation
- [ ] Create purchase history endpoint for parents

### Child Library Management
- [ ] Implement child library CRUD operations (already in repository)
- [ ] Add library organization features (collections, favorites, tags)
- [ ] Create library search and filtering endpoints
- [ ] Add usage tracking integration (play time, completion tracking)
- [ ] Implement offline content management flags

### Collection System
- [ ] Test existing collection CRUD operations
- [ ] Add default system collections ("Recent", "Favorites", etc.)
- [ ] Implement collection sharing between siblings
- [ ] Add collection item management (add/remove content from collections)

## Phase 3: Game/Applet Integration

### Game Content Discovery API
- [ ] Create game-facing API for querying child's available content packs  
- [ ] Add content pack manifest endpoint with game integration metadata
- [ ] Implement content pack asset listing with signed URLs
- [ ] Add usage tracking hooks for game content access
- [ ] Create content pack compatibility checking (game type, version, platform)

### Game Plugin Integration
- [ ] Update existing game plugin architecture to support marketplace content
- [ ] Add ContentPackPlugin base class for games that use marketplace content
- [ ] Create content pack loading utilities for common asset types
- [ ] Add content pack caching and offline availability management

## Phase 4: Advanced Features

### Creator Tools & Analytics
- [ ] Creator dashboard for managing content and viewing analytics
- [ ] Revenue tracking and payout management
- [ ] Creator tier advancement system based on performance metrics
- [ ] Content performance analytics (sales, usage, ratings)

### Advanced Marketplace Features
- [ ] Content recommendations based on child preferences and usage
- [ ] Advanced search with faceting (age, topic, creator, price)
- [ ] Featured content and promotional systems
- [ ] Bundle creation and cross-selling

### Platform Features  
- [ ] Subscription plans integration with content access levels
- [ ] Family sharing improvements (gifting, shared libraries)
- [ ] Content reviews and rating system
- [ ] Advanced content moderation tools

## Testing Strategy

### Unit Tests
- [ ] ContentPackService unit tests
- [ ] MarketplaceRepository test coverage completion
- [ ] Signed URL integration tests
- [ ] Purchase flow validation tests

### Integration Tests
- [ ] End-to-end content pack creation flow
- [ ] Purchase → library → game access integration test
- [ ] File upload → marketplace → signed URL → game download flow
- [ ] Multi-child family library sharing tests

### Platform Tests
- [ ] Test marketplace endpoints with actual database
- [ ] Content pack creation with real file uploads
- [ ] Game integration testing with Flutter plugins
- [ ] Payment processing integration testing (test mode)

## Database Migration Notes

### Existing Schema Compatibility
- Current marketplace_listings table structure needs to align with V002 schema
- May need schema update to properly link marketplace_listings to core.uploaded_files
- Ensure existing file reference system works with content pack requirements

### Required Schema Updates (if needed)
- [ ] Add content_pack_assets junction table if not covered by existing design
- [ ] Update marketplace_listings.asset_urls to reference core.uploaded_files
- [ ] Add content_pack_manifest table for game integration metadata
- [ ] Ensure proper foreign key relationships between all systems

## Risk Mitigation

### Technical Risks
- **File System Integration**: Ensure content pack system doesn't break existing file management
- **Performance**: Large content packs must not impact general file upload performance  
- **Security**: Signed URLs must be properly secured to prevent unauthorized access
- **Database Performance**: Marketplace browsing queries must be optimized for scale

### Business Risks  
- **Content Quality**: Need robust content review process before marketplace launch
- **Payment Processing**: Must handle edge cases (refunds, failed payments, chargebacks)
- **Creator Onboarding**: Balance ease of use with content quality requirements
- **Child Safety**: Ensure all content meets COPPA compliance requirements

## Success Metrics

### Phase 1 Success
- Content creators can upload multi-file content packs successfully
- Marketplace browsing shows available content with proper metadata
- Purchase flow creates library entries and provides secure content access
- Game plugins can query and download purchased content

### Technical KPIs
- Content pack creation success rate > 95%
- Marketplace page load time < 2 seconds
- Signed URL generation time < 100ms
- Game content loading time < 5 seconds
- Zero unauthorized content access incidents

### Business KPIs
- Creator adoption rate (target: 10 creators in first month)
- Content purchase conversion rate (target: 5% of marketplace visitors)
- Average revenue per family (target: $20/month)
- Content engagement rate (target: 70% of purchased content used within 7 days)