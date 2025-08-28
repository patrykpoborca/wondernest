import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react'
import type { BaseQueryFn, FetchArgs, FetchBaseQueryError } from '@reduxjs/toolkit/query'

import { RootState } from '../index'
import { logout, tokenRefreshed } from '../slices/authSlice'
import { LoginCredentials, LoginResponse, RefreshTokenRequest, ApiError } from '@/types/auth'

const baseQuery = fetchBaseQuery({
  baseUrl: '/api/web/v1',
  prepareHeaders: (headers, { getState }) => {
    const state = getState() as RootState
    const token = state.auth.token
    
    if (token) {
      headers.set('authorization', `Bearer ${token}`)
    }
    
    headers.set('content-type', 'application/json')
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
      const refreshResult = await baseQuery(
        {
          url: '/admin/auth/refresh',
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
    'Family'
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
    
    // Parent Authentication (uses existing endpoint)
    parentLogin: builder.mutation<LoginResponse, LoginCredentials>({
      query: (credentials) => ({
        url: '/auth/login', // Uses existing mobile auth endpoint
        method: 'POST',
        body: credentials,
      }),
      invalidatesTags: ['Session', 'User'],
    }),
    
    // Refresh Token
    refreshToken: builder.mutation<LoginResponse, RefreshTokenRequest>({
      query: (request) => ({
        url: '/admin/auth/refresh',
        method: 'POST',
        body: request,
      }),
    }),
    
    // Logout
    logout: builder.mutation<{ message: string }, void>({
      query: () => ({
        url: '/admin/auth/logout',
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
  }),
})

export const {
  useAdminLoginMutation,
  useParentLoginMutation,
  useRefreshTokenMutation,
  useLogoutMutation,
  useGetCurrentUserQuery,
  useGetSessionsQuery,
} = apiSlice