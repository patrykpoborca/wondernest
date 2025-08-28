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
      title: 'Your Digital Toy Box',
      description: 'Hundreds of delightful games and activities that make learning feel like play - all expertly curated for quality and fun.',
      features: [
        'Staff-curated educational games',
        'Interactive stories and adventures',
        'Creative drawing and music tools',
        'Age-appropriate challenges that grow'
      ],
      tag: 'Fun First',
      tagColor: theme.palette.primary.main,
    },
    {
      icon: <StoryIcon sx={{ fontSize: '3rem' }} />,
      title: 'Dual Curation Excellence',
      description: 'Expert-selected content by our education team, plus your own approved favorites - the best of both worlds.',
      features: [
        'Professional educator curation',
        'Add your family favorites',
        'Quality-guaranteed content',
        'Values-aligned selection'
      ],
      tag: 'Quality Content',
      tagColor: theme.palette.secondary.main,
    },
    {
      icon: <ProgressIcon sx={{ fontSize: '3rem' }} />,
      title: 'Learning Through Play',
      description: 'Watch your child discover new concepts naturally through games designed by education experts.',
      features: [
        'Stealth learning approach',
        'Natural skill development',
        'Adaptive difficulty levels',
        'Celebrate achievements together'
      ],
      tag: 'Educational',
      tagColor: theme.palette.warning.main,
    },
    {
      icon: <SafetyIcon sx={{ fontSize: '3rem' }} />,
      title: 'Safe Discovery Space',
      description: 'A protected digital playground where every game and story has been vetted for quality and safety.',
      features: [
        'Pre-screened content only',
        'No ads or in-app purchases',
        'COPPA compliant platform',
        'Parent peace of mind'
      ],
      tag: 'Safety First',
      tagColor: theme.palette.success.main,
    },
    {
      icon: <EducationIcon sx={{ fontSize: '3rem' }} />,
      title: 'Growing Vocabulary',
      description: 'From first words to rich vocabulary - watch language skills bloom through playful interaction.',
      features: [
        'Story-based word discovery',
        'Context-rich learning',
        'Natural language growth',
        'Yes, we track progress too!'
      ],
      tag: 'Language',
      tagColor: theme.palette.info.main,
    },
    {
      icon: <ParentIcon sx={{ fontSize: '3rem' }} />,
      title: 'Insightful Progress',
      description: 'Know your child is learning while they play - with gentle metrics that celebrate growth.',
      features: [
        'Weekly progress summaries',
        'Skill development insights',
        'Milestone celebrations',
        'Data when you want it'
      ],
      tag: 'Peace of Mind',
      tagColor: theme.palette.error.main,
    },
  ]

  const testimonials = [
    {
      quote: "My kids absolutely love their 'toy box time'! They're having so much fun with the games and stories, they don't even realize they're learning. Plus, I love that everything is pre-screened and I can add our family's favorite educational content too.",
      author: "Sarah Johnson",
      role: "Mother of Two",
      childAge: "6 and 9",
      location: "California",
      rating: 5,
    },
    {
      quote: "As a teacher, I appreciate the thoughtful curation by education professionals. My son explores wonderful games that align with what he's learning in school. The progress insights are a nice bonus - his vocabulary has tripled!",
      author: "Michael Chen",
      role: "Elementary Teacher",
      childAge: "7",
      location: "New York",
      rating: 5,
    },
    {
      quote: "WonderNest has become my daughter's favorite 'screen time'. She's discovered a love for storytelling through the creative games, and I have peace of mind knowing everything is safe and educational. The weekly progress reports are encouraging!",
      author: "Jennifer Martinez",
      role: "Working Mother",
      childAge: "5",
      location: "Texas",
      rating: 5,
    },
  ]

  const stats = [
    {
      value: "500+",
      label: "Curated Games",
      description: "Expert-selected activities"
    },
    {
      value: "100%",
      label: "Safe Content",
      description: "Pre-screened & approved"
    },
    {
      value: "3x",
      label: "Vocabulary Growth",
      description: "Average in 6 months"
    },
    {
      value: "50K+",
      label: "Happy Families",
      description: "Growing every day"
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
              A Digital Toy Box That Grows With Your Child
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Hundreds of expert-curated games and stories, plus your family favorites - where learning feels like play
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
              Open Your Child's Digital Toy Box Today
            </Typography>
            <Typography variant="h6" color="text.secondary" sx={{ mb: 4, maxWidth: '600px', mx: 'auto' }}>
              Join families discovering the joy of learning through play - with expert curation and gentle progress tracking.
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
              Families Love Their WonderNest Experience
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Parents share how their children are thriving through joyful learning
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
            Your Child's Personalized Digital Toy Box Awaits
          </Typography>
          <Typography variant="h6" color="text.secondary" sx={{ mb: 4 }}>
            Hundreds of curated games that make learning joyful - and yes, we track the amazing progress too!
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
            ✓ Expert-curated games ✓ Safe discovery space ✓ Educational fun ✓ Progress insights included
          </Typography>
        </Container>
      </Box>
    </Box>
  )
}