import React, { useState, useRef, useCallback } from 'react'
import {
  Box,
  Paper,
  Typography,
  IconButton,
  Button,
  Toolbar,
  Divider,
  Tooltip,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
} from '@mui/material'
import {
  ZoomIn as ZoomInIcon,
  ZoomOut as ZoomOutIcon,
  CenterFocusStrong as FitToScreenIcon,
  Add as AddIcon,
  TextFields as TextIcon,
  Image as ImageIcon,
  Palette as BackgroundIcon,
  Undo as UndoIcon,
  Redo as RedoIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'

import { StoryPage, TextBlock, PopupImage } from '../types/story'
import { PageEditor } from './PageEditor'
import { ImageLibrary } from './ImageLibrary'

const CanvasContainer = styled(Box)(({ theme }) => ({
  flex: 1,
  display: 'flex',
  flexDirection: 'column',
  backgroundColor: theme.palette.grey[50],
  position: 'relative',
  overflow: 'hidden',
}))

const CanvasToolbar = styled(Toolbar)(({ theme }) => ({
  backgroundColor: theme.palette.background.paper,
  borderBottom: `1px solid ${theme.palette.divider}`,
  minHeight: 48,
  paddingLeft: theme.spacing(2),
  paddingRight: theme.spacing(2),
}))

const CanvasViewport = styled(Box)(({ theme }) => ({
  flex: 1,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  padding: theme.spacing(2),
  overflow: 'auto',
  position: 'relative',
}))

const StoryPageCanvas = styled(Paper)<{ zoom: number }>(({ theme, zoom }) => ({
  width: 800,
  height: 600,
  backgroundColor: theme.palette.background.paper,
  border: `2px solid ${theme.palette.divider}`,
  borderRadius: theme.spacing(2),
  position: 'relative',
  overflow: 'hidden',
  transform: `scale(${zoom})`,
  transformOrigin: 'center',
  cursor: 'default',
  transition: 'transform 0.2s ease-in-out',
}))

const EmptyPageMessage = styled(Box)(({ theme }) => ({
  position: 'absolute',
  top: '50%',
  left: '50%',
  transform: 'translate(-50%, -50%)',
  textAlign: 'center',
  color: theme.palette.text.disabled,
  pointerEvents: 'none',
  userSelect: 'none',
}))

const AddContentFab = styled(Button)(({ theme }) => ({
  position: 'absolute',
  bottom: theme.spacing(3),
  right: theme.spacing(3),
  borderRadius: theme.spacing(3),
  boxShadow: theme.shadows[4],
  zIndex: 10,
}))

interface StoryCanvasProps {
  page: StoryPage | null
  onPageUpdate: (page: StoryPage) => void
  isReadOnly?: boolean
  showPageInfo?: boolean
}

export const StoryCanvas: React.FC<StoryCanvasProps> = ({
  page,
  onPageUpdate,
  isReadOnly = false,
  showPageInfo = true,
}) => {
  const [zoom, setZoom] = useState(0.75)
  const [addMenuAnchor, setAddMenuAnchor] = useState<null | HTMLElement>(null)
  const [imageLibraryOpen, setImageLibraryOpen] = useState(false)
  const [imageLibraryMode, setImageLibraryMode] = useState<'background' | 'popup'>('background')
  const canvasRef = useRef<HTMLDivElement>(null)

  const handleZoomIn = useCallback(() => {
    setZoom(prev => Math.min(prev + 0.1, 2))
  }, [])

  const handleZoomOut = useCallback(() => {
    setZoom(prev => Math.max(prev - 0.1, 0.3))
  }, [])

  const handleFitToScreen = useCallback(() => {
    if (canvasRef.current) {
      const container = canvasRef.current
      const containerWidth = container.clientWidth - 32 // Account for padding
      const containerHeight = container.clientHeight - 32
      const pageAspectRatio = 800 / 600
      const containerAspectRatio = containerWidth / containerHeight

      let newZoom
      if (containerAspectRatio > pageAspectRatio) {
        // Container is wider, fit to height
        newZoom = containerHeight / 600
      } else {
        // Container is taller, fit to width
        newZoom = containerWidth / 800
      }

      setZoom(Math.min(Math.max(newZoom, 0.3), 2))
    }
  }, [])

  const handleAddText = useCallback(() => {
    if (!page || isReadOnly) return

    const newTextBlock: TextBlock = {
      id: `text_${Date.now()}`,
      position: { x: 100, y: 100 },
      variants: {
        easy: 'Click to edit text',
        medium: 'Click to edit text',
        hard: 'Click to edit text',
      },
      vocabularyWords: [],
    }

    const updatedPage = {
      ...page,
      textBlocks: [...page.textBlocks, newTextBlock],
    }

    onPageUpdate(updatedPage)
    setAddMenuAnchor(null)
  }, [page, onPageUpdate, isReadOnly])

  const handleAddImage = useCallback(() => {
    if (!page || isReadOnly) return
    setImageLibraryMode('popup')
    setImageLibraryOpen(true)
    setAddMenuAnchor(null)
  }, [page, isReadOnly])

  const handleSetBackground = useCallback(() => {
    if (!page || isReadOnly) return
    setImageLibraryMode('background')
    setImageLibraryOpen(true)
    setAddMenuAnchor(null)
  }, [page, isReadOnly])

  const handleTextBlockUpdate = useCallback((updatedTextBlock: TextBlock) => {
    if (!page) return

    const updatedPage = {
      ...page,
      textBlocks: page.textBlocks.map(block =>
        block.id === updatedTextBlock.id ? updatedTextBlock : block
      ),
    }

    onPageUpdate(updatedPage)
  }, [page, onPageUpdate])

  const handleTextBlockDelete = useCallback((textBlockId: string) => {
    if (!page) return

    const updatedPage = {
      ...page,
      textBlocks: page.textBlocks.filter(block => block.id !== textBlockId),
    }

    onPageUpdate(updatedPage)
  }, [page, onPageUpdate])

  const handleImageUpdate = useCallback((updatedImage: PopupImage) => {
    if (!page) return

    const updatedPage = {
      ...page,
      popupImages: page.popupImages.map(img =>
        img.id === updatedImage.id ? updatedImage : img
      ),
    }

    onPageUpdate(updatedPage)
  }, [page, onPageUpdate])

  const handleImageDelete = useCallback((imageId: string) => {
    if (!page) return

    const updatedPage = {
      ...page,
      popupImages: page.popupImages.filter(img => img.id !== imageId),
    }

    onPageUpdate(updatedPage)
  }, [page, onPageUpdate])

  const handleImageSelect = useCallback((imageUrl: string) => {
    if (!page) return

    if (imageLibraryMode === 'background') {
      // Set as page background
      const updatedPage = {
        ...page,
        background: imageUrl,
      }
      onPageUpdate(updatedPage)
    } else {
      // Add as popup image
      const newPopupImage: PopupImage = {
        id: `img_${Date.now()}`,
        imageUrl: imageUrl,
        triggerWord: 'click here',
        position: { x: 200, y: 200 },
        size: { width: 150, height: 150 },
      }
      
      const updatedPage = {
        ...page,
        popupImages: [...page.popupImages, newPopupImage],
      }
      onPageUpdate(updatedPage)
    }
    
    setImageLibraryOpen(false)
  }, [page, onPageUpdate, imageLibraryMode])

  const isEmpty = !page || (
    page.textBlocks.length === 0 && 
    page.popupImages.length === 0 && 
    !page.background
  )

  if (!page) {
    return (
      <CanvasContainer>
        <Box sx={{ 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center', 
          height: '100%' 
        }}>
          <Typography variant="h6" color="text.secondary">
            Select a page to start editing
          </Typography>
        </Box>
      </CanvasContainer>
    )
  }

  return (
    <CanvasContainer>
      {/* Toolbar */}
      <CanvasToolbar variant="dense">
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexGrow: 1 }}>
          {showPageInfo && (
            <>
              <Typography variant="h6" sx={{ fontWeight: 500 }}>
                Page {page.pageNumber}
              </Typography>
              <Divider orientation="vertical" flexItem sx={{ mx: 1 }} />
            </>
          )}

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <Tooltip title="Zoom out">
              <IconButton size="small" onClick={handleZoomOut} disabled={zoom <= 0.3}>
                <ZoomOutIcon />
              </IconButton>
            </Tooltip>

            <Typography 
              variant="body2" 
              sx={{ minWidth: 48, textAlign: 'center', fontFamily: 'monospace' }}
            >
              {Math.round(zoom * 100)}%
            </Typography>

            <Tooltip title="Zoom in">
              <IconButton size="small" onClick={handleZoomIn} disabled={zoom >= 2}>
                <ZoomInIcon />
              </IconButton>
            </Tooltip>

            <Tooltip title="Fit to screen">
              <IconButton size="small" onClick={handleFitToScreen}>
                <FitToScreenIcon />
              </IconButton>
            </Tooltip>
          </Box>
        </Box>

        {!isReadOnly && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Tooltip title="Undo">
              <span>
                <IconButton size="small" disabled>
                  <UndoIcon />
                </IconButton>
              </span>
            </Tooltip>

            <Tooltip title="Redo">
              <span>
                <IconButton size="small" disabled>
                  <RedoIcon />
                </IconButton>
              </span>
            </Tooltip>

            <Divider orientation="vertical" flexItem sx={{ mx: 1 }} />

            <Button
              size="small"
              startIcon={<AddIcon />}
              onClick={(e) => setAddMenuAnchor(e.currentTarget)}
              variant="outlined"
            >
              Add Content
            </Button>
          </Box>
        )}
      </CanvasToolbar>

      {/* Canvas Viewport */}
      <CanvasViewport ref={canvasRef}>
        <StoryPageCanvas 
          zoom={zoom} 
          elevation={3}
          sx={{
            backgroundImage: page.background ? `url(${page.background})` : 'none',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            backgroundRepeat: 'no-repeat',
          }}
        >
          {isEmpty && (
            <EmptyPageMessage>
              <Box sx={{ mb: 2 }}>
                <Typography variant="h6" gutterBottom>
                  This page is empty
                </Typography>
                <Typography variant="body2">
                  Add text, images, or set a background to get started
                </Typography>
              </Box>
            </EmptyPageMessage>
          )}

          {/* Page Editor */}
          <PageEditor
            page={page}
            onTextBlockUpdate={handleTextBlockUpdate}
            onTextBlockDelete={handleTextBlockDelete}
            onImageUpdate={handleImageUpdate}
            onImageDelete={handleImageDelete}
            isReadOnly={isReadOnly}
            zoom={zoom}
          />

          {/* Quick Add Button for Empty Pages */}
          {isEmpty && !isReadOnly && (
            <AddContentFab
              variant="contained"
              startIcon={<AddIcon />}
              onClick={(e) => setAddMenuAnchor(e.currentTarget)}
            >
              Add Content
            </AddContentFab>
          )}
        </StoryPageCanvas>
      </CanvasViewport>

      {/* Add Content Menu */}
      <Menu
        anchorEl={addMenuAnchor}
        open={Boolean(addMenuAnchor)}
        onClose={() => setAddMenuAnchor(null)}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'left',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
      >
        <MenuItem onClick={handleAddText}>
          <ListItemIcon>
            <TextIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Add Text</ListItemText>
        </MenuItem>

        <MenuItem onClick={handleAddImage}>
          <ListItemIcon>
            <ImageIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Add Image</ListItemText>
        </MenuItem>

        <Divider />

        <MenuItem onClick={handleSetBackground}>
          <ListItemIcon>
            <BackgroundIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Set Background</ListItemText>
        </MenuItem>
      </Menu>

      {/* Image Library Dialog */}
      <ImageLibrary
        open={imageLibraryOpen}
        onClose={() => setImageLibraryOpen(false)}
        onSelectImage={handleImageSelect}
        title={imageLibraryMode === 'background' ? 'Select Background Image' : 'Add Image to Page'}
      />
    </CanvasContainer>
  )
}