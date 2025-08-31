export interface StoryPage {
  pageNumber: number
  background?: string // Asset ID for background image
  textBlocks: TextBlock[]
  popupImages: PopupImage[]
}

export interface TextBlock {
  id: string
  position: { x: number; y: number }
  variants: {
    easy: string
    medium: string
    hard: string
  }
  vocabularyWords: string[]
}

export interface PopupImage {
  id: string
  triggerWord: string
  imageUrl: string
  position: { x: number; y: number }
  size: { width: number; height: number }
  animation?: 'fadeIn' | 'slideIn' | 'bounce' | 'none'
}

export interface StoryContent {
  version: string
  pages: StoryPage[]
}

export interface StoryMetadata {
  targetAge: [number, number] // Min and max age
  educationalGoals: string[]
  estimatedReadTime: number // in seconds
  vocabularyList: string[]
}

export interface StoryDraft {
  id: string
  title: string
  description?: string
  content: StoryContent
  metadata: StoryMetadata
  status: 'draft' | 'published' | 'archived'
  pageCount: number
  lastModified: string
  createdAt: string
  thumbnail?: string
  collaborators: string[]
  version: number
}

export interface PublishedStory extends StoryDraft {
  storyId: string
  publishedAt: string
  assignedChildren: AssignedChild[]
  stats: StoryStats
  visibility: 'private' | 'global'
}

export interface AssignedChild {
  id: string
  name: string
  lastRead?: string
  completionRate: number
}

export interface StoryStats {
  totalReads: number
  averageReadTime: number
  vocabularyMastery: number
}

export interface Asset {
  id: string
  url: string
  thumbnail: string
  category: 'animals' | 'nature' | 'objects' | 'people' | 'fantasy'
  tags: string[]
  isPremium: boolean
}

export interface StoryTemplate {
  id: string
  name: string
  description: string
  thumbnail: string
  pageCount: number
  category: 'fairy-tale' | 'adventure' | 'educational' | 'custom'
  structure: {
    acts: number
    pages: TemplatePage[]
  }
}

export interface TemplatePage {
  type: 'introduction' | 'conflict' | 'resolution' | 'custom'
  suggestedContent: string
}

// API Response types
export interface CreateDraftRequest {
  title: string
  description?: string
  targetAge: [number, number]
  content?: StoryContent
}

export interface UpdateDraftRequest {
  title?: string
  description?: string
  content?: StoryContent
  metadata?: StoryMetadata
}

export interface PublishStoryRequest {
  draftId: string
  publishTo: 'private' | 'global'
  childIds?: string[]
  scheduledDate?: string
  expiryDate?: string
}

export interface StoryListResponse {
  data: StoryDraft[]
  pagination: {
    total: number
    limit: number
    offset: number
  }
}

export interface AssetLibraryResponse {
  data: Asset[]
  pagination: {
    total: number
    limit: number
    offset: number
  }
}

export interface PreviewRequest {
  content: StoryContent
  difficultyLevel: 'easy' | 'medium' | 'hard'
  childAge: number
}

export interface PreviewResponse {
  previewUrl: string
  expiresIn: number // seconds
}

// Redux state types
export interface StoryBuilderState {
  drafts: StoryDraft[]
  currentDraft: StoryDraft | null
  assets: Asset[]
  templates: StoryTemplate[]
  loading: {
    drafts: boolean
    currentDraft: boolean
    assets: boolean
    publishing: boolean
    saving: boolean
  }
  error: string | null
  autoSaveEnabled: boolean
  lastAutoSave?: string
}