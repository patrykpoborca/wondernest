import React from 'react'
import { Navigate } from 'react-router-dom'
import { Box, Typography, Button } from '@mui/material'
import { Lock as LockIcon } from '@mui/icons-material'

import { useAuth } from '@/hooks/useAuth'
import { UserRole, Permission } from '@/types/auth'
import { LoadingScreen } from './LoadingScreen'

interface ProtectedRouteProps {
  children: React.ReactNode
  userType?: UserRole | UserRole[]
  permission?: Permission | Permission[]
  requireAll?: boolean // If true, requires ALL permissions; if false, requires ANY permission
  fallback?: string // Redirect path for unauthorized users
}

const UnauthorizedAccess: React.FC<{ onBack?: () => void }> = ({ onBack }) => (
  <Box
    sx={{
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      height: '100vh',
      textAlign: 'center',
      gap: 3,
      px: 2,
    }}
  >
    <LockIcon sx={{ fontSize: 64, color: 'text.secondary' }} />
    <Typography variant="h4" color="textPrimary" fontWeight={600}>
      Access Denied
    </Typography>
    <Typography variant="body1" color="textSecondary" maxWidth={400}>
      You don't have permission to access this page. Please contact your administrator 
      if you believe this is an error.
    </Typography>
    {onBack && (
      <Button 
        variant="contained" 
        onClick={onBack}
        sx={{ mt: 2 }}
      >
        Go Back
      </Button>
    )}
  </Box>
)

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({
  children,
  userType,
  permission,
  requireAll = false,
  fallback = '/login',
}) => {
  const { 
    isAuthenticated, 
    isLoading, 
    user, 
    hasAnyRole, 
    hasAnyPermission, 
    hasAllPermissions,
    token 
  } = useAuth()
  
  // Show loading screen only on initial load
  // Don't show loading for subsequent navigations
  const [initialLoadComplete, setInitialLoadComplete] = React.useState(false)
  
  React.useEffect(() => {
    if (!isLoading) {
      setInitialLoadComplete(true)
    }
  }, [isLoading])
  
  // Show loading only on initial app load
  if (!initialLoadComplete && isLoading) {
    return <LoadingScreen message="Checking authentication..." />
  }
  
  // Redirect to fallback if not authenticated
  // Check both isAuthenticated and token to ensure we have valid auth
  if (!isAuthenticated || !user || !token) {
    return <Navigate to={fallback} replace />
  }
  
  // Check user type requirements
  if (userType) {
    const userTypes = Array.isArray(userType) ? userType : [userType]
    const hasRequiredRole = hasAnyRole(userTypes)
    
    if (!hasRequiredRole) {
      return <UnauthorizedAccess />
    }
  }
  
  // Check permission requirements
  if (permission) {
    const permissions = Array.isArray(permission) ? permission : [permission]
    const hasRequiredPermission = requireAll
      ? hasAllPermissions(permissions)
      : hasAnyPermission(permissions)
    
    if (!hasRequiredPermission) {
      return <UnauthorizedAccess />
    }
  }
  
  // All checks passed, render the protected content
  return <>{children}</>
}

// Higher-order component for easier use with specific roles
export const AdminRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <ProtectedRoute userType={[UserRole.ADMIN, UserRole.SUPER_ADMIN]}>
    {children}
  </ProtectedRoute>
)

export const ParentRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <ProtectedRoute userType={UserRole.PARENT}>
    {children}
  </ProtectedRoute>
)

export const ContentManagerRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <ProtectedRoute 
    permission={[Permission.CREATE_CONTENT, Permission.EDIT_CONTENT]}
    requireAll={false}
  >
    {children}
  </ProtectedRoute>
)