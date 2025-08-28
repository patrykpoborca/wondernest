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
  Create,
  Publish,
  Schedule,
  RateReview
} from '@mui/icons-material'

import { useAuth } from '@/hooks/useAuth'

export const ContentManagerDashboard: React.FC = () => {
  const { user } = useAuth()

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h4" fontWeight={600}>
            Content Studio
          </Typography>
          <Typography variant="body1" color="textSecondary">
            Create and manage educational content for children
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Chip 
            label="Content Manager" 
            color="secondary" 
            variant="outlined"
          />
          <Avatar sx={{ bgcolor: 'secondary.main' }}>
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
                  <Create />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    8
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Draft Stories
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
                  <Publish />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    24
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Published Content
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
                  <Schedule />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    3
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Pending Review
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
                  <RateReview />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    4.8
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Avg Rating
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
                Recent Content Activity
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
                  Content creation timeline, review status, and analytics will be displayed here
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
                Content Tools
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
                  Story editor, game builder, asset manager, and publishing tools
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}