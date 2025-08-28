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
      icon: <SecurityIcon sx={{ fontSize: '3rem' }} />,
      title: 'Safety First',
      description: 'Child privacy and safety are at the core of everything we build. We maintain the highest standards of data protection and content moderation.',
    },
    {
      icon: <SchoolIcon sx={{ fontSize: '3rem' }} />,
      title: 'Educational Excellence',
      description: 'We partner with educators and child development experts to create content that truly supports learning and growth.',
    },
    {
      icon: <HeartIcon sx={{ fontSize: '3rem' }} />,
      title: 'Family-Centered',
      description: 'We believe parents are their child\'s first teachers. Our platform strengthens family bonds through shared learning experiences.',
    },
    {
      icon: <InnovationIcon sx={{ fontSize: '3rem' }} />,
      title: 'Thoughtful Innovation',
      description: 'We use technology purposefully to enhance learning, never as a substitute for human connection and creativity.',
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
      description: 'Started with a mission to create safer, more educational digital experiences for children.',
    },
    {
      year: '2023',
      title: 'COPPA Certification',
      description: 'Achieved full COPPA compliance and launched our first educational games.',
    },
    {
      year: '2023',
      title: '1,000 Families',
      description: 'Reached our first 1,000 families using WonderNest for safe digital learning.',
    },
    {
      year: '2024',
      title: 'Educational Partnerships',
      description: 'Formed partnerships with leading educational institutions and child development organizations.',
    },
    {
      year: '2024',
      title: '10,000+ Families',
      description: 'Growing community of families creating positive digital learning experiences.',
    },
    {
      year: '2025',
      title: 'Global Expansion',
      description: 'Expanding internationally to bring safe digital learning to families worldwide.',
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
                Building the Future of Safe Digital Learning
              </Typography>
              <Typography className="section-subtitle" variant="h6">
                We're a team of educators, parents, and technologists united by a simple belief: 
                children deserve digital experiences that are safe, educational, and joyful.
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
                    Creating technology that brings families together and helps children learn in safe, supportive environments.
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
          At WonderNest, we believe every child deserves access to high-quality educational content 
          in an environment that prioritizes their safety, privacy, and wellbeing. We're committed to 
          creating technology that enhances family relationships and supports children's natural 
          curiosity and love of learning.
        </Typography>
        
        <Typography variant="h5" fontWeight={600} color="primary" gutterBottom sx={{ mt: 6 }}>
          Our Vision
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.7 }}>
          A world where every child has access to safe, engaging digital learning experiences that 
          celebrate their uniqueness, support their development, and bring families closer together.
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
              title: 'COPPA Compliant Certification',
              organization: 'Federal Trade Commission',
              description: 'Certified for full compliance with children\'s privacy protection standards',
            },
            {
              title: 'Educational Excellence Award',
              organization: 'National Education Association',
              description: 'Recognized for innovative approaches to digital learning',
            },
            {
              title: 'Best Family App',
              organization: 'Family Technology Awards 2024',
              description: 'Honored for creating technology that brings families together',
            },
            {
              title: 'Child Safety Innovation',
              organization: 'Digital Wellness Institute',
              description: 'Acknowledged for advancing child safety in digital environments',
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