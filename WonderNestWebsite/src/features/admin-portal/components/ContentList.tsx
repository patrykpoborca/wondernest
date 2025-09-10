import React, { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Avatar,
  Alert,
  CircularProgress,
  Menu,
  MenuItem,
  Tooltip,
  Checkbox,
  Toolbar,
  Grid,
  CardMedia
} from '@mui/material'
import {
  Add,
  Edit,
  MoreVert,
  CloudUpload,
  Publish,
  GetApp,
  Visibility,
  CheckCircle,
  Schedule,
  Cancel,
  SelectAll
} from '@mui/icons-material'

import { adminApiService } from '@/services/adminApi'
import { ContentItem } from '@/types/admin'

interface ContentListProps {
  onUploadContent: () => void
  onEditContent: (content: ContentItem) => void
  onBulkActions: (selectedIds: string[]) => void
}

export const ContentList: React.FC<ContentListProps> = ({
  onUploadContent,
  onEditContent,
  onBulkActions
}) => {
  const [content, setContent] = useState<ContentItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null)
  const [selectedContent, setSelectedContent] = useState<ContentItem | null>(null)
  const [selectedIds, setSelectedIds] = useState<string[]>([])

  useEffect(() => {
    loadContent()
  }, [])

  const loadContent = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await adminApiService.getContentList()
      // Ensure data is an array
      setContent(Array.isArray(data) ? data : [])
    } catch (err: any) {
      setError(err.error || 'Failed to load content')
      setContent([]) // Set to empty array on error
    } finally {
      setLoading(false)
    }
  }

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, item: ContentItem) => {
    setMenuAnchor(event.currentTarget)
    setSelectedContent(item)
  }

  const handleMenuClose = () => {
    setMenuAnchor(null)
    setSelectedContent(null)
  }

  const handleEditContent = () => {
    if (selectedContent) {
      onEditContent(selectedContent)
    }
    handleMenuClose()
  }

  const handlePublishContent = async () => {
    if (!selectedContent) return
    
    try {
      await adminApiService.publishContent(selectedContent.id)
      await loadContent()
    } catch (err: any) {
      setError(err.error || 'Failed to publish content')
    }
    handleMenuClose()
  }

  const handleSelectAll = () => {
    const contentArray = Array.isArray(content) ? content : []
    if (selectedIds.length === contentArray.length) {
      setSelectedIds([])
    } else {
      setSelectedIds(contentArray.map(item => item.id))
    }
  }

  const handleSelectItem = (id: string) => {
    setSelectedIds(prev => 
      prev.includes(id) 
        ? prev.filter(i => i !== id)
        : [...prev, id]
    )
  }

  const getStatusColor = (status: ContentItem['status']) => {
    switch (status) {
      case 'published': return 'success'
      case 'pending_review': return 'warning'
      case 'draft': return 'info'
      case 'rejected': return 'error'
      default: return 'default'
    }
  }

  const getStatusIcon = (status: ContentItem['status']) => {
    switch (status) {
      case 'published': return <CheckCircle />
      case 'pending_review': return <Schedule />
      case 'draft': return <Edit />
      case 'rejected': return <Cancel />
      default: return null
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString()
  }

  const formatFileSize = (bytes?: number) => {
    if (!bytes) return 'N/A'
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(1024))
    return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${sizes[i]}`
  }

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    )
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={600}>
            Content Library
          </Typography>
          <Typography variant="body2" color="textSecondary">
            Manage uploaded content and publishing status
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={onUploadContent}
        >
          Upload Content
        </Button>
      </Box>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Stats Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Avatar sx={{ bgcolor: 'primary.main', width: 40, height: 40 }}>
                  <CloudUpload />
                </Avatar>
                <Box>
                  <Typography variant="h6">{Array.isArray(content) ? content.length : 0}</Typography>
                  <Typography variant="body2" color="textSecondary">Total Items</Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Avatar sx={{ bgcolor: 'success.main', width: 40, height: 40 }}>
                  <CheckCircle />
                </Avatar>
                <Box>
                  <Typography variant="h6">
                    {Array.isArray(content) ? content.filter(c => c.status === 'published').length : 0}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">Published</Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Avatar sx={{ bgcolor: 'warning.main', width: 40, height: 40 }}>
                  <Schedule />
                </Avatar>
                <Box>
                  <Typography variant="h6">
                    {Array.isArray(content) ? content.filter(c => c.status === 'pending_review').length : 0}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">Pending</Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Avatar sx={{ bgcolor: 'info.main', width: 40, height: 40 }}>
                  <Edit />
                </Avatar>
                <Box>
                  <Typography variant="h6">
                    {Array.isArray(content) ? content.filter(c => c.status === 'draft').length : 0}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">Drafts</Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Bulk Actions Toolbar */}
      {selectedIds.length > 0 && (
        <Card sx={{ mb: 2 }}>
          <Toolbar>
            <Typography variant="subtitle1" sx={{ flex: 1 }}>
              {selectedIds.length} item(s) selected
            </Typography>
            <Button
              onClick={() => onBulkActions(selectedIds)}
              variant="contained"
              size="small"
              startIcon={<Publish />}
            >
              Bulk Actions
            </Button>
          </Toolbar>
        </Card>
      )}

      {/* Content Table */}
      <Card>
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell padding="checkbox">
                  <Checkbox
                    indeterminate={selectedIds.length > 0 && selectedIds.length < (Array.isArray(content) ? content.length : 0)}
                    checked={Array.isArray(content) && content.length > 0 && selectedIds.length === content.length}
                    onChange={handleSelectAll}
                  />
                </TableCell>
                <TableCell>Content</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Creator</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Size</TableCell>
                <TableCell>Upload Date</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {Array.isArray(content) && content.map((item) => (
                <TableRow key={item.id} hover selected={selectedIds.includes(item.id)}>
                  <TableCell padding="checkbox">
                    <Checkbox
                      checked={selectedIds.includes(item.id)}
                      onChange={() => handleSelectItem(item.id)}
                    />
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      {item.thumbnail_url ? (
                        <CardMedia
                          component="img"
                          sx={{ width: 50, height: 50, borderRadius: 1 }}
                          image={item.thumbnail_url}
                          alt={item.title}
                        />
                      ) : (
                        <Avatar sx={{ width: 50, height: 50 }}>
                          <CloudUpload />
                        </Avatar>
                      )}
                      <Box>
                        <Typography variant="body1" fontWeight={500}>
                          {item.title}
                        </Typography>
                        <Typography variant="body2" color="textSecondary">
                          {item.description || 'No description'}
                        </Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Chip size="small" label={item.content_type} />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {item.creator_name}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={item.status.replace('_', ' ')}
                      color={getStatusColor(item.status)}
                      icon={getStatusIcon(item.status)}
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {formatFileSize(item.file_size)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {formatDate(item.upload_date)}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Tooltip title="More actions">
                      <IconButton
                        onClick={(e) => handleMenuOpen(e, item)}
                      >
                        <MoreVert />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
              {(!Array.isArray(content) || content.length === 0) && !loading && (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                    <Typography color="textSecondary">
                      No content found. Upload your first content item to get started.
                    </Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>

      {/* Action Menu */}
      <Menu
        anchorEl={menuAnchor}
        open={Boolean(menuAnchor)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={handleEditContent}>
          <Edit sx={{ mr: 1 }} />
          Edit Content
        </MenuItem>
        {selectedContent?.status !== 'published' && (
          <MenuItem onClick={handlePublishContent}>
            <Publish sx={{ mr: 1 }} />
            Publish
          </MenuItem>
        )}
        <MenuItem>
          <Visibility sx={{ mr: 1 }} />
          Preview
        </MenuItem>
        <MenuItem>
          <GetApp sx={{ mr: 1 }} />
          Download
        </MenuItem>
      </Menu>
    </Box>
  )
}