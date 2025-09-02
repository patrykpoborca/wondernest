import React, { useState, useEffect } from 'react'
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  CardMedia,
  CardContent,
  CardActions,
  IconButton,
  Chip,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  TextField,
  InputAdornment,
  CircularProgress,
  Alert,
  Tabs,
  Tab,
  Tooltip,
} from '@mui/material'
import {
  Delete as DeleteIcon,
  Download as DownloadIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  Image as ImageIcon,
  PictureAsPdf as PdfIcon,
  InsertDriveFile as FileIcon,
  Warning as WarningIcon,
  Tag as TagIcon,
} from '@mui/icons-material'
import { 
  useGetUserFilesMutation, 
  useDeleteFileMutation,
  useCheckFileUsageMutation 
} from '@/store/api/apiSlice'
import { formatDistanceToNow } from 'date-fns'

interface FileItem {
  id: string
  originalName: string
  mimeType: string
  fileSize: number
  url: string
  tags: string[]
  category: string
  isPublic: boolean
  createdAt: string
  usageCount?: number
  usedInStories?: string[]
}

interface TabPanelProps {
  children?: React.ReactNode
  index: number
  value: number
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index }) => {
  return (
    <div hidden={value !== index}>
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  )
}

export const FileManagementScreen: React.FC = () => {
  const [files, setFiles] = useState<FileItem[]>([])
  const [filteredFiles, setFilteredFiles] = useState<FileItem[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedTags, setSelectedTags] = useState<string[]>([])
  const [allTags, setAllTags] = useState<string[]>([])
  const [deleteDialog, setDeleteDialog] = useState<{
    open: boolean
    file: FileItem | null
    hasUsage: boolean
  }>({ open: false, file: null, hasUsage: false })
  const [tabValue, setTabValue] = useState(0)
  const [selectedCategory, setSelectedCategory] = useState<string>('all')

  const [getUserFiles, { isLoading: isLoadingFiles }] = useGetUserFilesMutation()
  const [deleteFile, { isLoading: isDeleting }] = useDeleteFileMutation()
  const [checkFileUsage] = useCheckFileUsageMutation()

  // Load user files
  useEffect(() => {
    loadFiles()
  }, [selectedCategory])

  const loadFiles = async () => {
    try {
      const result = await getUserFiles({
        category: selectedCategory === 'all' ? undefined : selectedCategory,
      }).unwrap()
      
      if (result.data) {
        setFiles(result.data)
        setFilteredFiles(result.data)
        
        // Extract all unique tags
        const tags = new Set<string>()
        result.data.forEach((file: FileItem) => {
          file.tags?.forEach(tag => tags.add(tag))
        })
        setAllTags(Array.from(tags).sort())
      }
    } catch (error) {
      console.error('Failed to load files:', error)
    }
  }

  // Filter files based on search and tags
  useEffect(() => {
    let filtered = files

    // Filter by search query
    if (searchQuery) {
      filtered = filtered.filter(file =>
        file.originalName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        file.tags?.some(tag => tag.toLowerCase().includes(searchQuery.toLowerCase()))
      )
    }

    // Filter by selected tags
    if (selectedTags.length > 0) {
      filtered = filtered.filter(file =>
        selectedTags.every(tag => file.tags?.includes(tag))
      )
    }

    setFilteredFiles(filtered)
  }, [searchQuery, selectedTags, files])

  const handleDeleteClick = async (file: FileItem) => {
    // Check if file is used in any stories
    try {
      const usage = await checkFileUsage({ fileId: file.id }).unwrap()
      setDeleteDialog({
        open: true,
        file,
        hasUsage: usage.data?.usedInStories?.length > 0,
      })
    } catch {
      // If check fails, show dialog anyway
      setDeleteDialog({ open: true, file, hasUsage: false })
    }
  }

  const handleDeleteConfirm = async () => {
    if (!deleteDialog.file) return

    try {
      await deleteFile({ 
        fileId: deleteDialog.file.id,
        softDelete: deleteDialog.hasUsage, // Soft delete if used in stories
      }).unwrap()
      
      // Reload files after deletion
      await loadFiles()
      setDeleteDialog({ open: false, file: null, hasUsage: false })
    } catch (error) {
      console.error('Failed to delete file:', error)
    }
  }

  const toggleTag = (tag: string) => {
    setSelectedTags(prev =>
      prev.includes(tag)
        ? prev.filter(t => t !== tag)
        : [...prev, tag]
    )
  }

  const getFileIcon = (mimeType: string) => {
    if (mimeType.startsWith('image/')) return <ImageIcon />
    if (mimeType === 'application/pdf') return <PdfIcon />
    return <FileIcon />
  }

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  const categories = [
    { value: 'all', label: 'All Files' },
    { value: 'profile_picture', label: 'Profile Pictures' },
    { value: 'content', label: 'Content' },
    { value: 'document', label: 'Documents' },
    { value: 'game_asset', label: 'Game Assets' },
    { value: 'artwork', label: 'Artwork' },
  ]

  return (
    <Container maxWidth="xl" sx={{ py: 4 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          File Management
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Manage your uploaded files, view tags, and control file usage
        </Typography>
      </Box>

      {/* Search and Filters */}
      <Box sx={{ mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              placeholder="Search files by name or tag..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <FilterIcon color="action" />
              <Typography variant="body2" sx={{ mr: 1 }}>
                Categories:
              </Typography>
              <Tabs
                value={tabValue}
                onChange={(_, value) => {
                  setTabValue(value)
                  setSelectedCategory(categories[value].value)
                }}
                variant="scrollable"
                scrollButtons="auto"
              >
                {categories.map((cat, index) => (
                  <Tab key={cat.value} label={cat.label} />
                ))}
              </Tabs>
            </Box>
          </Grid>
        </Grid>

        {/* Tag Filter */}
        {allTags.length > 0 && (
          <Box sx={{ mt: 2 }}>
            <Typography variant="body2" sx={{ mb: 1 }}>
              Filter by tags:
            </Typography>
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
              {allTags.map(tag => (
                <Chip
                  key={tag}
                  label={tag}
                  onClick={() => toggleTag(tag)}
                  color={selectedTags.includes(tag) ? 'primary' : 'default'}
                  size="small"
                  icon={<TagIcon />}
                />
              ))}
            </Box>
          </Box>
        )}
      </Box>

      {/* File Grid */}
      {isLoadingFiles ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress />
        </Box>
      ) : filteredFiles.length === 0 ? (
        <Alert severity="info">
          No files found matching your criteria
        </Alert>
      ) : (
        <Grid container spacing={3}>
          {filteredFiles.map(file => (
            <Grid item xs={12} sm={6} md={4} lg={3} key={file.id}>
              <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                {/* File Preview */}
                {file.mimeType.startsWith('image/') ? (
                  <CardMedia
                    component="img"
                    height="200"
                    image={file.url}
                    alt={file.originalName}
                    sx={{ objectFit: 'cover' }}
                  />
                ) : (
                  <Box
                    sx={{
                      height: 200,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      bgcolor: 'grey.100',
                    }}
                  >
                    {getFileIcon(file.mimeType)}
                  </Box>
                )}

                <CardContent sx={{ flexGrow: 1 }}>
                  <Typography variant="body2" noWrap title={file.originalName}>
                    {file.originalName}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {formatFileSize(file.fileSize)} • {formatDistanceToNow(new Date(file.createdAt), { addSuffix: true })}
                  </Typography>

                  {/* Tags */}
                  {file.tags && file.tags.length > 0 && (
                    <Box sx={{ mt: 1, display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {file.tags.map(tag => (
                        <Chip
                          key={tag}
                          label={tag}
                          size="small"
                          variant="outlined"
                        />
                      ))}
                    </Box>
                  )}

                  {/* Usage indicator */}
                  {file.usageCount && file.usageCount > 0 && (
                    <Alert severity="info" sx={{ mt: 1, py: 0 }}>
                      <Typography variant="caption">
                        Used in {file.usageCount} {file.usageCount === 1 ? 'story' : 'stories'}
                      </Typography>
                    </Alert>
                  )}
                </CardContent>

                <CardActions>
                  <Tooltip title="Download">
                    <IconButton
                      size="small"
                      href={file.url}
                      download={file.originalName}
                      target="_blank"
                    >
                      <DownloadIcon />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Delete">
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleDeleteClick(file)}
                      disabled={isDeleting}
                    >
                      <DeleteIcon />
                    </IconButton>
                  </Tooltip>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteDialog.open}
        onClose={() => setDeleteDialog({ open: false, file: null, hasUsage: false })}
      >
        <DialogTitle>
          {deleteDialog.hasUsage ? 'File In Use' : 'Delete File'}
        </DialogTitle>
        <DialogContent>
          {deleteDialog.hasUsage ? (
            <>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <WarningIcon color="warning" sx={{ mr: 1 }} />
                <Typography variant="body2" color="warning.main">
                  This file is currently being used in stories
                </Typography>
              </Box>
              <DialogContentText>
                This file is being used in existing stories. If you proceed, the file will be
                removed from your library but will remain available for existing stories to
                prevent them from breaking.
              </DialogContentText>
              <DialogContentText sx={{ mt: 2 }}>
                Are you sure you want to remove "{deleteDialog.file?.originalName}" from your library?
              </DialogContentText>
            </>
          ) : (
            <DialogContentText>
              Are you sure you want to permanently delete "{deleteDialog.file?.originalName}"?
              This action cannot be undone.
            </DialogContentText>
          )}
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setDeleteDialog({ open: false, file: null, hasUsage: false })}
            disabled={isDeleting}
          >
            Cancel
          </Button>
          <Button
            onClick={handleDeleteConfirm}
            color={deleteDialog.hasUsage ? 'warning' : 'error'}
            variant="contained"
            disabled={isDeleting}
            startIcon={isDeleting ? <CircularProgress size={16} /> : <DeleteIcon />}
          >
            {deleteDialog.hasUsage ? 'Remove from Library' : 'Delete'}
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  )
}

export default FileManagementScreen