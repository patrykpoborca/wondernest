# Implementation Todo: Story Builder to Flutter Integration

## Phase 1: Data Model Updates (Flutter)
- [ ] Create new models in `/lib/models/story/`
  - [ ] Create `enhanced_story_models.dart` with:
    - [ ] EnhancedStoryPage model
    - [ ] TextBlock model matching web structure
    - [ ] TextVariant model with metadata
    - [ ] TextBlockStyle model
    - [ ] VariantMetadata model
  - [ ] Add JSON serialization with json_annotation
  - [ ] Create converter utilities for legacy format
- [ ] Update story service to handle new models
  - [ ] Add variant selection logic based on child age
  - [ ] Implement style CSS generation for Flutter
- [ ] Test model serialization/deserialization

## Phase 2: Backend Verification
- [ ] Check database schema
  - [ ] Verify stories table exists with JSONB content field
  - [ ] Create story_assignments table if needed
  - [ ] Create story_progress table if needed
- [ ] Test API endpoints with new structure
  - [ ] Test story creation with variants
  - [ ] Test story retrieval
  - [ ] Test publishing flow
- [ ] Implement image upload
  - [ ] Add image upload endpoint
  - [ ] Configure storage (local/S3)
  - [ ] Return URLs for Flutter consumption

## Phase 3: Flutter Story Viewer Implementation
- [ ] Create enhanced story viewer components
  - [ ] Create `StyledTextBlock` widget for Flutter
  - [ ] Implement CSS-to-Flutter style converter
  - [ ] Add animation support
  - [ ] Create vocabulary tooltip widget
- [ ] Update story reader screen
  - [ ] Handle multiple text blocks per page
  - [ ] Position text blocks absolutely
  - [ ] Load and cache background images
  - [ ] Add page navigation with animations
- [ ] Implement variant selection
  - [ ] Get child's age from profile
  - [ ] Select appropriate variant per text block
  - [ ] Allow manual variant switching in parent mode
- [ ] Add progress tracking
  - [ ] Track current page
  - [ ] Save reading time
  - [ ] Mark story as completed
  - [ ] Send progress to backend

## Phase 4: Story Selection & Management
- [ ] Update story selection screen
  - [ ] Show user-created stories
  - [ ] Show assigned stories
  - [ ] Filter by age appropriateness
  - [ ] Show completion status
- [ ] Add story assignment UI (parent mode)
  - [ ] List available stories
  - [ ] Select children to assign
  - [ ] Bulk assignment options
- [ ] Implement offline support
  - [ ] Download story content
  - [ ] Cache images locally
  - [ ] Queue progress updates
  - [ ] Sync when online

## Phase 5: Testing & Polish
- [ ] Unit tests
  - [ ] Model serialization tests
  - [ ] Variant selection logic tests
  - [ ] Style conversion tests
- [ ] Integration tests
  - [ ] API communication tests
  - [ ] Story loading tests
  - [ ] Progress tracking tests
- [ ] UI/UX polish
  - [ ] Loading states
  - [ ] Error handling
  - [ ] Smooth animations
  - [ ] Accessibility features
- [ ] Performance optimization
  - [ ] Image lazy loading
  - [ ] Text rendering optimization
  - [ ] Memory management for large stories

## Phase 6: Documentation & Deployment
- [ ] Document API changes
- [ ] Update Flutter app documentation
- [ ] Create parent guide for story builder
- [ ] Add help screens in app
- [ ] Prepare for app store updates

## Critical Path Items (Do First)
1. **Flutter model updates** - Nothing works without this
2. **Backend API verification** - Ensure data can be saved/retrieved
3. **Basic story viewer** - MVP with text display
4. **Variant selection** - Core feature for age-appropriate content

## Known Blockers
- Backend database schema may need updates
- Image storage solution not finalized
- Performance with large stories unknown
- Offline sync complexity

## Success Criteria
- [ ] Story created on web appears in Flutter app
- [ ] Correct text variant shown based on child age
- [ ] Styling renders properly in Flutter
- [ ] Images load and display correctly
- [ ] Progress saves and persists
- [ ] Works offline after initial download
- [ ] Parent can manage story assignments
- [ ] No regression in existing features