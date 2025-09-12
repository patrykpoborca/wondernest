import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { CreatorAccount } from '@/features/creator-portal/services/creatorApi'
import { creatorApi } from '@/features/creator-portal/services/creatorApi'

interface CreatorAuthContextType {
  // State
  isAuthenticated: boolean
  isLoading: boolean
  creator: CreatorAccount | null
  error: string | null
  
  // Authentication actions
  login: (email: string, password: string, totpCode?: string) => Promise<void>
  logout: () => Promise<void>
  register: (registrationData: any) => Promise<void>
  
  // Profile management
  refreshProfile: () => Promise<void>
  updateProfile: (updates: Partial<CreatorAccount>) => Promise<void>
  
  // Utility functions
  hasActiveStatus: () => boolean
  canCreateContent: () => boolean
  getTierLevel: () => string
}

const CreatorAuthContext = createContext<CreatorAuthContextType | undefined>(undefined)

interface CreatorAuthProviderProps {
  children: ReactNode
}

export function CreatorAuthProvider({ children }: CreatorAuthProviderProps) {
  const [isLoading, setIsLoading] = useState(true)
  const [creator, setCreator] = useState<CreatorAccount | null>(null)
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()

  // Initialize authentication state
  useEffect(() => {
    const initializeAuth = async () => {
      try {
        if (creatorApi.isAuthenticated()) {
          setIsAuthenticated(true)
          
          // Try to fetch profile to ensure authentication is valid
          try {
            await refreshProfile()
          } catch (profileError) {
            console.warn('Failed to fetch creator profile, token may be expired')
            await logout()
          }
        }
      } catch (err) {
        console.error('Failed to initialize creator auth:', err)
        setError('Failed to initialize authentication')
      } finally {
        setIsLoading(false)
      }
    }

    initializeAuth()
  }, [])

  const login = async (email: string, password: string, totpCode?: string) => {
    setIsLoading(true)
    setError(null)
    
    try {
      const response = await creatorApi.login({
        email,
        password,
        totp_code: totpCode
      })
      
      if (response.requires_2fa && !totpCode) {
        throw new Error('Two-factor authentication required')
      }
      
      setIsAuthenticated(true)
      await refreshProfile()
      
      // Redirect to dashboard
      navigate('/creator/dashboard')
    } catch (err: any) {
      const errorMessage = err.message || 'Login failed'
      setError(errorMessage)
      throw new Error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const register = async (registrationData: any) => {
    setIsLoading(true)
    setError(null)
    
    try {
      await creatorApi.register(registrationData)
      // Registration successful - user needs to verify email
      navigate('/creator/login', { 
        state: { message: 'Registration successful! Please check your email to verify your account.' }
      })
    } catch (err: any) {
      const errorMessage = err.message || 'Registration failed'
      setError(errorMessage)
      throw new Error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const logout = async () => {
    setIsLoading(true)
    
    try {
      await creatorApi.logout()
    } catch (err) {
      console.error('Logout error:', err)
    } finally {
      setCreator(null)
      setIsAuthenticated(false)
      setError(null)
      setIsLoading(false)
      navigate('/creator/login')
    }
  }

  const refreshProfile = async () => {
    if (!creatorApi.isAuthenticated()) {
      throw new Error('Not authenticated')
    }
    
    try {
      const profile = await creatorApi.getProfile()
      setCreator(profile)
      setError(null)
    } catch (err: any) {
      console.error('Failed to refresh creator profile:', err)
      setError('Failed to load profile')
      throw err
    }
  }

  const updateProfile = async (updates: Partial<CreatorAccount>) => {
    if (!creatorApi.isAuthenticated()) {
      throw new Error('Not authenticated')
    }
    
    try {
      const updatedProfile = await creatorApi.updateProfile(updates)
      setCreator(updatedProfile)
      setError(null)
    } catch (err: any) {
      const errorMessage = err.message || 'Failed to update profile'
      setError(errorMessage)
      throw new Error(errorMessage)
    }
  }

  // Utility functions
  const hasActiveStatus = (): boolean => {
    return creator?.status === 'active'
  }

  const canCreateContent = (): boolean => {
    return hasActiveStatus() && creator?.email_verified === true
  }

  const getTierLevel = (): string => {
    return creator?.creator_tier || 'tier_1'
  }

  const contextValue: CreatorAuthContextType = {
    // State
    isAuthenticated,
    isLoading,
    creator,
    error,
    
    // Actions
    login,
    logout,
    register,
    refreshProfile,
    updateProfile,
    
    // Utilities
    hasActiveStatus,
    canCreateContent,
    getTierLevel,
  }

  return (
    <CreatorAuthContext.Provider value={contextValue}>
      {children}
    </CreatorAuthContext.Provider>
  )
}

// Hook to use the creator auth context
export function useCreatorAuth() {
  const context = useContext(CreatorAuthContext)
  if (context === undefined) {
    throw new Error('useCreatorAuth must be used within a CreatorAuthProvider')
  }
  return context
}

// HOC for protecting creator routes
export function withCreatorAuth<P extends object>(Component: React.ComponentType<P>) {
  return function ProtectedComponent(props: P) {
    const { isAuthenticated, isLoading } = useCreatorAuth()
    const navigate = useNavigate()

    useEffect(() => {
      if (!isLoading && !isAuthenticated) {
        navigate('/creator/login')
      }
    }, [isAuthenticated, isLoading, navigate])

    if (isLoading) {
      return <div>Loading...</div> // TODO: Replace with proper loading component
    }

    if (!isAuthenticated) {
      return null
    }

    return <Component {...props} />
  }
}

export default CreatorAuthContext