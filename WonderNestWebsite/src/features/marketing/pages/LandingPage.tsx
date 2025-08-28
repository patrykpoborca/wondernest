import React from 'react'
import {
  Box,
  Container,
  Typography,
  Grid,
  Button,
  Stack,
  useTheme,
} from '@mui/material'
import {
  Games as GamesIcon,
  MenuBook as StoryIcon,
  TrendingUp as ProgressIcon,
  Shield as SafetyIcon,
  School as EducationIcon,
  FamilyRestroom as ParentIcon,
} from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'

import { HeroSection } from '../../../components/marketing/HeroSection'
import { FeatureCard } from '../../../components/marketing/FeatureCard'
import { TestimonialCard } from '../../../components/marketing/TestimonialCard'
import { StatsBanner } from '../../../components/marketing/StatsBanner'

export const LandingPage: React.FC = () => {
  const theme = useTheme()
  const navigate = useNavigate()

  const handleGetStarted = () => {
    navigate('/app/signup')
  }

  const handleWatchDemo = () => {
    // For now, just scroll to features section
    document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' })
  }

  const features = [
    {
      icon: <GamesIcon sx={{ fontSize: '3rem' }} />,
      title: 'Educational Games',
      description: 'Interactive learning games designed by child development experts to make learning fun and engaging.',
      features: [
        'Age-appropriate content for 3-12 years',
        'Adaptive difficulty levels',
        'Progress tracking and rewards',
        'Offline play capability'
      ],
      tag: 'Core Feature',
      tagColor: theme.palette.primary.main,
    },
    {
      icon: <StoryIcon sx={{ fontSize: '3rem' }} />,
      title: 'Story Adventures',
      description: 'Immersive storytelling experiences that develop reading skills, creativity, and imagination.',
      features: [
        'Interactive story paths',
        'Voice narration and reading along',
        'Custom story creation tools',
        'Family story sharing'
      ],
      tag: 'Popular',
      tagColor: theme.palette.secondary.main,
    },
    {
      icon: <ProgressIcon sx={{ fontSize: '3rem' }} />,
      title: 'Development Tracking',
      description: 'Comprehensive insights into your child\'s learning progress and developmental milestones.',
      features: [
        'Learning analytics dashboard',
        'Milestone achievement tracking',
        'Personalized recommendations',
        'Progress reports for parents'
      ],
      tag: 'Insights',
      tagColor: theme.palette.warning.main,
    },
    {
      icon: <SafetyIcon sx={{ fontSize: '3rem' }} />,
      title: 'Safety First',
      description: 'COPPA-compliant platform with comprehensive parental controls and content filtering.',
      features: [
        'No third-party ads or tracking',
        'Parental approval for all activities',
        'Content filtering and moderation',
        'Secure data encryption'
      ],
      tag: 'Certified',
      tagColor: theme.palette.success.main,
    },
    {
      icon: <EducationIcon sx={{ fontSize: '3rem' }} />,
      title: 'Expert-Designed',
      description: 'Content created in partnership with educators and child development specialists.',
      features: [
        'Curriculum-aligned activities',
        'Evidence-based learning methods',
        'Regular content updates',
        'Multi-language support'
      ],
      tag: 'Quality',
      tagColor: theme.palette.info.main,
    },
    {
      icon: <ParentIcon sx={{ fontSize: '3rem' }} />,
      title: 'Parent Dashboard',
      description: 'Comprehensive tools for parents to monitor, guide, and participate in their child\'s learning journey.',
      features: [
        'Real-time activity monitoring',
        'Screen time controls',
        'Family challenges and goals',
        'Communication tools'
      ],
      tag: 'Control',
      tagColor: theme.palette.error.main,
    },
  ]

  const testimonials = [
    {
      quote: "WonderNest has transformed how my daughter learns. She's excited about math and reading in ways I never thought possible. The safety features give me complete peace of mind.",
      author: "Sarah Johnson",
      role: "Mother of two",
      childAge: "6 and 9",
      location: "California",
      rating: 5,
    },
    {
      quote: "As an educator, I'm impressed by the quality of content. The developmental tracking helps me understand exactly where each of my students stands and how to support them better.",
      author: "Michael Chen",
      role: "Elementary Teacher",
      childAge: "Classes 1-3",
      location: "New York",
      rating: 5,
    },
    {
      quote: "The parent controls are exactly what I needed. I can see what my son is learning, set appropriate limits, and even join him in some activities. It's become our quality time together.",
      author: "Jennifer Martinez",
      role: "Working Mother",
      childAge: "5",
      location: "Texas",
      rating: 5,
    },
  ]

  const stats = [
    {
      value: "10,000+",
      label: "Families",
      description: "Trust WonderNest daily"
    },
    {
      value: "50+",
      label: "Games & Stories",
      description: "Educational content"
    },
    {
      value: "95%",
      label: "Parent Satisfaction",
      description: "Would recommend to others"
    },
    {
      value: "100%",
      label: "COPPA Compliant",
      description: "Child privacy protected"
    },
  ]

  return (
    <Box>
      {/* Hero Section */}
      <HeroSection 
        onGetStarted={handleGetStarted}
        onWatchDemo={handleWatchDemo}
      />

      {/* Features Section */}
      <Box id="features" className="feature-section">
        <Container maxWidth="lg" className="section-container">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography className="section-title" variant="h2" component="h2">
              Everything Your Child Needs to Learn and Grow
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Comprehensive educational tools designed with safety, engagement, and development in mind
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {features.map((feature, index) => (
              <Grid item xs={12} md={6} lg={4} key={index}>
                <FeatureCard {...feature} />
              </Grid>
            ))}
          </Grid>

          {/* CTA Section */}
          <Box sx={{ textAlign: 'center', mt: 8 }}>
            <Typography variant="h4" fontWeight={600} color="primary" gutterBottom>
              Ready to Start Your Child's Learning Journey?
            </Typography>
            <Typography variant="h6" color="text.secondary" sx={{ mb: 4, maxWidth: '600px', mx: 'auto' }}>
              Join thousands of families using WonderNest to create safe, educational, and fun digital experiences for their children.
            </Typography>
            <Stack
              direction={{ xs: 'column', sm: 'row' }}
              spacing={2}
              justifyContent="center"
            >
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
                sx={{ borderColor: theme.palette.primary.main, color: theme.palette.primary.main }}
              >
                View Pricing Plans
              </Button>
            </Stack>
          </Box>
        </Container>
      </Box>

      {/* Stats Banner */}
      <StatsBanner stats={stats} />

      {/* Testimonials Section */}
      <Box className="testimonial-section">
        <Container maxWidth="lg" className="section-container">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography className="section-title" variant="h2" component="h2">
              Loved by Families Everywhere
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              See what parents and educators are saying about WonderNest
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {testimonials.map((testimonial, index) => (
              <Grid item xs={12} md={4} key={index}>
                <TestimonialCard {...testimonial} />
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* Final CTA Section */}
      <Box sx={{ 
        background: `linear-gradient(135deg, ${theme.palette.primary.main}05 0%, ${theme.palette.secondary.main}05 100%)`,
        py: 8 
      }}>
        <Container maxWidth="md" sx={{ textAlign: 'center' }}>
          <Typography variant="h3" fontWeight={700} color="primary" gutterBottom>
            Start Your Child's Safe Learning Adventure Today
          </Typography>
          <Typography variant="h6" color="text.secondary" sx={{ mb: 4 }}>
            No credit card required. Full access to all features during your free trial.
          </Typography>
          
          <Button
            className="cta-primary"
            size="large"
            onClick={handleGetStarted}
            sx={{ mb: 2 }}
          >
            Get Started Free
          </Button>
          
          <Typography variant="body2" color="text.secondary">
            ✓ 14-day free trial ✓ No commitment ✓ Cancel anytime ✓ COPPA compliant
          </Typography>
        </Container>
      </Box>
    </Box>
  )
}