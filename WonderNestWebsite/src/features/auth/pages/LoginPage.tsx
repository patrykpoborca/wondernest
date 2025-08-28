import React, { useState } from 'react'
import { 
  Box, 
  Paper, 
  TextField, 
  Button, 
  Typography, 
  Alert,
  Tabs,
  Tab,
  InputAdornment,
  IconButton
} from '@mui/material'
import { 
  Visibility,
  VisibilityOff,
  AdminPanelSettings,
  FamilyRestroom,
  Create
} from '@mui/icons-material'
import { useNavigate, useLocation } from 'react-router-dom'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

import { useAuth } from '@/hooks/useAuth'
import { LoginCredentials } from '@/types/auth'
import { customColors } from '@/theme/wonderNestTheme'
import { LoadingScreen } from '@/components/common/LoadingScreen'

const loginSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
  password: z.string().min(1, 'Password is required'),
  twoFactorCode: z.string().optional(),
})

type LoginFormData = z.infer<typeof loginSchema>

type UserType = 'admin' | 'parent'

interface TabPanelProps {
  children?: React.ReactNode
  index: number
  value: number
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index }) => (
  <div hidden={value !== index} style={{ width: '100%' }}>
    {value === index && children}
  </div>
)

export const LoginPage: React.FC = () => {
  const navigate = useNavigate()
  const location = useLocation()
  const { login, isLoading, error } = useAuth()
  
  const [userType, setUserType] = useState<UserType>('admin')
  const [showPassword, setShowPassword] = useState(false)
  const [requiresTwoFactor, setRequiresTwoFactor] = useState(false)
  const [loginError, setLoginError] = useState<string | null>(null)
  
  const { control, handleSubmit, formState: { errors }, watch, reset } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
      twoFactorCode: '',
    }
  })
  
  // Determine redirect path based on current location or user type
  const getRedirectPath = () => {
    const from = location.state?.from?.pathname || '/'
    if (from !== '/') return from
    return userType === 'admin' ? '/admin' : '/parent'
  }
  
  const onSubmit = async (data: LoginFormData) => {
    setLoginError(null)
    
    const credentials: LoginCredentials = {
      email: data.email,
      password: data.password,
      twoFactorCode: data.twoFactorCode,
    }
    
    const result = await login(credentials, userType)
    
    if (result.success) {
      // Navigate to appropriate dashboard
      navigate(getRedirectPath(), { replace: true })
    } else if (result.requiresTwoFactor) {
      setRequiresTwoFactor(true)
    } else if (result.error) {
      setLoginError(result.error)
    }
  }
  
  const handleUserTypeChange = (_: React.SyntheticEvent, newValue: number) => {
    const newUserType: UserType = newValue === 0 ? 'admin' : 'parent'
    setUserType(newUserType)
    setRequiresTwoFactor(false)
    setLoginError(null)
    reset()
  }
  
  if (isLoading) {
    return <LoadingScreen message="Signing you in..." />
  }
  
  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: customColors.gradients.primary,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 2,
      }}
    >
      <Paper
        elevation={3}
        sx={{
          width: '100%',
          maxWidth: 450,
          padding: 4,
          borderRadius: 3,
        }}
      >
        {/* Header */}
        <Box sx={{ textAlign: 'center', mb: 4 }}>
          <Typography 
            variant="h4" 
            fontWeight={700}
            sx={{ 
              background: customColors.gradients.primary,
              backgroundClip: 'text',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              mb: 1,
            }}
          >
            WonderNest
          </Typography>
          <Typography variant="h6" color="textSecondary" fontWeight={400}>
            Web Platform
          </Typography>
        </Box>
        
        {/* User Type Tabs */}
        <Tabs 
          value={userType === 'admin' ? 0 : 1} 
          onChange={handleUserTypeChange}
          variant="fullWidth"
          sx={{ mb: 3 }}
        >
          <Tab 
            icon={<AdminPanelSettings />} 
            label="Admin" 
            sx={{ textTransform: 'none', fontWeight: 600 }}
          />
          <Tab 
            icon={<FamilyRestroom />} 
            label="Parent" 
            sx={{ textTransform: 'none', fontWeight: 600 }}
          />
        </Tabs>
        
        {/* Error Alert */}
        {(error || loginError) && (
          <Alert severity="error" sx={{ mb: 3 }}>
            {loginError || error}
          </Alert>
        )}
        
        {/* 2FA Required Alert */}
        {requiresTwoFactor && (
          <Alert severity="info" sx={{ mb: 3 }}>
            Two-factor authentication code required
          </Alert>
        )}
        
        {/* Login Form */}
        <TabPanel value={userType === 'admin' ? 0 : 1} index={userType === 'admin' ? 0 : 1}>
          <form onSubmit={handleSubmit(onSubmit)}>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <Controller
                name="email"
                control={control}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Email Address"
                    type="email"
                    fullWidth
                    variant="outlined"
                    error={!!errors.email}
                    helperText={errors.email?.message}
                    disabled={isLoading}
                    autoComplete="email"
                  />
                )}
              />
              
              <Controller
                name="password"
                control={control}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Password"
                    type={showPassword ? 'text' : 'password'}
                    fullWidth
                    variant="outlined"
                    error={!!errors.password}
                    helperText={errors.password?.message}
                    disabled={isLoading}
                    autoComplete="current-password"
                    InputProps={{
                      endAdornment: (
                        <InputAdornment position="end">
                          <IconButton
                            onClick={() => setShowPassword(!showPassword)}
                            edge="end"
                            size="small"
                          >
                            {showPassword ? <VisibilityOff /> : <Visibility />}
                          </IconButton>
                        </InputAdornment>
                      ),
                    }}
                  />
                )}
              />
              
              {requiresTwoFactor && (
                <Controller
                  name="twoFactorCode"
                  control={control}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      label="2FA Code"
                      fullWidth
                      variant="outlined"
                      placeholder="Enter 6-digit code"
                      error={!!errors.twoFactorCode}
                      helperText={errors.twoFactorCode?.message}
                      disabled={isLoading}
                      autoComplete="one-time-code"
                    />
                  )}
                />
              )}
              
              <Button
                type="submit"
                variant="contained"
                size="large"
                fullWidth
                disabled={isLoading}
                sx={{ 
                  mt: 2,
                  py: 1.5,
                  fontSize: '1rem',
                  fontWeight: 600,
                }}
              >
                {isLoading ? 'Signing In...' : 'Sign In'}
              </Button>
            </Box>
          </form>
        </TabPanel>
        
        {/* Footer */}
        <Box sx={{ textAlign: 'center', mt: 4 }}>
          <Typography variant="caption" color="textSecondary">
            {userType === 'admin' ? (
              'Admin access for platform management and content moderation'
            ) : (
              'Parent access for child activity management and progress tracking'
            )}
          </Typography>
        </Box>
      </Paper>
    </Box>
  )
}