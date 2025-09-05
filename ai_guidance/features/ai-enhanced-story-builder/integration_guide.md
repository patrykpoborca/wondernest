# AI-Enhanced Story Builder Integration Guide

## Current Story Builder Analysis

The existing Story Builder in the web app has:
- Redux-based state management (`storyBuilderSlice`)
- Auto-save functionality
- Page navigation system
- Text styling editor
- Image upload capability
- Draft management

## Specific Integration Points

### 1. Add AI Panel to StoryEditor.tsx

```tsx
// Add to imports
import { AIAssistantPanel } from '../components/AIAssistantPanel'
import { useAIStoryGeneration } from '../hooks/useAIStoryGeneration'

// Add AI state
const [aiPanelOpen, setAIPanelOpen] = useState(false)
const [aiMode, setAIMode] = useState<'quick' | 'builder' | 'focus'>('builder')
```

### 2. Extend Redux Store

Add to `store/slices/storyBuilderSlice.ts`:
```typescript
// New AI-related state
aiSuggestions: {
  currentSuggestion: string | null,
  history: AIHistoryItem[],
  isGenerating: boolean,
  generationParams: GenerationParams | null
},
aiMetadata: {
  percentAIGenerated: number,
  lastAIAssistTime: string | null,
  educationalGoals: string[],
  vocabularyLevel: string
}
```

### 3. Create New Components

#### Required Components:
1. **AIAssistantPanel** - Main AI interface panel
2. **AIQuickActions** - Floating action buttons for quick AI help
3. **InlineSuggestion** - Contextual suggestion overlay
4. **SmartTemplateSelector** - Template browser with AI customization
5. **VocabularyHelper** - Vocab suggestion widget

### 4. API Integration

Add to `src/store/api/apiSlice.ts`:
```typescript
// AI Story Endpoints
generateStoryContent: builder.mutation({
  query: (params) => ({
    url: '/ai/story/generate',
    method: 'POST',
    body: params,
  }),
}),

enhanceText: builder.mutation({
  query: ({ text, mode }) => ({
    url: '/ai/story/enhance',
    method: 'POST',
    body: { text, mode },
  }),
}),

getSuggestions: builder.query({
  query: ({ context, type }) => ({
    url: `/ai/story/suggestions?type=${type}`,
    method: 'POST',
    body: { context },
  }),
}),
```

### 5. Modify StoryCanvas Component

Update `StoryCanvas.tsx` to support AI interactions:
```tsx
// Add AI suggestion overlay
{showAISuggestion && (
  <AIInlineSuggestion
    suggestion={currentSuggestion}
    onAccept={handleAcceptSuggestion}
    onReject={handleRejectSuggestion}
    onModify={handleModifySuggestion}
  />
)}
```

### 6. Enhance Toolbar

Add AI actions to the toolbar:
```tsx
<IconButton
  onClick={() => setAIPanelOpen(!aiPanelOpen)}
  color={aiPanelOpen ? 'primary' : 'default'}
  title="AI Assistant"
>
  <AutoAwesomeIcon />
</IconButton>
```

## Implementation Sequence

### Phase 1: Foundation (Week 1-2)
1. Set up AI service communication
2. Add basic AI panel component
3. Implement simple text generation

### Phase 2: Integration (Week 3-4)
1. Connect AI to existing editor
2. Add inline suggestions
3. Implement auto-save for AI content

### Phase 3: Enhancement (Week 5-6)
1. Add smart templates
2. Implement vocabulary helper
3. Add educational goal tracking

### Phase 4: Polish (Week 7-8)
1. Optimize AI response times
2. Add loading states and animations
3. Implement keyboard shortcuts

### Phase 5: Launch (Week 9-10)
1. Beta testing with select parents
2. Performance optimization
3. Documentation and help system

## State Management Strategy

### Redux Actions for AI
```typescript
// New actions in storyBuilderSlice
generateWithAI: (state, action) => {
  state.aiSuggestions.isGenerating = true
  state.aiSuggestions.generationParams = action.payload
},

applyAISuggestion: (state, action) => {
  const { pageId, suggestion } = action.payload
  // Apply suggestion to specific page
  const page = state.currentDraft.pages.find(p => p.id === pageId)
  if (page) {
    page.content = suggestion
    state.aiMetadata.percentAIGenerated = calculateAIPercentage(state)
  }
},

trackAIUsage: (state, action) => {
  state.aiMetadata.lastAIAssistTime = new Date().toISOString()
  state.aiSuggestions.history.push(action.payload)
}
```

## UI Layout Changes

### Current Layout:
```
[Header]
[PageNavigator | StoryCanvas | TextStyleEditor]
```

### Enhanced Layout:
```
[Header with AI Toggle]
[PageNavigator | StoryCanvas | AIPanel/TextStyleEditor]
[AIQuickActions (floating)]
```

## Styling Considerations

Use Material-UI theme with AI accent color:
```typescript
// Add to theme
aiAccent: {
  main: '#9C27B0', // Purple for AI features
  light: '#E1BEE7',
  dark: '#6A1B9A',
}
```

## Performance Optimizations

1. **Debounced AI Requests**: Wait 500ms after typing stops
2. **Response Caching**: Cache suggestions for 5 minutes
3. **Progressive Loading**: Stream AI responses
4. **Optimistic Updates**: Show UI changes before API confirms

## Feature Flags

Implement feature flags for gradual rollout:
```typescript
const AI_FEATURES = {
  FULL_GENERATION: 'ai_full_generation',
  INLINE_SUGGESTIONS: 'ai_inline_suggestions',
  SMART_TEMPLATES: 'ai_smart_templates',
  VOCABULARY_HELPER: 'ai_vocabulary_helper',
}
```

## Testing Strategy

1. **Unit Tests**: Test AI integration functions
2. **Integration Tests**: Test AI + Redux flow
3. **E2E Tests**: Full story creation with AI
4. **A/B Testing**: Compare AI vs non-AI creation times

## Metrics to Track

```typescript
interface AIMetrics {
  generationTime: number
  suggestionsAccepted: number
  suggestionsRejected: number
  manualEditsAfterAI: number
  completionRate: number
  timeToCompletion: number
}
```

## Security Considerations

1. **Rate Limiting**: Max 50 AI requests per hour per user
2. **Content Filtering**: Double-check AI output for appropriateness
3. **Audit Logging**: Track all AI generations for compliance
4. **Data Privacy**: Don't send child PII to AI service

## Migration Path

For existing stories:
1. Add AI metadata fields with defaults
2. Allow "enhancement" of existing stories
3. Track which parts are AI vs human created

## Rollback Plan

If issues arise:
1. Feature flag to disable AI
2. Fallback to manual-only mode
3. Preserve all manual content
4. Clear AI suggestions cache

This integration maintains backward compatibility while progressively enhancing the Story Builder with AI capabilities.