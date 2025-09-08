import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Alert,
  CircularProgress,
  Container,
  Paper
} from '@mui/material'
import { Shield, Login } from '@mui/icons-material'
import { useAdminAuth } from '@/contexts/AdminAuthContext'

export const AdminLoginPage: React.FC = () => {
  const navigate = useNavigate()
  const { login, isAuthenticated, isLoading, error } = useAdminAuth()
  
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  })
  const [loginError, setLoginError] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated && !isLoading) {
      navigate('/admin/dashboard', { replace: true })
    }
  }, [isAuthenticated, isLoading, navigate])

  const handleInputChange = (field: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [field]: event.target.value
    }))
    // Clear errors when user starts typing
    if (loginError) {
      setLoginError(null)
    }
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    
    if (!formData.email.trim() || !formData.password.trim()) {
      setLoginError('Please enter both email and password')
      return
    }

    setIsSubmitting(true)
    setLoginError(null)

    try {
      await login(formData.email.trim(), formData.password)
      // Navigation handled by useEffect above
    } catch (err: any) {
      setLoginError(err.error || 'Login failed. Please check your credentials.')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleKeyPress = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' && !isSubmitting) {
      handleSubmit(event as any)
    }
  }

  if (isLoading) {
    return (
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        minHeight: '100vh',
        bgcolor: 'grey.50'
      }}>
        <CircularProgress size={40} />
      </Box>
    )
  }

  return (
    <Box sx={{ 
      minHeight: '100vh',
      bgcolor: 'grey.50',
      display: 'flex',
      alignItems: 'center',
      py: 4
    }}>
      <Container maxWidth="sm">
        <Paper 
          elevation={3}
          sx={{ 
            p: 4,
            borderRadius: 2
          }}
        >
          {/* Header */}
          <Box sx={{ 
            display: 'flex', 
            flexDirection: 'column', 
            alignItems: 'center',
            mb: 4
          }}>
            <Box sx={{ 
              display: 'flex',
              alignItems: 'center',
              mb: 2
            }}>
              <Shield sx={{ 
                fontSize: 32, 
                color: 'primary.main', 
                mr: 1 
              }} />
              <Typography variant="h4" fontWeight={600}>
                WonderNest
              </Typography>
            </Box>
            <Typography variant="h5" fontWeight={500} gutterBottom>
              Admin Portal
            </Typography>
            <Typography variant="body2" color="textSecondary" align="center">
              Secure access for platform administrators
            </Typography>
          </Box>

          {/* Error Alert */}
          {(loginError || error) && (
            <Alert 
              severity="error" 
              sx={{ mb: 3 }}
              onClose={() => setLoginError(null)}
            >
              {loginError || error}
            </Alert>
          )}

          {/* Login Form */}
          <Box component="form" onSubmit={handleSubmit}>
            <TextField
              fullWidth
              label="Admin Email"
              type="email"
              value={formData.email}
              onChange={handleInputChange('email')}
              onKeyPress={handleKeyPress}
              margin="normal"
              required
              autoComplete="email"
              autoFocus
              disabled={isSubmitting}
              sx={{ mb: 2 }}
            />
            
            <TextField
              fullWidth
              label="Password"
              type="password"
              value={formData.password}
              onChange={handleInputChange('password')}
              onKeyPress={handleKeyPress}
              margin="normal"
              required
              autoComplete="current-password"
              disabled={isSubmitting}
              sx={{ mb: 3 }}
            />
            
            <Button
              type="submit"
              fullWidth
              variant="contained"
              size="large"
              disabled={isSubmitting || !formData.email.trim() || !formData.password.trim()}
              startIcon={isSubmitting ? <CircularProgress size={20} /> : <Login />}
              sx={{ 
                py: 1.5,
                fontSize: '1.1rem',
                fontWeight: 500
              }}
            >
              {isSubmitting ? 'Signing In...' : 'Sign In'}
            </Button>
          </Box>

          {/* Footer */}
          <Box sx={{ 
            mt: 4, 
            pt: 3, 
            borderTop: 1, 
            borderColor: 'divider',
            textAlign: 'center'
          }}>
            <Typography variant="caption" color="textSecondary">
              WonderNest Admin Portal v1.0
            </Typography>
          </Box>
        </Paper>
      </Container>
    </Box>
  )
}