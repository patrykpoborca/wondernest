# Story Builder to Flutter Integration - Implementation Audit

## Current State Analysis

### ✅ Web Story Builder (Complete)
The web-based story builder has the following implemented features:
1. **Data Model**: Enhanced TextBlock with variants system
   - Primary/Alternate variant types
   - Target age and vocabulary difficulty per variant
   - Rich styling capabilities (backgrounds, colors, animations)
   
2. **UI Components**:
   - StoryCanvas for visual editing
   - TextStyleEditor for styling controls
   - VariantManager for managing text variants
   - PageNavigator for multi-page stories
   
3. **State Management**:
   - Redux store with storyBuilderSlice
   - Proper actions for updating text blocks, styles, and variants
   - Auto-save functionality

### ⚠️ Backend API (Partially Implemented)
The backend API endpoints exist but need verification:
1. **Endpoints Defined**:
   - `/api/v2/story-builder/drafts` - Create/Update/Get drafts
   - `/api/v2/story-builder/publish` - Publish stories
   - `/api/v2/story-builder/my-stories` - Get published stories
   
2. **Missing/Unclear**:
   - Backend database schema for the new variant structure
   - Image upload and storage mechanism
   - Story-to-child assignment logic

### ❌ Flutter Story Viewer (Needs Major Updates)
The Flutter app has basic story infrastructure but needs updates:
1. **Current Structure**:
   - StoryTemplate model exists but doesn't match web builder structure
   - Simple text-only pages without variant support
   - No styling support
   
2. **Missing Components**:
   - Text variant selection based on child age
   - Rich text rendering with styles
   - Image loading and caching
   - Progress tracking integration

## Data Structure Mismatch Analysis

### Web Builder TextBlock Structure
```typescript
{
  id: string,
  position: { x, y },
  size: { width, height },
  variants: [
    {
      id: string,
      content: string,
      type: 'primary' | 'alternate',
      metadata: {
        targetAge: number,
        ageRange: [min, max],
        vocabularyDifficulty: string,
        vocabularyLevel: number,
        readingTime: number,
        wordCount: number
      }
    }
  ],
  style: {
    background: { type, color, opacity, padding, borderRadius },
    text: { color, fontSize, fontWeight, textAlign },
    effects: { shadow, glow, outline },
    animation: { type, duration, delay }
  },
  vocabularyWords: string[],
  interactions: []
}
```

### Flutter StoryPage Structure (Current)
```dart
{
  pageNumber: int,
  text: String,  // Simple string, no variants
  image: String?,
  audioUrl: String?,
  vocabularyWords: []
}
```

## Required Changes

### 1. Flutter Model Updates
- [ ] Create new TextBlock model matching web structure
- [ ] Add TextVariant model with metadata
- [ ] Add TextBlockStyle model for styling
- [ ] Update StoryPage to contain TextBlocks instead of simple text
- [ ] Add variant selection logic based on child age

### 2. Backend Schema Updates
- [ ] Verify stories table can store the new JSON structure
- [ ] Add published_stories table if not exists
- [ ] Add story_assignments table for child access
- [ ] Implement image storage solution

### 3. API Integration
- [ ] Update backend to handle new story structure
- [ ] Implement story publishing endpoint
- [ ] Add endpoint to fetch stories for specific child
- [ ] Add progress tracking endpoints

### 4. Flutter UI Components
- [ ] Create StyledTextBlock widget for Flutter
- [ ] Implement variant selection logic
- [ ] Add image loading with caching
- [ ] Create story reader with page navigation
- [ ] Add progress tracking

## Implementation Plan

### Phase 1: Data Model Alignment (Priority: HIGH)
1. Update Flutter models to match web builder structure
2. Create converters for API responses
3. Test data serialization/deserialization

### Phase 2: Backend Integration (Priority: HIGH)
1. Verify/update backend database schema
2. Test story creation and retrieval
3. Implement image upload/storage
4. Add story-child assignment logic

### Phase 3: Flutter Story Viewer (Priority: HIGH)
1. Create story selection screen
2. Build story reader with variant support
3. Add styling renderer
4. Implement progress tracking

### Phase 4: Testing & Polish (Priority: MEDIUM)
1. End-to-end testing of story creation to viewing
2. Performance optimization for large stories
3. Offline support implementation
4. Error handling and edge cases

## Critical Issues to Address

### 1. Data Structure Compatibility
**Issue**: Flutter models don't match web builder structure
**Solution**: Create new models with proper JSON serialization

### 2. Variant Selection Logic
**Issue**: No logic to select appropriate variant based on child age
**Solution**: Port variant selection logic from StyledTextBlock.tsx to Flutter

### 3. Image Storage
**Issue**: No clear image storage/CDN solution
**Solution**: Implement image upload to backend with URL storage in database

### 4. Styling Renderer
**Issue**: Flutter doesn't have styling renderer for rich text
**Solution**: Create custom widget using RichText or flutter_html

### 5. Progress Tracking
**Issue**: No connection between story progress and backend
**Solution**: Implement progress API endpoints and Flutter integration

## Database Schema Requirements

### stories table
```sql
CREATE TABLE stories (
  id UUID PRIMARY KEY,
  family_id UUID REFERENCES families(id),
  creator_id UUID REFERENCES users(id),
  title VARCHAR(255),
  description TEXT,
  content JSONB, -- Full story content with pages, text blocks, variants
  metadata JSONB, -- Target age, educational goals, etc.
  status VARCHAR(50), -- draft, published, archived
  visibility VARCHAR(50), -- private, family, public
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  published_at TIMESTAMP
);
```

### story_assignments table
```sql
CREATE TABLE story_assignments (
  id UUID PRIMARY KEY,
  story_id UUID REFERENCES stories(id),
  child_id UUID REFERENCES children(id),
  assigned_at TIMESTAMP,
  assigned_by UUID REFERENCES users(id)
);
```

### story_progress table
```sql
CREATE TABLE story_progress (
  id UUID PRIMARY KEY,
  story_id UUID REFERENCES stories(id),
  child_id UUID REFERENCES children(id),
  current_page INT,
  pages_read INT[],
  completion_percentage INT,
  total_reading_time INT, -- seconds
  last_read_at TIMESTAMP,
  completed_at TIMESTAMP
);
```

## API Endpoints Needed

### Story Management
- `POST /api/v2/stories` - Create new story
- `PUT /api/v2/stories/{id}` - Update story
- `GET /api/v2/stories/{id}` - Get story details
- `POST /api/v2/stories/{id}/publish` - Publish story
- `DELETE /api/v2/stories/{id}` - Delete story

### Story Assignment
- `POST /api/v2/stories/{id}/assign` - Assign to children
- `GET /api/v2/children/{childId}/stories` - Get child's stories
- `DELETE /api/v2/stories/{id}/assignments/{childId}` - Unassign

### Progress Tracking
- `POST /api/v2/stories/{id}/progress` - Update progress
- `GET /api/v2/stories/{id}/progress/{childId}` - Get progress
- `GET /api/v2/children/{childId}/reading-stats` - Get stats

## Testing Checklist

### Web Builder
- [ ] Create story with multiple pages
- [ ] Add text blocks with variants
- [ ] Apply styling to text blocks
- [ ] Add images to pages
- [ ] Save draft
- [ ] Publish story

### Backend
- [ ] Story saves to database
- [ ] Published stories retrievable
- [ ] Images upload successfully
- [ ] Story assignment works

### Flutter App
- [ ] Stories appear in selection screen
- [ ] Correct variant selected for child age
- [ ] Styling renders correctly
- [ ] Images load and cache
- [ ] Progress tracks properly
- [ ] Offline mode works

## Next Steps

1. **Immediate Priority**: Update Flutter models to match web builder structure
2. **Backend Verification**: Test current API endpoints with new structure
3. **Flutter Implementation**: Build story viewer with variant support
4. **Integration Testing**: End-to-end test from creation to viewing
5. **Performance Optimization**: Handle large stories efficiently