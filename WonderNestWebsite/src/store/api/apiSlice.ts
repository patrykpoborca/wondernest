import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react'
import type { BaseQueryFn, FetchArgs, FetchBaseQueryError } from '@reduxjs/toolkit/query'

import { RootState } from '../index'
import { logout, tokenRefreshed } from '../slices/authSlice'
import { LoginCredentials, LoginResponse, BackendAuthResponse, RefreshTokenRequest, User, UserRole, Permission } from '@/types/auth'

const baseQuery = fetchBaseQuery({
  baseUrl: '/api/v1',
  prepareHeaders: (headers, { getState, endpoint }) => {
    const state = getState() as RootState
    const token = state.auth.token
    
    if (token) {
      headers.set('authorization', `Bearer ${token}`)
    }
    
    // Don't set content-type for file uploads - let the browser set it with boundary
    if (endpoint !== 'uploadFile') {
      headers.set('content-type', 'application/json')
    } else {
      // Explicitly delete content-type for file uploads to ensure browser sets it
      headers.delete('content-type')
    }
    
    return headers
  },
})

const baseQueryWithReauth: BaseQueryFn<
  string | FetchArgs,
  unknown,
  FetchBaseQueryError
> = async (args, api, extraOptions) => {
  let result = await baseQuery(args, api, extraOptions)
  
  if (result.error && result.error.status === 401) {
    // Try to refresh the token
    const state = api.getState() as RootState
    const refreshToken = state.auth.refreshToken
    
    if (refreshToken) {
      // Try parent refresh first, fallback to admin if needed
      const state = api.getState() as RootState
      const isParent = state.auth.user?.userType === 'parent'
      const refreshUrl = isParent ? '/auth/parent/refresh' : '/admin/auth/refresh'
      
      const refreshResult = await baseQuery(
        {
          url: refreshUrl,
          method: 'POST',
          body: { refreshToken } as RefreshTokenRequest,
        },
        api,
        extraOptions
      )
      
      if (refreshResult.data) {
        const data = refreshResult.data as LoginResponse
        // Store the new token
        api.dispatch(tokenRefreshed({
          accessToken: data.accessToken,
          refreshToken: data.refreshToken
        }))
        
        // Retry the original query with the new token
        result = await baseQuery(args, api, extraOptions)
      } else {
        // Refresh failed, logout user
        api.dispatch(logout())
        window.location.href = '/login'
      }
    } else {
      // No refresh token, logout user
      api.dispatch(logout())
      window.location.href = '/login'
    }
  }
  
  return result
}

export const apiSlice = createApi({
  reducerPath: 'api',
  baseQuery: baseQueryWithReauth,
  tagTypes: [
    'User', 
    'AdminUser', 
    'Session', 
    'PlatformAnalytics',
    'Content',
    'Bookmark',
    'Child',
    'Family',
    'File',
    'StoryDraft',
    'PublishedStory',
    'Asset',
    'StoryTemplate',
    'StoryAnalytics'
  ],
  endpoints: (builder) => ({
    // Admin Authentication
    adminLogin: builder.mutation<LoginResponse, LoginCredentials>({
      query: (credentials) => ({
        url: '/admin/auth/login',
        method: 'POST',
        body: credentials,
      }),
      invalidatesTags: ['Session', 'AdminUser'],
    }),
    
    // Parent Authentication (uses parent-specific endpoint)
    parentLogin: builder.mutation<LoginResponse, LoginCredentials>({
      query: (credentials) => ({
        url: '/auth/parent/login', // Uses parent-specific endpoint like mobile app
        method: 'POST',
        body: credentials,
      }),
      transformResponse: (response: BackendAuthResponse): LoginResponse => {
        // Transform backend response to frontend structure
        const user: User = {
          id: response.data.userId,
          email: response.data.email,
          firstName: response.data.email.split('@')[0], // Extract from email for now
          lastName: '',
          userType: UserRole.PARENT,
          permissions: [
            Permission.VIEW_CHILD_PROGRESS,
            Permission.MANAGE_CHILD_SETTINGS,
            Permission.MANAGE_BOOKMARKS,
            Permission.VIEW_CHILD_CONTENT,
            Permission.MANAGE_CONTENT_FILTERS,
            Permission.VIEW_ANALYTICS,
            Permission.MANAGE_FAMILY_SETTINGS,
          ],
          twoFactorEnabled: false,
          familyId: response.data.userId, // Use userId as familyId for now
        }

        return {
          accessToken: response.data.accessToken,
          refreshToken: response.data.refreshToken,
          user: user,
          permissions: user.permissions,
          expiresIn: response.data.expiresIn,
          requiresTwoFactor: response.data.requiresPinSetup,
        }
      },
      invalidatesTags: ['Session', 'User'],
    }),
    
    // Refresh Token - Admin
    adminRefreshToken: builder.mutation<LoginResponse, RefreshTokenRequest>({
      query: (request) => ({
        url: '/admin/auth/refresh',
        method: 'POST',
        body: request,
      }),
    }),
    
    // Refresh Token - Parent
    parentRefreshToken: builder.mutation<LoginResponse, RefreshTokenRequest>({
      query: (request) => ({
        url: '/auth/parent/refresh',
        method: 'POST',
        body: request,
      }),
    }),
    
    // Logout - Admin
    adminLogout: builder.mutation<{ message: string }, void>({
      query: () => ({
        url: '/admin/auth/logout',
        method: 'POST',
      }),
      invalidatesTags: ['Session', 'AdminUser'],
    }),
    
    // Logout - Parent
    parentLogout: builder.mutation<{ message: string }, void>({
      query: () => ({
        url: '/auth/parent/logout',
        method: 'POST',
      }),
      invalidatesTags: ['Session', 'User'],
    }),
    
    // Logout (Generic - chooses appropriate endpoint)
    logout: builder.mutation<{ message: string }, { userType?: 'admin' | 'parent' }>({
      query: ({ userType = 'admin' }) => ({
        url: userType === 'parent' ? '/auth/parent/logout' : '/admin/auth/logout',
        method: 'POST',
      }),
      invalidatesTags: ['Session', 'AdminUser', 'User'],
    }),
    
    // Get current user profile
    getCurrentUser: builder.query<any, void>({
      query: () => '/admin/auth/profile',
      providesTags: ['AdminUser'],
    }),
    
    // Get active sessions
    getSessions: builder.query<{ sessions: any[] }, void>({
      query: () => '/admin/auth/sessions',
      providesTags: ['Session'],
    }),
    
    // File Upload Endpoints
    uploadFile: builder.mutation<any, {
      formData: FormData;
      category?: string;
      childId?: string;
      isPublic?: boolean;
      tags?: string;
    }>({
      query: ({ formData, category, childId, isPublic, tags }) => {
        // Build query parameters
        const params = new URLSearchParams()
        if (category) params.append('category', category)
        if (childId) params.append('childId', childId)
        if (isPublic !== undefined) params.append('isPublic', isPublic.toString())
        if (tags) params.append('tags', tags)
        
        return {
          url: `/files/upload${params.toString() ? `?${params.toString()}` : ''}`,
          method: 'POST',
          body: formData,
        }
      },
      invalidatesTags: ['File'],
    }),
    
    getUserFiles: builder.mutation<any, { category?: string }>({
      query: ({ category }) => ({
        url: '/files',
        method: 'GET',
        params: { category },
      }),
      invalidatesTags: ['File'],
    }),
    
    getFile: builder.query<any, string>({
      query: (fileId) => `/files/${fileId}`,
      providesTags: (_, __, fileId) => [{ type: 'File', id: fileId }],
    }),
    
    deleteFile: builder.mutation<any, { fileId: string; softDelete?: boolean }>({
      query: ({ fileId, softDelete }) => ({
        url: `/files/${fileId}`,
        method: 'DELETE',
        params: { softDelete },
      }),
      invalidatesTags: (_, __, { fileId }) => [{ type: 'File', id: fileId }, 'File'],
    }),
    
    checkFileUsage: builder.mutation<any, { fileId: string }>({
      query: ({ fileId }) => ({
        url: `/files/${fileId}/usage`,
        method: 'GET',
      }),
    }),
    
    listUserFiles: builder.query<any, { category?: string; childId?: string; limit?: number; offset?: number }>({
      query: (params) => ({
        url: '/files',
        params,
      }),
      providesTags: ['File'],
    }),
    
    // Game Data Endpoints
    saveGameData: builder.mutation<any, {
      childId: string;
      gameType: string;
      dataKey: string;
      dataValue: any;
    }>({
      query: ({ childId, gameType, dataKey, dataValue }) => ({
        url: `/games/children/${childId}/data`,
        method: 'PUT',
        body: {
          gameType,
          dataKey,
          dataValue,
        },
      }),
      invalidatesTags: ['StoryDraft', 'PublishedStory'],
    }),
    
    loadGameData: builder.query<any, {
      childId: string;
      gameType?: string;
      dataKey?: string;
    }>({
      query: ({ childId, gameType, dataKey }) => ({
        url: `/games/children/${childId}/data`,
        params: { gameType, dataKey },
      }),
      providesTags: ['StoryDraft', 'PublishedStory'],
    }),
    
    getSpecificGameData: builder.query<any, {
      childId: string;
      gameType: string;
      dataKey: string;
    }>({
      query: ({ childId, gameType, dataKey }) => ({
        url: `/games/children/${childId}/data/${gameType}/${dataKey}`,
      }),
      providesTags: (_, __, { dataKey }) => [{ type: 'StoryDraft', id: dataKey }],
    }),
  }),
})

export const {
  useAdminLoginMutation,
  useParentLoginMutation,
  useAdminRefreshTokenMutation,
  useParentRefreshTokenMutation,
  useAdminLogoutMutation,
  useParentLogoutMutation,
  useLogoutMutation,
  useGetCurrentUserQuery,
  useGetSessionsQuery,
  useUploadFileMutation,
  useGetUserFilesMutation,
  useGetFileQuery,
  useDeleteFileMutation,
  useCheckFileUsageMutation,
  useListUserFilesQuery,
  useSaveGameDataMutation,
  useLoadGameDataQuery,
  useGetSpecificGameDataQuery,
} = apiSlice