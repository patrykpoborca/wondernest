import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { AdminInfo, AdminSession } from '@/types/admin'
import { adminApiService } from '@/services/adminApi'

interface AdminAuthContextType {
  // State
  isAuthenticated: boolean
  isLoading: boolean
  admin: AdminInfo | null
  error: string | null
  
  // Authentication actions
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
  
  // Permission checking
  hasPermission: (permission: string) => boolean
  hasAnyPermission: (permissions: string[]) => boolean
  isRootAdmin: () => boolean
  
  // Profile management
  refreshProfile: () => Promise<void>
}

const AdminAuthContext = createContext<AdminAuthContextType | undefined>(undefined)

interface AdminAuthProviderProps {
  children: ReactNode
}

export function AdminAuthProvider({ children }: AdminAuthProviderProps) {
  const [isLoading, setIsLoading] = useState(true)
  const [admin, setAdmin] = useState<AdminInfo | null>(null)
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Initialize authentication state
  useEffect(() => {
    const initializeAuth = async () => {
      try {
        const session = adminApiService.getSession()
        if (session && adminApiService.isAuthenticated()) {
          setAdmin(session.admin)
          setIsAuthenticated(true)
          
          // Refresh profile to ensure data is current
          try {
            await refreshProfile()
          } catch (err) {
            console.warn('Profile refresh failed during initialization:', err)
          }
        } else {
          // Clear invalid/expired session
          adminApiService.clearSession()
          setAdmin(null)
          setIsAuthenticated(false)
        }
      } catch (error) {
        console.error('Error initializing auth:', error)
        adminApiService.clearSession()
        setAdmin(null)
        setIsAuthenticated(false)
      } finally {
        setIsLoading(false)
      }
    }

    initializeAuth()
  }, [])

  // Auto-logout when token expires
  useEffect(() => {
    if (!isAuthenticated) return

    const checkTokenExpiry = () => {
      if (!adminApiService.isAuthenticated()) {
        logout()
      }
    }

    // Check token expiry every minute
    const interval = setInterval(checkTokenExpiry, 60000)
    return () => clearInterval(interval)
  }, [isAuthenticated])

  const login = async (email: string, password: string): Promise<void> => {
    setIsLoading(true)
    setError(null)
    
    try {
      const response = await adminApiService.login({ email, password })
      setAdmin(response.admin)
      setIsAuthenticated(true)
    } catch (error: any) {
      setAdmin(null)
      setIsAuthenticated(false)
      setError(error.error || 'Login failed')
      throw error
    } finally {
      setIsLoading(false)
    }
  }

  const logout = async (): Promise<void> => {
    setIsLoading(true)
    setError(null)
    
    try {
      await adminApiService.logout()
    } catch (error) {
      // Log error but continue with logout
      console.error('Error during logout:', error)
    } finally {
      setAdmin(null)
      setIsAuthenticated(false)
      setIsLoading(false)
    }
  }

  const refreshProfile = async (): Promise<void> => {
    if (!isAuthenticated) return
    
    try {
      const updatedAdmin = await adminApiService.getProfile()
      setAdmin(updatedAdmin)
    } catch (error) {
      console.error('Error refreshing profile:', error)
      // If profile refresh fails due to auth, logout
      if ((error as any)?.status === 401) {
        await logout()
      }
    }
  }

  const hasPermission = (permission: string): boolean => {
    return adminApiService.hasPermission(permission)
  }

  const hasAnyPermission = (permissions: string[]): boolean => {
    return adminApiService.hasAnyPermission(permissions)
  }

  const isRootAdmin = (): boolean => {
    return admin?.role_level === 5 || false
  }

  const value: AdminAuthContextType = {
    isAuthenticated,
    isLoading,
    admin,
    error,
    login,
    logout,
    hasPermission,
    hasAnyPermission,
    isRootAdmin,
    refreshProfile,
  }

  return (
    <AdminAuthContext.Provider value={value}>
      {children}
    </AdminAuthContext.Provider>
  )
}

export function useAdminAuth(): AdminAuthContextType {
  const context = useContext(AdminAuthContext)
  if (context === undefined) {
    throw new Error('useAdminAuth must be used within an AdminAuthProvider')
  }
  return context
}

// Higher-order component for protected admin routes
export function withAdminAuth<P extends object>(Component: React.ComponentType<P>) {
  return function ProtectedAdminComponent(props: P) {
    const { isAuthenticated, isLoading } = useAdminAuth()

    if (isLoading) {
      return (
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center', 
          minHeight: '50vh' 
        }}>
          <div>Loading admin session...</div>
        </div>
      )
    }

    if (!isAuthenticated) {
      // Redirect to admin login will be handled by router
      return (
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center', 
          minHeight: '50vh' 
        }}>
          <div>Please log in as an administrator to access this page.</div>
        </div>
      )
    }

    return <Component {...props} />
  }
}

// Hook for permission-based rendering
export function useAdminPermissions() {
  const { hasPermission, hasAnyPermission, isRootAdmin } = useAdminAuth()
  
  return {
    hasPermission,
    hasAnyPermission,
    isRootAdmin,
    canViewAdminAccounts: hasPermission('admin_accounts_view'),
    canCreateAdminAccounts: hasPermission('admin_accounts_create'),
    canManageUsers: hasAnyPermission(['users_view', 'users_update', 'users_disable']),
    canViewAuditLogs: hasPermission('audit_logs_view'),
    canManageContent: hasAnyPermission(['content_approve', 'content_reject', 'content_moderation_queue']),
    canViewAnalytics: hasPermission('analytics_view'),
    canManageSystem: hasAnyPermission(['system_config_view', 'system_config_update', 'system_maintenance']),
  }
}