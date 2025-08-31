# Quick Implementation Guide: Text Input Enhancements

## 🚀 Start Here

This guide provides a practical, step-by-step approach to implementing the text input enhancements for the WonderNest Story Builder.

## Step 1: Update Type Definitions (30 minutes)

### File: `/src/features/story-builder/types/story.ts`

```typescript
// ADD these new interfaces above TextBlock

export interface TextVariant {
  id: string
  content: string
  metadata: {
    difficulty: 'easy' | 'medium' | 'hard' | 'advanced'
    ageRange: [number, number]
    vocabularyLevel: number
    wordCount: number
  }
  createdAt: string
  updatedAt: string
}

export interface TextBlockStyle {
  background?: {
    type: 'solid' | 'gradient' | 'none'
    color?: string
    opacity?: number
    gradient?: {
      type: 'linear' | 'radial'
      colors: Array<{ color: string; position: number }>
      angle?: number
    }
    padding?: { top: number; right: number; bottom: number; left: number }
    borderRadius?: number
    blur?: number
  }
  text?: {
    color?: string
    fontSize?: number
    fontWeight?: number | string
  }
  effects?: {
    shadow?: boolean
    glow?: boolean
  }
  animation?: {
    type: 'none' | 'pulse' | 'glow' | 'shimmer'
    duration?: number
  }
}

// UPDATE the TextBlock interface
export interface TextBlock {
  id: string
  position: { x: number; y: number }
  variants: TextVariant[]  // Changed from { easy, medium, hard }
  activeVariantId?: string  // New field
  style?: TextBlockStyle    // New field
  vocabularyWords: string[]
}
```

## Step 2: Create Migration Utility (20 minutes)

### File: `/src/features/story-builder/utils/migration.ts`

```typescript
export function migrateTextBlock(oldBlock: any): TextBlock {
  // Handle old format
  if (oldBlock.variants && typeof oldBlock.variants.easy === 'string') {
    return {
      ...oldBlock,
      variants: [
        {
          id: `${oldBlock.id}_easy`,
          content: oldBlock.variants.easy,
          metadata: {
            difficulty: 'easy',
            ageRange: [3, 5],
            vocabularyLevel: 1,
            wordCount: oldBlock.variants.easy.split(' ').length
          },
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: `${oldBlock.id}_medium`,
          content: oldBlock.variants.medium,
          metadata: {
            difficulty: 'medium',
            ageRange: [6, 8],
            vocabularyLevel: 5,
            wordCount: oldBlock.variants.medium.split(' ').length
          },
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: `${oldBlock.id}_hard`,
          content: oldBlock.variants.hard,
          metadata: {
            difficulty: 'hard',
            ageRange: [9, 12],
            vocabularyLevel: 8,
            wordCount: oldBlock.variants.hard.split(' ').length
          },
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ],
      activeVariantId: `${oldBlock.id}_medium`,
      style: undefined
    }
  }
  return oldBlock
}
```

## Step 3: Add Style Tab to TextBlockEditor (45 minutes)

### Update: `/src/features/story-builder/components/PageEditor.tsx`

Add a new Style tab to the TextBlockEditor component (around line 155):

```typescript
// Add to the Tabs component
<Tab label="Style" />

// Add new TabPanel after Vocabulary panel
<TabPanel value={activeTab} index={2}>
  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
    <Typography variant="subtitle2">Background</Typography>
    
    {/* Background Color Picker */}
    <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
      <input
        type="color"
        value={editedBlock.style?.background?.color || '#FFFFFF'}
        onChange={(e) => handleStyleChange('backgroundColor', e.target.value)}
        style={{ width: 50, height: 40, cursor: 'pointer' }}
      />
      <TextField
        label="Color"
        value={editedBlock.style?.background?.color || '#FFFFFF'}
        onChange={(e) => handleStyleChange('backgroundColor', e.target.value)}
        size="small"
        sx={{ flex: 1 }}
      />
    </Box>
    
    {/* Opacity Slider */}
    <Box>
      <Typography variant="body2">
        Opacity: {Math.round((editedBlock.style?.background?.opacity || 1) * 100)}%
      </Typography>
      <Slider
        value={(editedBlock.style?.background?.opacity || 1) * 100}
        onChange={(_, value) => handleStyleChange('opacity', (value as number) / 100)}
        min={0}
        max={100}
        valueLabelDisplay="auto"
        valueLabelFormat={(v) => `${v}%`}
      />
    </Box>
    
    {/* Border Radius */}
    <Box>
      <Typography variant="body2">
        Rounded Corners: {editedBlock.style?.background?.borderRadius || 0}px
      </Typography>
      <Slider
        value={editedBlock.style?.background?.borderRadius || 0}
        onChange={(_, value) => handleStyleChange('borderRadius', value as number)}
        min={0}
        max={20}
        valueLabelDisplay="auto"
        valueLabelFormat={(v) => `${v}px`}
      />
    </Box>
    
    {/* Blur Effect */}
    <Box>
      <Typography variant="body2">
        Background Blur: {editedBlock.style?.background?.blur || 0}px
      </Typography>
      <Slider
        value={editedBlock.style?.background?.blur || 0}
        onChange={(_, value) => handleStyleChange('blur', value as number)}
        min={0}
        max={10}
        valueLabelDisplay="auto"
        valueLabelFormat={(v) => `${v}px`}
      />
    </Box>
    
    {/* Quick Presets */}
    <Box>
      <Typography variant="subtitle2" sx={{ mb: 1 }}>Quick Styles</Typography>
      <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
        <Chip
          label="Vocabulary"
          onClick={() => applyPreset('vocabulary')}
          color="primary"
          variant="outlined"
        />
        <Chip
          label="Emphasis"
          onClick={() => applyPreset('emphasis')}
          color="secondary"
          variant="outlined"
        />
        <Chip
          label="Dialogue"
          onClick={() => applyPreset('dialogue')}
          color="info"
          variant="outlined"
        />
        <Chip
          label="Clear"
          onClick={() => handleStyleChange('clear', null)}
          variant="outlined"
        />
      </Box>
    </Box>
  </Box>
</TabPanel>

// Add handler functions
const handleStyleChange = (property: string, value: any) => {
  setEditedBlock(prev => ({
    ...prev,
    style: {
      ...prev.style,
      background: {
        ...prev.style?.background,
        type: 'solid' as const,
        [property]: value
      }
    }
  }))
}

const applyPreset = (preset: string) => {
  const presets = {
    vocabulary: {
      background: {
        type: 'solid' as const,
        color: '#FFF3CD',
        opacity: 0.8,
        borderRadius: 4,
        padding: { top: 4, right: 8, bottom: 4, left: 8 }
      }
    },
    emphasis: {
      background: {
        type: 'solid' as const,
        color: '#D4EDDA',
        opacity: 0.7,
        borderRadius: 6,
        padding: { top: 6, right: 10, bottom: 6, left: 10 }
      }
    },
    dialogue: {
      background: {
        type: 'solid' as const,
        color: '#D1ECF1',
        opacity: 0.6,
        borderRadius: 8,
        padding: { top: 8, right: 12, bottom: 8, left: 12 }
      }
    }
  }
  
  if (presets[preset]) {
    setEditedBlock(prev => ({
      ...prev,
      style: presets[preset]
    }))
  }
}
```

## Step 4: Update Text Rendering with Styles (30 minutes)

### Update: `/src/features/story-builder/components/PageEditor.tsx`

Modify the DraggableTextBlock to apply styles (around line 35):

```typescript
const DraggableTextBlock = styled(Paper)<{ 
  selected?: boolean 
  zoom?: number 
  textStyle?: TextBlockStyle  // Add this prop
}>(({ theme, selected, zoom = 1, textStyle }) => {
  // Compute background CSS
  const getBackgroundCSS = () => {
    if (!textStyle?.background) return {}
    
    const bg = textStyle.background
    const css: any = {}
    
    if (bg.type === 'solid' && bg.color) {
      const opacity = bg.opacity ?? 1
      // Convert hex to rgba
      const r = parseInt(bg.color.slice(1, 3), 16)
      const g = parseInt(bg.color.slice(3, 5), 16)
      const b = parseInt(bg.color.slice(5, 7), 16)
      css.backgroundColor = `rgba(${r}, ${g}, ${b}, ${opacity})`
    }
    
    if (bg.borderRadius !== undefined) {
      css.borderRadius = `${bg.borderRadius}px`
    }
    
    if (bg.blur !== undefined && bg.blur > 0) {
      css.backdropFilter = `blur(${bg.blur}px)`
      css.webkitBackdropFilter = `blur(${bg.blur}px)` // Safari support
    }
    
    if (bg.padding) {
      css.padding = `${bg.padding.top}px ${bg.padding.right}px ${bg.padding.bottom}px ${bg.padding.left}px`
    }
    
    return css
  }
  
  // Compute text CSS
  const getTextCSS = () => {
    if (!textStyle?.text) return {}
    
    const text = textStyle.text
    const css: any = {}
    
    if (text.color) css.color = text.color
    if (text.fontSize) css.fontSize = `${text.fontSize}px`
    if (text.fontWeight) css.fontWeight = text.fontWeight
    
    return css
  }
  
  return {
    position: 'absolute',
    minWidth: 120,
    minHeight: 60,
    padding: theme.spacing(1),
    cursor: 'move',
    border: selected ? `2px solid ${theme.palette.primary.main}` : `1px dashed ${theme.palette.grey[400]}`,
    backgroundColor: selected ? theme.palette.primary.light : theme.palette.background.paper,
    transition: 'all 0.2s ease-in-out',
    transform: `scale(${1 / zoom})`,
    transformOrigin: 'top left',
    ...getBackgroundCSS(),  // Apply background styles
    '& .text-content': {    // Apply text styles to content
      ...getTextCSS()
    },
    '&:hover': {
      boxShadow: theme.shadows[4],
      borderColor: selected ? theme.palette.primary.main : theme.palette.primary.light,
    },
    // ... rest of existing styles
  }
})

// Update usage in render (around line 453)
<DraggableTextBlock
  key={textBlock.id}
  selected={selectedTextBlock === textBlock.id}
  zoom={zoom}
  textStyle={textBlock.style}  // Pass the style prop
  sx={{
    left: textBlock.position.x,
    top: textBlock.position.y,
  }}
  // ... rest of props
>
  {/* Update text content rendering */}
  <Typography
    className="text-content"  // Add className for styling
    variant="body2"
    sx={{
      lineHeight: 1.4,
      wordBreak: 'break-word',
      userSelect: 'none',
      cursor: isReadOnly ? 'default' : 'text',
    }}
  >
    {/* Use active variant or fallback */}
    {getActiveVariantContent(textBlock)}
  </Typography>
</DraggableTextBlock>

// Add helper function to get active variant content
const getActiveVariantContent = (textBlock: TextBlock): string => {
  if (Array.isArray(textBlock.variants)) {
    const activeVariant = textBlock.variants.find(
      v => v.id === textBlock.activeVariantId
    )
    return activeVariant?.content || textBlock.variants[0]?.content || 'Empty text block'
  }
  // Fallback for old format
  return textBlock.variants?.medium || 'Empty text block'
}
```

## Step 5: Test Your Implementation (15 minutes)

### Quick Test Checklist

1. **Data Migration Test**
   ```typescript
   // In browser console
   const oldBlock = {
     id: 'test',
     position: { x: 100, y: 100 },
     variants: { easy: 'Simple', medium: 'Normal', hard: 'Complex' }
   }
   console.log(migrateTextBlock(oldBlock))
   ```

2. **Style Application Test**
   - Open story editor
   - Double-click a text block
   - Navigate to Style tab
   - Change background color
   - Adjust opacity slider
   - Apply a preset
   - Save and verify rendering

3. **Responsive Test**
   - Test on different zoom levels (50%, 75%, 100%, 150%)
   - Verify styles scale correctly
   - Check mobile viewport

## Step 6: Commit Your Changes

```bash
git add -A
git commit -m "feat(story-builder): implement text background styling

- Added TextBlockStyle interface with background properties
- Created Style tab in TextBlockEditor
- Implemented color picker and opacity controls
- Added style presets (vocabulary, emphasis, dialogue)
- Updated text rendering to apply styles
- Added migration utility for backward compatibility"
```

## Common Issues & Solutions

### Issue 1: Styles not persisting
**Solution**: Ensure you're updating the Redux store and API calls include style data

### Issue 2: Old stories breaking
**Solution**: Always run migration utility when loading stories

### Issue 3: Performance lag with many styled blocks
**Solution**: Implement style caching and memoization

### Issue 4: Styles not visible at different zoom levels
**Solution**: Ensure transform-origin is set correctly

## Next Features to Implement

After basic styling works:

1. **Enhanced Variant Manager** (Week 2)
   - Replace simple variant display
   - Add variant CRUD operations
   - Implement metadata display

2. **Gradient Backgrounds** (Week 3)
   - Add gradient type selector
   - Implement gradient editor
   - Support multiple color stops

3. **Animations** (Week 3)
   - Add animation selector
   - Implement CSS animations
   - Create preview mode

4. **Style Storage** (Week 4)
   - Set up IndexedDB
   - Implement auto-save
   - Add preset management

## Resources

- [CSS-in-JS Best Practices](https://emotion.sh/docs/best-practices)
- [React Performance Optimization](https://react.dev/learn/render-and-commit)
- [Material-UI Styling](https://mui.com/system/styled/)
- [WCAG Color Contrast](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)

## Questions?

If you encounter issues not covered here:
1. Check the technical architecture document
2. Review the UI/UX design specs
3. Consult the remaining_todos for context

---

**Remember**: Start small, test often, and iterate based on feedback!