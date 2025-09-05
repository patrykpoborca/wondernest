import { apiSlice } from '../../../store/api/apiSlice'
import { StoryDraft, StoryContent, CreateDraftRequest, UpdateDraftRequest } from '../types/story'
import { v4 as uuidv4 } from 'uuid'

/**
 * Story Builder API that integrates with the game data system
 * Stories are saved as game data for the "story_adventure" game type
 * Note: Game routes are at /api/v2 while apiSlice uses /api/v1 base,
 * so we need to use absolute paths starting with /api/v2
 */
const GAME_TYPE = 'story_adventure'
const API_V2_PREFIX = '../v2' // Relative path to v2 from v1 base

// Helper function to get child ID from user context
const getChildId = () => {
  // TODO: In production, parents should select which child they're creating stories for
  // For now, use a test child ID that exists in the database
  // This is "Test Test" child from the database
  const TEST_CHILD_ID = '50cb1b31-bd85-4604-8cd1-efc1a73c9359'
  
  // In future, we would:
  // 1. Prompt parent to select a child from their family
  // 2. Or create stories at the family level
  // 3. Or auto-create a child profile for the parent
  
  return TEST_CHILD_ID
}

// Helper functions
const createDraftDataKey = (draftId: string) => `story_draft_${draftId}`
const createPublishedDataKey = (storyId: string) => `story_published_${storyId}`

const transformGameDataToStoryDraft = (gameData: any): StoryDraft => {
  // dataValue is a Map<String, JsonElement> from backend
  // The story data is stored as a JSON string in the 'data' key
  let data: any = {}
  
  if (gameData.dataValue?.data) {
    try {
      // Parse the JSON string
      data = typeof gameData.dataValue.data === 'string' 
        ? JSON.parse(gameData.dataValue.data)
        : gameData.dataValue.data
    } catch (e) {
      console.error('Failed to parse story data:', e)
      data = {}
    }
  } else {
    // Fallback to direct dataValue if no 'data' key
    data = gameData.dataValue || {}
  }
  
  return {
    id: gameData.dataKey.replace('story_draft_', ''),
    title: data.title || 'Untitled Story',
    description: data.description || '',
    content: data.content || {
      version: '1.0',
      pages: [{
        pageNumber: 1,
        textBlocks: [],
        popupImages: []
      }]
    },
    metadata: data.metadata || {
      targetAge: [4, 6] as [number, number],
      educationalGoals: [],
      estimatedReadTime: 60,
      vocabularyList: []
    },
    status: 'draft' as const,
    pageCount: data.content?.pages?.length || 1,
    lastModified: gameData.updatedAt,
    createdAt: gameData.createdAt,
    collaborators: data.collaborators || [],
    version: data.version || 1,
    thumbnail: data.thumbnail || undefined,
  }
}

const transformStoryDraftToGameData = (draft: Partial<StoryDraft>) => {
  const storyData = {
    title: draft.title,
    description: draft.description,
    content: draft.content,
    metadata: draft.metadata,
    collaborators: draft.collaborators || [],
    version: (draft.version || 0) + 1,
    thumbnail: draft.thumbnail,
  }
  
  // Return as JSON string in 'data' key for backend Map<String, JsonElement>
  return {
    data: JSON.stringify(storyData)
  }
}

export const storyGameDataApi = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    // Get all story drafts for current child
    getStoryDrafts: builder.query<{ data: StoryDraft[] }, {}>({
      query: () => ({
        url: `${API_V2_PREFIX}/games/children/${getChildId()}/data`,
        params: { gameType: GAME_TYPE },
      }),
      transformResponse: (response: any) => {
        // Backend returns LoadGameDataResponse with gameData array
        if (!response || !response.success) {
          return { data: [] }
        }
        
        const drafts = (response.gameData || [])
          .filter((item: any) => item.dataKey?.startsWith('story_draft_'))
          .map(transformGameDataToStoryDraft)
        
        return { data: drafts }
      },
      providesTags: ['StoryDraft'],
    }),

    // Get specific story draft
    getStoryDraft: builder.query<StoryDraft, string>({
      async queryFn(draftId, _queryApi, _extraOptions, fetchWithBQ) {
        // First try to get the specific draft
        const specificResult = await fetchWithBQ({
          url: `${API_V2_PREFIX}/games/children/${getChildId()}/data/${GAME_TYPE}/${createDraftDataKey(draftId)}`,
        })
        
        if (specificResult.data && (specificResult.data as any).dataKey) {
          return { data: transformGameDataToStoryDraft(specificResult.data) }
        }
        
        // If specific query fails, try to get all drafts and find the one we need
        const allDraftsResult = await fetchWithBQ({
          url: `${API_V2_PREFIX}/games/children/${getChildId()}/data`,
          params: { gameType: GAME_TYPE },
        })
        
        if (allDraftsResult.data && (allDraftsResult.data as any).success) {
          const drafts = ((allDraftsResult.data as any).gameData || [])
            .filter((item: any) => item.dataKey === createDraftDataKey(draftId))
            .map(transformGameDataToStoryDraft)
          
          if (drafts.length > 0) {
            return { data: drafts[0] }
          }
        }
        
        return { error: { status: 404, data: { message: 'Story draft not found' } } }
      },
      providesTags: (_, __, draftId) => [{ type: 'StoryDraft', id: draftId }],
    }),

    // Create new story draft
    createStoryDraft: builder.mutation<{ id: string }, CreateDraftRequest>({
      query: ({ title, description, targetAge }) => {
        const draftId = uuidv4().substring(0, 8)
        const initialContent: StoryContent = {
          version: '1.0',
          pages: [{
            pageNumber: 1,
            textBlocks: [],
            popupImages: []
          }]
        }

        // Wrap the story data as a single JSON value
        const storyData = {
          title,
          description: description || '',
          content: initialContent,
          metadata: {
            targetAge,
            educationalGoals: [],
            estimatedReadTime: 60,
            vocabularyList: []
          },
          collaborators: [],
          version: 1,
        }

        return {
          url: `${API_V2_PREFIX}/games/children/${getChildId()}/data`,
          method: 'PUT',
          body: {
            gameType: GAME_TYPE,
            dataKey: createDraftDataKey(draftId),
            dataValue: {
              data: JSON.stringify(storyData) // Store as JSON string in a single key
            }
          }
        }
      },
      transformResponse: (response: any, meta, { title }) => {
        // Extract draft ID from response or generate one
        const draftId = response.dataKey?.replace('story_draft_', '') || uuidv4().substring(0, 8)
        return { id: draftId }
      },
      invalidatesTags: ['StoryDraft'],
    }),

    // Update existing story draft
    updateStoryDraft: builder.mutation<void, { id: string; data: UpdateDraftRequest }>({
      query: ({ id, data }) => ({
        url: `${API_V2_PREFIX}/games/children/${getChildId()}/data`,
        method: 'PUT',
        body: {
          gameType: GAME_TYPE,
          dataKey: createDraftDataKey(id),
          dataValue: transformStoryDraftToGameData(data)
        }
      }),
      invalidatesTags: (_, __, { id }) => [
        { type: 'StoryDraft', id },
        'StoryDraft'
      ],
    }),

    // Delete story draft
    deleteStoryDraft: builder.mutation<void, string>({
      query: (draftId) => ({
        url: `${API_V2_PREFIX}/games/children/${getChildId()}/data/${GAME_TYPE}/${createDraftDataKey(draftId)}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_, __, draftId) => [
        { type: 'StoryDraft', id: draftId },
        'StoryDraft'
      ],
    }),

    // Publish story (convert draft to published story)
    publishStory: builder.mutation<{ publishedId: string }, { draftId: string; publishData: any }>({
      query: ({ draftId, publishData }) => {
        const publishedId = uuidv4().substring(0, 8)
        const storyData = {
          ...publishData,
          originalDraftId: draftId,
          publishedAt: new Date().toISOString(),
          status: 'published'
        }
        
        return {
          url: `${API_V2_PREFIX}/games/children/${getChildId()}/data`,
          method: 'PUT',
          body: {
            gameType: GAME_TYPE,
            dataKey: createPublishedDataKey(publishedId),
            dataValue: {
              data: JSON.stringify(storyData)
            }
          }
        }
      },
      transformResponse: (response: any) => {
        const publishedId = response.dataKey?.replace('story_published_', '') || uuidv4().substring(0, 8)
        return { publishedId }
      },
      invalidatesTags: ['PublishedStory', 'StoryDraft'],
    }),

    // Get published stories
    getPublishedStories: builder.query<{ data: any[] }, {}>({
      query: () => ({
        url: `${API_V2_PREFIX}/games/children/${getChildId()}/data`,
        params: { gameType: GAME_TYPE },
      }),
      transformResponse: (response: any) => {
        const stories = (response.gameData || [])
          .filter((item: any) => item.dataKey.startsWith('story_published_'))
          .map((item: any) => ({
            id: item.dataKey.replace('story_published_', ''),
            ...item.dataValue,
            publishedAt: item.updatedAt,
          }))
        
        return { data: stories }
      },
      providesTags: ['PublishedStory'],
    }),

    // AI Story Generation Endpoints
    generateStory: builder.mutation<any, {
      prompt: string;
      title?: string;
      age_range: string;
      educational_goals: string[];
      max_pages?: number;
      vocabulary_level?: string;
      include_images?: boolean;
    }>({
      query: (params) => ({
        url: '/ai/story/generate',
        method: 'POST',
        body: params,
      }),
    }),

    enhanceText: builder.mutation<any, {
      text: string;
      mode: 'simplify' | 'elaborate' | 'add_vocabulary' | 'make_exciting' | 'add_educational';
      context?: string;
    }>({
      query: (params) => ({
        url: '/ai/story/enhance',
        method: 'POST',
        body: params,
      }),
    }),

    getSuggestions: builder.mutation<any, {
      context: {
        current_text: string;
        previous_page?: string;
        next_page?: string;
        story_title: string;
        target_age: string;
      };
      suggestion_type: 'next_sentence' | 'plot_twist' | 'character' | 'setting' | 'dialogue' | 'ending';
    }>({
      query: (params) => ({
        url: '/ai/story/suggest',
        method: 'POST',
        body: params,
      }),
    }),

    getAITemplates: builder.query<any[], void>({
      query: () => ({
        url: '/ai/story/templates',
        method: 'GET',
      }),
    }),
  }),
  overrideExisting: false,
})

export const {
  useGetStoryDraftsQuery,
  useGetStoryDraftQuery,
  useCreateStoryDraftMutation,
  useUpdateStoryDraftMutation,
  useDeleteStoryDraftMutation,
  usePublishStoryMutation,
  useGetPublishedStoriesQuery,
  useGenerateStoryMutation,
  useEnhanceTextMutation,
  useGetSuggestionsMutation,
  useGetAITemplatesQuery,
} = storyGameDataApi