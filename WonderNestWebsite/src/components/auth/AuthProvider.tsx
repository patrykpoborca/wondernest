import React, { useEffect, useRef } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { RootState, AppDispatch } from '@/store'
import { 
  restoreSession, 
  setLoading, 
  tokenRefreshed, 
  logout 
} from '@/store/slices/authSlice'
import { 
  useAdminRefreshTokenMutation, 
  useParentRefreshTokenMutation 
} from '@/store/api/apiSlice'
import { 
  isTokenExpired, 
  getTokenRefreshTime 
} from '@/utils/auth'

interface AuthProviderProps {
  children: React.ReactNode
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const dispatch = useDispatch<AppDispatch>()
  const { 
    token, 
    refreshToken, 
    user, 
    isAuthenticated 
  } = useSelector((state: RootState) => state.auth)
  
  const [adminRefreshToken] = useAdminRefreshTokenMutation()
  const [parentRefreshToken] = useParentRefreshTokenMutation()
  const refreshTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const isRefreshingRef = useRef(false)
  
  // Initial session restoration
  useEffect(() => {
    const initializeAuth = async () => {
      dispatch(setLoading(true))
      dispatch(restoreSession())
      
      // If we have a refresh token but expired access token, try to refresh
      const storedToken = localStorage.getItem('wondernest_token')
      const storedRefreshToken = localStorage.getItem('wondernest_refresh_token')
      
      if (storedRefreshToken && (!storedToken || isTokenExpired(storedToken))) {
        await attemptTokenRefresh(storedRefreshToken)
      }
      
      dispatch(setLoading(false))
    }
    
    initializeAuth()
  }, [])
  
  // Set up automatic token refresh
  useEffect(() => {
    if (token && isAuthenticated) {
      // Clear any existing timer
      if (refreshTimerRef.current) {
        clearTimeout(refreshTimerRef.current)
      }
      
      // Calculate when to refresh (75% of token lifetime)
      const refreshTime = getTokenRefreshTime(token)
      
      if (refreshTime > 0) {
        console.log(`Setting up token refresh in ${refreshTime / 1000 / 60} minutes`)
        
        refreshTimerRef.current = setTimeout(async () => {
          if (refreshToken && !isRefreshingRef.current) {
            await attemptTokenRefresh(refreshToken)
          }
        }, refreshTime)
      }
    }
    
    return () => {
      if (refreshTimerRef.current) {
        clearTimeout(refreshTimerRef.current)
      }
    }
  }, [token, refreshToken, isAuthenticated])
  
  const attemptTokenRefresh = async (refreshTokenValue: string) => {
    if (isRefreshingRef.current) return
    
    isRefreshingRef.current = true
    console.log('Attempting to refresh token...')
    
    try {
      const isParent = user?.userType === 'parent' || 
                      localStorage.getItem('wondernest_user')?.includes('"userType":"parent"')
      
      const refreshMutation = isParent ? parentRefreshToken : adminRefreshToken
      const result = await refreshMutation({ 
        refreshToken: refreshTokenValue 
      }).unwrap()
      
      if (result.accessToken && result.refreshToken) {
        dispatch(tokenRefreshed({
          accessToken: result.accessToken,
          refreshToken: result.refreshToken
        }))
        console.log('Token refreshed successfully')
      } else {
        throw new Error('Invalid refresh response')
      }
    } catch (error) {
      console.error('Token refresh failed:', error)
      // Clear auth state and redirect to login
      dispatch(logout())
      window.location.href = '/app/login'
    } finally {
      isRefreshingRef.current = false
    }
  }
  
  // Check token validity on visibility change (tab focus)
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible' && token) {
        if (isTokenExpired(token, 30)) {
          // Token expired or about to expire, refresh it
          if (refreshToken && !isRefreshingRef.current) {
            attemptTokenRefresh(refreshToken)
          }
        }
      }
    }
    
    document.addEventListener('visibilitychange', handleVisibilityChange)
    
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange)
    }
  }, [token, refreshToken])
  
  // Check token validity on route change
  useEffect(() => {
    const checkAuthOnNavigation = () => {
      if (token && isTokenExpired(token, 30)) {
        if (refreshToken && !isRefreshingRef.current) {
          attemptTokenRefresh(refreshToken)
        }
      }
    }
    
    // Listen for navigation events
    window.addEventListener('popstate', checkAuthOnNavigation)
    
    return () => {
      window.removeEventListener('popstate', checkAuthOnNavigation)
    }
  }, [token, refreshToken])
  
  return <>{children}</>
}

export default AuthProvider