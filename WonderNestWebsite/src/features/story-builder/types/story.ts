export interface StoryPage {
  pageNumber: number
  background?: string // Asset ID for background image
  textBlocks: TextBlock[]
  popupImages: PopupImage[]
}

// Enhanced TextBlock with styling support
export interface TextBlock {
  id: string
  position: { x: number; y: number }
  size?: { width: number; height: number }
  variants: TextVariant[]
  activeVariantId?: string
  style?: TextBlockStyle
  metadata?: TextBlockMetadata
  vocabularyWords: string[]
  interactions?: TextInteraction[]
}

// Text variant with metadata for intelligent selection
export interface TextVariant {
  id: string
  content: string
  type: 'primary' | 'alternate'
  metadata: VariantMetadata
  createdAt: string
  updatedAt: string
  tags?: string[]
}

export interface VariantMetadata {
  targetAge: number // Single age target (e.g., 5 for 5-year-olds)
  ageRange: [number, number] // Suitable age range [min, max]
  vocabularyDifficulty: 'simple' | 'moderate' | 'advanced' | 'complex' // Vocabulary complexity
  vocabularyLevel: number // 1-10 scale for fine-tuning
  readingTime: number // estimated seconds
  wordCount: number
  characterCount: number
  sentenceComplexity?: number // Flesch-Kincaid score
  educationalTags?: string[]
  languageCode?: string // for multi-language support
}

// Text styling configuration
export interface TextBlockStyle {
  background?: BackgroundStyle
  text?: TextStyle
  effects?: TextEffects
  animation?: TextAnimation
  responsive?: ResponsiveStyle
  presetId?: string
}

export interface BackgroundStyle {
  type: 'solid' | 'gradient' | 'image' | 'pattern'
  color?: string // hex, rgb, rgba
  opacity?: number // 0-1
  gradient?: GradientStyle
  image?: BackgroundImage
  padding?: BoxSpacing
  borderRadius?: BorderRadius
  blur?: number // 0-20px backdrop blur
  mixBlendMode?: string
}

export interface GradientStyle {
  type: 'linear' | 'radial' | 'conic'
  colors: GradientStop[]
  angle?: number // for linear gradients
  center?: { x: number; y: number } // for radial
}

export interface GradientStop {
  color: string
  position: number // 0-100%
  opacity?: number
}

export interface BackgroundImage {
  url: string
  size?: 'cover' | 'contain' | 'auto' | string
  position?: string
  repeat?: 'repeat' | 'repeat-x' | 'repeat-y' | 'no-repeat'
}

export interface BoxSpacing {
  top?: number
  right?: number
  bottom?: number
  left?: number
}

export interface BorderRadius {
  topLeft?: number
  topRight?: number
  bottomLeft?: number
  bottomRight?: number
}

export interface TextStyle {
  color?: string
  fontSize?: number | 'responsive'
  fontWeight?: number | string
  fontFamily?: string
  lineHeight?: number
  letterSpacing?: number
  textAlign?: 'left' | 'center' | 'right' | 'justify'
  textDecoration?: string
  textTransform?: 'none' | 'uppercase' | 'lowercase' | 'capitalize'
  wordSpacing?: number
}

export interface TextEffects {
  shadow?: ShadowEffect[]
  glow?: GlowEffect
  outline?: OutlineEffect
  stroke?: StrokeEffect
  filter?: string // CSS filter
}

export interface ShadowEffect {
  x: number
  y: number
  blur: number
  spread?: number
  color: string
  inset?: boolean
}

export interface GlowEffect {
  color: string
  radius: number
  intensity: number
}

export interface OutlineEffect {
  width: number
  color: string
  style: 'solid' | 'dashed' | 'dotted'
}

export interface StrokeEffect {
  width: number
  color: string
}

export interface TextAnimation {
  type: 'none' | 'pulse' | 'glow' | 'shimmer' | 'bounce' | 'fade' | 'slide' | 'typewriter'
  duration?: number // milliseconds
  delay?: number
  iteration?: number | 'infinite'
  easing?: string
  customKeyframes?: AnimationKeyframe[]
}

export interface AnimationKeyframe {
  offset: number // 0-1
  properties: Record<string, any>
}

export interface ResponsiveStyle {
  mobile?: Partial<TextBlockStyle>
  tablet?: Partial<TextBlockStyle>
  desktop?: Partial<TextBlockStyle>
}

export interface TextBlockMetadata {
  createdAt: string
  updatedAt: string
  createdBy: string
  lockedForEditing?: boolean
  aiGenerated?: boolean
  validationStatus?: 'valid' | 'warning' | 'error'
  validationMessages?: string[]
}

export interface TextInteraction {
  type: 'click' | 'hover' | 'focus'
  action: 'showDefinition' | 'playSound' | 'highlight' | 'navigate'
  payload?: any
}

export interface PopupImage {
  id: string
  triggerWord: string
  imageUrl: string
  position: { x: number; y: number }
  size: { width: number; height: number }
  rotation?: number // Rotation in degrees
  flipHorizontal?: boolean
  flipVertical?: boolean
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

// Style Preset System
export interface StylePreset {
  id: string
  name: string
  description?: string
  category: PresetCategory
  style: TextBlockStyle
  thumbnail?: string
  tags: string[]
  isCustom: boolean
  isGlobal: boolean
  createdAt: string
  updatedAt: string
  usageCount: number
}

export type PresetCategory = 
  | 'emphasis'
  | 'vocabulary'
  | 'dialogue'
  | 'narration'
  | 'title'
  | 'caption'
  | 'interactive'
  | 'seasonal'
  | 'custom'

export interface StyleLibrary {
  presets: StylePreset[]
  categories: PresetCategory[]
  recentlyUsed: string[] // preset IDs
  favorites: string[] // preset IDs
  custom: StylePreset[]
}