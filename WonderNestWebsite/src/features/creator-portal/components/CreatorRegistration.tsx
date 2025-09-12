import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  Checkbox,
  FormControlLabel,
  Grid,
  Link,
  Divider,
  LinearProgress,
  CircularProgress,
} from '@mui/material';
import { AccountCircle, Email, Lock, Person } from '@mui/icons-material';

import { creatorApi, CreatorRegisterRequest } from '../services/creatorApi';

interface RegistrationFormData {
  email: string;
  password: string;
  confirmPassword: string;
  firstName: string;
  lastName: string;
  displayName: string;
  country: string;
  acceptTerms: boolean;
}

const CreatorRegistration: React.FC = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState<RegistrationFormData>({
    email: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
    displayName: '',
    country: '',
    acceptTerms: false,
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleInputChange = (field: keyof RegistrationFormData) => (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    setFormData(prev => ({
      ...prev,
      [field]: value,
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
    if (formData.password.length < 8) return 'Password must be at least 8 characters long';
    
    if (formData.password !== formData.confirmPassword) {
      return 'Passwords do not match';
    }
    
    if (!formData.firstName.trim()) return 'First name is required';
    if (!formData.lastName.trim()) return 'Last name is required';
    if (!formData.displayName.trim()) return 'Display name is required';
    if (!formData.country.trim()) return 'Country is required';
    
    if (!formData.acceptTerms) {
      return 'You must accept the Terms of Service and Privacy Policy';
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

    setLoading(true);
    setError(null);

    try {
      const registerRequest: CreatorRegisterRequest = {
        email: formData.email.trim(),
        password: formData.password,
        first_name: formData.firstName.trim(),
        last_name: formData.lastName.trim(),
        display_name: formData.displayName.trim(),
        country: formData.country.trim(),
        accept_terms: formData.acceptTerms,
      };

      await creatorApi.register(registerRequest);
      
      setSuccess(true);
      
      // Redirect to verification page after a brief delay
      setTimeout(() => {
        navigate('/creator/verify-email', { 
          state: { email: formData.email }
        });
      }, 2000);
      
    } catch (err) {
      console.error('Registration failed:', err);
      setError(err instanceof Error ? err.message : 'Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
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
        <Card sx={{ maxWidth: 500, width: '100%' }}>
          <CardContent sx={{ textAlign: 'center', p: 4 }}>
            <AccountCircle sx={{ fontSize: 64, color: 'success.main', mb: 2 }} />
            <Typography variant="h4" gutterBottom color="success.main">
              Registration Successful!
            </Typography>
            <Typography variant="body1" sx={{ mb: 3 }}>
              Thank you for joining the WonderNest Creator Platform. 
              We've sent a verification email to <strong>{formData.email}</strong>.
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Please check your email and click the verification link to complete your registration.
            </Typography>
            <LinearProgress sx={{ mt: 3 }} />
          </CardContent>
        </Card>
      </Box>
    );
  }

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
      <Card sx={{ maxWidth: 600, width: '100%' }}>
        <CardContent sx={{ p: 4 }}>
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <Typography variant="h4" gutterBottom color="primary">
              Join WonderNest Creators
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Create engaging, educational content for children and families
            </Typography>
          </Box>

          {error && (
            <Alert severity="error" sx={{ mb: 3 }}>
              {error}
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
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Password"
                  type="password"
                  value={formData.password}
                  onChange={handleInputChange('password')}
                  required
                  helperText="At least 8 characters"
                  InputProps={{
                    startAdornment: <Lock sx={{ mr: 1, color: 'text.secondary' }} />,
                  }}
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Confirm Password"
                  type="password"
                  value={formData.confirmPassword}
                  onChange={handleInputChange('confirmPassword')}
                  required
                  error={formData.confirmPassword !== '' && formData.password !== formData.confirmPassword}
                  helperText={
                    formData.confirmPassword !== '' && formData.password !== formData.confirmPassword
                      ? 'Passwords do not match'
                      : ''
                  }
                  InputProps={{
                    startAdornment: <Lock sx={{ mr: 1, color: 'text.secondary' }} />,
                  }}
                />
              </Grid>

              {/* Name fields */}
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="First Name"
                  value={formData.firstName}
                  onChange={handleInputChange('firstName')}
                  required
                  InputProps={{
                    startAdornment: <Person sx={{ mr: 1, color: 'text.secondary' }} />,
                  }}
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Last Name"
                  value={formData.lastName}
                  onChange={handleInputChange('lastName')}
                  required
                  InputProps={{
                    startAdornment: <Person sx={{ mr: 1, color: 'text.secondary' }} />,
                  }}
                />
              </Grid>

              {/* Display name */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Creator Display Name"
                  value={formData.displayName}
                  onChange={handleInputChange('displayName')}
                  required
                  helperText="This is how your name will appear to users"
                />
              </Grid>

              {/* Country */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Country"
                  value={formData.country}
                  onChange={handleInputChange('country')}
                  required
                  helperText="Required for tax and legal compliance"
                />
              </Grid>

              {/* Terms acceptance */}
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.acceptTerms}
                      onChange={handleInputChange('acceptTerms')}
                      required
                    />
                  }
                  label={
                    <Typography variant="body2">
                      I agree to the{' '}
                      <Link href="/terms" target="_blank" color="primary">
                        Terms of Service
                      </Link>
                      {' '}and{' '}
                      <Link href="/privacy" target="_blank" color="primary">
                        Privacy Policy
                      </Link>
                    </Typography>
                  }
                />
              </Grid>

              {/* Submit button */}
              <Grid item xs={12}>
                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  size="large"
                  disabled={loading || !formData.acceptTerms}
                  startIcon={loading ? <CircularProgress size={20} color="inherit" /> : undefined}
                  sx={{ py: 1.5 }}
                >
                  {loading ? 'Creating Account...' : 'Create Creator Account'}
                </Button>
              </Grid>
            </Grid>
          </form>

          <Divider sx={{ my: 3 }} />

          <Box sx={{ textAlign: 'center' }}>
            <Typography variant="body2" color="text.secondary">
              Already have a creator account?{' '}
              <Link
                component="button"
                type="button"
                onClick={() => navigate('/creator/login')}
                color="primary"
                sx={{ textDecoration: 'none', fontWeight: 500 }}
              >
                Sign In
              </Link>
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
};

export default CreatorRegistration;