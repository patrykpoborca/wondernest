import React, { useState } from 'react'
import {
  Box,
  Container,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Stack,
  Link,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Checkbox,
  FormControlLabel,
  Alert,
  Divider,
  useTheme,
} from '@mui/material'
import { Link as RouterLink, useNavigate, useLocation } from 'react-router-dom'
import {
  School as SchoolIcon,
  ArrowBack as BackIcon,
} from '@mui/icons-material'

export const SignupPage: React.FC = () => {
  const theme = useTheme()
  const navigate = useNavigate()
  const location = useLocation()
  const selectedPlan = location.state?.selectedPlan || 'family'

  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    confirmPassword: '',
    plan: selectedPlan,
    agreeTerms: false,
    agreePrivacy: false,
    marketingEmails: true,
  })

  const [errors, setErrors] = useState<{ [key: string]: string }>({})
  const [isSubmitting, setIsSubmitting] = useState(false)

  const plans = [
    { value: 'starter', label: 'Starter Plan - $12/month', description: '1 child, 10 games' },
    { value: 'family', label: 'Family Plan - $25/month', description: '4 children, 50+ games' },
    { value: 'premium', label: 'Premium Plan - $45/month', description: 'Unlimited children, all features' },
  ]

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }))
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({
        ...prev,
        [field]: '',
      }))
    }
  }

  const validateForm = () => {
    const newErrors: { [key: string]: string } = {}

    if (!formData.firstName.trim()) newErrors.firstName = 'First name is required'
    if (!formData.lastName.trim()) newErrors.lastName = 'Last name is required'
    if (!formData.email.trim()) newErrors.email = 'Email is required'
    else if (!/\S+@\S+\.\S+/.test(formData.email)) newErrors.email = 'Please enter a valid email'
    
    if (!formData.password) newErrors.password = 'Password is required'
    else if (formData.password.length < 8) newErrors.password = 'Password must be at least 8 characters'
    
    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match'
    }
    
    if (!formData.agreeTerms) newErrors.agreeTerms = 'You must agree to the Terms of Service'
    if (!formData.agreePrivacy) newErrors.agreePrivacy = 'You must agree to the Privacy Policy'

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!validateForm()) return

    setIsSubmitting(true)
    
    try {
      // In a real app, this would call the signup API
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      // Redirect to app dashboard or onboarding
      navigate('/app/parent', { replace: true })
    } catch (error) {
      setErrors({ submit: 'An error occurred during signup. Please try again.' })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default', py: 4 }}>
      <Container maxWidth="sm">
        {/* Header */}
        <Box sx={{ textAlign: 'center', mb: 4 }}>
          <Button
            startIcon={<BackIcon />}
            onClick={() => navigate(-1)}
            sx={{ mb: 2, alignSelf: 'flex-start' }}
          >
            Back
          </Button>
          
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 2 }}>
            <SchoolIcon sx={{ fontSize: '2rem', color: theme.palette.primary.main, mr: 1 }} />
            <Typography
              variant="h4"
              component="h1"
              fontWeight={700}
              sx={{
                background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`,
                backgroundClip: 'text',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
              }}
            >
              WonderNest
            </Typography>
          </Box>
          
          <Typography variant="h5" fontWeight={600} color="primary" gutterBottom>
            Start Your Free Trial
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Create your account and begin your 14-day free trial
          </Typography>
        </Box>

        {/* Signup Form */}
        <Card elevation={3} sx={{ borderRadius: 3 }}>
          <CardContent sx={{ p: 4 }}>
            {errors.submit && (
              <Alert severity="error" sx={{ mb: 3 }}>
                {errors.submit}
              </Alert>
            )}

            <form onSubmit={handleSubmit}>
              <Stack spacing={3}>
                {/* Plan Selection */}
                <FormControl fullWidth>
                  <InputLabel>Choose Your Plan</InputLabel>
                  <Select
                    value={formData.plan}
                    label="Choose Your Plan"
                    onChange={(e) => handleInputChange('plan', e.target.value)}
                  >
                    {plans.map((plan) => (
                      <MenuItem key={plan.value} value={plan.value}>
                        <Box>
                          <Typography variant="body1" fontWeight={600}>
                            {plan.label}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {plan.description}
                          </Typography>
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>

                <Divider />

                {/* Name Fields */}
                <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                  <TextField
                    fullWidth
                    label="First Name"
                    value={formData.firstName}
                    onChange={(e) => handleInputChange('firstName', e.target.value)}
                    error={!!errors.firstName}
                    helperText={errors.firstName}
                    required
                  />
                  <TextField
                    fullWidth
                    label="Last Name"
                    value={formData.lastName}
                    onChange={(e) => handleInputChange('lastName', e.target.value)}
                    error={!!errors.lastName}
                    helperText={errors.lastName}
                    required
                  />
                </Stack>

                {/* Email */}
                <TextField
                  fullWidth
                  type="email"
                  label="Email Address"
                  value={formData.email}
                  onChange={(e) => handleInputChange('email', e.target.value)}
                  error={!!errors.email}
                  helperText={errors.email}
                  required
                />

                {/* Password Fields */}
                <TextField
                  fullWidth
                  type="password"
                  label="Password"
                  value={formData.password}
                  onChange={(e) => handleInputChange('password', e.target.value)}
                  error={!!errors.password}
                  helperText={errors.password || 'Minimum 8 characters'}
                  required
                />

                <TextField
                  fullWidth
                  type="password"
                  label="Confirm Password"
                  value={formData.confirmPassword}
                  onChange={(e) => handleInputChange('confirmPassword', e.target.value)}
                  error={!!errors.confirmPassword}
                  helperText={errors.confirmPassword}
                  required
                />

                {/* Agreements */}
                <Stack spacing={1}>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={formData.agreeTerms}
                        onChange={(e) => handleInputChange('agreeTerms', e.target.checked)}
                      />
                    }
                    label={
                      <Typography variant="body2">
                        I agree to the{' '}
                        <Link component={RouterLink} to="/terms" color="primary">
                          Terms of Service
                        </Link>
                      </Typography>
                    }
                    sx={{ color: errors.agreeTerms ? 'error.main' : 'inherit' }}
                  />

                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={formData.agreePrivacy}
                        onChange={(e) => handleInputChange('agreePrivacy', e.target.checked)}
                      />
                    }
                    label={
                      <Typography variant="body2">
                        I agree to the{' '}
                        <Link component={RouterLink} to="/privacy" color="primary">
                          Privacy Policy
                        </Link>{' '}
                        and understand how my data will be used
                      </Typography>
                    }
                    sx={{ color: errors.agreePrivacy ? 'error.main' : 'inherit' }}
                  />

                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={formData.marketingEmails}
                        onChange={(e) => handleInputChange('marketingEmails', e.target.checked)}
                      />
                    }
                    label={
                      <Typography variant="body2">
                        Send me helpful tips and updates (optional)
                      </Typography>
                    }
                  />
                </Stack>

                {/* Submit Button */}
                <Button
                  type="submit"
                  variant="contained"
                  size="large"
                  disabled={isSubmitting}
                  sx={{
                    py: 1.5,
                    fontSize: '1.1rem',
                    fontWeight: 600,
                    background: theme.palette.primary.main,
                  }}
                >
                  {isSubmitting ? 'Creating Account...' : 'Start Free Trial'}
                </Button>

                {/* Trial Info */}
                <Box sx={{ textAlign: 'center', p: 2, bgcolor: 'background.default', borderRadius: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    ✓ 14-day free trial • ✓ No credit card required • ✓ Cancel anytime
                  </Typography>
                </Box>

                {/* Login Link */}
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="body2" color="text.secondary">
                    Already have an account?{' '}
                    <Link component={RouterLink} to="/app/login" color="primary" fontWeight={600}>
                      Sign in here
                    </Link>
                  </Typography>
                </Box>
              </Stack>
            </form>
          </CardContent>
        </Card>

        {/* Additional Info */}
        <Box sx={{ textAlign: 'center', mt: 4 }}>
          <Typography variant="body2" color="text.secondary">
            Questions about getting started?{' '}
            <Link component={RouterLink} to="/contact" color="primary">
              Contact our support team
            </Link>
          </Typography>
        </Box>
      </Container>
    </Box>
  )
}