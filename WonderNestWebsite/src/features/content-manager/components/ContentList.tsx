import React, { useState, useEffect } from 'react'
import {
  Box,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Chip,
  Typography,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Button,
  Tooltip,
  CircularProgress,
  Alert
} from '@mui/material'
import {
  Edit,
  Delete,
  Publish,
  Visibility,
  FilterList,
  Search,
  Archive
} from '@mui/icons-material'
import adminApi from '@/services/adminApi'
import { ContentType } from './ContentUploadForm'

interface ContentItem {
  id: string
  title: string
  description?: string
  contentType: ContentType
  status: 'draft' | 'ready' | 'published' | 'archived'
  price: number
  currency: string
  ageRangeMin?: number
  ageRangeMax?: number
  tags: string[]
  createdAt: string
  updatedAt: string
  publishedAt?: string
}

interface ContentListProps {
  onEdit?: (item: ContentItem) => void
}

export const ContentList: React.FC<ContentListProps> = ({ onEdit }) => {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [content, setContent] = useState<ContentItem[]>([])
  const [filteredContent, setFilteredContent] = useState<ContentItem[]>([])
  
  // Filter state
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [typeFilter, setTypeFilter] = useState<string>('all')

  useEffect(() => {
    fetchContent()
  }, [])

  useEffect(() => {
    applyFilters()
  }, [content, searchTerm, statusFilter, typeFilter])

  const fetchContent = async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await adminApi.get('/api/admin/seed/content/list')
      setContent(response.data.items || [])
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch content')
    } finally {
      setLoading(false)
    }
  }

  const applyFilters = () => {
    let filtered = [...content]

    // Search filter
    if (searchTerm) {
      filtered = filtered.filter(item =>
        item.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.tags.some(tag => tag.toLowerCase().includes(searchTerm.toLowerCase()))
      )
    }

    // Status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter(item => item.status === statusFilter)
    }

    // Type filter
    if (typeFilter !== 'all') {
      filtered = filtered.filter(item => item.contentType === typeFilter)
    }

    setFilteredContent(filtered)
  }

  const handlePublish = async (id: string) => {
    try {
      await adminApi.post(`/api/admin/seed/content/${id}/publish`)
      fetchContent() // Refresh list
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to publish content')
    }
  }

  const handleArchive = async (id: string) => {
    try {
      await adminApi.patch(`/api/admin/seed/content/${id}`, { status: 'archived' })
      fetchContent() // Refresh list
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to archive content')
    }
  }

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this content?')) {
      try {
        await adminApi.delete(`/api/admin/seed/content/${id}`)
        fetchContent() // Refresh list
      } catch (err: any) {
        setError(err.response?.data?.message || 'Failed to delete content')
      }
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'published': return 'success'
      case 'ready': return 'primary'
      case 'draft': return 'default'
      case 'archived': return 'error'
      default: return 'default'
    }
  }

  const getTypeIcon = (type: ContentType) => {
    switch (type) {
      case 'story': return '📖'
      case 'sticker_pack': return '🎨'
      case 'game': return '🎮'
      case 'activity': return '🎯'
      case 'educational_pack': return '📚'
      case 'template': return '📋'
      default: return '📄'
    }
  }

  if (loading) {
    return (
      <Card>
        <CardContent sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
          <Typography variant="h5" fontWeight={600}>
            Content Library
          </Typography>
          <Button
            variant="contained"
            onClick={fetchContent}
            size="small"
          >
            Refresh
          </Button>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
            {error}
          </Alert>
        )}

        {/* Filters */}
        <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
          <TextField
            placeholder="Search content..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            size="small"
            InputProps={{
              startAdornment: <Search sx={{ mr: 1, color: 'text.secondary' }} />
            }}
            sx={{ flexGrow: 1, maxWidth: 300 }}
          />
          
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Status</InputLabel>
            <Select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              label="Status"
            >
              <MenuItem value="all">All</MenuItem>
              <MenuItem value="draft">Draft</MenuItem>
              <MenuItem value="ready">Ready</MenuItem>
              <MenuItem value="published">Published</MenuItem>
              <MenuItem value="archived">Archived</MenuItem>
            </Select>
          </FormControl>

          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Type</InputLabel>
            <Select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              label="Type"
            >
              <MenuItem value="all">All</MenuItem>
              <MenuItem value="story">Story</MenuItem>
              <MenuItem value="sticker_pack">Sticker Pack</MenuItem>
              <MenuItem value="game">Game</MenuItem>
              <MenuItem value="activity">Activity</MenuItem>
              <MenuItem value="educational_pack">Educational Pack</MenuItem>
              <MenuItem value="template">Template</MenuItem>
            </Select>
          </FormControl>
        </Box>

        {/* Content Table */}
        <TableContainer component={Paper} variant="outlined">
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Type</TableCell>
                <TableCell>Title</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Price</TableCell>
                <TableCell>Age Range</TableCell>
                <TableCell>Tags</TableCell>
                <TableCell>Created</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredContent.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                    <Typography color="textSecondary">
                      No content found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                filteredContent.map((item) => (
                  <TableRow key={item.id} hover>
                    <TableCell>
                      <Typography variant="h6">
                        {getTypeIcon(item.contentType)}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box>
                        <Typography variant="body1" fontWeight={500}>
                          {item.title}
                        </Typography>
                        {item.description && (
                          <Typography variant="caption" color="textSecondary" noWrap sx={{ maxWidth: 200, display: 'block' }}>
                            {item.description}
                          </Typography>
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={item.status}
                        color={getStatusColor(item.status) as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      ${item.price.toFixed(2)} {item.currency}
                    </TableCell>
                    <TableCell>
                      {item.ageRangeMin && item.ageRangeMax
                        ? `${item.ageRangeMin}-${item.ageRangeMax} years`
                        : '-'}
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                        {item.tags.slice(0, 3).map(tag => (
                          <Chip key={tag} label={tag} size="small" variant="outlined" />
                        ))}
                        {item.tags.length > 3 && (
                          <Chip label={`+${item.tags.length - 3}`} size="small" variant="outlined" />
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="caption">
                        {new Date(item.createdAt).toLocaleDateString()}
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'flex-end' }}>
                        <Tooltip title="View">
                          <IconButton size="small">
                            <Visibility fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Edit">
                          <IconButton size="small" onClick={() => onEdit?.(item)}>
                            <Edit fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        {item.status === 'draft' || item.status === 'ready' ? (
                          <Tooltip title="Publish">
                            <IconButton 
                              size="small" 
                              color="primary"
                              onClick={() => handlePublish(item.id)}
                            >
                              <Publish fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        ) : item.status === 'published' ? (
                          <Tooltip title="Archive">
                            <IconButton 
                              size="small" 
                              color="warning"
                              onClick={() => handleArchive(item.id)}
                            >
                              <Archive fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        ) : null}
                        <Tooltip title="Delete">
                          <IconButton 
                            size="small" 
                            color="error"
                            onClick={() => handleDelete(item.id)}
                          >
                            <Delete fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>

        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mt: 2 }}>
          <Typography variant="body2" color="textSecondary">
            Showing {filteredContent.length} of {content.length} items
          </Typography>
        </Box>
      </CardContent>
    </Card>
  )
}