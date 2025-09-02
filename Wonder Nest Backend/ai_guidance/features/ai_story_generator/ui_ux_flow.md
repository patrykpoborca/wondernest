# AI Story Generator - UI/UX Flow Specification

## User Journey Map

### Discovery Phase
1. **Entry Points**
   - "Create Story" button in parent dashboard
   - "AI Magic" badge on story library
   - Onboarding tutorial for new users
   - Push notification about new feature

2. **First-Time Experience**
   - Animated introduction explaining the feature
   - Sample generated story preview
   - "Try it free" with 3 complimentary generations
   - Trust indicators (COPPA badge, parent review info)

### Story Creation Flow

```
┌─────────────────┐
│ Parent Dashboard│
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐     ┌────────────────┐
│ Create Story    │────▶│Select Images │────▶│ Write Prompt   │
│ (Choose Method) │     │(1-5 images)  │     │ (Guide+Input)  │
└─────────────────┘     └──────────────┘     └────────────────┘
                                                      │
                                ┌─────────────────────┘
                                ▼
                        ┌──────────────┐     ┌────────────────┐
                        │ Configure    │────▶│ Review &       │
                        │ Settings     │     │ Generate       │
                        └──────────────┘     └────────────────┘
                                                      │
                                ┌─────────────────────┘
                                ▼
                        ┌──────────────┐     ┌────────────────┐
                        │ Generation   │────▶│ Preview &      │
                        │ Progress     │     │ Edit           │
                        └──────────────┘     └────────────────┘
                                                      │
                                ┌─────────────────────┘
                                ▼
                        ┌──────────────┐     ┌────────────────┐
                        │ Approve &    │────▶│ Story Ready    │
                        │ Save         │     │ for Child      │
                        └──────────────┘     └────────────────┘
```

## Screen Specifications

### 1. Story Creation Method Selection
**Purpose**: Let parent choose between manual creation or AI generation

**UI Elements**:
- Card-based selection with icons
- "Create Manually" - traditional story builder
- "Generate with AI" - NEW badge, sparkle animation
- Comparison table showing time/effort differences
- Quota indicator (e.g., "3 free generations remaining")

**Interactions**:
- Tap to select method
- Info button explains AI generation
- Link to pricing for additional generations

### 2. Image Selection Screen
**Purpose**: Choose characters and backgrounds for the story

**UI Elements**:
```
┌─────────────────────────────────────┐
│ Select Your Story Images            │
│ Choose 1-5 images (2 selected)      │
├─────────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│ │ ✓   │ │     │ │ ✓   │ │     │   │
│ └─────┘ └─────┘ └─────┘ └─────┘   │
│ Dragon  Castle  Knight  Forest     │
│                                     │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│ │     │ │     │ │     │ │ +   │   │
│ └─────┘ └─────┘ └─────┘ └─────┘   │
│ Puppy   Garden  Robot   Upload     │
├─────────────────────────────────────┤
│ Tip: Mix characters and backgrounds │
│                                     │
│ [Skip Selection]          [Next →] │
└─────────────────────────────────────┘
```

**Features**:
- Grid view of uploaded images
- Checkbox overlay for selection
- Tags shown below each image
- Smart suggestions based on selections
- Upload new image option
- Counter showing selection progress

**Validation**:
- Minimum 0 (can skip)
- Maximum 5 images
- Warning if only backgrounds or only characters

### 3. Prompt Input Screen
**Purpose**: Capture parent's story idea

**UI Elements**:
```
┌─────────────────────────────────────┐
│ Tell Your Story Idea                │
├─────────────────────────────────────┤
│ Selected Images: 🐉 Dragon, 🏰 Castle│
├─────────────────────────────────────┤
│ What story would you like?          │
│ ┌───────────────────────────────┐   │
│ │ A brave dragon who is afraid  │   │
│ │ of the dark learns to be      │   │
│ │ courageous with help from     │   │
│ │ new friends...                │   │
│ └───────────────────────────────┘   │
│ 85/500 characters                   │
├─────────────────────────────────────┤
│ 💡 Prompt Ideas:                    │
│ • An adventure about...             │
│ • A lesson about sharing...         │
│ • A journey to discover...          │
├─────────────────────────────────────┤
│ Or use a template:                  │
│ [Adventure] [Friendship] [Learning] │
│                                     │
│ [← Back]                   [Next →] │
└─────────────────────────────────────┘
```

**Features**:
- Large text input with character counter
- Prompt suggestions based on age group
- Template quick-select buttons
- Examples that update based on selected images
- Voice-to-text option
- Save as template option

**Validation**:
- Minimum 10 characters
- Maximum 500 characters
- Profanity filter
- Warning for potentially problematic content

### 4. Story Configuration
**Purpose**: Set age-appropriate parameters

**UI Elements**:
```
┌─────────────────────────────────────┐
│ Customize Your Story                │
├─────────────────────────────────────┤
│ For Child: [Dropdown - Select]      │
│                                     │
│ Story Length:                       │
│ [5] ←──────●────→ [15] pages       │
│         10 pages                    │
│                                     │
│ Reading Level:                      │
│ ○ Emerging (Ages 3-5)              │
│ ● Developing (Ages 6-8)            │
│ ○ Fluent (Ages 9-12)               │
│                                     │
│ Story Tone:                         │
│ [Adventurous ▼]                    │
│                                     │
│ Educational Focus (Optional):       │
│ [+ Add vocabulary words]            │
│ [+ Add learning themes]             │
│                                     │
│ [← Back]              [Generate →] │
└─────────────────────────────────────┘
```

**Features**:
- Child selector (pre-populated if context)
- Slider for page count
- Radio buttons for reading level
- Dropdown for tone selection
- Optional vocabulary word input
- Optional theme selection
- Estimated reading time display

### 5. Generation Progress Screen
**Purpose**: Show generation status and manage expectations

**UI Elements**:
```
┌─────────────────────────────────────┐
│      Creating Your Story Magic       │
├─────────────────────────────────────┤
│                                     │
│         ✨ Animation ✨              │
│                                     │
│    ▓▓▓▓▓▓▓▓░░░░░░░░  45%          │
│                                     │
│ 📖 Crafting the narrative...        │
│                                     │
│ Estimated time: 15 seconds          │
│                                     │
├─────────────────────────────────────┤
│ Did you know?                       │
│ Our AI creates unique stories that  │
│ help children learn 200+ new words  │
│                                     │
│              [Cancel]               │
└─────────────────────────────────────┘
```

**Features**:
- Animated progress bar
- Step-by-step status updates
- Educational tips during wait
- Cancel option (doesn't use quota)
- Background animation (subtle)
- Success animation on completion

**Status Messages**:
1. "Understanding your images..." (0-20%)
2. "Crafting the narrative..." (20-50%)
3. "Adding vocabulary words..." (50-70%)
4. "Ensuring age-appropriateness..." (70-90%)
5. "Finalizing your story..." (90-100%)

### 6. Story Preview & Edit Screen
**Purpose**: Review and optionally edit generated story

**UI Elements**:
```
┌─────────────────────────────────────┐
│ Review Your Story                   │
│ ┌─────────────────────────────────┐ │
│ │Title: The Brave Little Dragon   │ │
│ │[Edit ✏️]                        │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ Page 1 of 10              [< >]    │
│ ┌─────────────────────────────────┐ │
│ │     [Dragon Image]               │ │
│ │                                  │ │
│ │ Once upon a time, in a          │ │
│ │ magnificent castle, lived a      │ │
│ │ little dragon named Spark...     │ │
│ │                                  │ │
│ │ [Edit Text]                      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📚 Vocabulary (5 words)             │
│ • Courage - being brave            │
│ • Magnificent - very beautiful     │
│                                     │
│ ⚠️ Parent Review Required           │
├─────────────────────────────────────┤
│ [Regenerate]  [Save Draft]  [✓Approve]│
└─────────────────────────────────────┘
```

**Features**:
- Full story preview with pagination
- Inline editing for title and text
- Vocabulary word highlighting
- Image placement visualization
- Quick edit buttons per page
- Regenerate option (uses new quota)
- Save as draft for later
- Approval confirmation

**Edit Mode**:
- Tap to edit any text
- Drag to reorder pages
- Remove/add vocabulary words
- Change image assignments
- Undo/redo functionality

### 7. Approval Confirmation
**Purpose**: Final safety check before child access

**UI Elements**:
```
┌─────────────────────────────────────┐
│ Ready to Share with Your Child?     │
├─────────────────────────────────────┤
│ ✓ Story content reviewed            │
│ ✓ Age-appropriate for Sarah (6)     │
│ ✓ Educational value confirmed       │
│                                     │
│ This story will be added to:        │
│ 👧 Sarah's Library                  │
│                                     │
│ ⭐ Optional: Share to Marketplace   │
│ Help other families enjoy your      │
│ story (with full control)           │
│ □ Share anonymously                 │
│                                     │
│ [← Edit More]    [Approve & Save ✓] │
└─────────────────────────────────────┘
```

### 8. Success Screen
**Purpose**: Confirm story is ready and suggest next actions

**UI Elements**:
```
┌─────────────────────────────────────┐
│        ✨ Story Created! ✨          │
├─────────────────────────────────────┤
│ "The Brave Little Dragon" is now    │
│ available in Sarah's library        │
│                                     │
│ 📊 Generation Stats:                │
│ • 2 of 5 free stories used         │
│ • Next reset: Tomorrow             │
│                                     │
│ What's Next?                        │
│ [View in Library]                   │
│ [Create Another]                    │
│ [Share with Family]                 │
│                                     │
│ 💡 Tip: Watch Sarah read to see     │
│ vocabulary progress!                │
└─────────────────────────────────────┘
```

## Interaction Patterns

### Touch Gestures
- **Tap**: Select, navigate, edit
- **Long press**: More options, preview
- **Swipe**: Navigate pages, dismiss
- **Pinch**: Zoom story preview
- **Drag**: Reorder elements

### Feedback Mechanisms
- **Haptic**: Selection confirmation, errors
- **Visual**: Loading states, success animations
- **Audio**: Optional completion sounds
- **Progress**: Clear indicators at each step

### Error Handling

**Network Errors**:
```
┌─────────────────────────────────────┐
│ Connection Issue                    │
│ Unable to generate story.           │
│ Your prompt has been saved.         │
│                                     │
│ [Try Again]         [Save for Later]│
└─────────────────────────────────────┘
```

**Generation Failures**:
```
┌─────────────────────────────────────┐
│ Generation Unsuccessful              │
│ We couldn't create your story.      │
│ You have not been charged.          │
│                                     │
│ [Try Different Prompt]   [Get Help] │
└─────────────────────────────────────┘
```

**Content Safety Issues**:
```
┌─────────────────────────────────────┐
│ Content Review Needed                │
│ Some content may not be suitable.   │
│ Please review and edit:             │
│ • Page 3: Complex theme detected    │
│                                     │
│ [Review & Edit]          [Regenerate]│
└─────────────────────────────────────┘
```

## Responsive Design

### Mobile (Primary)
- Full-screen modals for each step
- Large touch targets (48dp minimum)
- Thumb-reachable primary actions
- Portrait orientation optimized

### Tablet
- Split-view for image selection
- Side-by-side preview and edit
- Landscape orientation support
- Multi-column layouts where appropriate

### Desktop (Flutter Desktop)
- Keyboard shortcuts for power users
- Hover states for all interactive elements
- Wider layouts with sidebars
- Drag-and-drop for image selection

## Accessibility

### Screen Reader Support
- All images have descriptive alt text
- Form fields properly labeled
- Status announcements for progress
- Semantic heading structure

### Visual Accessibility
- High contrast mode support
- Minimum 4.5:1 contrast ratios
- Focus indicators for keyboard nav
- Adjustable text size support

### Motor Accessibility
- Large touch targets (48x48dp)
- Adequate spacing between buttons
- Gesture alternatives for all actions
- Adjustable timeout periods

## Performance Considerations

### Loading States
- Skeleton screens during data fetch
- Progressive image loading
- Optimistic UI updates
- Cached previous selections

### Offline Handling
- Queue generation requests
- Save drafts locally
- Sync when connected
- Clear offline indicators

## Analytics Events

### Tracking Points
1. `ai_story_initiated` - User starts AI generation
2. `images_selected` - Number and types of images
3. `prompt_entered` - Length and template usage
4. `generation_started` - Configuration selected
5. `generation_completed` - Success/failure, time taken
6. `story_edited` - Which parts were changed
7. `story_approved` - Time to approval
8. `story_shared` - Marketplace sharing
9. `quota_exhausted` - User hits limit
10. `premium_upgrade` - Conversion point

### Key Metrics
- Time to complete first story
- Abandonment rate per step
- Edit rate after generation
- Regeneration frequency
- Template vs custom prompt usage

## A/B Testing Opportunities

### Test Variations
1. **Prompt Templates**: Required vs optional
2. **Image Selection**: Grid vs carousel
3. **Progress Display**: Steps vs percentage
4. **Edit Interface**: Inline vs modal
5. **Pricing Display**: Upfront vs at limit

### Success Metrics
- Completion rate
- Time to completion
- User satisfaction score
- Premium conversion rate
- Feature retention rate