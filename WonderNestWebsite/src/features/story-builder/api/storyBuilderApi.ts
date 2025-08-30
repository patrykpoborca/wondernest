import { apiSlice } from '@/store/api/apiSlice'
import { 
  StoryDraft, 
  CreateDraftRequest, 
  UpdateDraftRequest, 
  StoryListResponse,
  PublishStoryRequest,
  PreviewRequest,
  PreviewResponse,
  AssetLibraryResponse,
  StoryTemplate
} from '../types/story'

export const storyBuilderApi = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    // Draft Management
    createDraft: builder.mutation<StoryDraft, CreateDraftRequest>({
      query: (draft) => ({
        url: '/api/v2/story-builder/drafts',
        method: 'POST',
        body: draft,
      }),
      invalidatesTags: ['StoryDraft'],
    }),

    updateDraft: builder.mutation<StoryDraft, { id: string; data: UpdateDraftRequest }>({
      query: ({ id, data }) => ({
        url: `/api/v2/story-builder/drafts/${id}`,
        method: 'PUT',
        body: data,
      }),
      invalidatesTags: (_, __, { id }) => [
        { type: 'StoryDraft', id },
        'StoryDraft'
      ],
    }),

    getDrafts: builder.query<StoryListResponse, {
      status?: 'draft' | 'published' | 'archived'
      limit?: number
      offset?: number
      sortBy?: 'created' | 'modified' | 'title'
      order?: 'asc' | 'desc'
    }>({
      query: (params) => ({
        url: '/api/v2/story-builder/drafts',
        params,
      }),
      providesTags: (result) => [
        'StoryDraft',
        ...(result?.data || []).map(({ id }) => ({ type: 'StoryDraft' as const, id }))
      ],
    }),

    getDraft: builder.query<StoryDraft, string>({
      query: (draftId) => `/api/v2/story-builder/drafts/${draftId}`,
      providesTags: (_, __, draftId) => [{ type: 'StoryDraft', id: draftId }],
    }),

    deleteDraft: builder.mutation<{ message: string }, string>({
      query: (draftId) => ({
        url: `/api/v2/story-builder/drafts/${draftId}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_, __, draftId) => [
        { type: 'StoryDraft', id: draftId },
        'StoryDraft'
      ],
    }),

    // Publishing
    publishStory: builder.mutation<any, PublishStoryRequest>({
      query: (publishData) => ({
        url: '/api/v2/story-builder/publish',
        method: 'POST',
        body: publishData,
      }),
      invalidatesTags: ['StoryDraft', 'PublishedStory'],
    }),

    unpublishStory: builder.mutation<{ message: string }, string>({
      query: (storyId) => ({
        url: `/api/v2/story-builder/unpublish/${storyId}`,
        method: 'POST',
      }),
      invalidatesTags: ['PublishedStory'],
    }),

    // Preview
    generatePreview: builder.mutation<PreviewResponse, PreviewRequest>({
      query: (previewData) => ({
        url: '/api/v2/story-builder/preview',
        method: 'POST',
        body: previewData,
      }),
    }),

    // Asset Management
    getAssets: builder.query<AssetLibraryResponse, {
      category?: 'animals' | 'nature' | 'objects' | 'people' | 'fantasy'
      tags?: string
      search?: string
      isPremium?: boolean
      limit?: number
      offset?: number
    }>({
      query: (params) => ({
        url: '/api/v2/story-builder/assets/images',
        params,
      }),
      providesTags: ['Asset'],
    }),

    uploadAsset: builder.mutation<any, FormData>({
      query: (formData) => ({
        url: '/api/v2/story-builder/assets/upload',
        method: 'POST',
        body: formData,
        formData: true,
      }),
      invalidatesTags: ['Asset'],
    }),

    deleteAsset: builder.mutation<{ message: string }, string>({
      query: (assetId) => ({
        url: `/api/v2/story-builder/assets/${assetId}`,
        method: 'DELETE',
      }),
      invalidatesTags: ['Asset'],
    }),

    // Templates
    getTemplates: builder.query<{ data: StoryTemplate[] }, {
      category?: 'fairy-tale' | 'adventure' | 'educational' | 'custom'
      ageRange?: '3-5' | '6-8' | '9-12'
      limit?: number
      offset?: number
    }>({
      query: (params) => ({
        url: '/api/v2/story-builder/templates',
        params,
      }),
      providesTags: ['StoryTemplate'],
    }),

    createFromTemplate: builder.mutation<StoryDraft, {
      templateId: string
      title: string
      customizations?: Record<string, string>
    }>({
      query: ({ templateId, ...data }) => ({
        url: `/api/v2/story-builder/templates/${templateId}/create`,
        method: 'POST',
        body: data,
      }),
      invalidatesTags: ['StoryDraft'],
    }),

    // Story Management
    getMyStories: builder.query<any, {
      childId?: string
      limit?: number
      offset?: number
    }>({
      query: (params) => ({
        url: '/api/v2/story-builder/my-stories',
        params,
      }),
      providesTags: ['PublishedStory'],
    }),

    getStoryAnalytics: builder.query<any, string>({
      query: (storyId) => `/api/v2/story-builder/stories/${storyId}/analytics`,
      providesTags: (_, __, storyId) => [{ type: 'StoryAnalytics', id: storyId }],
    }),

    // Mock endpoints for development (will be replaced with real backend)
    mockGetDrafts: builder.query<StoryListResponse, any>({
      queryFn: async () => {
        // Mock data for development
        return {
          data: {
            data: [
              {
                id: '1',
                title: 'The Brave Little Bunny',
                description: 'A story about courage and friendship',
                content: {
                  version: '1.0',
                  pages: [{
                    pageNumber: 1,
                    textBlocks: [],
                    popupImages: []
                  }]
                },
                metadata: {
                  targetAge: [4, 6] as [number, number],
                  educationalGoals: ['vocabulary', 'courage'],
                  estimatedReadTime: 180,
                  vocabularyList: ['brave', 'bunny', 'forest']
                },
                status: 'draft' as const,
                pageCount: 1,
                lastModified: new Date().toISOString(),
                createdAt: new Date().toISOString(),
                collaborators: [],
                version: 1
              }
            ],
            pagination: {
              total: 1,
              limit: 20,
              offset: 0
            }
          }
        }
      },
      providesTags: ['StoryDraft'],
    }),

    mockCreateDraft: builder.mutation<StoryDraft, CreateDraftRequest>({
      queryFn: async (draft) => {
        const newDraft: StoryDraft = {
          id: Math.random().toString(36).substr(2, 9),
          title: draft.title,
          description: draft.description,
          content: draft.content || {
            version: '1.0',
            pages: [{
              pageNumber: 1,
              textBlocks: [],
              popupImages: []
            }]
          },
          metadata: {
            targetAge: draft.targetAge,
            educationalGoals: [],
            estimatedReadTime: 0,
            vocabularyList: []
          },
          status: 'draft',
          pageCount: 1,
          lastModified: new Date().toISOString(),
          createdAt: new Date().toISOString(),
          collaborators: [],
          version: 1
        }
        
        return { data: newDraft }
      },
      invalidatesTags: ['StoryDraft'],
    }),

    mockUpdateDraft: builder.mutation<StoryDraft, { id: string; data: UpdateDraftRequest }>({
      queryFn: async ({ id, data }) => {
        // Mock update - return updated draft
        const updatedDraft: StoryDraft = {
          id,
          title: data.title || 'Updated Story',
          description: data.description,
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
            estimatedReadTime: 0,
            vocabularyList: []
          },
          status: 'draft',
          pageCount: data.content?.pages?.length || 1,
          lastModified: new Date().toISOString(),
          createdAt: new Date().toISOString(),
          collaborators: [],
          version: 1
        }
        
        return { data: updatedDraft }
      },
      invalidatesTags: (_, __, { id }) => [
        { type: 'StoryDraft', id },
        'StoryDraft'
      ],
    }),

    mockGetAssets: builder.query<AssetLibraryResponse, any>({
      queryFn: async () => {
        return {
          data: {
            data: [
              {
                id: 'asset_1',
                url: '/api/placeholder/400/300?text=Forest+Background',
                thumbnail: '/api/placeholder/150/100?text=Forest',
                category: 'nature' as const,
                tags: ['forest', 'trees', 'nature'],
                isPremium: false
              },
              {
                id: 'asset_2',
                url: '/api/placeholder/400/300?text=Cute+Bunny',
                thumbnail: '/api/placeholder/150/100?text=Bunny',
                category: 'animals' as const,
                tags: ['bunny', 'rabbit', 'cute'],
                isPremium: false
              },
              {
                id: 'asset_3',
                url: '/api/placeholder/400/300?text=Castle',
                thumbnail: '/api/placeholder/150/100?text=Castle',
                category: 'fantasy' as const,
                tags: ['castle', 'fairy-tale', 'medieval'],
                isPremium: true
              }
            ],
            pagination: {
              total: 3,
              limit: 50,
              offset: 0
            }
          }
        }
      },
      providesTags: ['Asset'],
    }),
  }),
  overrideExisting: false,
})

// Export hooks for usage in functional components
export const {
  useCreateDraftMutation,
  useUpdateDraftMutation,
  useGetDraftsQuery,
  useGetDraftQuery,
  useDeleteDraftMutation,
  usePublishStoryMutation,
  useUnpublishStoryMutation,
  useGeneratePreviewMutation,
  useGetAssetsQuery,
  useUploadAssetMutation,
  useDeleteAssetMutation,
  useGetTemplatesQuery,
  useCreateFromTemplateMutation,
  useGetMyStoriesQuery,
  useGetStoryAnalyticsQuery,
  
  // Mock hooks for development
  useMockGetDraftsQuery,
  useMockCreateDraftMutation,
  useMockUpdateDraftMutation,
  useMockGetAssetsQuery,
} = storyBuilderApi