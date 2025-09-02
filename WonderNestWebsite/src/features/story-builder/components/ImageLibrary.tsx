import React, { useState, useCallback } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Grid,
  Typography,
  Tabs,
  Tab,
  TextField,
  InputAdornment,
  IconButton,
  Paper,
  Chip,
  CircularProgress,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Alert,
} from '@mui/material'
import {
  Close as CloseIcon,
  Search as SearchIcon,
  CloudUpload as UploadIcon,
  Collections as LibraryIcon,
  Image as ImageIcon,
  Check as CheckIcon,
  MoreVert as MoreVertIcon,
  Delete as DeleteIcon,
  Info as InfoIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'
import { FileUploadWithTags } from '@/components/common/FileUploadWithTags'
import { useGetUserFilesMutation, useDeleteFileMutation, useCheckFileUsageMutation } from '@/store/api/apiSlice'

const ImageCard = styled(Paper)<{ selected?: boolean }>(({ theme, selected }) => ({
  position: 'relative',
  paddingTop: '75%', // 4:3 aspect ratio
  cursor: 'pointer',
  overflow: 'hidden',
  border: selected ? `3px solid ${theme.palette.primary.main}` : '1px solid transparent',
  transition: 'all 0.2s',
  '&:hover': {
    boxShadow: theme.shadows[4],
    transform: 'scale(1.02)',
  },
}))

const ImageContent = styled('img')({
  position: 'absolute',
  top: 0,
  left: 0,
  width: '100%',
  height: '100%',
  objectFit: 'cover',
})

const SelectionOverlay = styled(Box)(({ theme }) => ({
  position: 'absolute',
  top: theme.spacing(1),
  right: theme.spacing(1),
  width: 24,
  height: 24,
  borderRadius: '50%',
  backgroundColor: theme.palette.primary.main,
  color: theme.palette.primary.contrastText,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
}))

const TabPanel: React.FC<{ value: number; index: number; children: React.ReactNode }> = ({ 
  value, 
  index, 
  children 
}) => (
  <div hidden={value !== index}>
    {value === index && <Box sx={{ pt: 2 }}>{children}</Box>}
  </div>
)

// Mock default library images for MVP
const DEFAULT_LIBRARY_IMAGES = [
  { id: 'lib1', url: 'https://picsum.photos/400/300?random=1', name: 'Forest Scene', category: 'nature' },
  { id: 'lib2', url: 'https://picsum.photos/400/300?random=2', name: 'Ocean Waves', category: 'nature' },
  { id: 'lib3', url: 'https://picsum.photos/400/300?random=3', name: 'Mountain Peak', category: 'nature' },
  { id: 'lib4', url: 'https://picsum.photos/400/300?random=4', name: 'Cartoon Animals', category: 'characters' },
  { id: 'lib5', url: 'https://picsum.photos/400/300?random=5', name: 'Space Adventure', category: 'fantasy' },
  { id: 'lib6', url: 'https://picsum.photos/400/300?random=6', name: 'Castle', category: 'fantasy' },
  { id: 'lib7', url: 'https://picsum.photos/400/300?random=7', name: 'Playground', category: 'everyday' },
  { id: 'lib8', url: 'https://picsum.photos/400/300?random=8', name: 'School', category: 'everyday' },
  { id: 'lib9', url: 'https://picsum.photos/400/300?random=9', name: 'Rainbow', category: 'nature' },
  { id: 'lib10', url: 'https://picsum.photos/400/300?random=10', name: 'Dinosaurs', category: 'characters' },
]

const CATEGORIES = ['all', 'nature', 'characters', 'fantasy', 'everyday', 'educational']

interface ImageLibraryProps {
  open: boolean
  onClose: () => void
  onSelectImage: (imageUrl: string) => void
  selectionMode?: 'single' | 'multiple'
  title?: string
}

export const ImageLibrary: React.FC<ImageLibraryProps> = ({
  open,
  onClose,
  onSelectImage,
  selectionMode = 'single',
  title = 'Select Image',
}) => {
  const [activeTab, setActiveTab] = useState(0)
  const [selectedImages, setSelectedImages] = useState<string[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [uploadedImages, setUploadedImages] = useState<any[]>([])
  const [fileMenuAnchor, setFileMenuAnchor] = useState<{ element: HTMLElement; file: any } | null>(null)
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false)
  const [fileToDelete, setFileToDelete] = useState<any>(null)
  const [fileUsageInfo, setFileUsageInfo] = useState<any>(null)
  const [deleteError, setDeleteError] = useState<string | null>(null)
  const [getUserFiles, { isLoading: isLoadingFiles }] = useGetUserFilesMutation()
  const [deleteFile] = useDeleteFileMutation()
  const [checkFileUsage, { isLoading: isCheckingUsage }] = useCheckFileUsageMutation()

  // Load user's uploaded images
  React.useEffect(() => {
    if (open && activeTab === 1) {
      loadUserImages()
    }
  }, [open, activeTab])

  const loadUserImages = async () => {
    try {
      const result = await getUserFiles({ category: 'game_asset' }).unwrap()
      if (result.data) {
        setUploadedImages(result.data)
      }
    } catch (error) {
      console.error('Failed to load user images:', error)
    }
  }

  const handleImageSelect = (imageUrl: string) => {
    if (selectionMode === 'single') {
      setSelectedImages([imageUrl])
    } else {
      setSelectedImages(prev => 
        prev.includes(imageUrl) 
          ? prev.filter(url => url !== imageUrl)
          : [...prev, imageUrl]
      )
    }
  }

  const handleConfirm = () => {
    if (selectionMode === 'single' && selectedImages.length > 0) {
      onSelectImage(selectedImages[0])
    } else {
      selectedImages.forEach(url => onSelectImage(url))
    }
    handleClose()
  }

  const handleClose = () => {
    setSelectedImages([])
    setSearchQuery('')
    setSelectedCategory('all')
    onClose()
  }

  const handleUploadComplete = (file: any) => {
    // Add the newly uploaded file to the list
    setUploadedImages(prev => [file, ...prev])
    // Auto-select the uploaded image
    if (file.url) {
      handleImageSelect(file.url)
    }
  }

  const handleFileMenuOpen = (event: React.MouseEvent<HTMLElement>, file: any) => {
    event.stopPropagation()
    setFileMenuAnchor({ element: event.currentTarget, file })
  }

  const handleFileMenuClose = () => {
    setFileMenuAnchor(null)
  }

  const handleDeleteClick = async (file: any) => {
    setFileToDelete(file)
    handleFileMenuClose()
    setDeleteError(null)
    
    // Check if file is used in any stories
    try {
      const usage = await checkFileUsage({ fileId: file.id }).unwrap()
      setFileUsageInfo(usage)
    } catch (error: any) {
      console.error('Failed to check file usage:', error)
      // If we can't check usage, assume it might be used to be safe
      setFileUsageInfo({ 
        isUsed: false, 
        checkFailed: true,
        error: error?.data?.error?.message || 'Unable to check if file is in use'
      })
    }
    
    setDeleteConfirmOpen(true)
  }

  const handleDeleteConfirm = async () => {
    if (!fileToDelete) return
    
    setDeleteError(null)
    
    try {
      // Use soft delete if file is being used or if we couldn't check
      const softDelete = fileUsageInfo?.isUsed || fileUsageInfo?.checkFailed || false
      await deleteFile({ fileId: fileToDelete.id, softDelete }).unwrap()
      
      // Remove from local state
      setUploadedImages(prev => prev.filter(f => f.id !== fileToDelete.id))
      
      // Clear selection if deleted file was selected
      setSelectedImages(prev => prev.filter(url => url !== fileToDelete.url))
      
      setDeleteConfirmOpen(false)
      setFileToDelete(null)
      setFileUsageInfo(null)
      setDeleteError(null)
    } catch (error: any) {
      console.error('Failed to delete file:', error)
      setDeleteError(
        error?.data?.error?.message || 
        error?.message || 
        'Failed to delete file. Please try again.'
      )
    }
  }

  const handleDeleteCancel = () => {
    setDeleteConfirmOpen(false)
    setFileToDelete(null)
    setFileUsageInfo(null)
    setDeleteError(null)
  }

  // Filter library images based on search and category
  const filteredLibraryImages = DEFAULT_LIBRARY_IMAGES.filter(image => {
    const matchesSearch = image.name.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesCategory = selectedCategory === 'all' || image.category === selectedCategory
    return matchesSearch && matchesCategory
  })

  return (
    <Dialog 
      open={open} 
      onClose={handleClose}
      maxWidth="lg"
      fullWidth
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Typography variant="h6">{title}</Typography>
          <IconButton onClick={handleClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>

      <DialogContent>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={activeTab} onChange={(_, value) => setActiveTab(value)}>
            <Tab 
              icon={<LibraryIcon />} 
              label="Image Library" 
              iconPosition="start"
            />
            <Tab 
              icon={<UploadIcon />} 
              label="My Uploads" 
              iconPosition="start"
            />
          </Tabs>
        </Box>

        {/* Library Tab */}
        <TabPanel value={activeTab} index={0}>
          <Box sx={{ mb: 2 }}>
            <Grid container spacing={2} alignItems="center">
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  size="small"
                  placeholder="Search images..."
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
                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                  {CATEGORIES.map(category => (
                    <Chip
                      key={category}
                      label={category.charAt(0).toUpperCase() + category.slice(1)}
                      onClick={() => setSelectedCategory(category)}
                      color={selectedCategory === category ? 'primary' : 'default'}
                      size="small"
                    />
                  ))}
                </Box>
              </Grid>
            </Grid>
          </Box>

          <Grid container spacing={2}>
            {filteredLibraryImages.map(image => (
              <Grid item xs={6} sm={4} md={3} key={image.id}>
                <ImageCard 
                  selected={selectedImages.includes(image.url)}
                  onClick={() => handleImageSelect(image.url)}
                >
                  <ImageContent src={image.url} alt={image.name} />
                  {selectedImages.includes(image.url) && (
                    <SelectionOverlay>
                      <CheckIcon sx={{ fontSize: 16 }} />
                    </SelectionOverlay>
                  )}
                </ImageCard>
                <Typography variant="caption" sx={{ mt: 0.5, display: 'block' }}>
                  {image.name}
                </Typography>
              </Grid>
            ))}
          </Grid>

          {filteredLibraryImages.length === 0 && (
            <Box sx={{ textAlign: 'center', py: 4 }}>
              <ImageIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
              <Typography color="text.secondary">
                No images found matching your criteria
              </Typography>
            </Box>
          )}
        </TabPanel>

        {/* Uploads Tab */}
        <TabPanel value={activeTab} index={1}>
          <Box sx={{ mb: 3 }}>
            <FileUploadWithTags
              accept={{
                'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'],
              }}
              maxSize={5 * 1024 * 1024} // 5MB limit as per requirements
              category="game_asset"
              isPublic={false}
              onUploadComplete={handleUploadComplete}
              requireTags={true}
              minTags={2}
            />
          </Box>

          {isLoadingFiles ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : (
            <Grid container spacing={2}>
              {uploadedImages.map(file => (
                <Grid item xs={6} sm={4} md={3} key={file.id}>
                  <Box sx={{ position: 'relative' }}>
                    <ImageCard 
                      selected={selectedImages.includes(file.url)}
                      onClick={() => handleImageSelect(file.url)}
                    >
                      <ImageContent src={file.url} alt={file.originalName} />
                      {selectedImages.includes(file.url) && (
                        <SelectionOverlay>
                          <CheckIcon sx={{ fontSize: 16 }} />
                        </SelectionOverlay>
                      )}
                      {/* More options button */}
                      <IconButton
                        onClick={(e) => handleFileMenuOpen(e, file)}
                        sx={{
                          position: 'absolute',
                          top: 4,
                          right: 4,
                          backgroundColor: 'rgba(255, 255, 255, 0.9)',
                          '&:hover': {
                            backgroundColor: 'rgba(255, 255, 255, 1)',
                          },
                          padding: 0.5,
                        }}
                        size="small"
                      >
                        <MoreVertIcon fontSize="small" />
                      </IconButton>
                    </ImageCard>
                    <Typography variant="caption" sx={{ mt: 0.5, display: 'block' }} noWrap>
                      {file.originalName}
                    </Typography>
                  </Box>
                </Grid>
              ))}
            </Grid>
          )}

          {!isLoadingFiles && uploadedImages.length === 0 && (
            <Box sx={{ textAlign: 'center', py: 4 }}>
              <ImageIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
              <Typography color="text.secondary">
                No uploaded images yet. Upload your first image above!
              </Typography>
            </Box>
          )}
        </TabPanel>
      </DialogContent>

      <DialogActions>
        <Button onClick={handleClose}>Cancel</Button>
        <Button 
          onClick={handleConfirm}
          variant="contained"
          disabled={selectedImages.length === 0}
        >
          {selectionMode === 'single' ? 'Select Image' : `Select ${selectedImages.length} Images`}
        </Button>
      </DialogActions>

      {/* File Options Menu */}
      <Menu
        anchorEl={fileMenuAnchor?.element}
        open={Boolean(fileMenuAnchor)}
        onClose={handleFileMenuClose}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
      >
        <MenuItem onClick={() => fileMenuAnchor && handleDeleteClick(fileMenuAnchor.file)}>
          <ListItemIcon>
            <DeleteIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Delete Image</ListItemText>
        </MenuItem>
      </Menu>

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteConfirmOpen}
        onClose={handleDeleteCancel}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <DeleteIcon color="error" />
            <Typography variant="h6">Delete Image</Typography>
          </Box>
        </DialogTitle>
        <DialogContent>
          {isCheckingUsage ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
              <CircularProgress />
            </Box>
          ) : (
            <>
              <Typography variant="body1" gutterBottom>
                Are you sure you want to delete "{fileToDelete?.originalName}"?
              </Typography>
              
              {/* Error message if deletion failed */}
              {deleteError && (
                <Alert severity="error" sx={{ mt: 2, mb: 2 }}>
                  <Typography variant="body2">
                    {deleteError}
                  </Typography>
                </Alert>
              )}
              
              {/* Warning if usage check failed */}
              {fileUsageInfo?.checkFailed && (
                <Alert severity="warning" sx={{ mt: 2 }}>
                  <Typography variant="body2" sx={{ fontWeight: 500, mb: 1 }}>
                    Unable to verify if this image is used in stories
                  </Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    {fileUsageInfo.error}
                  </Typography>
                  <Typography variant="body2" sx={{ mt: 2, fontStyle: 'italic' }}>
                    To be safe, the image will be soft deleted to prevent breaking any stories that might be using it.
                  </Typography>
                </Alert>
              )}
              
              {/* Show usage info if file is being used */}
              {fileUsageInfo?.isUsed && !fileUsageInfo?.checkFailed && (
                <Alert severity="warning" sx={{ mt: 2 }}>
                  <Typography variant="body2" sx={{ fontWeight: 500, mb: 1 }}>
                    This image is currently used in:
                  </Typography>
                  <Box component="ul" sx={{ mt: 1, mb: 0, pl: 2 }}>
                    {fileUsageInfo.stories?.map((story: any) => (
                      <li key={story.id}>
                        <Typography variant="body2">
                          {story.title} ({story.pageCount} page{story.pageCount !== 1 ? 's' : ''})
                        </Typography>
                      </li>
                    ))}
                  </Box>
                  <Typography variant="body2" sx={{ mt: 2, fontStyle: 'italic' }}>
                    The image will be marked as deleted but preserved to prevent breaking these stories.
                    It will no longer appear in your uploads.
                  </Typography>
                </Alert>
              )}
              
              {/* Info if file is not being used */}
              {!fileUsageInfo?.isUsed && !fileUsageInfo?.checkFailed && (
                <Alert severity="info" sx={{ mt: 2 }}>
                  <Typography variant="body2">
                    This image is not currently used in any stories and will be permanently deleted.
                  </Typography>
                </Alert>
              )}
            </>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDeleteCancel}>Cancel</Button>
          <Button 
            onClick={handleDeleteConfirm}
            color="error"
            variant="contained"
            disabled={isCheckingUsage}
          >
            {deleteError ? 'Retry' : 
             fileUsageInfo?.isUsed || fileUsageInfo?.checkFailed ? 'Soft Delete' : 'Delete Permanently'}
          </Button>
        </DialogActions>
      </Dialog>
    </Dialog>
  )
}