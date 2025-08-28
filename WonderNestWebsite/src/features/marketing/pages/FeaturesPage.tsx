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
      title: 'Digital Toy Box Collection',
      description: 'Hundreds of delightful games and activities, each expertly selected by education professionals for quality, fun, and learning value.',
      image: '/api/placeholder/600/400', // Placeholder for game screenshot
      features: [
        'Puzzle games that teach logic',
        'Story adventures for reading',
        'Creative art and music tools',
        'Math games that feel like play',
        'Science exploration activities',
        'Language learning adventures',
      ],
      category: 'Games & Fun',
    },
    {
      icon: <StoryIcon sx={{ fontSize: '4rem', color: theme.palette.secondary.main }} />,
      title: 'Dual Curation System',
      description: 'Professional educators curate quality content, while you add your own approved favorites - creating a personalized learning library.',
      image: '/api/placeholder/600/400', // Placeholder for story screenshot
      features: [
        'Expert educator selections',
        'Add your family favorites',
        'YouTube Kids integration',
        'Custom content approval',
        'Quality-first approach',
        'Values-aligned choices',
      ],
      category: 'Curation',
    },
    {
      icon: <ProgressIcon sx={{ fontSize: '4rem', color: theme.palette.warning.main }} />,
      title: 'Natural Learning Journey',
      description: 'Watch your child discover and grow through play, with games that adapt to their pace and celebrate their achievements.',
      image: '/api/placeholder/600/400', // Placeholder for analytics dashboard
      features: [
        'Games that grow with your child',
        'Natural skill progression',
        'Milestone celebrations',
        'Encouraging feedback',
        'No pressure, just fun',
        'Progress insights for parents',
      ],
      category: 'Educational',
    },
    {
      icon: <SafetyIcon sx={{ fontSize: '4rem', color: theme.palette.success.main }} />,
      title: 'Safe Discovery Space',
      description: 'Every game, story, and activity has been carefully vetted - creating a protected digital playground for exploration.',
      image: '/api/placeholder/600/400', // Placeholder for safety dashboard
      features: [
        'Pre-screened content only',
        'No ads or in-app purchases',
        'COPPA compliant platform',
        'Age-appropriate content',
        'Safe social features',
        'Parent peace of mind',
      ],
      category: 'Safety',
    },
  ]

  const additionalFeatures = [
    {
      icon: <CognitionIcon />,
      title: 'Growing Vocabulary',
      description: 'Watch language bloom naturally through stories and games - from first words to rich expression.',
    },
    {
      icon: <RewardsIcon />,
      title: 'Celebration Moments',
      description: 'Achievements and milestones that make your child feel proud of their learning journey.',
    },
    {
      icon: <OfflineIcon />,
      title: 'Works Offline Too',
      description: 'Download favorites for car rides, flights, or anywhere without internet.',
    },
    {
      icon: <MultilingualIcon />,
      title: 'Multiple Languages',
      description: 'Games and stories in various languages to support bilingual families.',
    },
    {
      icon: <TimeIcon />,
      title: 'Gentle Progress Tracking',
      description: 'Weekly summaries show growth without pressure - data when you want it.',
    },
    {
      icon: <CommunityIcon />,
      title: 'Family Sharing',
      description: 'Multiple child profiles with age-appropriate content for each sibling.',
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
            A Digital Toy Box Where Learning Feels Like Play
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            Expert-curated games and stories, plus your family favorites - all in one safe, delightful space
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
              More Delightful Features
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Everything you need for a complete, safe, and enriching digital experience
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
            Open Your Child's Digital Toy Box Today
          </Typography>
          <Typography variant="h6" color="text.secondary" sx={{ mb: 4 }}>
            Join families discovering the joy of learning through expertly curated games and stories.
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
            ✓ 500+ curated games ✓ Safe discovery space ✓ Add your favorites ✓ Progress insights included
          </Typography>
        </Container>
      </Box>
    </Box>
  )
}