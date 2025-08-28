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
  Bookmark
} from '@mui/icons-material'

import { useAuth } from '@/hooks/useAuth'

export const ParentDashboard: React.FC = () => {
  const { user, logout } = useAuth()

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
              <Box sx={{ 
                height: 300, 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                bgcolor: 'grey.50',
                borderRadius: 1
              }}>
                <Typography color="textSecondary">
                  Quick action buttons for managing bookmarks, settings, etc.
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}