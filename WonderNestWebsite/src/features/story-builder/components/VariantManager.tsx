import React, { useState, useCallback } from 'react'
import {
  Box,
  Paper,
  Typography,
  Button,
  IconButton,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip,
  Stack,
  Grid,
  Slider,
  Tooltip,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  FormLabel,
  ToggleButtonGroup,
  ToggleButton,
} from '@mui/material'
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Edit as EditIcon,
  ContentCopy as CopyIcon,
  AutoAwesome as AIIcon,
  Check as CheckIcon,
  Close as CloseIcon,
  Language as LanguageIcon,
  School as EducationIcon,
  Speed as SpeedIcon,
  SortByAlpha as SortIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'

import { TextVariant, VariantMetadata } from '../types/story'

interface VariantManagerProps {
  variants: TextVariant[]
  activeVariantId?: string
  onVariantsChange: (variants: TextVariant[]) => void
  onActiveVariantChange: (variantId: string) => void
  enableAISuggestions?: boolean
  maxVariants?: number
}

const VariantCard = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(2),
  cursor: 'pointer',
  transition: 'all 0.2s',
  '&:hover': {
    boxShadow: theme.shadows[4],
  },
  '&.active': {
    borderColor: theme.palette.primary.main,
    borderWidth: 2,
  },
}))

const DifficultyChip = ({ difficulty }: { difficulty: string }) => {
  const getColor = () => {
    switch (difficulty) {
      case 'easy':
        return 'success'
      case 'medium':
        return 'warning'
      case 'hard':
        return 'error'
      case 'advanced':
        return 'secondary'
      default:
        return 'default'
    }
  }

  return <Chip label={difficulty} size="small" color={getColor() as any} />
}

export const VariantManager: React.FC<VariantManagerProps> = ({
  variants,
  activeVariantId,
  onVariantsChange,
  onActiveVariantChange,
  enableAISuggestions = false,
  maxVariants = 10,
}) => {
  const [editingVariant, setEditingVariant] = useState<TextVariant | null>(null)
  const [showEditDialog, setShowEditDialog] = useState(false)
  const [sortBy, setSortBy] = useState<'difficulty' | 'age' | 'vocabulary'>('difficulty')
  const [filterDifficulty, setFilterDifficulty] = useState<string | 'all'>('all')

  const handleAddVariant = () => {
    if (variants.length >= maxVariants) {
      alert(`Maximum ${maxVariants} variants allowed`)
      return
    }

    const newVariant: TextVariant = {
      id: `variant-${Date.now()}`,
      content: '',
      metadata: {
        difficulty: 'medium',
        ageRange: [5, 8],
        vocabularyLevel: 5,
        readingTime: 0,
        wordCount: 0,
        characterCount: 0,
      },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      isDefault: variants.length === 0,
    }

    onVariantsChange([...variants, newVariant])
    setEditingVariant(newVariant)
    setShowEditDialog(true)
  }

  const handleEditVariant = (variant: TextVariant) => {
    setEditingVariant(variant)
    setShowEditDialog(true)
  }

  const handleDeleteVariant = (variantId: string) => {
    const updatedVariants = variants.filter((v) => v.id !== variantId)
    
    // If deleting the active variant, select another one
    if (activeVariantId === variantId && updatedVariants.length > 0) {
      onActiveVariantChange(updatedVariants[0].id)
    }
    
    // If only one variant remains, make it default
    if (updatedVariants.length === 1) {
      updatedVariants[0].isDefault = true
    }
    
    onVariantsChange(updatedVariants)
  }

  const handleDuplicateVariant = (variant: TextVariant) => {
    if (variants.length >= maxVariants) {
      alert(`Maximum ${maxVariants} variants allowed`)
      return
    }

    const duplicatedVariant: TextVariant = {
      ...variant,
      id: `variant-${Date.now()}`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      isDefault: false,
    }

    onVariantsChange([...variants, duplicatedVariant])
  }

  const handleSaveEdit = () => {
    if (!editingVariant) return

    const updatedVariants = variants.map((v) =>
      v.id === editingVariant.id ? editingVariant : v
    )

    onVariantsChange(updatedVariants)
    setShowEditDialog(false)
    setEditingVariant(null)
  }

  const handleAISuggestion = async () => {
    // Placeholder for AI suggestion functionality
    alert('AI suggestions will be implemented in the next phase')
  }

  const updateVariantMetadata = (content: string): VariantMetadata => {
    const words = content.split(/\s+/).filter(Boolean)
    const sentences = content.split(/[.!?]+/).filter(Boolean)
    const avgWordsPerSentence = sentences.length > 0 ? words.length / sentences.length : 0
    
    // Simple Flesch-Kincaid approximation
    const complexityScore = Math.min(10, Math.max(1, Math.round(avgWordsPerSentence / 2)))
    
    return {
      ...editingVariant!.metadata,
      wordCount: words.length,
      characterCount: content.length,
      readingTime: Math.ceil(words.length / 200 * 60), // 200 words per minute
      sentenceComplexity: complexityScore,
    }
  }

  const getSortedAndFilteredVariants = () => {
    let filtered = [...variants]
    
    // Apply filter
    if (filterDifficulty !== 'all') {
      filtered = filtered.filter((v) => v.metadata.difficulty === filterDifficulty)
    }
    
    // Apply sort
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'difficulty':
          const diffOrder = { easy: 0, medium: 1, hard: 2, advanced: 3 }
          return (diffOrder[a.metadata.difficulty] || 0) - (diffOrder[b.metadata.difficulty] || 0)
        case 'age':
          return a.metadata.ageRange[0] - b.metadata.ageRange[0]
        case 'vocabulary':
          return a.metadata.vocabularyLevel - b.metadata.vocabularyLevel
        default:
          return 0
      }
    })
    
    return filtered
  }

  const displayVariants = getSortedAndFilteredVariants()

  return (
    <Box>
      {/* Header Controls */}
      <Paper elevation={1} sx={{ p: 2, mb: 2 }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center">
          <Typography variant="h6">
            Text Variants ({variants.length}/{maxVariants})
          </Typography>
          
          <Stack direction="row" spacing={1}>
            {enableAISuggestions && (
              <Button
                startIcon={<AIIcon />}
                onClick={handleAISuggestion}
                variant="outlined"
                size="small"
              >
                AI Suggest
              </Button>
            )}
            <Button
              startIcon={<AddIcon />}
              onClick={handleAddVariant}
              variant="contained"
              size="small"
              disabled={variants.length >= maxVariants}
            >
              Add Variant
            </Button>
          </Stack>
        </Stack>

        {/* Filter and Sort Controls */}
        <Stack direction="row" spacing={2} sx={{ mt: 2 }}>
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Filter</InputLabel>
            <Select
              value={filterDifficulty}
              onChange={(e) => setFilterDifficulty(e.target.value)}
              label="Filter"
            >
              <MenuItem value="all">All</MenuItem>
              <MenuItem value="easy">Easy</MenuItem>
              <MenuItem value="medium">Medium</MenuItem>
              <MenuItem value="hard">Hard</MenuItem>
              <MenuItem value="advanced">Advanced</MenuItem>
            </Select>
          </FormControl>

          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Sort By</InputLabel>
            <Select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as any)}
              label="Sort By"
            >
              <MenuItem value="difficulty">Difficulty</MenuItem>
              <MenuItem value="age">Age Range</MenuItem>
              <MenuItem value="vocabulary">Vocabulary</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Paper>

      {/* Variants List */}
      <Grid container spacing={2}>
        {displayVariants.map((variant) => (
          <Grid item xs={12} key={variant.id}>
            <VariantCard
              className={activeVariantId === variant.id ? 'active' : ''}
              variant="outlined"
              onClick={() => onActiveVariantChange(variant.id)}
            >
              <Stack spacing={1}>
                {/* Header */}
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <DifficultyChip difficulty={variant.metadata.difficulty} />
                    {variant.isDefault && (
                      <Chip label="Default" size="small" color="primary" variant="outlined" />
                    )}
                    {activeVariantId === variant.id && (
                      <Chip label="Active" size="small" color="primary" />
                    )}
                  </Stack>

                  <Stack direction="row" spacing={0.5}>
                    <Tooltip title="Edit">
                      <IconButton
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleEditVariant(variant)
                        }}
                      >
                        <EditIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Duplicate">
                      <IconButton
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleDuplicateVariant(variant)
                        }}
                      >
                        <CopyIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Delete">
                      <IconButton
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleDeleteVariant(variant.id)
                        }}
                        disabled={variants.length <= 1}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </Stack>
                </Box>

                {/* Content Preview */}
                <Typography
                  variant="body2"
                  sx={{
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                  }}
                >
                  {variant.content || '(Empty variant)'}
                </Typography>

                {/* Metadata */}
                <Stack direction="row" spacing={2}>
                  <Stack direction="row" spacing={0.5} alignItems="center">
                    <EducationIcon fontSize="small" color="action" />
                    <Typography variant="caption" color="text.secondary">
                      Age {variant.metadata.ageRange[0]}-{variant.metadata.ageRange[1]}
                    </Typography>
                  </Stack>
                  <Stack direction="row" spacing={0.5} alignItems="center">
                    <SpeedIcon fontSize="small" color="action" />
                    <Typography variant="caption" color="text.secondary">
                      {variant.metadata.readingTime}s
                    </Typography>
                  </Stack>
                  <Stack direction="row" spacing={0.5} alignItems="center">
                    <SortIcon fontSize="small" color="action" />
                    <Typography variant="caption" color="text.secondary">
                      {variant.metadata.wordCount} words
                    </Typography>
                  </Stack>
                </Stack>

                {/* Tags */}
                {variant.tags && variant.tags.length > 0 && (
                  <Box>
                    {variant.tags.map((tag) => (
                      <Chip
                        key={tag}
                        label={tag}
                        size="small"
                        variant="outlined"
                        sx={{ mr: 0.5, mb: 0.5 }}
                      />
                    ))}
                  </Box>
                )}
              </Stack>
            </VariantCard>
          </Grid>
        ))}
      </Grid>

      {/* Empty State */}
      {displayVariants.length === 0 && (
        <Paper variant="outlined" sx={{ p: 4, textAlign: 'center' }}>
          <Typography color="text.secondary" gutterBottom>
            No variants match your filter criteria
          </Typography>
          <Button
            startIcon={<AddIcon />}
            onClick={handleAddVariant}
            variant="contained"
            sx={{ mt: 2 }}
          >
            Create First Variant
          </Button>
        </Paper>
      )}

      {/* Edit Dialog */}
      <Dialog
        open={showEditDialog}
        onClose={() => setShowEditDialog(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          {editingVariant?.id ? 'Edit Variant' : 'New Variant'}
        </DialogTitle>
        <DialogContent>
          {editingVariant && (
            <Stack spacing={2} sx={{ mt: 1 }}>
              <TextField
                label="Content"
                multiline
                rows={4}
                fullWidth
                value={editingVariant.content}
                onChange={(e) => {
                  const newMetadata = updateVariantMetadata(e.target.value)
                  setEditingVariant({
                    ...editingVariant,
                    content: e.target.value,
                    metadata: newMetadata,
                    updatedAt: new Date().toISOString(),
                  })
                }}
              />

              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <FormControl fullWidth>
                    <InputLabel>Difficulty</InputLabel>
                    <Select
                      value={editingVariant.metadata.difficulty}
                      onChange={(e) =>
                        setEditingVariant({
                          ...editingVariant,
                          metadata: {
                            ...editingVariant.metadata,
                            difficulty: e.target.value as any,
                          },
                        })
                      }
                      label="Difficulty"
                    >
                      <MenuItem value="easy">Easy</MenuItem>
                      <MenuItem value="medium">Medium</MenuItem>
                      <MenuItem value="hard">Hard</MenuItem>
                      <MenuItem value="advanced">Advanced</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>

                <Grid item xs={6}>
                  <Box>
                    <FormLabel>Vocabulary Level</FormLabel>
                    <Slider
                      value={editingVariant.metadata.vocabularyLevel}
                      onChange={(_, value) =>
                        setEditingVariant({
                          ...editingVariant,
                          metadata: {
                            ...editingVariant.metadata,
                            vocabularyLevel: value as number,
                          },
                        })
                      }
                      min={1}
                      max={10}
                      marks
                      valueLabelDisplay="auto"
                    />
                  </Box>
                </Grid>

                <Grid item xs={12}>
                  <Typography variant="subtitle2" gutterBottom>
                    Age Range
                  </Typography>
                  <Slider
                    value={editingVariant.metadata.ageRange}
                    onChange={(_, value) =>
                      setEditingVariant({
                        ...editingVariant,
                        metadata: {
                          ...editingVariant.metadata,
                          ageRange: value as [number, number],
                        },
                      })
                    }
                    min={3}
                    max={12}
                    marks
                    valueLabelDisplay="auto"
                  />
                </Grid>
              </Grid>

              <TextField
                label="Tags (comma separated)"
                fullWidth
                value={editingVariant.tags?.join(', ') || ''}
                onChange={(e) =>
                  setEditingVariant({
                    ...editingVariant,
                    tags: e.target.value.split(',').map((t) => t.trim()).filter(Boolean),
                  })
                }
                helperText="e.g., vocabulary, phonics, sight-words"
              />

              {/* Statistics */}
              <Alert severity="info">
                <Stack spacing={1}>
                  <Typography variant="subtitle2">Content Statistics</Typography>
                  <Typography variant="body2">
                    Words: {editingVariant.metadata.wordCount} |
                    Characters: {editingVariant.metadata.characterCount} |
                    Reading Time: {editingVariant.metadata.readingTime}s
                  </Typography>
                </Stack>
              </Alert>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowEditDialog(false)}>Cancel</Button>
          <Button onClick={handleSaveEdit} variant="contained">
            Save
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}