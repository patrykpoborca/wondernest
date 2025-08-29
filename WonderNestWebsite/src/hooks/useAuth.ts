import { useEffect } from 'react'
import { useSelector, useDispatch } from 'react-redux'
import type { RootState, AppDispatch } from '@/store'
import { 
  restoreSession, 
  loginStart, 
  loginSuccess, 
  loginFailure, 
  logout as logoutAction 
} from '@/store/slices/authSlice'
import { 
  useAdminLoginMutation, 
  useParentLoginMutation, 
  useLogoutMutation 
} from '@/store/api/apiSlice'
import { LoginCredentials, UserRole, Permission } from '@/types/auth'

export const useAuth = () => {
  const dispatch = useDispatch<AppDispatch>()
  const authState = useSelector((state: RootState) => state.auth)
  
  const [adminLogin] = useAdminLoginMutation()
  const [parentLogin] = useParentLoginMutation()
  const [logoutMutation] = useLogoutMutation()
  
  // Restore session on hook initialization
  useEffect(() => {
    if (!authState.isAuthenticated && !authState.isLoading) {
      dispatch(restoreSession())
    }
  }, [dispatch, authState.isAuthenticated, authState.isLoading])
  
  const login = async (credentials: LoginCredentials, userType: 'admin' | 'parent' = 'admin') => {
    dispatch(loginStart())
    
    try {
      const result = userType === 'admin' 
        ? await adminLogin(credentials).unwrap()
        : await parentLogin(credentials).unwrap()
      
      if (result.requiresTwoFactor) {
        // Handle 2FA requirement
        return { requiresTwoFactor: true }
      }
      
      dispatch(loginSuccess(result))
      return { success: true }
    } catch (error: any) {
      const errorMessage = error?.data?.message || error?.message || 'Login failed'
      dispatch(loginFailure(errorMessage))
      return { success: false, error: errorMessage }
    }
  }
  
  const logout = async () => {
    try {
      // Call the appropriate logout endpoint based on user type
      const userType = authState.user?.userType === 'parent' ? 'parent' : 'admin'
      await logoutMutation({ userType }).unwrap()
    } catch (error) {
      // Even if server logout fails, we still clear local state
      console.warn('Server logout failed, but clearing local state:', error)
    } finally {
      dispatch(logoutAction())
    }
  }
  
  const hasPermission = (permission: Permission): boolean => {
    return authState.user?.permissions?.includes(permission) ?? false
  }
  
  const hasAnyPermission = (permissions: Permission[]): boolean => {
    return permissions.some(permission => hasPermission(permission))
  }
  
  const hasAllPermissions = (permissions: Permission[]): boolean => {
    return permissions.every(permission => hasPermission(permission))
  }
  
  const hasRole = (role: UserRole): boolean => {
    return authState.user?.userType === role
  }
  
  const hasAnyRole = (roles: UserRole[]): boolean => {
    return roles.some(role => hasRole(role))
  }
  
  const isAdmin = (): boolean => {
    return hasAnyRole([UserRole.ADMIN, UserRole.SUPER_ADMIN])
  }
  
  const isContentManager = (): boolean => {
    return hasAnyRole([UserRole.CONTENT_MANAGER, UserRole.CONTENT_MODERATOR]) ||
           hasAnyPermission([Permission.CREATE_CONTENT, Permission.EDIT_CONTENT])
  }
  
  const isParent = (): boolean => {
    return hasRole(UserRole.PARENT)
  }
  
  return {
    // State
    user: authState.user,
    isAuthenticated: authState.isAuthenticated,
    isLoading: authState.isLoading,
    error: authState.error,
    token: authState.token,
    
    // Actions
    login,
    logout,
    
    // Permission helpers
    hasPermission,
    hasAnyPermission,
    hasAllPermissions,
    hasRole,
    hasAnyRole,
    isAdmin,
    isContentManager,
    isParent,
  }
}