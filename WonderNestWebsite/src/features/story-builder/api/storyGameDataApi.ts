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
  // For now, use the user's ID as the child ID since parents are the primary users
  // In a real implementation, this would come from selected child context
  const userStr = localStorage.getItem('wondernest_user')
  if (userStr) {
    try {
      const user = JSON.parse(userStr)
      // Use the family ID or user ID as a proxy for child ID
      return user.familyId || user.id || 'default-child'
    } catch {
      return 'default-child'
    }
  }
  return 'default-child'
}

// Helper functions
const createDraftDataKey = (draftId: string) => `story_draft_${draftId}`
const createPublishedDataKey = (storyId: string) => `story_published_${storyId}`

const transformGameDataToStoryDraft = (gameData: any): StoryDraft => {
  // dataValue is a Map<String, JsonElement> from backend
  const data = gameData.dataValue || {}
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
  return {
    title: draft.title,
    description: draft.description,
    content: draft.content,
    metadata: draft.metadata,
    collaborators: draft.collaborators || [],
    version: (draft.version || 0) + 1,
    thumbnail: draft.thumbnail,
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
      query: (draftId) => ({
        url: `${API_V2_PREFIX}/games/children/${getChildId()}/data/${GAME_TYPE}/${createDraftDataKey(draftId)}`,
      }),
      transformResponse: (response: any) => {
        // Backend returns single GameDataItem directly for specific queries
        if (response && response.dataKey) {
          return transformGameDataToStoryDraft(response)
        }
        throw new Error('Draft not found')
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

        return {
          url: `${API_V2_PREFIX}/games/children/${getChildId()}/data`,
          method: 'PUT',
          body: {
            gameType: GAME_TYPE,
            dataKey: createDraftDataKey(draftId),
            dataValue: {
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
        return {
          url: `${API_V2_PREFIX}/games/children/${getChildId()}/data`,
          method: 'PUT',
          body: {
            gameType: GAME_TYPE,
            dataKey: createPublishedDataKey(publishedId),
            dataValue: {
              ...publishData,
              originalDraftId: draftId,
              publishedAt: new Date().toISOString(),
              status: 'published'
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
} = storyGameDataApi