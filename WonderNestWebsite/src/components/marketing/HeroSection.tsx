import React from 'react'
import {
  Box,
  Container,
  Typography,
  Button,
  Grid,
  Stack,
  Chip,
  useTheme,
} from '@mui/material'
import {
  PlayArrow as PlayIcon,
  Star as StarIcon,
  Security as SecurityIcon,
  FamilyRestroom as FamilyIcon,
  School as SchoolIcon,
} from '@mui/icons-material'

interface HeroSectionProps {
  onGetStarted?: () => void
  onWatchDemo?: () => void
}

export const HeroSection: React.FC<HeroSectionProps> = ({
  onGetStarted,
  onWatchDemo,
}) => {
  const theme = useTheme()

  const trustBadges = [
    { icon: <SecurityIcon />, label: 'COPPA Compliant', color: '#10B981' },
    { icon: <FamilyIcon />, label: 'Family Safe', color: '#6366F1' },
    { icon: <SchoolIcon />, label: 'Educational', color: '#F59E0B' },
  ]

  return (
    <Box className="hero-section">
      <Container className="hero-container" maxWidth="lg">
        <Grid container spacing={4} alignItems="center" sx={{ minHeight: '90vh' }}>
          <Grid item xs={12} md={6}>
            <Stack spacing={3} sx={{ textAlign: { xs: 'center', md: 'left' } }}>
              {/* Trust Badge */}
              <Box>
                <Chip
                  icon={<StarIcon />}
                  label="Trusted by 10,000+ families"
                  color="primary"
                  variant="outlined"
                  sx={{
                    backgroundColor: 'rgba(99, 102, 241, 0.1)',
                    borderColor: theme.palette.primary.main,
                    fontWeight: 600,
                  }}
                />
              </Box>

              {/* Main Headline */}
              <Typography className="hero-title" variant="h1">
                Safe Learning Adventures for Your Child
              </Typography>

              {/* Subtitle */}
              <Typography className="hero-subtitle" variant="h5">
                WonderNest provides COPPA-compliant educational games, interactive stories, 
                and developmental tracking tools that help your child learn while you stay in control.
              </Typography>

              {/* Key Benefits */}
              <Box>
                <Stack direction="row" spacing={2} flexWrap="wrap" justifyContent={{ xs: 'center', md: 'flex-start' }}>
                  {trustBadges.map((badge, index) => (
                    <Chip
                      key={index}
                      icon={badge.icon}
                      label={badge.label}
                      sx={{
                        backgroundColor: `${badge.color}15`,
                        color: badge.color,
                        fontWeight: 500,
                        '& .MuiChip-icon': {
                          color: badge.color,
                        },
                      }}
                    />
                  ))}
                </Stack>
              </Box>

              {/* CTA Buttons */}
              <Stack
                direction={{ xs: 'column', sm: 'row' }}
                spacing={2}
                sx={{ 
                  justifyContent: { xs: 'center', md: 'flex-start' },
                  mt: 4,
                }}
              >
                <Button
                  className="cta-primary"
                  size="large"
                  onClick={onGetStarted}
                  sx={{ minWidth: 200 }}
                >
                  Start Free Trial
                </Button>
                <Button
                  className="cta-secondary"
                  size="large"
                  startIcon={<PlayIcon />}
                  onClick={onWatchDemo}
                  sx={{ minWidth: 200 }}
                >
                  Watch Demo
                </Button>
              </Stack>

              {/* Social Proof */}
              <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
                Join thousands of families creating safe digital learning experiences
              </Typography>
            </Stack>
          </Grid>

          {/* Hero Visual */}
          <Grid item xs={12} md={6}>
            <Box
              sx={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                height: { xs: '300px', md: '500px' },
                background: `linear-gradient(135deg, ${theme.palette.primary.main}10 0%, ${theme.palette.secondary.main}10 100%)`,
                borderRadius: '20px',
                border: `2px solid ${theme.palette.primary.main}20`,
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              {/* Placeholder for hero image/video */}
              <Box
                sx={{
                  width: '100%',
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'center',
                  alignItems: 'center',
                  padding: 4,
                }}
              >
                <SchoolIcon sx={{ fontSize: '4rem', color: theme.palette.primary.main, mb: 2 }} />
                <Typography variant="h6" color="primary" textAlign="center">
                  Interactive Learning Experience Preview
                </Typography>
                <Typography variant="body2" color="text.secondary" textAlign="center" sx={{ mt: 1 }}>
                  Educational games • Story adventures • Progress tracking
                </Typography>
              </Box>

              {/* Floating Elements */}
              <Box
                sx={{
                  position: 'absolute',
                  top: '20px',
                  right: '20px',
                  backgroundColor: theme.palette.secondary.main,
                  color: 'white',
                  padding: '8px 16px',
                  borderRadius: '20px',
                  fontSize: '0.875rem',
                  fontWeight: 600,
                  animation: 'float 3s ease-in-out infinite',
                  '@keyframes float': {
                    '0%, 100%': { transform: 'translateY(0)' },
                    '50%': { transform: 'translateY(-10px)' },
                  },
                }}
              >
                100% Safe
              </Box>

              <Box
                sx={{
                  position: 'absolute',
                  bottom: '20px',
                  left: '20px',
                  backgroundColor: theme.palette.warning.main,
                  color: 'white',
                  padding: '8px 16px',
                  borderRadius: '20px',
                  fontSize: '0.875rem',
                  fontWeight: 600,
                  animation: 'float 3s ease-in-out infinite 1s',
                }}
              >
                Ages 3-12
              </Box>
            </Box>
          </Grid>
        </Grid>
      </Container>
    </Box>
  )
}