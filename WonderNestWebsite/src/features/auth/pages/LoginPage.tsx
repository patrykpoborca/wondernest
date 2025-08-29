import React, { useState } from 'react'
import { 
  Box, 
  Paper, 
  TextField, 
  Button, 
  Typography, 
  Alert,
  InputAdornment,
  IconButton,
  Link
} from '@mui/material'
import { 
  Visibility,
  VisibilityOff,
  AdminPanelSettings,
  FamilyRestroom
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

export const LoginPage: React.FC = () => {
  const navigate = useNavigate()
  const location = useLocation()
  const { login, isLoading, error } = useAuth()
  
  const [userType, setUserType] = useState<UserType>('parent')
  const [showAdminLogin, setShowAdminLogin] = useState(false)
  const [showPassword, setShowPassword] = useState(false)
  const [requiresTwoFactor, setRequiresTwoFactor] = useState(false)
  const [loginError, setLoginError] = useState<string | null>(null)
  
  const { control, handleSubmit, formState: { errors }, reset } = useForm<LoginFormData>({
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
    return showAdminLogin ? '/admin' : '/parent'
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
  
  const handleToggleAdminLogin = () => {
    const newShowAdmin = !showAdminLogin
    setShowAdminLogin(newShowAdmin)
    setUserType(newShowAdmin ? 'admin' : 'parent')
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
            {showAdminLogin ? 'Admin Portal' : 'Parent Portal'}
          </Typography>
          <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }}>
            {showAdminLogin 
              ? 'Platform management and content moderation'
              : 'Manage your child\'s learning journey'
            }
          </Typography>
        </Box>
        
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
              startIcon={showAdminLogin ? <AdminPanelSettings /> : <FamilyRestroom />}
              sx={{ 
                mt: 2,
                py: 1.5,
                fontSize: '1rem',
                fontWeight: 600,
              }}
            >
              {isLoading ? 'Signing In...' : `Sign In as ${showAdminLogin ? 'Admin' : 'Parent'}`}
            </Button>
          </Box>
        </form>
        
        {/* Admin Access Toggle */}
        <Box sx={{ textAlign: 'center', mt: 3 }}>
          <Link
            component="button"
            type="button"
            onClick={handleToggleAdminLogin}
            sx={{
              fontSize: '0.875rem',
              color: 'text.secondary',
              textDecoration: 'none',
              '&:hover': {
                color: 'primary.main',
                textDecoration: 'underline',
              },
              cursor: 'pointer',
            }}
          >
            {showAdminLogin 
              ? 'Are you a parent? Switch to Parent Login' 
              : 'Are you a staff member? Access Admin Portal'
            }
          </Link>
        </Box>
      </Paper>
    </Box>
  )
}