import { createSlice, PayloadAction } from '@reduxjs/toolkit'
import { AuthState, User, LoginResponse } from '@/types/auth'

const initialState: AuthState = {
  user: null,
  token: null,
  refreshToken: null,
  isAuthenticated: false,
  isLoading: false,
  error: null,
}

export const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    loginStart: (state) => {
      state.isLoading = true
      state.error = null
    },
    loginSuccess: (state, action: PayloadAction<LoginResponse>) => {
      state.isLoading = false
      state.isAuthenticated = true
      state.user = action.payload.user
      state.token = action.payload.accessToken
      state.refreshToken = action.payload.refreshToken
      state.error = null
      
      // Store in localStorage
      localStorage.setItem('wondernest_token', action.payload.accessToken)
      localStorage.setItem('wondernest_refresh_token', action.payload.refreshToken)
      localStorage.setItem('wondernest_user', JSON.stringify(action.payload.user))
    },
    loginFailure: (state, action: PayloadAction<string>) => {
      state.isLoading = false
      state.isAuthenticated = false
      state.user = null
      state.token = null
      state.refreshToken = null
      state.error = action.payload
    },
    logout: (state) => {
      state.user = null
      state.token = null
      state.refreshToken = null
      state.isAuthenticated = false
      state.isLoading = false
      state.error = null
      
      // Clear localStorage
      localStorage.removeItem('wondernest_token')
      localStorage.removeItem('wondernest_refresh_token')
      localStorage.removeItem('wondernest_user')
    },
    updateUser: (state, action: PayloadAction<User>) => {
      state.user = action.payload
      localStorage.setItem('wondernest_user', JSON.stringify(action.payload))
    },
    clearError: (state) => {
      state.error = null
    },
    restoreSession: (state) => {
      state.isLoading = true
      
      const token = localStorage.getItem('wondernest_token')
      const refreshToken = localStorage.getItem('wondernest_refresh_token')
      const userStr = localStorage.getItem('wondernest_user')
      
      if (token && refreshToken && userStr) {
        try {
          const user = JSON.parse(userStr) as User
          state.token = token
          state.refreshToken = refreshToken
          state.user = user
          state.isAuthenticated = true
        } catch (error) {
          // Invalid stored data, clear it
          localStorage.removeItem('wondernest_token')
          localStorage.removeItem('wondernest_refresh_token')
          localStorage.removeItem('wondernest_user')
        }
      }
      
      state.isLoading = false
    },
    tokenRefreshed: (state, action: PayloadAction<{ accessToken: string; refreshToken: string }>) => {
      state.token = action.payload.accessToken
      state.refreshToken = action.payload.refreshToken
      
      // Update localStorage
      localStorage.setItem('wondernest_token', action.payload.accessToken)
      localStorage.setItem('wondernest_refresh_token', action.payload.refreshToken)
    }
  },
})

export const {
  loginStart,
  loginSuccess,
  loginFailure,
  logout,
  updateUser,
  clearError,
  restoreSession,
  tokenRefreshed,
} = authSlice.actions

export default authSlice.reducer