import React, { useState } from 'react'
import { 
  Box, 
  Paper, 
  Button, 
  Typography, 
  Card,
  CardContent,
  CardActions,
  Grid,
  Chip,
  alpha
} from '@mui/material'
import { 
  FamilyRestroom,
  AdminPanelSettings,
  Create as CreatorIcon,
  ArrowForward,
  Home,
  School,
  Business
} from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'
import { styled, useTheme } from '@mui/material/styles'

import { customColors } from '@/theme/wonderNestTheme'

const StyledCard = styled(Card)(({ theme }) => ({
  height: '100%',
  display: 'flex',
  flexDirection: 'column',
  transition: 'all 0.3s ease-in-out',
  cursor: 'pointer',
  border: `2px solid transparent`,
  '&:hover': {
    transform: 'translateY(-8px)',
    boxShadow: theme.shadows[8],
    borderColor: theme.palette.primary.main,
  },
}))

const StyledCardContent = styled(CardContent)(({ theme }) => ({
  flexGrow: 1,
  textAlign: 'center',
  padding: theme.spacing(3),
}))

const FeatureChip = styled(Chip)(({ theme }) => ({
  fontSize: '0.75rem',
  height: 24,
  margin: theme.spacing(0.25),
}))

interface PortalOption {
  id: 'parent' | 'creator' | 'admin'
  title: string
  subtitle: string
  description: string
  icon: React.ReactNode
  path: string
  color: 'primary' | 'secondary' | 'warning'
  features: string[]
  bgGradient: string
}

const portalOptions: PortalOption[] = [
  {
    id: 'parent',
    title: 'Parent Portal',
    subtitle: 'For Families',
    description: 'Manage your child\'s learning journey and track their development with personalized insights.',
    icon: <FamilyRestroom sx={{ fontSize: 48 }} />,
    path: '/app/login',
    color: 'primary',
    features: ['Child Progress Tracking', 'Story Builder', 'Safe Content', 'Family Dashboard'],
    bgGradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  },
  {
    id: 'creator',
    title: 'Creator Studio',
    subtitle: 'For Educators & Artists',
    description: 'Create, publish, and monetize educational content for children and families worldwide.',
    icon: <CreatorIcon sx={{ fontSize: 48 }} />,
    path: '/creator/login',
    color: 'secondary',
    features: ['Content Creation', 'Analytics Dashboard', 'Revenue Tracking', 'Global Reach'],
    bgGradient: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
  },
  {
    id: 'admin',
    title: 'Admin Portal',
    subtitle: 'For WonderNest Team',
    description: 'Platform management, content moderation, and system administration tools.',
    icon: <AdminPanelSettings sx={{ fontSize: 48 }} />,
    path: '/admin/login',
    color: 'warning',
    features: ['Content Moderation', 'User Management', 'Analytics', 'System Controls'],
    bgGradient: 'linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)',
  },
]

export const UnifiedLoginPage: React.FC = () => {
  const navigate = useNavigate()
  const theme = useTheme()
  const [hoveredCard, setHoveredCard] = useState<string | null>(null)

  const handlePortalSelect = (path: string) => {
    navigate(path)
  }

  const getPortalStats = (portalId: string) => {
    switch (portalId) {
      case 'parent':
        return '10K+ Families'
      case 'creator':
        return '500+ Creators'
      case 'admin':
        return 'Staff Only'
      default:
        return ''
    }
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: customColors.gradients.primary,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: { xs: 2, md: 4 },
      }}
    >
      {/* Header */}
      <Box sx={{ textAlign: 'center', mb: 6, maxWidth: 800 }}>
        <Typography 
          variant="h2" 
          fontWeight={700}
          sx={{ 
            background: 'linear-gradient(45deg, #fff 30%, #f8f9fa 90%)',
            backgroundClip: 'text',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            mb: 2,
            fontSize: { xs: '2.5rem', md: '3.5rem' }
          }}
        >
          Welcome to WonderNest
        </Typography>
        <Typography 
          variant="h6" 
          color="white" 
          sx={{ 
            opacity: 0.9,
            mb: 1,
            fontWeight: 400,
          }}
        >
          Choose your portal to get started
        </Typography>
        <Typography 
          variant="body1" 
          color="white" 
          sx={{ 
            opacity: 0.7,
            maxWidth: 600,
            mx: 'auto'
          }}
        >
          Whether you're a parent managing your child's learning, a creator building educational content, 
          or a team member managing the platform - we have the right tools for you.
        </Typography>
      </Box>

      {/* Portal Selection Cards */}
      <Grid container spacing={4} maxWidth="1200px" sx={{ mb: 4 }}>
        {portalOptions.map((portal) => (
          <Grid item xs={12} md={4} key={portal.id}>
            <StyledCard
              onClick={() => handlePortalSelect(portal.path)}
              onMouseEnter={() => setHoveredCard(portal.id)}
              onMouseLeave={() => setHoveredCard(null)}
              sx={{
                ...(hoveredCard === portal.id && {
                  backgroundColor: theme.palette.grey[50],
                  borderColor: theme.palette[portal.color].main,
                  transform: 'translateY(-4px)',
                }),
              }}
            >
              <StyledCardContent>
                {/* Icon with gradient background */}
                <Box
                  sx={{
                    width: 80,
                    height: 80,
                    borderRadius: '50%',
                    background: portal.bgGradient,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mx: 'auto',
                    mb: 3,
                    color: 'white',
                    boxShadow: '0 8px 32px rgba(0, 0, 0, 0.1)',
                  }}
                >
                  {portal.icon}
                </Box>

                {/* Title and Stats */}
                <Box sx={{ mb: 2 }}>
                  <Typography variant="h5" fontWeight={700} gutterBottom>
                    {portal.title}
                  </Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 1, mb: 1 }}>
                    <Chip 
                      label={portal.subtitle} 
                      size="small" 
                      color={portal.color}
                      variant="outlined"
                    />
                    <Chip 
                      label={getPortalStats(portal.id)} 
                      size="small" 
                      sx={{ 
                        bgcolor: alpha(theme.palette[portal.color].main, 0.1),
                        color: theme.palette[portal.color].main,
                      }}
                    />
                  </Box>
                </Box>

                {/* Description */}
                <Typography variant="body2" color="text.secondary" sx={{ mb: 3, minHeight: 48 }}>
                  {portal.description}
                </Typography>

                {/* Features */}
                <Box sx={{ mb: 2 }}>
                  {portal.features.map((feature, index) => (
                    <FeatureChip
                      key={index}
                      label={feature}
                      size="small"
                      variant="outlined"
                      sx={{
                        borderColor: alpha(theme.palette[portal.color].main, 0.3),
                        color: theme.palette[portal.color].main,
                      }}
                    />
                  ))}
                </Box>
              </StyledCardContent>

              <CardActions sx={{ justifyContent: 'center', pb: 3 }}>
                <Button
                  variant="contained"
                  color={portal.color}
                  endIcon={<ArrowForward />}
                  size="large"
                  sx={{
                    px: 4,
                    py: 1.5,
                    borderRadius: 3,
                    fontWeight: 600,
                    textTransform: 'none',
                    boxShadow: 'none',
                    '&:hover': {
                      boxShadow: '0 8px 25px rgba(0, 0, 0, 0.15)',
                    },
                  }}
                >
                  Enter {portal.title}
                </Button>
              </CardActions>
            </StyledCard>
          </Grid>
        ))}
      </Grid>

      {/* Quick Stats */}
      <Paper
        sx={{
          background: alpha('#fff', 0.1),
          backdropFilter: 'blur(10px)',
          border: `1px solid ${alpha('#fff', 0.2)}`,
          borderRadius: 3,
          p: 3,
          mt: 4,
          maxWidth: 800,
          width: '100%',
        }}
      >
        <Grid container spacing={4} sx={{ textAlign: 'center' }}>
          <Grid item xs={12} md={4}>
            <Box sx={{ color: 'white' }}>
              <Home sx={{ fontSize: 32, mb: 1, opacity: 0.9 }} />
              <Typography variant="h6" fontWeight={600}>10,000+</Typography>
              <Typography variant="body2" sx={{ opacity: 0.8 }}>Active Families</Typography>
            </Box>
          </Grid>
          <Grid item xs={12} md={4}>
            <Box sx={{ color: 'white' }}>
              <School sx={{ fontSize: 32, mb: 1, opacity: 0.9 }} />
              <Typography variant="h6" fontWeight={600}>5,000+</Typography>
              <Typography variant="body2" sx={{ opacity: 0.8 }}>Educational Stories</Typography>
            </Box>
          </Grid>
          <Grid item xs={12} md={4}>
            <Box sx={{ color: 'white' }}>
              <Business sx={{ fontSize: 32, mb: 1, opacity: 0.9 }} />
              <Typography variant="h6" fontWeight={600}>500+</Typography>
              <Typography variant="body2" sx={{ opacity: 0.8 }}>Content Creators</Typography>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Footer */}
      <Typography 
        variant="body2" 
        color="white" 
        sx={{ 
          opacity: 0.6, 
          mt: 4,
          textAlign: 'center'
        }}
      >
        © 2025 WonderNest. Building the future of child development through technology.
      </Typography>
    </Box>
  )
}

export default UnifiedLoginPage