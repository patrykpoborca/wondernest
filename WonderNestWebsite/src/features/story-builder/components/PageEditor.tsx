import React, { useState, useRef, useCallback, useEffect } from 'react'
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

import { StoryPage, TextBlock, PopupImage, TextVariant } from '../types/story'
import { DraggableImage } from './DraggableImage'
import { StyledTextBlock } from './StyledTextBlock'
import { TextStyleEditor } from './TextStyleEditor'

// Using StyledTextBlock component instead of DraggableTextBlock

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
    onUpdate({
      ...editedBlock,
      metadata: {
        ...editedBlock.metadata,
        createdAt: editedBlock.metadata?.createdAt || new Date().toISOString(),
        createdBy: editedBlock.metadata?.createdBy || 'user',
        updatedAt: new Date().toISOString(),
        validationStatus: 'valid' as const,
      },
    })
    onClose()
  }

  const handleVariantChange = (variantId: string, content: string) => {
    setEditedBlock(prev => ({
      ...prev,
      variants: prev.variants.map(v => 
        v.id === variantId 
          ? {
              ...v,
              content,
              metadata: {
                ...v.metadata,
                wordCount: content.split(' ').filter(Boolean).length,
                characterCount: content.length,
                readingTime: Math.ceil(content.split(' ').filter(Boolean).length / 200 * 60),
              },
              updatedAt: new Date().toISOString(),
            }
          : v
      ),
    }))
  }

  const handleStyleChange = (style: any) => {
    setEditedBlock(prev => ({
      ...prev,
      style,
    }))
  }

  const handleVariantsChange = (variants: TextVariant[]) => {
    setEditedBlock(prev => ({
      ...prev,
      variants,
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
    <Dialog open onClose={onClose} maxWidth="lg" fullWidth>
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
            <Tab label="Styling" />
          </Tabs>
        </Box>

        <TabPanel value={activeTab} index={0}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {editedBlock.variants.map((variant) => (
              <Paper key={variant.id} variant="outlined" sx={{ p: 2 }}>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Chip
                      label={`${variant.metadata.difficulty} (${variant.metadata.ageRange[0]}-${variant.metadata.ageRange[1]} years)`}
                      size="small"
                      color={
                        variant.metadata.difficulty === 'easy'
                          ? 'success'
                          : variant.metadata.difficulty === 'medium'
                          ? 'warning'
                          : 'error'
                      }
                    />
                    {variant.isDefault && (
                      <Chip label="Default" size="small" color="primary" />
                    )}
                  </Box>

                  <TextField
                    multiline
                    rows={3}
                    fullWidth
                    value={variant.content}
                    onChange={(e) => handleVariantChange(variant.id, e.target.value)}
                    placeholder="Enter text variant..."
                    variant="outlined"
                  />

                  <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                    <Typography variant="caption" color="text.secondary">
                      Words: {variant.metadata.wordCount}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      Characters: {variant.metadata.characterCount}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      Reading time: {variant.metadata.readingTime}s
                    </Typography>
                  </Box>
                </Box>
              </Paper>
            ))}
          </Box>
        </TabPanel>

        <TabPanel value={activeTab} index={2}>
          <TextStyleEditor
            textBlock={editedBlock}
            onStyleChange={handleStyleChange}
            onVariantChange={handleVariantsChange}
            allowCustomStyles={true}
          />
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
  onTextBlockSelect?: (textBlock: TextBlock | null) => void
  selectedTextBlockId?: string | null
}

export const PageEditor: React.FC<PageEditorProps> = ({
  page,
  onTextBlockUpdate,
  onTextBlockDelete,
  onImageUpdate,
  onImageDelete,
  isReadOnly = false,
  zoom = 1,
  onTextBlockSelect,
  selectedTextBlockId = null,
}) => {
  const [selectedTextBlock, setSelectedTextBlock] = useState<string | null>(selectedTextBlockId)
  const [selectedImage, setSelectedImage] = useState<string | null>(null)
  const [editingTextBlock, setEditingTextBlock] = useState<TextBlock | null>(null)

  // Sync local selection state with external state
  useEffect(() => {
    setSelectedTextBlock(selectedTextBlockId)
  }, [selectedTextBlockId])
  const [contextMenu, setContextMenu] = useState<{
    mouseX: number
    mouseY: number
    textBlockId: string
  } | null>(null)
  
  // Removed dragRef since StyledTextBlock handles its own dragging

  const handleTextBlockClick = useCallback((textBlockId: string) => {
    if (isReadOnly) return
    setSelectedTextBlock(textBlockId)
    
    // Notify parent component about selection
    if (onTextBlockSelect) {
      const textBlock = page.textBlocks.find(tb => tb.id === textBlockId)
      onTextBlockSelect(textBlock || null)
    }
  }, [isReadOnly, onTextBlockSelect, page.textBlocks])

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

  // Mouse handling now done by StyledTextBlock component

  // Handle clicking outside to deselect
  const handleCanvasClick = useCallback((event: React.MouseEvent) => {
    if (event.target === event.currentTarget) {
      setSelectedTextBlock(null)
      setSelectedImage(null)
      onTextBlockSelect?.(null)
    }
  }, [onTextBlockSelect])

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
        <StyledTextBlock
          key={textBlock.id}
          textBlock={textBlock}
          isEditing={!isReadOnly}
          isSelected={selectedTextBlock === textBlock.id}
          onSelect={() => handleTextBlockClick(textBlock.id)}
          onPositionChange={(position) => {
            const updatedTextBlock = { ...textBlock, position }
            onTextBlockUpdate(updatedTextBlock)
          }}
          onContentChange={(content) => {
            // During editing, always update the primary variant
            const primaryVariant = textBlock.variants.find(v => v.type === 'primary') || textBlock.variants[0]
            if (primaryVariant) {
              const updatedVariants = textBlock.variants.map(v =>
                v.id === primaryVariant.id
                  ? {
                      ...v,
                      content,
                      metadata: {
                        ...v.metadata,
                        wordCount: content.split(' ').filter(Boolean).length,
                        characterCount: content.length,
                        readingTime: Math.ceil(content.split(' ').filter(Boolean).length / 200 * 60),
                      },
                      updatedAt: new Date().toISOString(),
                    }
                  : v
              )
              const updatedTextBlock = {
                ...textBlock,
                variants: updatedVariants,
                metadata: {
                  createdAt: textBlock.metadata?.createdAt || new Date().toISOString(),
                  createdBy: textBlock.metadata?.createdBy || 'user',
                  ...textBlock.metadata,
                  updatedAt: new Date().toISOString(),
                  validationStatus: 'valid' as const,
                },
              }
              onTextBlockUpdate(updatedTextBlock)
            }
          }}
          viewMode="desktop"
          difficulty="medium"
          childAge={7}
          zoom={zoom}
          canvasSize={{ width: 800, height: 600 }}
        />
      ))}

      {/* Legacy mouse handlers for backward compatibility */}
      {page.textBlocks.map((textBlock) => (
        <Box
          key={`handler-${textBlock.id}`}
          sx={{
            position: 'absolute',
            left: textBlock.position.x,
            top: textBlock.position.y,
            width: textBlock.size?.width || 200,
            height: textBlock.size?.height || 60,
            pointerEvents: 'none',
            zIndex: selectedTextBlock === textBlock.id ? 10 : 1,
          }}
          onContextMenu={(e) => {
            e.preventDefault()
            if (!isReadOnly) {
              setContextMenu({
                mouseX: e.clientX - 2,
                mouseY: e.clientY - 4,
                textBlockId: textBlock.id,
              })
            }
          }}
          onDoubleClick={() => !isReadOnly && handleTextBlockDoubleClick(textBlock)}
        />
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