import React from 'react'
import { 
  Box, 
  Typography, 
  Card, 
  CardContent,
  Grid,
  Avatar,
  Chip
} from '@mui/material'
import { 
  ChildCare,
  Schedule,
  TrendingUp,
  Bookmark,
  Folder,
  Settings,
  PlayCircle,
  Assessment,
  AutoStories
} from '@mui/icons-material'

import { useAuth } from '@/hooks/useAuth'
import { useNavigate } from 'react-router-dom'
import { Button, Stack } from '@mui/material'

export const ParentDashboard: React.FC = () => {
  const { user } = useAuth()
  const navigate = useNavigate()

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h4" fontWeight={600}>
            Welcome back, {user?.firstName}!
          </Typography>
          <Typography variant="body1" color="textSecondary">
            Here's what's happening with your children's learning journey
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Chip 
            label="Parent Account" 
            color="primary" 
            variant="outlined"
          />
          <Avatar sx={{ bgcolor: 'primary.main' }}>
            {user?.firstName?.[0]}{user?.lastName?.[0]}
          </Avatar>
        </Box>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'primary.main' }}>
                  <ChildCare />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    3
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Active Children
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'secondary.main' }}>
                  <Schedule />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    2.5h
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Today's Screen Time
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'warning.main' }}>
                  <TrendingUp />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    12
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Skills Developed
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'success.main' }}>
                  <Bookmark />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    24
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Bookmarked Games
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Main Content */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
                Children's Activity Overview
              </Typography>
              <Box sx={{ 
                height: 300, 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                bgcolor: 'grey.50',
                borderRadius: 1
              }}>
                <Typography color="textSecondary">
                  Activity charts and child progress will be displayed here
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
                Quick Actions
              </Typography>
              <Stack spacing={2}>
                <Button
                  variant="outlined"
                  startIcon={<Folder />}
                  fullWidth
                  onClick={() => navigate('/app/parent/files')}
                  sx={{ justifyContent: 'flex-start' }}
                >
                  Manage Files
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<AutoStories />}
                  fullWidth
                  onClick={() => navigate('/app/parent/story-builder')}
                  sx={{ justifyContent: 'flex-start' }}
                >
                  Story Builder
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<PlayCircle />}
                  fullWidth
                  onClick={() => navigate('/app/parent/games')}
                  sx={{ justifyContent: 'flex-start' }}
                >
                  Browse Games
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<Assessment />}
                  fullWidth
                  onClick={() => navigate('/app/parent/analytics')}
                  sx={{ justifyContent: 'flex-start' }}
                >
                  View Analytics
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<Bookmark />}
                  fullWidth
                  onClick={() => navigate('/app/parent/bookmarks')}
                  sx={{ justifyContent: 'flex-start' }}
                >
                  Manage Bookmarks
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<Settings />}
                  fullWidth
                  onClick={() => navigate('/app/parent/settings')}
                  sx={{ justifyContent: 'flex-start' }}
                >
                  Family Settings
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}