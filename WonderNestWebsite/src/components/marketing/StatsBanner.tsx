import React from 'react'
import {
  Box,
  Container,
  Typography,
  Grid,
  Stack,
  useTheme,
  useMediaQuery,
} from '@mui/material'

interface Stat {
  value: string
  label: string
  description?: string
}

interface StatsBannerProps {
  stats: Stat[]
  title?: string
  subtitle?: string
}

export const StatsBanner: React.FC<StatsBannerProps> = ({
  stats,
  title = "Trusted by Families Worldwide",
  subtitle = "Join thousands of parents creating safe digital learning experiences for their children",
}) => {
  const theme = useTheme()
  const isMobile = useMediaQuery(theme.breakpoints.down('md'))

  return (
    <Box className="stats-banner">
      <Container maxWidth="lg">
        <Stack spacing={4} alignItems="center">
          {/* Header */}
          <Box sx={{ textAlign: 'center', maxWidth: '800px' }}>
            <Typography
              variant={isMobile ? 'h4' : 'h3'}
              component="h2"
              fontWeight={700}
              color="white"
              gutterBottom
            >
              {title}
            </Typography>
            <Typography
              variant="h6"
              color="rgba(255, 255, 255, 0.9)"
              sx={{ fontWeight: 400 }}
            >
              {subtitle}
            </Typography>
          </Box>

          {/* Stats Grid */}
          <Grid container spacing={4} justifyContent="center" sx={{ width: '100%' }}>
            {stats.map((stat, index) => (
              <Grid item xs={12} sm={6} md={3} key={index}>
                <Box
                  sx={{
                    textAlign: 'center',
                    padding: 2,
                    borderRadius: 2,
                    background: 'rgba(255, 255, 255, 0.1)',
                    backdropFilter: 'blur(10px)',
                    border: '1px solid rgba(255, 255, 255, 0.2)',
                    transition: 'transform 0.3s ease',
                    '&:hover': {
                      transform: 'translateY(-5px)',
                    },
                  }}
                >
                  <Typography
                    variant="h3"
                    component="div"
                    fontWeight={800}
                    color="white"
                    sx={{
                      fontSize: { xs: '2rem', sm: '2.5rem', md: '3rem' },
                      lineHeight: 1.2,
                      mb: 1,
                    }}
                  >
                    {stat.value}
                  </Typography>
                  
                  <Typography
                    variant="h6"
                    color="rgba(255, 255, 255, 0.9)"
                    fontWeight={600}
                    gutterBottom
                  >
                    {stat.label}
                  </Typography>
                  
                  {stat.description && (
                    <Typography
                      variant="body2"
                      color="rgba(255, 255, 255, 0.7)"
                      sx={{ fontSize: '0.875rem' }}
                    >
                      {stat.description}
                    </Typography>
                  )}
                </Box>
              </Grid>
            ))}
          </Grid>
        </Stack>
      </Container>
    </Box>
  )
}