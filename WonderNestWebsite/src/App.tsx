import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { Box } from '@mui/material'

import { useAuth } from './hooks/useAuth'
import { LoadingScreen } from './components/common/LoadingScreen'
import { LoginPage } from './features/auth/pages/LoginPage'
import { SignupPage } from './features/auth/pages/SignupPage'
import { ParentDashboard } from './features/parent-portal/pages/ParentDashboard'
import { FileManagementPage } from './features/parent-portal/pages/FileManagementPage'
import { StoryBuilderDashboard } from './features/story-builder/pages/StoryBuilderDashboard'
import { StoryEditor } from './features/story-builder/pages/StoryEditor'
import { AdminDashboard } from './features/admin-portal/pages/AdminDashboard'
import { AdminLoginPage } from './features/admin-portal/pages/AdminLoginPage'
import { ContentSeedingDashboard } from './features/admin-portal/pages/ContentSeedingDashboard'
import { useAdminAuth, withAdminAuth } from './contexts/AdminAuthContext'
import { ContentManagerDashboard } from './features/content-manager/pages/ContentManagerDashboard'
import { ProtectedRoute } from './components/common/ProtectedRoute'
import { UserRole, Permission } from './types/auth'

// Marketing pages
import { MarketingLayout } from './components/marketing/MarketingLayout'
import { LandingPage } from './features/marketing/pages/LandingPage'
import { AboutPage } from './features/marketing/pages/AboutPage'
import { PricingPage } from './features/marketing/pages/PricingPage'
import { FeaturesPage } from './features/marketing/pages/FeaturesPage'
import { SafetyPage } from './features/marketing/pages/SafetyPage'
import { ContactPage } from './features/marketing/pages/ContactPage'
import { ResourcesPage } from './features/marketing/pages/ResourcesPage'

function App() {
  const { isLoading, isAuthenticated, user } = useAuth()

  if (isLoading) {
    return <LoadingScreen />
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      <Routes>
        {/* Marketing Pages - Public */}
        <Route path="/" element={<MarketingLayout><LandingPage /></MarketingLayout>} />
        <Route path="/about" element={<MarketingLayout><AboutPage /></MarketingLayout>} />
        <Route path="/pricing" element={<MarketingLayout><PricingPage /></MarketingLayout>} />
        <Route path="/features" element={<MarketingLayout><FeaturesPage /></MarketingLayout>} />
        <Route path="/safety" element={<MarketingLayout><SafetyPage /></MarketingLayout>} />
        <Route path="/contact" element={<MarketingLayout><ContactPage /></MarketingLayout>} />
        <Route path="/resources" element={<MarketingLayout><ResourcesPage /></MarketingLayout>} />
        
        {/* Authenticated App Routes */}
        <Route 
          path="/app/login" 
          element={
            <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
              {isAuthenticated ? (
                <Navigate to={getDefaultRoute(user?.userType)} replace />
              ) : (
                <LoginPage />
              )}
            </Box>
          } 
        />
        
        <Route 
          path="/app/signup" 
          element={
            <Box sx={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
              {isAuthenticated ? (
                <Navigate to={getDefaultRoute(user?.userType)} replace />
              ) : (
                <SignupPage />
              )}
            </Box>
          } 
        />
        
        {/* Protected app routes */}
        <Route
          path="/app/parent"
          element={
            <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
              <ProtectedRoute 
                userType={UserRole.PARENT} 
                fallback="/app/login"
              >
                <ParentDashboard />
              </ProtectedRoute>
            </Box>
          }
        />
        
        <Route
          path="/app/parent/files"
          element={
            <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
              <ProtectedRoute 
                userType={UserRole.PARENT} 
                fallback="/app/login"
              >
                <FileManagementPage />
              </ProtectedRoute>
            </Box>
          }
        />

        <Route
          path="/app/parent/story-builder"
          element={
            <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
              <ProtectedRoute 
                userType={UserRole.PARENT} 
                fallback="/app/login"
              >
                <StoryBuilderDashboard />
              </ProtectedRoute>
            </Box>
          }
        />

        <Route
          path="/app/parent/story-builder/editor/:draftId"
          element={
            <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
              <ProtectedRoute 
                userType={UserRole.PARENT} 
                fallback="/app/login"
              >
                <StoryEditor />
              </ProtectedRoute>
            </Box>
          }
        />
        
        {/* Admin Portal Routes */}
        <Route 
          path="/admin/login" 
          element={
            <Box sx={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
              <AdminLoginPage />
            </Box>
          } 
        />
        
        <Route
          path="/admin/dashboard"
          element={
            <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
              {React.createElement(withAdminAuth(AdminDashboard))}
            </Box>
          }
        />
        
        <Route
          path="/admin/content-seeding"
          element={
            <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
              {React.createElement(withAdminAuth(ContentSeedingDashboard))}
            </Box>
          }
        />
        
        <Route
          path="/admin/*"
          element={<Navigate to="/admin/dashboard" replace />}
        />
        
        <Route
          path="/app/content/*"
          element={
            <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
              <ProtectedRoute 
                permission={Permission.CREATE_CONTENT}
                fallback="/app/login"
              >
                <ContentManagerDashboard />
              </ProtectedRoute>
            </Box>
          }
        />
        
        {/* App route redirect */}
        <Route 
          path="/app" 
          element={
            <Navigate 
              to={isAuthenticated ? getDefaultRoute(user?.userType) : '/app/login'} 
              replace 
            />
          } 
        />
        
        {/* Legacy redirects for old routes */}
        <Route path="/login" element={<Navigate to="/app/login" replace />} />
        <Route path="/parent/*" element={<Navigate to="/app/parent" replace />} />
        <Route path="/admin/*" element={<Navigate to="/app/admin" replace />} />
        <Route path="/content/*" element={<Navigate to="/app/content" replace />} />
        
        {/* Catch all route */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Box>
  )
}

function getDefaultRoute(userType?: string): string {
  switch (userType) {
    case UserRole.PARENT:
      return '/app/parent'
    case UserRole.ADMIN:
    case UserRole.SUPER_ADMIN:
      return '/app/admin'
    case UserRole.CONTENT_MANAGER:
      return '/app/content'
    default:
      return '/app/login'
  }
}

export default App