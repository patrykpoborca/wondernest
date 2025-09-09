import React, { useState } from 'react'
import { 
  Box, 
  Typography, 
  Card, 
  CardContent,
  Grid,
  Avatar,
  Chip,
  Button,
  Tabs,
  Tab,
  Dialog,
  DialogTitle,
  DialogContent,
  IconButton
} from '@mui/material'
import { 
  Create,
  Publish,
  Schedule,
  RateReview,
  Add,
  Upload,
  Close
} from '@mui/icons-material'

import { useAuth } from '@/hooks/useAuth'
import { ContentUploadForm } from '../components/ContentUploadForm'
import { ContentList } from '../components/ContentList'

export const ContentManagerDashboard: React.FC = () => {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState(0)
  const [uploadDialogOpen, setUploadDialogOpen] = useState(false)

  const handleTabChange = (_: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue)
  }

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
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => setUploadDialogOpen(true)}
          >
            Upload Content
          </Button>
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

      {/* Tabs */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={activeTab} onChange={handleTabChange}>
          <Tab label="Content Library" />
          <Tab label="Upload New" />
          <Tab label="Analytics" />
        </Tabs>
      </Box>

      {/* Tab Content */}
      {activeTab === 0 && (
        <ContentList 
          onEdit={(item) => {
            console.log('Edit item:', item)
            // TODO: Implement edit functionality
          }}
        />
      )}

      {activeTab === 1 && (
        <ContentUploadForm 
          onSuccess={() => {
            setActiveTab(0) // Switch to library after successful upload
          }}
        />
      )}

      {activeTab === 2 && (
        <Card>
          <CardContent>
            <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
              Content Analytics
            </Typography>
            <Box sx={{ 
              height: 400, 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              bgcolor: 'grey.50',
              borderRadius: 1
            }}>
              <Typography color="textSecondary">
                Analytics dashboard coming soon: views, downloads, ratings, and revenue metrics
              </Typography>
            </Box>
          </CardContent>
        </Card>
      )}

      {/* Upload Dialog */}
      <Dialog
        open={uploadDialogOpen}
        onClose={() => setUploadDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6">Quick Upload</Typography>
            <IconButton onClick={() => setUploadDialogOpen(false)}>
              <Close />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          <ContentUploadForm
            onSuccess={() => {
              setUploadDialogOpen(false)
              setActiveTab(0)
            }}
            onCancel={() => setUploadDialogOpen(false)}
          />
        </DialogContent>
      </Dialog>
    </Box>
  )
}