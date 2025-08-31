import React, { useState, useRef, useCallback } from 'react'
import {
  Box,
  Paper,
  Typography,
  TextField,
  IconButton,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Divider,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Tabs,
  Tab,
  Chip,
} from '@mui/material'
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  DragIndicator as DragIcon,
  Close as CloseIcon,
  Add as AddIcon,
  Remove as RemoveIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'

import { StoryPage, TextBlock, PopupImage } from '../types/story'
import { DraggableImage } from './DraggableImage'

const DraggableTextBlock = styled(Paper)<{ 
  selected?: boolean 
  zoom?: number 
}>(({ theme, selected, zoom = 1 }) => ({
  position: 'absolute',
  minWidth: 120,
  minHeight: 60,
  padding: theme.spacing(1),
  cursor: 'move',
  border: selected ? `2px solid ${theme.palette.primary.main}` : `1px dashed ${theme.palette.grey[400]}`,
  backgroundColor: selected ? theme.palette.primary.light : theme.palette.background.paper,
  transition: 'all 0.2s ease-in-out',
  transform: `scale(${1 / zoom})`,
  transformOrigin: 'top left',
  '&:hover': {
    boxShadow: theme.shadows[4],
    borderColor: selected ? theme.palette.primary.main : theme.palette.primary.light,
  },
  '& .drag-handle': {
    position: 'absolute',
    top: -4,
    right: -4,
    opacity: 0,
    transition: 'opacity 0.2s',
  },
  '&:hover .drag-handle': {
    opacity: 1,
  },
}))

const PopupImageMarker = styled(Box)<{ zoom?: number }>(({ theme, zoom = 1 }) => ({
  position: 'absolute',
  width: 24,
  height: 24,
  backgroundColor: theme.palette.secondary.main,
  borderRadius: '50%',
  cursor: 'pointer',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  color: theme.palette.secondary.contrastText,
  fontSize: 12,
  fontWeight: 'bold',
  transform: `scale(${1 / zoom})`,
  transformOrigin: 'center',
  '&:hover': {
    backgroundColor: theme.palette.secondary.dark,
    transform: `scale(${1.2 / zoom})`,
  },
}))

interface TabPanelProps {
  children?: React.ReactNode
  index: number
  value: number
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index }) => (
  <div hidden={value !== index}>
    {value === index && <Box sx={{ p: 2 }}>{children}</Box>}
  </div>
)

interface TextBlockEditorProps {
  textBlock: TextBlock
  onUpdate: (textBlock: TextBlock) => void
  onClose: () => void
}

const TextBlockEditor: React.FC<TextBlockEditorProps> = ({ textBlock, onUpdate, onClose }) => {
  const [activeTab, setActiveTab] = useState(0)
  const [editedBlock, setEditedBlock] = useState<TextBlock>({ ...textBlock })
  const [newVocabWord, setNewVocabWord] = useState('')

  const handleSave = () => {
    onUpdate(editedBlock)
    onClose()
  }

  const handleVariantChange = (difficulty: 'easy' | 'medium' | 'hard', text: string) => {
    setEditedBlock(prev => ({
      ...prev,
      variants: {
        ...prev.variants,
        [difficulty]: text,
      },
    }))
  }

  const handleAddVocabWord = () => {
    if (newVocabWord.trim() && !editedBlock.vocabularyWords.includes(newVocabWord.trim())) {
      setEditedBlock(prev => ({
        ...prev,
        vocabularyWords: [...prev.vocabularyWords, newVocabWord.trim()],
      }))
      setNewVocabWord('')
    }
  }

  const handleRemoveVocabWord = (word: string) => {
    setEditedBlock(prev => ({
      ...prev,
      vocabularyWords: prev.vocabularyWords.filter(w => w !== word),
    }))
  }

  return (
    <Dialog open onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        Edit Text Block
        <IconButton
          onClick={onClose}
          sx={{ position: 'absolute', right: 8, top: 8 }}
        >
          <CloseIcon />
        </IconButton>
      </DialogTitle>
      
      <DialogContent>
        <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 2 }}>
          <Tabs value={activeTab} onChange={(_, value) => setActiveTab(value)}>
            <Tab label="Text Variants" />
            <Tab label="Vocabulary" />
          </Tabs>
        </Box>

        <TabPanel value={activeTab} index={0}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <TextField
              label="Easy (Ages 3-5)"
              value={editedBlock.variants.easy}
              onChange={(e) => handleVariantChange('easy', e.target.value)}
              fullWidth
              multiline
              rows={2}
              helperText="Use simple words and short sentences"
            />
            
            <TextField
              label="Medium (Ages 6-8)"
              value={editedBlock.variants.medium}
              onChange={(e) => handleVariantChange('medium', e.target.value)}
              fullWidth
              multiline
              rows={2}
              helperText="Use moderate vocabulary and longer sentences"
            />
            
            <TextField
              label="Hard (Ages 9-12)"
              value={editedBlock.variants.hard}
              onChange={(e) => handleVariantChange('hard', e.target.value)}
              fullWidth
              multiline
              rows={2}
              helperText="Use advanced vocabulary and complex sentences"
            />
          </Box>
        </TabPanel>

        <TabPanel value={activeTab} index={1}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Add vocabulary words that this text block teaches or reinforces.
            </Typography>

            <Box sx={{ display: 'flex', gap: 1 }}>
              <TextField
                label="Add vocabulary word"
                value={newVocabWord}
                onChange={(e) => setNewVocabWord(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleAddVocabWord()}
                size="small"
                sx={{ flexGrow: 1 }}
              />
              <Button
                variant="outlined"
                startIcon={<AddIcon />}
                onClick={handleAddVocabWord}
                disabled={!newVocabWord.trim()}
              >
                Add
              </Button>
            </Box>

            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, minHeight: 40 }}>
              {editedBlock.vocabularyWords.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  No vocabulary words added yet
                </Typography>
              ) : (
                editedBlock.vocabularyWords.map((word) => (
                  <Chip
                    key={word}
                    label={word}
                    onDelete={() => handleRemoveVocabWord(word)}
                    deleteIcon={<RemoveIcon />}
                    size="small"
                    color="primary"
                    variant="outlined"
                  />
                ))
              )}
            </Box>
          </Box>
        </TabPanel>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button onClick={handleSave} variant="contained">
          Save Changes
        </Button>
      </DialogActions>
    </Dialog>
  )
}

interface PageEditorProps {
  page: StoryPage
  onTextBlockUpdate: (textBlock: TextBlock) => void
  onTextBlockDelete: (textBlockId: string) => void
  onImageUpdate?: (image: PopupImage) => void
  onImageDelete?: (imageId: string) => void
  isReadOnly?: boolean
  zoom?: number
}

export const PageEditor: React.FC<PageEditorProps> = ({
  page,
  onTextBlockUpdate,
  onTextBlockDelete,
  onImageUpdate,
  onImageDelete,
  isReadOnly = false,
  zoom = 1,
}) => {
  const [selectedTextBlock, setSelectedTextBlock] = useState<string | null>(null)
  const [selectedImage, setSelectedImage] = useState<string | null>(null)
  const [editingTextBlock, setEditingTextBlock] = useState<TextBlock | null>(null)
  const [contextMenu, setContextMenu] = useState<{
    mouseX: number
    mouseY: number
    textBlockId: string
  } | null>(null)
  
  const dragRef = useRef<{
    isDragging: boolean
    startPosition: { x: number; y: number }
    elementPosition: { x: number; y: number }
    textBlockId: string | null
  }>({
    isDragging: false,
    startPosition: { x: 0, y: 0 },
    elementPosition: { x: 0, y: 0 },
    textBlockId: null,
  })

  const handleTextBlockClick = useCallback((textBlockId: string) => {
    if (isReadOnly) return
    setSelectedTextBlock(textBlockId)
  }, [isReadOnly])

  const handleTextBlockDoubleClick = useCallback((textBlock: TextBlock) => {
    if (isReadOnly) return
    setEditingTextBlock(textBlock)
  }, [isReadOnly])

  const handleTextBlockRightClick = useCallback((
    event: React.MouseEvent,
    textBlockId: string
  ) => {
    event.preventDefault()
    if (isReadOnly) return

    setContextMenu({
      mouseX: event.clientX - 2,
      mouseY: event.clientY - 4,
      textBlockId,
    })
  }, [isReadOnly])

  const handleContextMenuClose = useCallback(() => {
    setContextMenu(null)
  }, [])

  const handleEditTextBlock = useCallback(() => {
    if (contextMenu) {
      const textBlock = page.textBlocks.find(tb => tb.id === contextMenu.textBlockId)
      if (textBlock) {
        setEditingTextBlock(textBlock)
      }
    }
    handleContextMenuClose()
  }, [contextMenu, page.textBlocks])

  const handleDeleteTextBlock = useCallback(() => {
    if (contextMenu) {
      onTextBlockDelete(contextMenu.textBlockId)
      if (selectedTextBlock === contextMenu.textBlockId) {
        setSelectedTextBlock(null)
      }
    }
    handleContextMenuClose()
  }, [contextMenu, selectedTextBlock, onTextBlockDelete])

  const handleMouseDown = useCallback((
    event: React.MouseEvent,
    textBlockId: string,
    textBlock: TextBlock
  ) => {
    if (isReadOnly) return

    dragRef.current = {
      isDragging: false,
      startPosition: { x: event.clientX, y: event.clientY },
      elementPosition: { x: textBlock.position.x, y: textBlock.position.y },
      textBlockId,
    }

    const handleMouseMove = (moveEvent: MouseEvent) => {
      if (!dragRef.current.isDragging && (
        Math.abs(moveEvent.clientX - dragRef.current.startPosition.x) > 5 ||
        Math.abs(moveEvent.clientY - dragRef.current.startPosition.y) > 5
      )) {
        dragRef.current.isDragging = true
      }

      if (dragRef.current.isDragging) {
        const deltaX = (moveEvent.clientX - dragRef.current.startPosition.x) / zoom
        const deltaY = (moveEvent.clientY - dragRef.current.startPosition.y) / zoom

        const newPosition = {
          x: Math.max(0, Math.min(800 - 120, dragRef.current.elementPosition.x + deltaX)),
          y: Math.max(0, Math.min(600 - 60, dragRef.current.elementPosition.y + deltaY)),
        }

        const updatedTextBlock = {
          ...textBlock,
          position: newPosition,
        }

        onTextBlockUpdate(updatedTextBlock)
      }
    }

    const handleMouseUp = () => {
      if (!dragRef.current.isDragging) {
        handleTextBlockClick(textBlockId)
      }
      
      dragRef.current = {
        isDragging: false,
        startPosition: { x: 0, y: 0 },
        elementPosition: { x: 0, y: 0 },
        textBlockId: null,
      }

      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }

    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
  }, [isReadOnly, zoom, onTextBlockUpdate, handleTextBlockClick])

  // Handle clicking outside to deselect
  const handleCanvasClick = useCallback((event: React.MouseEvent) => {
    if (event.target === event.currentTarget) {
      setSelectedTextBlock(null)
      setSelectedImage(null)
    }
  }, [])

  // Image handlers
  const handleImageUpdate = useCallback((id: string, updates: {
    position?: { x: number; y: number }
    size?: { width: number; height: number }
    rotation?: number
    flipHorizontal?: boolean
    flipVertical?: boolean
  }) => {
    if (!onImageUpdate) return
    
    const image = page.popupImages.find(img => img.id === id)
    if (image) {
      onImageUpdate({
        ...image,
        ...updates,
      })
    }
  }, [page.popupImages, onImageUpdate])

  const handleImageDelete = useCallback((id: string) => {
    if (onImageDelete) {
      onImageDelete(id)
      if (selectedImage === id) {
        setSelectedImage(null)
      }
    }
  }, [selectedImage, onImageDelete])

  const handleImageSelect = useCallback((id: string) => {
    setSelectedImage(id)
    setSelectedTextBlock(null)
  }, [])

  return (
    <Box
      sx={{ 
        width: '100%', 
        height: '100%', 
        position: 'relative',
        cursor: isReadOnly ? 'default' : 'crosshair',
      }}
      onClick={handleCanvasClick}
    >
      {/* Text Blocks */}
      {page.textBlocks.map((textBlock) => (
        <DraggableTextBlock
          key={textBlock.id}
          selected={selectedTextBlock === textBlock.id}
          zoom={zoom}
          sx={{
            left: textBlock.position.x,
            top: textBlock.position.y,
          }}
          onMouseDown={(e) => handleMouseDown(e, textBlock.id, textBlock)}
          onDoubleClick={() => handleTextBlockDoubleClick(textBlock)}
          onContextMenu={(e) => handleTextBlockRightClick(e, textBlock.id)}
        >
          {/* Drag Handle */}
          <IconButton
            className="drag-handle"
            size="small"
            sx={{ 
              width: 20, 
              height: 20,
              backgroundColor: 'primary.main',
              color: 'primary.contrastText',
              '&:hover': {
                backgroundColor: 'primary.dark',
              },
            }}
          >
            <DragIcon sx={{ fontSize: 12 }} />
          </IconButton>

          {/* Text Content */}
          <Typography
            variant="body2"
            sx={{
              lineHeight: 1.4,
              wordBreak: 'break-word',
              userSelect: 'none',
              cursor: isReadOnly ? 'default' : 'text',
            }}
          >
            {textBlock.variants.medium || 'Empty text block'}
          </Typography>

          {/* Vocabulary indicator */}
          {textBlock.vocabularyWords.length > 0 && (
            <Box sx={{ mt: 0.5 }}>
              <Chip
                label={`${textBlock.vocabularyWords.length} vocab`}
                size="small"
                color="secondary"
                sx={{ fontSize: '0.7rem', height: 18 }}
              />
            </Box>
          )}
        </DraggableTextBlock>
      ))}

      {/* Popup Images */}
      {page.popupImages.map((popupImage) => (
        <DraggableImage
          key={popupImage.id}
          id={popupImage.id}
          imageUrl={popupImage.imageUrl}
          position={popupImage.position || { x: 100, y: 100 }}
          size={popupImage.size || { width: 150, height: 150 }}
          rotation={popupImage.rotation || 0}
          flipHorizontal={popupImage.flipHorizontal || false}
          flipVertical={popupImage.flipVertical || false}
          selected={selectedImage === popupImage.id}
          zoom={zoom}
          onUpdate={handleImageUpdate}
          onDelete={handleImageDelete}
          onSelect={handleImageSelect}
          isReadOnly={isReadOnly}
          canvasSize={{ width: 800, height: 600 }}
        />
      ))}

      {/* Context Menu */}
      <Menu
        open={contextMenu !== null}
        onClose={handleContextMenuClose}
        anchorReference="anchorPosition"
        anchorPosition={
          contextMenu !== null
            ? { top: contextMenu.mouseY, left: contextMenu.mouseX }
            : undefined
        }
      >
        <MenuItem onClick={handleEditTextBlock}>
          <ListItemIcon>
            <EditIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Edit Text Block</ListItemText>
        </MenuItem>
        
        <Divider />
        
        <MenuItem onClick={handleDeleteTextBlock} sx={{ color: 'error.main' }}>
          <ListItemIcon>
            <DeleteIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Delete Text Block</ListItemText>
        </MenuItem>
      </Menu>

      {/* Text Block Editor Dialog */}
      {editingTextBlock && (
        <TextBlockEditor
          textBlock={editingTextBlock}
          onUpdate={onTextBlockUpdate}
          onClose={() => setEditingTextBlock(null)}
        />
      )}
    </Box>
  )
}