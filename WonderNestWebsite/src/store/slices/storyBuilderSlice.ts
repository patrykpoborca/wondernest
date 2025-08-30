import { createSlice, PayloadAction } from '@reduxjs/toolkit'
import { StoryBuilderState, StoryDraft, Asset, StoryTemplate, StoryContent, StoryMetadata } from '../../features/story-builder/types/story'

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
      state.currentDraft = action.payload
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
} = storyBuilderSlice.actions

export default storyBuilderSlice.reducer