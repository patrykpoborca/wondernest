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
} from '@mui/material'
import {
  Close as CloseIcon,
  Search as SearchIcon,
  CloudUpload as UploadIcon,
  Collections as LibraryIcon,
  Image as ImageIcon,
  Check as CheckIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'
import { FileUpload } from '@/components/common/FileUpload'
import { useGetUserFilesMutation } from '@/store/api/apiSlice'

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
  const [getUserFiles, { isLoading: isLoadingFiles }] = useGetUserFilesMutation()

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
            <FileUpload
              accept={{
                'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'],
              }}
              maxSize={5 * 1024 * 1024} // 5MB limit as per requirements
              category="game_asset"
              isPublic={false}
              onUploadComplete={handleUploadComplete}
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
                  </ImageCard>
                  <Typography variant="caption" sx={{ mt: 0.5, display: 'block' }} noWrap>
                    {file.originalName}
                  </Typography>
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
    </Dialog>
  )
}