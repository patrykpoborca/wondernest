import React, { useEffect, useState } from 'react'
import { 
  Box, 
  Typography, 
  Card, 
  CardContent,
  Grid,
  Avatar,
  Chip,
  Button,
  CircularProgress,
  Alert
} from '@mui/material'
import { 
  People,
  Games,
  Analytics,
  Security,
  ExitToApp,
  Shield,
  CloudUpload
} from '@mui/icons-material'

import { useAdminAuth } from '@/contexts/AdminAuthContext'
import { adminApiService } from '@/services/adminApi'
import { DashboardMetrics } from '@/types/admin'

export const AdminDashboard: React.FC = () => {
  const { admin, logout, isAuthenticated, isLoading } = useAdminAuth()
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null)
  const [metricsLoading, setMetricsLoading] = useState(true)
  const [metricsError, setMetricsError] = useState<string | null>(null)

  // Load dashboard metrics
  useEffect(() => {
    const loadMetrics = async () => {
      if (!isAuthenticated) return
      
      try {
        setMetricsLoading(true)
        const data = await adminApiService.getDashboardMetrics()
        setMetrics(data)
      } catch (error: any) {
        setMetricsError(error.error || 'Failed to load dashboard metrics')
      } finally {
        setMetricsLoading(false)
      }
    }
    
    loadMetrics()
  }, [isAuthenticated])

  const handleLogout = async () => {
    await logout()
  }

  if (isLoading) {
    return (
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        minHeight: '50vh' 
      }}>
        <CircularProgress />
      </Box>
    )
  }

  if (!isAuthenticated || !admin) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="warning">
          Admin authentication required. Please log in to access the dashboard.
        </Alert>
      </Box>
    )
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
            icon={<Shield />}
            label={admin.role.replace('_', ' ').toUpperCase()} 
            color="primary" 
            variant="outlined"
          />
          <Avatar sx={{ bgcolor: 'primary.main' }}>
            {admin?.first_name?.[0] || admin?.email?.[0]?.toUpperCase()}
            {admin?.last_name?.[0] || ''}
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

      {/* Error Alert */}
      {metricsError && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {metricsError}
        </Alert>
      )}

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
                    {metricsLoading ? <CircularProgress size={20} /> : (metrics?.active_families || 0).toLocaleString()}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Active Families
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
                    {metricsLoading ? <CircularProgress size={20} /> : (metrics?.total_content_items || 0).toLocaleString()}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Content Items
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
                <Avatar sx={{ bgcolor: metrics?.system_health === 'healthy' ? 'success.main' : 'warning.main' }}>
                  <Analytics />
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    {metricsLoading ? <CircularProgress size={20} /> : metrics?.system_health?.toUpperCase() || 'UNKNOWN'}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    System Health
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
                    {metricsLoading ? <CircularProgress size={20} /> : (metrics?.pending_moderation || 0)}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Pending Review
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
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Button
                  variant="contained"
                  fullWidth
                  startIcon={<CloudUpload />}
                  onClick={() => window.location.href = '/admin/content-seeding'}
                  size="large"
                >
                  Content Seeding
                </Button>
                <Button
                  variant="outlined"
                  fullWidth
                  startIcon={<People />}
                  size="large"
                  disabled
                >
                  User Management
                </Button>
                <Button
                  variant="outlined"
                  fullWidth
                  startIcon={<Security />}
                  size="large"
                  disabled
                >
                  Content Moderation
                </Button>
                <Button
                  variant="outlined"
                  fullWidth
                  startIcon={<Analytics />}
                  size="large"
                  disabled
                >
                  System Monitoring
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}