import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  Grid,
  Link,
  Divider,
  Paper,
} from '@mui/material';
import { CircularProgress } from '@mui/material';
import { Email, Lock, Security } from '@mui/icons-material';

import { CreatorLoginRequest } from '../services/creatorApi';
import { useCreatorAuth } from '@/contexts/CreatorAuthContext';

interface LoginFormData {
  email: string;
  password: string;
  totpCode: string;
}

const CreatorLogin: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { login, isLoading, error: authError } = useCreatorAuth();
  
  const [formData, setFormData] = useState<LoginFormData>({
    email: '',
    password: '',
    totpCode: '',
  });

  const [error, setError] = useState<string | null>(null);
  const [requires2FA, setRequires2FA] = useState(false);

  // Get the intended destination from state (for redirects after login)
  const from = location.state?.from?.pathname || '/creator/dashboard';

  const handleInputChange = (field: keyof LoginFormData) => (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    setFormData(prev => ({
      ...prev,
      [field]: event.target.value,
    }));
    
    // Clear error when user starts typing
    if (error) {
      setError(null);
    }
  };

  const validateForm = (): string | null => {
    if (!formData.email) return 'Email is required';
    if (!formData.email.includes('@')) return 'Please enter a valid email address';
    if (!formData.password) return 'Password is required';
    
    if (requires2FA && !formData.totpCode) {
      return 'Two-factor authentication code is required';
    }
    
    return null;
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    
    const validationError = validateForm();
    if (validationError) {
      setError(validationError);
      return;
    }

    setError(null);

    try {
      await login(
        formData.email.trim(),
        formData.password,
        formData.totpCode || undefined
      );
      
      // Login successful - context handles navigation
      
    } catch (err) {
      console.error('Login failed:', err);
      
      if (err instanceof Error) {
        if (err.message.includes('Two-factor')) {
          setRequires2FA(true);
          setError('Please enter your two-factor authentication code');
        } else if (err.message.includes('not verified')) {
          setError('Please verify your email address before logging in');
        } else if (err.message.includes('suspended')) {
          setError('Your account has been suspended. Please contact support.');
        } else {
          setError(err.message);
        }
      } else {
        setError('Login failed. Please check your credentials and try again.');
      }
    }
  };

  const handleForgotPassword = () => {
    navigate('/creator/forgot-password', { 
      state: { email: formData.email }
    });
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
        p: 3,
      }}
    >
      <Grid container maxWidth="lg" spacing={4} alignItems="center">
        {/* Welcome Section */}
        <Grid item xs={12} md={6}>
          <Box sx={{ textAlign: { xs: 'center', md: 'left' } }}>
            <Typography variant="h2" gutterBottom color="primary">
              Welcome Back, Creator
            </Typography>
            <Typography variant="h6" color="text.secondary" sx={{ mb: 3 }}>
              Continue building amazing educational content for children and families
            </Typography>
            
            <Paper sx={{ p: 3, bgcolor: 'primary.50' }}>
              <Typography variant="h6" gutterBottom>
                Creator Platform Features:
              </Typography>
              <Box component="ul" sx={{ pl: 2 }}>
                <Typography component="li" variant="body2" sx={{ mb: 1 }}>
                  Upload and manage educational content
                </Typography>
                <Typography component="li" variant="body2" sx={{ mb: 1 }}>
                  Track content performance and analytics
                </Typography>
                <Typography component="li" variant="body2" sx={{ mb: 1 }}>
                  Collaborate with our curation team
                </Typography>
                <Typography component="li" variant="body2">
                  Earn revenue from your content
                </Typography>
              </Box>
            </Paper>
          </Box>
        </Grid>

        {/* Login Form */}
        <Grid item xs={12} md={6}>
          <Card sx={{ maxWidth: 500, mx: 'auto' }}>
            <CardContent sx={{ p: 4 }}>
              <Box sx={{ textAlign: 'center', mb: 4 }}>
                <Typography variant="h4" gutterBottom>
                  Sign In
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Access your creator dashboard
                </Typography>
              </Box>

              {(error || authError) && (
                <Alert severity="error" sx={{ mb: 3 }}>
                  {error || authError}
                </Alert>
              )}

              <form onSubmit={handleSubmit}>
                <Grid container spacing={3}>
                  {/* Email */}
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Email Address"
                      type="email"
                      value={formData.email}
                      onChange={handleInputChange('email')}
                      required
                      InputProps={{
                        startAdornment: <Email sx={{ mr: 1, color: 'text.secondary' }} />,
                      }}
                    />
                  </Grid>

                  {/* Password */}
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Password"
                      type="password"
                      value={formData.password}
                      onChange={handleInputChange('password')}
                      required
                      InputProps={{
                        startAdornment: <Lock sx={{ mr: 1, color: 'text.secondary' }} />,
                      }}
                    />
                  </Grid>

                  {/* 2FA Code (shown only when required) */}
                  {requires2FA && (
                    <Grid item xs={12}>
                      <TextField
                        fullWidth
                        label="Two-Factor Authentication Code"
                        value={formData.totpCode}
                        onChange={handleInputChange('totpCode')}
                        required
                        helperText="Enter the 6-digit code from your authenticator app"
                        InputProps={{
                          startAdornment: <Security sx={{ mr: 1, color: 'text.secondary' }} />,
                        }}
                      />
                    </Grid>
                  )}

                  {/* Submit button */}
                  <Grid item xs={12}>
                    <Button
                      type="submit"
                      fullWidth
                      variant="contained"
                      size="large"
                      disabled={isLoading}
                      startIcon={isLoading ? <CircularProgress size={20} color="inherit" /> : undefined}
                      sx={{ py: 1.5 }}
                    >
                      {isLoading ? 'Signing In...' : 'Sign In'}
                    </Button>
                  </Grid>

                  {/* Forgot password */}
                  <Grid item xs={12}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Button
                        variant="text"
                        color="primary"
                        onClick={handleForgotPassword}
                        size="small"
                      >
                        Forgot your password?
                      </Button>
                    </Box>
                  </Grid>
                </Grid>
              </form>

              <Divider sx={{ my: 3 }} />

              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="body2" color="text.secondary">
                  Don't have a creator account?{' '}
                  <Link
                    component="button"
                    type="button"
                    onClick={() => navigate('/creator/register')}
                    color="primary"
                    sx={{ textDecoration: 'none', fontWeight: 500 }}
                  >
                    Join the Creator Platform
                  </Link>
                </Typography>
              </Box>

              {/* Navigation Links */}
              <Box sx={{ textAlign: 'center', mt: 2 }}>
                <Link
                  component="button"
                  type="button"
                  onClick={() => navigate('/login')}
                  sx={{
                    fontSize: '0.8rem',
                    color: 'text.disabled',
                    textDecoration: 'none',
                    '&:hover': {
                      color: 'primary.main',
                      textDecoration: 'underline',
                    },
                    cursor: 'pointer',
                  }}
                >
                  ← Back to Portal Selection
                </Link>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default CreatorLogin;