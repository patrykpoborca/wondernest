import { createSlice, PayloadAction } from '@reduxjs/toolkit'
import { StoryBuilderState, StoryDraft, Asset, StoryTemplate, StoryContent, StoryMetadata, TextBlock, TextBlockStyle, TextVariant } from '../../features/story-builder/types/story'

// Helper function to normalize variants from old format to new format
const normalizeTextBlockVariants = (textBlock: TextBlock): TextBlock => {
  // If variants is already an array, return as-is
  if (Array.isArray(textBlock.variants)) {
    return textBlock
  }

  // Convert old format (object with easy/medium/hard) to new format
  const oldVariants = textBlock.variants as any
  const variants: TextVariant[] = []

  if (oldVariants?.easy) {
    variants.push({
      id: 'variant-easy',
      content: oldVariants.easy,
      metadata: {
        difficulty: 'easy',
        ageRange: [3, 6],
        vocabularyLevel: 3,
        readingTime: Math.ceil((oldVariants.easy || '').split(' ').filter(Boolean).length / 200 * 60),
        wordCount: (oldVariants.easy || '').split(' ').filter(Boolean).length,
        characterCount: (oldVariants.easy || '').length,
      },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      isDefault: true,
    })
  }

  if (oldVariants?.medium) {
    variants.push({
      id: 'variant-medium',
      content: oldVariants.medium,
      metadata: {
        difficulty: 'medium',
        ageRange: [5, 8],
        vocabularyLevel: 5,
        readingTime: Math.ceil((oldVariants.medium || '').split(' ').filter(Boolean).length / 200 * 60),
        wordCount: (oldVariants.medium || '').split(' ').filter(Boolean).length,
        characterCount: (oldVariants.medium || '').length,
      },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    })
  }

  if (oldVariants?.hard) {
    variants.push({
      id: 'variant-hard',
      content: oldVariants.hard,
      metadata: {
        difficulty: 'hard',
        ageRange: [7, 10],
        vocabularyLevel: 7,
        readingTime: Math.ceil((oldVariants.hard || '').split(' ').filter(Boolean).length / 200 * 60),
        wordCount: (oldVariants.hard || '').split(' ').filter(Boolean).length,
        characterCount: (oldVariants.hard || '').length,
      },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    })
  }

  return {
    ...textBlock,
    variants
  }
}

const initialState: StoryBuilderState = {
  drafts: [],
  currentDraft: null,
  assets: [],
  templates: [],
  loading: {
    drafts: false,
    currentDraft: false,
    assets: false,
    publishing: false,
    saving: false,
  },
  error: null,
  autoSaveEnabled: true,
  lastAutoSave: undefined,
}

export const storyBuilderSlice = createSlice({
  name: 'storyBuilder',
  initialState,
  reducers: {
    // Draft management
    setCurrentDraft: (state, action: PayloadAction<StoryDraft | null>) => {
      // Normalize any old-format text blocks when loading a draft
      if (action.payload) {
        const normalizedDraft = {
          ...action.payload,
          content: {
            ...action.payload.content,
            pages: action.payload.content.pages.map(page => ({
              ...page,
              textBlocks: page.textBlocks.map(normalizeTextBlockVariants)
            }))
          }
        }
        state.currentDraft = normalizedDraft
      } else {
        state.currentDraft = action.payload
      }
      state.error = null
    },

    updateCurrentDraftTitle: (state, action: PayloadAction<string>) => {
      if (state.currentDraft) {
        state.currentDraft.title = action.payload
        state.currentDraft.lastModified = new Date().toISOString()
      }
    },

    updateCurrentDraftDescription: (state, action: PayloadAction<string>) => {
      if (state.currentDraft) {
        state.currentDraft.description = action.payload
        state.currentDraft.lastModified = new Date().toISOString()
      }
    },

    updateCurrentDraftContent: (state, action: PayloadAction<StoryContent>) => {
      if (state.currentDraft) {
        state.currentDraft.content = action.payload
        state.currentDraft.pageCount = action.payload.pages.length
        state.currentDraft.lastModified = new Date().toISOString()
      }
    },

    updateCurrentDraftMetadata: (state, action: PayloadAction<StoryMetadata>) => {
      if (state.currentDraft) {
        state.currentDraft.metadata = action.payload
        state.currentDraft.lastModified = new Date().toISOString()
      }
    },

    addPageToCurrentDraft: (state) => {
      if (state.currentDraft) {
        const newPageNumber = state.currentDraft.content.pages.length + 1
        state.currentDraft.content.pages.push({
          pageNumber: newPageNumber,
          textBlocks: [],
          popupImages: [],
        })
        state.currentDraft.pageCount = state.currentDraft.content.pages.length
        state.currentDraft.lastModified = new Date().toISOString()
      }
    },

    removePageFromCurrentDraft: (state, action: PayloadAction<number>) => {
      if (state.currentDraft && state.currentDraft.content.pages.length > 1) {
        const pageIndex = action.payload - 1
        state.currentDraft.content.pages.splice(pageIndex, 1)
        
        // Renumber remaining pages
        state.currentDraft.content.pages.forEach((page, index) => {
          page.pageNumber = index + 1
        })
        
        state.currentDraft.pageCount = state.currentDraft.content.pages.length
        state.currentDraft.lastModified = new Date().toISOString()
      }
    },

    reorderPages: (state, action: PayloadAction<{ fromIndex: number; toIndex: number }>) => {
      if (state.currentDraft) {
        const { fromIndex, toIndex } = action.payload
        const pages = state.currentDraft.content.pages
        const [movedPage] = pages.splice(fromIndex, 1)
        pages.splice(toIndex, 0, movedPage)
        
        // Renumber pages
        pages.forEach((page, index) => {
          page.pageNumber = index + 1
        })
        
        state.currentDraft.lastModified = new Date().toISOString()
      }
    },

    // Draft list management
    setDrafts: (state, action: PayloadAction<StoryDraft[]>) => {
      state.drafts = action.payload
    },

    addDraft: (state, action: PayloadAction<StoryDraft>) => {
      state.drafts.unshift(action.payload)
    },

    updateDraft: (state, action: PayloadAction<StoryDraft>) => {
      const index = state.drafts.findIndex(draft => draft.id === action.payload.id)
      if (index !== -1) {
        state.drafts[index] = action.payload
      }
      
      // Update current draft if it's the same one
      if (state.currentDraft?.id === action.payload.id) {
        state.currentDraft = action.payload
      }
    },

    removeDraft: (state, action: PayloadAction<string>) => {
      state.drafts = state.drafts.filter(draft => draft.id !== action.payload)
      
      // Clear current draft if it was the deleted one
      if (state.currentDraft?.id === action.payload) {
        state.currentDraft = null
      }
    },

    // Assets management
    setAssets: (state, action: PayloadAction<Asset[]>) => {
      state.assets = action.payload
    },

    addAssets: (state, action: PayloadAction<Asset[]>) => {
      state.assets.push(...action.payload)
    },

    // Templates management
    setTemplates: (state, action: PayloadAction<StoryTemplate[]>) => {
      state.templates = action.payload
    },

    // Loading states
    setDraftsLoading: (state, action: PayloadAction<boolean>) => {
      state.loading.drafts = action.payload
    },

    setCurrentDraftLoading: (state, action: PayloadAction<boolean>) => {
      state.loading.currentDraft = action.payload
    },

    setAssetsLoading: (state, action: PayloadAction<boolean>) => {
      state.loading.assets = action.payload
    },

    setPublishingLoading: (state, action: PayloadAction<boolean>) => {
      state.loading.publishing = action.payload
    },

    setSavingLoading: (state, action: PayloadAction<boolean>) => {
      state.loading.saving = action.payload
    },

    // Error handling
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload
    },

    clearError: (state) => {
      state.error = null
    },

    // Auto-save
    setAutoSaveEnabled: (state, action: PayloadAction<boolean>) => {
      state.autoSaveEnabled = action.payload
    },

    setLastAutoSave: (state, action: PayloadAction<string>) => {
      state.lastAutoSave = action.payload
    },

    // Reset state
    resetStoryBuilder: () => initialState,

    // Clear current draft
    clearCurrentDraft: (state) => {
      state.currentDraft = null
      state.error = null
    },

    // Text Block Operations
    updateTextBlock: (state, action: PayloadAction<{ pageNumber: number; textBlock: TextBlock }>) => {
      if (state.currentDraft) {
        const { pageNumber, textBlock } = action.payload
        const pageIndex = pageNumber - 1
        const page = state.currentDraft.content.pages[pageIndex]
        
        if (page) {
          const textBlockIndex = page.textBlocks.findIndex(tb => tb.id === textBlock.id)
          if (textBlockIndex !== -1) {
            page.textBlocks[textBlockIndex] = textBlock
          }
          state.currentDraft.lastModified = new Date().toISOString()
        }
      }
    },

    updateTextBlockStyle: (state, action: PayloadAction<{ pageNumber: number; textBlockId: string; style: TextBlockStyle }>) => {
      if (state.currentDraft) {
        const { pageNumber, textBlockId, style } = action.payload
        const pageIndex = pageNumber - 1
        const page = state.currentDraft.content.pages[pageIndex]
        
        if (page) {
          const textBlockIndex = page.textBlocks.findIndex(tb => tb.id === textBlockId)
          if (textBlockIndex !== -1) {
            page.textBlocks[textBlockIndex].style = style
            if (page.textBlocks[textBlockIndex].metadata) {
              page.textBlocks[textBlockIndex].metadata!.updatedAt = new Date().toISOString()
            }
          }
          state.currentDraft.lastModified = new Date().toISOString()
        }
      }
    },

    updateTextBlockVariants: (state, action: PayloadAction<{ pageNumber: number; textBlockId: string; variants: TextVariant[] }>) => {
      if (state.currentDraft) {
        const { pageNumber, textBlockId, variants } = action.payload
        const pageIndex = pageNumber - 1
        const page = state.currentDraft.content.pages[pageIndex]
        
        if (page) {
          const textBlockIndex = page.textBlocks.findIndex(tb => tb.id === textBlockId)
          if (textBlockIndex !== -1) {
            page.textBlocks[textBlockIndex].variants = variants
            if (page.textBlocks[textBlockIndex].metadata) {
              page.textBlocks[textBlockIndex].metadata!.updatedAt = new Date().toISOString()
            }
          }
          state.currentDraft.lastModified = new Date().toISOString()
        }
      }
    },

    setTextBlockActiveVariant: (state, action: PayloadAction<{ pageNumber: number; textBlockId: string; variantId: string }>) => {
      if (state.currentDraft) {
        const { pageNumber, textBlockId, variantId } = action.payload
        const pageIndex = pageNumber - 1
        const page = state.currentDraft.content.pages[pageIndex]
        
        if (page) {
          const textBlockIndex = page.textBlocks.findIndex(tb => tb.id === textBlockId)
          if (textBlockIndex !== -1) {
            page.textBlocks[textBlockIndex].activeVariantId = variantId
          }
          state.currentDraft.lastModified = new Date().toISOString()
        }
      }
    },
  },
})

export const {
  setCurrentDraft,
  updateCurrentDraftTitle,
  updateCurrentDraftDescription,
  updateCurrentDraftContent,
  updateCurrentDraftMetadata,
  addPageToCurrentDraft,
  removePageFromCurrentDraft,
  reorderPages,
  setDrafts,
  addDraft,
  updateDraft,
  removeDraft,
  setAssets,
  addAssets,
  setTemplates,
  setDraftsLoading,
  setCurrentDraftLoading,
  setAssetsLoading,
  setPublishingLoading,
  setSavingLoading,
  setError,
  clearError,
  setAutoSaveEnabled,
  setLastAutoSave,
  resetStoryBuilder,
  clearCurrentDraft,
  updateTextBlock,
  updateTextBlockStyle,
  updateTextBlockVariants,
  setTextBlockActiveVariant,
} = storyBuilderSlice.actions

export default storyBuilderSlice.reducer