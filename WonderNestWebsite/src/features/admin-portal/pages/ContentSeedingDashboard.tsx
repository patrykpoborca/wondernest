import React, { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  Tabs,
  Tab,
  Card,
  CardContent,
  Grid,
  Avatar,
  Alert,
  CircularProgress,
  Breadcrumbs,
  Link
} from '@mui/material'
import {
  Dashboard,
  People,
  CloudUpload,
  Analytics,
  Home
} from '@mui/icons-material'

import { adminApiService } from '@/services/adminApi'
import { ContentSeedingStats, ContentCreator, ContentItem } from '@/types/admin'
import { CreatorsList } from '../components/CreatorsList'
import { CreatorForm } from '../components/CreatorForm'
import { ContentList } from '../components/ContentList'
import { ContentUploadForm } from '../components/ContentUploadForm'
import { BulkOperations } from '../components/BulkOperations'

interface TabPanelProps {
  children?: React.ReactNode
  index: number
  value: number
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index }) => (
  <div hidden={value !== index}>
    {value === index && <Box>{children}</Box>}
  </div>
)

export const ContentSeedingDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0)
  const [stats, setStats] = useState<ContentSeedingStats | null>(null)
  const [statsLoading, setStatsLoading] = useState(true)
  const [statsError, setStatsError] = useState<string | null>(null)

  // Form states
  const [creatorFormOpen, setCreatorFormOpen] = useState(false)
  const [selectedCreator, setSelectedCreator] = useState<ContentCreator | null>(null)
  const [contentFormOpen, setContentFormOpen] = useState(false)
  const [selectedContent, setSelectedContent] = useState<ContentItem | null>(null)
  const [bulkOpsOpen, setBulkOpsOpen] = useState(false)
  const [selectedContentIds, setSelectedContentIds] = useState<string[]>([])

  // Refresh triggers
  const [refreshTrigger, setRefreshTrigger] = useState(0)

  useEffect(() => {
    loadStats()
  }, [refreshTrigger])

  const loadStats = async () => {
    try {
      setStatsLoading(true)
      setStatsError(null)
      const data = await adminApiService.getContentSeedingStats()
      setStats(data)
    } catch (err: any) {
      setStatsError(err.error || 'Failed to load content seeding statistics')
    } finally {
      setStatsLoading(false)
    }
  }

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue)
  }

  const handleRefresh = () => {
    setRefreshTrigger(prev => prev + 1)
  }

  const handleCreateCreator = () => {
    setSelectedCreator(null)
    setCreatorFormOpen(true)
  }

  const handleEditCreator = (creator: ContentCreator) => {
    setSelectedCreator(creator)
    setCreatorFormOpen(true)
  }

  const handleUploadContent = () => {
    setSelectedContent(null)
    setContentFormOpen(true)
  }

  const handleEditContent = (content: ContentItem) => {
    setSelectedContent(content)
    setContentFormOpen(true)
  }

  const handleBulkActions = (contentIds: string[]) => {
    setSelectedContentIds(contentIds)
    setBulkOpsOpen(true)
  }

  const handleFormSuccess = () => {
    handleRefresh()
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* Breadcrumbs */}
      <Breadcrumbs sx={{ mb: 2 }}>
        <Link href="/admin" sx={{ display: 'flex', alignItems: 'center', gap: 0.5, color: 'inherit', textDecoration: 'none' }}>
          <Home size={16} />
          Admin
        </Link>
        <Typography color="textPrimary" sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
          <Dashboard size={16} />
          Content Seeding
        </Typography>
      </Breadcrumbs>

      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" fontWeight={600} sx={{ mb: 1 }}>
          Content Seeding Dashboard
        </Typography>
        <Typography variant="body1" color="textSecondary">
          Manage content creators, upload educational materials, and oversee the content library
        </Typography>
      </Box>

      {/* Stats Overview */}
      {statsError && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {statsError}
        </Alert>
      )}

      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'primary.main', width: 50, height: 50 }}>
                  <People />
                </Avatar>
                <Box>
                  <Typography variant="h5" fontWeight={600}>
                    {statsLoading ? <CircularProgress size={24} /> : (stats?.total_creators || 0)}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Total Creators
                  </Typography>
                  <Typography variant="caption" color="success.main">
                    {statsLoading ? '...' : `${stats?.active_creators || 0} active`}
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
                <Avatar sx={{ bgcolor: 'secondary.main', width: 50, height: 50 }}>
                  <CloudUpload />
                </Avatar>
                <Box>
                  <Typography variant="h5" fontWeight={600}>
                    {statsLoading ? <CircularProgress size={24} /> : (stats?.total_content_items || 0)}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Content Items
                  </Typography>
                  <Typography variant="caption" color="success.main">
                    {statsLoading ? '...' : `${stats?.published_content || 0} published`}
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
                <Avatar sx={{ bgcolor: 'warning.main', width: 50, height: 50 }}>
                  <Analytics />
                </Avatar>
                <Box>
                  <Typography variant="h5" fontWeight={600}>
                    {statsLoading ? <CircularProgress size={24} /> : (stats?.pending_review || 0)}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Pending Review
                  </Typography>
                  <Typography variant="caption" color="warning.main">
                    Needs attention
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
                <Avatar sx={{ bgcolor: 'info.main', width: 50, height: 50 }}>
                  <CloudUpload />
                </Avatar>
                <Box>
                  <Typography variant="h5" fontWeight={600}>
                    {statsLoading ? <CircularProgress size={24} /> : (stats?.recent_uploads || 0)}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Recent Uploads
                  </Typography>
                  <Typography variant="caption" color="info.main">
                    Last 30 days
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Content Type Breakdown */}
      {stats?.content_types_breakdown && Object.keys(stats.content_types_breakdown).length > 0 && (
        <Card sx={{ mb: 4 }}>
          <CardContent>
            <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
              Content Types Breakdown
            </Typography>
            <Grid container spacing={2}>
              {Object.entries(stats.content_types_breakdown).map(([type, count]) => (
                <Grid item xs={6} sm={4} md={3} key={type}>
                  <Box sx={{ textAlign: 'center', p: 1 }}>
                    <Typography variant="h6" color="primary.main">
                      {count}
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      {type}
                    </Typography>
                  </Box>
                </Grid>
              ))}
            </Grid>
          </CardContent>
        </Card>
      )}

      {/* Main Content Tabs */}
      <Card>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs 
            value={activeTab} 
            onChange={handleTabChange}
            variant="fullWidth"
          >
            <Tab 
              label="Creators" 
              icon={<People />} 
              iconPosition="start"
              sx={{ minHeight: 64 }}
            />
            <Tab 
              label="Content Library" 
              icon={<CloudUpload />} 
              iconPosition="start"
              sx={{ minHeight: 64 }}
            />
          </Tabs>
        </Box>

        <Box sx={{ p: 3 }}>
          {/* Creators Tab */}
          <TabPanel value={activeTab} index={0}>
            <CreatorsList
              onCreateCreator={handleCreateCreator}
              onEditCreator={handleEditCreator}
            />
          </TabPanel>

          {/* Content Library Tab */}
          <TabPanel value={activeTab} index={1}>
            <ContentList
              onUploadContent={handleUploadContent}
              onEditContent={handleEditContent}
              onBulkActions={handleBulkActions}
            />
          </TabPanel>
        </Box>
      </Card>

      {/* Forms and Dialogs */}
      <CreatorForm
        open={creatorFormOpen}
        onClose={() => setCreatorFormOpen(false)}
        onSuccess={handleFormSuccess}
        creator={selectedCreator}
      />

      <ContentUploadForm
        open={contentFormOpen}
        onClose={() => setContentFormOpen(false)}
        onSuccess={handleFormSuccess}
        content={selectedContent}
      />

      <BulkOperations
        open={bulkOpsOpen}
        onClose={() => setBulkOpsOpen(false)}
        onSuccess={handleFormSuccess}
        selectedContentIds={selectedContentIds}
      />
    </Box>
  )
}