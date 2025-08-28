import React from 'react'
import { 
  Box, 
  Typography, 
  Card, 
  CardContent,
  Grid,
  Avatar,
  Chip,
  Button
} from '@mui/material'
import { 
  People,
  Games,
  Analytics,
  Security,
  ExitToApp
} from '@mui/icons-material'

import { useAuth } from '@/hooks/useAuth'

export const AdminDashboard: React.FC = () => {
  const { user, logout } = useAuth()

  const handleLogout = async () => {
    await logout()
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h4" fontWeight={600}>
            Admin Dashboard
          </Typography>
          <Typography variant="body1" color="textSecondary">
            Platform management and oversight
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Chip 
            label={user?.userType.replace('_', ' ').toUpperCase()} 
            color="primary" 
            variant="outlined"
          />
          <Avatar sx={{ bgcolor: 'primary.main' }}>
            {user?.firstName?.[0]}{user?.lastName?.[0]}
          </Avatar>
          <Button 
            variant="outlined" 
            startIcon={<ExitToApp />} 
            onClick={handleLogout}
          >
            Logout
          </Button>
        </Box>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'primary.main' }}>
                  <People />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    1,247
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Active Users
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
                  <Games />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    156
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Published Games
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
                  <Analytics />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    89.2%
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Platform Health
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
                <Avatar sx={{ bgcolor: 'error.main' }}>
                  <Security />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    3
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Security Alerts
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
                Platform Analytics
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
                  Platform analytics charts and user activity metrics will be displayed here
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
                Admin Actions
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
                  Admin tools for user management, content moderation, and system monitoring
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}