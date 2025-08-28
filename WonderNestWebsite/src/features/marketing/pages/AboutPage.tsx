import React from 'react'
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  Avatar,
  Stack,
  Chip,
  useTheme,
} from '@mui/material'
import {
  School as SchoolIcon,
  Favorite as HeartIcon,
  Security as SecurityIcon,
  Groups as CommunityIcon,
  Psychology as InnovationIcon,
  EmojiEvents as AchievementIcon,
} from '@mui/icons-material'

export const AboutPage: React.FC = () => {
  const theme = useTheme()

  const values = [
    {
      icon: <HeartIcon sx={{ fontSize: '3rem' }} />,
      title: 'Joy in Learning',
      description: 'Learning should feel like play. We create delightful experiences where children discover naturally through expertly crafted games and stories.',
    },
    {
      icon: <SecurityIcon sx={{ fontSize: '3rem' }} />,
      title: 'Dual Curation Excellence',
      description: 'Professional educators curate quality content, while parents add their own approved favorites - creating a personalized, safe learning library.',
    },
    {
      icon: <SchoolIcon sx={{ fontSize: '3rem' }} />,
      title: 'Educational Through Play',
      description: 'Every game teaches something valuable - from vocabulary and math to creativity and problem-solving - all wrapped in fun, engaging experiences.',
    },
    {
      icon: <InnovationIcon sx={{ fontSize: '3rem' }} />,
      title: 'Gentle Progress Insights',
      description: 'Yes, we track progress! Parents receive thoughtful insights about their child\'s growth without overwhelming metrics or pressure.',
    },
  ]

  const team = [
    {
      name: 'Dr. Sarah Mitchell',
      role: 'Founder & CEO',
      bio: 'Former elementary school principal with 15 years in education. PhD in Child Development from Stanford University.',
      avatar: '',
      expertise: ['Education Leadership', 'Child Psychology', 'Curriculum Development'],
    },
    {
      name: 'Michael Chen',
      role: 'CTO & Co-Founder',
      bio: 'Former senior engineer at top tech companies. Father of two who understands the importance of safe digital experiences.',
      avatar: '',
      expertise: ['Software Architecture', 'Data Privacy', 'Child Safety Technology'],
    },
    {
      name: 'Dr. Jennifer Rodriguez',
      role: 'Head of Learning Sciences',
      bio: 'Educational researcher with expertise in digital learning environments and child cognitive development.',
      avatar: '',
      expertise: ['Learning Science', 'Educational Technology', 'Assessment Design'],
    },
    {
      name: 'David Park',
      role: 'Head of Product',
      bio: 'Product leader with experience building family-friendly technology. Parent and advocate for responsible design.',
      avatar: '',
      expertise: ['Product Strategy', 'User Experience', 'Family Technology'],
    },
  ]

  const milestones = [
    {
      year: '2022',
      title: 'Company Founded',
      description: 'Started with a vision to create a delightful digital toy box for children\'s learning.',
    },
    {
      year: '2023',
      title: 'First 100 Games Curated',
      description: 'Launched with expert-selected educational games that make learning feel like play.',
    },
    {
      year: '2023',
      title: 'Dual Curation Launched',
      description: 'Introduced system allowing parents to add favorites alongside expert selections.',
    },
    {
      year: '2024',
      title: '500+ Games Available',
      description: 'Expanded toy box to over 500 carefully curated games and activities.',
    },
    {
      year: '2024',
      title: '50K Happy Families',
      description: 'Reached 50,000 families enjoying safe, educational fun together.',
    },
    {
      year: '2025',
      title: 'Global Expansion',
      description: 'Bringing our digital toy box to families worldwide with multilingual support.',
    },
  ]

  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase()
  }

  return (
    <Box>
      {/* Hero Section */}
      <Box
        sx={{
          pt: 8,
          pb: 6,
          background: `linear-gradient(135deg, ${theme.palette.primary.main}10 0%, ${theme.palette.secondary.main}10 100%)`,
        }}
      >
        <Container maxWidth="lg">
          <Grid container spacing={6} alignItems="center">
            <Grid item xs={12} md={6}>
              <Typography className="section-title" variant="h2" component="h1">
                Where Learning Feels Like Play
              </Typography>
              <Typography className="section-subtitle" variant="h6">
                We believe in creating a delightful digital toy box filled with expert-curated games and stories 
                that make learning joyful - with the added benefit of gentle progress insights for parents.
              </Typography>
            </Grid>
            <Grid item xs={12} md={6}>
              <Box
                sx={{
                  display: 'flex',
                  justifyContent: 'center',
                  alignItems: 'center',
                  height: 300,
                  background: `linear-gradient(135deg, ${theme.palette.primary.main}15 0%, ${theme.palette.secondary.main}15 100%)`,
                  borderRadius: '16px',
                  border: `2px solid ${theme.palette.primary.main}20`,
                }}
              >
                <Stack alignItems="center" spacing={2}>
                  <CommunityIcon sx={{ fontSize: '4rem', color: theme.palette.primary.main }} />
                  <Typography variant="h5" color="primary" textAlign="center">
                    Our Mission
                  </Typography>
                  <Typography variant="body1" color="text.secondary" textAlign="center" maxWidth={300}>
                    Creating joyful learning experiences through expertly curated games, safe exploration, and meaningful educational fun.
                  </Typography>
                </Stack>
              </Box>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Mission Statement */}
      <Container maxWidth="md" sx={{ py: 8, textAlign: 'center' }}>
        <Typography variant="h3" fontWeight={700} color="primary" gutterBottom>
          Our Mission
        </Typography>
        <Typography variant="h6" color="text.secondary" sx={{ mb: 4, lineHeight: 1.7 }}>
          At WonderNest, we believe learning should be joyful, safe, and enriching. We create a digital toy box 
          filled with hundreds of expert-curated games and stories that make education feel like play. Parents can 
          add their own approved content alongside our professional selections, creating a personalized learning 
          experience. And yes, we provide gentle progress insights too - so you know your child is growing!
        </Typography>
        
        <Typography variant="h5" fontWeight={600} color="primary" gutterBottom sx={{ mt: 6 }}>
          Our Vision
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.7 }}>
          A world where every child has access to a delightful digital toy box that makes learning feel like 
          play, where parents and educators work together to curate quality content, and where growth happens naturally.
        </Typography>
      </Container>

      {/* Values */}
      <Box sx={{ bgcolor: 'background.default', py: 8 }}>
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography className="section-title" variant="h3" component="h2">
              Our Values
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              The principles that guide everything we do
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {values.map((value, index) => (
              <Grid item xs={12} md={6} key={index}>
                <Card
                  sx={{
                    height: '100%',
                    p: 3,
                    border: `1px solid ${theme.palette.divider}`,
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      transform: 'translateY(-4px)',
                      boxShadow: theme.shadows[8],
                      borderColor: theme.palette.primary.main,
                    },
                  }}
                >
                  <Stack direction="row" spacing={3} alignItems="flex-start">
                    <Box sx={{ color: theme.palette.primary.main, mt: 1 }}>
                      {value.icon}
                    </Box>
                    <Box>
                      <Typography variant="h5" fontWeight={600} gutterBottom>
                        {value.title}
                      </Typography>
                      <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.6 }}>
                        {value.description}
                      </Typography>
                    </Box>
                  </Stack>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* Team */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        <Box sx={{ textAlign: 'center', mb: 6 }}>
          <Typography className="section-title" variant="h3" component="h2">
            Meet Our Team
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            Educators, parents, and technologists working together for children's digital wellbeing
          </Typography>
        </Box>

        <Grid container spacing={4}>
          {team.map((member, index) => (
            <Grid item xs={12} sm={6} md={3} key={index}>
              <Card
                sx={{
                  height: '100%',
                  textAlign: 'center',
                  p: 3,
                  border: `1px solid ${theme.palette.divider}`,
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: theme.shadows[8],
                  },
                }}
              >
                <Avatar
                  src={member.avatar}
                  sx={{
                    width: 100,
                    height: 100,
                    mx: 'auto',
                    mb: 2,
                    bgcolor: theme.palette.primary.main,
                    fontSize: '2rem',
                    fontWeight: 600,
                  }}
                >
                  {getInitials(member.name)}
                </Avatar>

                <Typography variant="h6" fontWeight={600} gutterBottom>
                  {member.name}
                </Typography>
                
                <Typography variant="subtitle1" color="primary" gutterBottom>
                  {member.role}
                </Typography>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 2, lineHeight: 1.6 }}>
                  {member.bio}
                </Typography>

                <Stack direction="row" spacing={0.5} justifyContent="center" flexWrap="wrap">
                  {member.expertise.map((skill, skillIndex) => (
                    <Chip
                      key={skillIndex}
                      label={skill}
                      size="small"
                      variant="outlined"
                      sx={{ fontSize: '0.75rem', mb: 0.5 }}
                    />
                  ))}
                </Stack>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Timeline */}
      <Box sx={{ bgcolor: 'background.default', py: 8 }}>
        <Container maxWidth="md">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography className="section-title" variant="h3" component="h2">
              Our Journey
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Key milestones in building safer digital learning experiences
            </Typography>
          </Box>

          <Box sx={{ position: 'relative' }}>
            {/* Timeline line */}
            <Box
              sx={{
                position: 'absolute',
                left: '50%',
                top: 0,
                bottom: 0,
                width: '2px',
                bgcolor: theme.palette.primary.main,
                transform: 'translateX(-50%)',
                display: { xs: 'none', md: 'block' },
              }}
            />

            {milestones.map((milestone, index) => (
              <Box
                key={index}
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  mb: 4,
                  position: 'relative',
                  flexDirection: { xs: 'column', md: index % 2 === 0 ? 'row' : 'row-reverse' },
                }}
              >
                {/* Content */}
                <Box
                  sx={{
                    width: { xs: '100%', md: '45%' },
                    textAlign: { xs: 'center', md: index % 2 === 0 ? 'right' : 'left' },
                    pr: { xs: 0, md: index % 2 === 0 ? 3 : 0 },
                    pl: { xs: 0, md: index % 2 === 1 ? 3 : 0 },
                  }}
                >
                  <Card
                    sx={{
                      p: 3,
                      border: `1px solid ${theme.palette.divider}`,
                      boxShadow: theme.shadows[2],
                    }}
                  >
                    <Typography variant="h6" color="primary" fontWeight={600} gutterBottom>
                      {milestone.year}
                    </Typography>
                    <Typography variant="h6" fontWeight={600} gutterBottom>
                      {milestone.title}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {milestone.description}
                    </Typography>
                  </Card>
                </Box>

                {/* Timeline dot */}
                <Box
                  sx={{
                    position: { xs: 'static', md: 'absolute' },
                    left: { xs: 'auto', md: '50%' },
                    transform: { xs: 'none', md: 'translateX(-50%)' },
                    width: 20,
                    height: 20,
                    borderRadius: '50%',
                    bgcolor: theme.palette.primary.main,
                    border: `3px solid ${theme.palette.background.paper}`,
                    zIndex: 1,
                    my: { xs: 2, md: 0 },
                  }}
                />
              </Box>
            ))}
          </Box>
        </Container>
      </Box>

      {/* Awards and Recognition */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        <Box sx={{ textAlign: 'center', mb: 6 }}>
          <Typography className="section-title" variant="h3" component="h2">
            Awards & Recognition
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            Recognition for our commitment to child safety and educational excellence
          </Typography>
        </Box>

        <Grid container spacing={4} justifyContent="center">
          {[
            {
              title: 'Best Children\'s Learning Platform',
              organization: 'EdTech Breakthrough Awards',
              description: 'Recognized for making learning joyful through expert curation',
            },
            {
              title: 'Parent Choice Gold Award',
              organization: 'Parent Choice Foundation',
              description: 'Honored for safe, curated content and family-friendly design',
            },
            {
              title: 'Excellence in Educational Gaming',
              organization: 'Learning Innovation Society',
              description: 'Acknowledged for seamlessly blending education with entertainment',
            },
            {
              title: 'Innovation in Dual Curation',
              organization: 'Digital Safety Alliance',
              description: 'Recognized for combining expert and parent curation models',
            },
          ].map((award, index) => (
            <Grid item xs={12} sm={6} md={3} key={index}>
              <Card
                sx={{
                  height: '100%',
                  textAlign: 'center',
                  p: 3,
                  border: `1px solid ${theme.palette.divider}`,
                }}
              >
                <AchievementIcon
                  sx={{
                    fontSize: '3rem',
                    color: theme.palette.warning.main,
                    mb: 2,
                  }}
                />
                <Typography variant="h6" fontWeight={600} gutterBottom>
                  {award.title}
                </Typography>
                <Typography variant="subtitle2" color="primary" gutterBottom>
                  {award.organization}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {award.description}
                </Typography>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>
    </Box>
  )
}