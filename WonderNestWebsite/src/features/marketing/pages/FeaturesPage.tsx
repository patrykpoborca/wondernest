import React from 'react'
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  Button,
  Stack,
  Chip,
  useTheme,
} from '@mui/material'
import {
  Games as GamesIcon,
  MenuBook as StoryIcon,
  TrendingUp as ProgressIcon,
  Shield as SafetyIcon,
  Psychology as CognitionIcon,
  EmojiEvents as RewardsIcon,
  CloudDownload as OfflineIcon,
  Language as MultilingualIcon,
  AccessTime as TimeIcon,
  Groups as CommunityIcon,
} from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'

export const FeaturesPage: React.FC = () => {
  const theme = useTheme()
  const navigate = useNavigate()

  const mainFeatures = [
    {
      icon: <GamesIcon sx={{ fontSize: '4rem', color: theme.palette.primary.main }} />,
      title: 'Interactive Educational Games',
      description: 'Our library of 50+ educational games covers math, science, reading, and critical thinking skills.',
      image: '/api/placeholder/600/400', // Placeholder for game screenshot
      features: [
        'Age-adaptive difficulty levels',
        'Curriculum-aligned content',
        'Multiple learning styles supported',
        'Progress tracking and analytics',
        'Reward and achievement system',
        'Collaborative family challenges',
      ],
      category: 'Learning',
    },
    {
      icon: <StoryIcon sx={{ fontSize: '4rem', color: theme.palette.secondary.main }} />,
      title: 'Story Adventures & Creation',
      description: 'Immersive storytelling experiences that develop reading comprehension and creative writing skills.',
      image: '/api/placeholder/600/400', // Placeholder for story screenshot
      features: [
        'Interactive story branching',
        'Voice narration and read-along',
        'Custom story creation tools',
        'Character and world building',
        'Family story sharing library',
        'Reading comprehension quizzes',
      ],
      category: 'Creativity',
    },
    {
      icon: <ProgressIcon sx={{ fontSize: '4rem', color: theme.palette.warning.main }} />,
      title: 'Development Tracking',
      description: 'Comprehensive insights into learning progress with detailed analytics and milestone tracking.',
      image: '/api/placeholder/600/400', // Placeholder for analytics dashboard
      features: [
        'Real-time learning analytics',
        'Developmental milestone tracking',
        'Personalized learning recommendations',
        'Progress reports and insights',
        'Goal setting and achievement',
        'Parent-teacher communication tools',
      ],
      category: 'Analytics',
    },
    {
      icon: <SafetyIcon sx={{ fontSize: '4rem', color: theme.palette.success.main }} />,
      title: 'Safety & Privacy',
      description: 'COPPA-compliant platform with comprehensive safety features and parental controls.',
      image: '/api/placeholder/600/400', // Placeholder for safety dashboard
      features: [
        'Full COPPA compliance',
        'No third-party advertising',
        'Content moderation and filtering',
        'Secure data encryption',
        'Parental approval workflows',
        'Emergency contact system',
      ],
      category: 'Security',
    },
  ]

  const additionalFeatures = [
    {
      icon: <CognitionIcon />,
      title: 'Cognitive Development',
      description: 'Activities designed to enhance memory, attention, and problem-solving skills.',
    },
    {
      icon: <RewardsIcon />,
      title: 'Achievement System',
      description: 'Motivating rewards and badges that celebrate learning milestones.',
    },
    {
      icon: <OfflineIcon />,
      title: 'Offline Access',
      description: 'Download content for learning anywhere, even without internet connection.',
    },
    {
      icon: <MultilingualIcon />,
      title: 'Multilingual Support',
      description: 'Content available in multiple languages to support diverse families.',
    },
    {
      icon: <TimeIcon />,
      title: 'Screen Time Controls',
      description: 'Smart time management tools to promote healthy digital habits.',
    },
    {
      icon: <CommunityIcon />,
      title: 'Family Community',
      description: 'Safe community features for families to share and celebrate learning.',
    },
  ]

  const handleGetStarted = () => {
    navigate('/app/signup')
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ pt: 8, pb: 6, textAlign: 'center', bgcolor: 'background.default' }}>
        <Container maxWidth="lg">
          <Typography className="section-title" variant="h2" component="h1">
            Comprehensive Learning Platform
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            Everything your child needs for safe, engaging, and educational digital experiences
          </Typography>
        </Container>
      </Box>

      {/* Main Features */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        {mainFeatures.map((feature, index) => (
          <Box key={index} sx={{ mb: 12 }}>
            <Grid
              container
              spacing={6}
              alignItems="center"
              direction={index % 2 === 0 ? 'row' : 'row-reverse'}
            >
              {/* Content */}
              <Grid item xs={12} md={6}>
                <Stack spacing={3}>
                  <Box>
                    <Chip
                      label={feature.category}
                      color="primary"
                      variant="outlined"
                      sx={{ mb: 2 }}
                    />
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      {feature.icon}
                      <Typography
                        variant="h3"
                        component="h2"
                        fontWeight={700}
                        color="primary"
                        sx={{ ml: 2 }}
                      >
                        {feature.title}
                      </Typography>
                    </Box>
                    <Typography
                      variant="h6"
                      color="text.secondary"
                      sx={{ lineHeight: 1.6, mb: 3 }}
                    >
                      {feature.description}
                    </Typography>
                  </Box>

                  <Box>
                    <Grid container spacing={2}>
                      {feature.features.map((item, itemIndex) => (
                        <Grid item xs={12} sm={6} key={itemIndex}>
                          <Typography
                            variant="body1"
                            sx={{
                              display: 'flex',
                              alignItems: 'center',
                              '&:before': {
                                content: '"✓"',
                                color: theme.palette.secondary.main,
                                fontWeight: 'bold',
                                marginRight: 1,
                                fontSize: '1.2rem',
                              },
                            }}
                          >
                            {item}
                          </Typography>
                        </Grid>
                      ))}
                    </Grid>
                  </Box>

                  <Box>
                    <Button
                      variant="contained"
                      color="primary"
                      size="large"
                      onClick={handleGetStarted}
                      sx={{ mt: 2 }}
                    >
                      Try This Feature Free
                    </Button>
                  </Box>
                </Stack>
              </Grid>

              {/* Image/Visual */}
              <Grid item xs={12} md={6}>
                <Card
                  elevation={8}
                  sx={{
                    borderRadius: '16px',
                    overflow: 'hidden',
                    transition: 'transform 0.3s ease',
                    '&:hover': {
                      transform: 'translateY(-8px)',
                    },
                  }}
                >
                  <Box
                    sx={{
                      height: 400,
                      background: `linear-gradient(135deg, ${feature.icon.props.sx.color}15 0%, ${feature.icon.props.sx.color}05 100%)`,
                      display: 'flex',
                      flexDirection: 'column',
                      justifyContent: 'center',
                      alignItems: 'center',
                      position: 'relative',
                      overflow: 'hidden',
                    }}
                  >
                    {/* Placeholder for feature demo */}
                    <Box
                      sx={{
                        fontSize: '6rem',
                        color: feature.icon.props.sx.color,
                        opacity: 0.3,
                        mb: 2,
                      }}
                    >
                      {React.cloneElement(feature.icon, { sx: { fontSize: '6rem' } })}
                    </Box>
                    <Typography variant="h5" color="primary" textAlign="center">
                      {feature.title} Demo
                    </Typography>
                    <Typography variant="body2" color="text.secondary" textAlign="center" sx={{ mt: 1 }}>
                      Interactive preview coming soon
                    </Typography>
                  </Box>
                </Card>
              </Grid>
            </Grid>
          </Box>
        ))}
      </Container>

      {/* Additional Features Grid */}
      <Box sx={{ bgcolor: 'background.default', py: 8 }}>
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography className="section-title" variant="h3" component="h2">
              Additional Features
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Every detail designed with your child's development and safety in mind
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {additionalFeatures.map((feature, index) => (
              <Grid item xs={12} sm={6} md={4} key={index}>
                <Card
                  sx={{
                    height: '100%',
                    p: 3,
                    textAlign: 'center',
                    border: `1px solid ${theme.palette.divider}`,
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      transform: 'translateY(-4px)',
                      boxShadow: theme.shadows[8],
                      borderColor: theme.palette.primary.main,
                    },
                  }}
                >
                  <Box
                    sx={{
                      color: theme.palette.primary.main,
                      fontSize: '3rem',
                      mb: 2,
                    }}
                  >
                    {feature.icon}
                  </Box>
                  <Typography variant="h6" fontWeight={600} gutterBottom>
                    {feature.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {feature.description}
                  </Typography>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* CTA Section */}
      <Box sx={{ py: 8 }}>
        <Container maxWidth="md" sx={{ textAlign: 'center' }}>
          <Typography variant="h3" fontWeight={700} color="primary" gutterBottom>
            Ready to Explore All Features?
          </Typography>
          <Typography variant="h6" color="text.secondary" sx={{ mb: 4 }}>
            Start your free trial today and give your child access to our complete educational platform.
          </Typography>
          
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} justifyContent="center">
            <Button
              className="cta-primary"
              size="large"
              onClick={handleGetStarted}
            >
              Start Free 14-Day Trial
            </Button>
            <Button
              variant="outlined"
              size="large"
              onClick={() => navigate('/pricing')}
            >
              View Pricing Plans
            </Button>
          </Stack>
          
          <Typography variant="body2" color="text.secondary" sx={{ mt: 3 }}>
            ✓ Full feature access during trial ✓ No credit card required ✓ Cancel anytime
          </Typography>
        </Container>
      </Box>
    </Box>
  )
}