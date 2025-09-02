import React, { useState, useCallback, KeyboardEvent, useRef } from 'react'
import { useDropzone } from 'react-dropzone'
import { 
  Upload, 
  X, 
  File, 
  Image, 
  FileText, 
  AlertCircle, 
  Tag,
  Plus,
  Check,
  Loader2,
  Camera
} from 'lucide-react'
import {
  Box,
  Button,
  Chip,
  IconButton,
  LinearProgress,
  Paper,
  TextField,
  Typography,
  Alert,
  Avatar,
  Divider,
  Fade,
  Collapse,
  Popper,
  ClickAwayListener,
  Card,
  CardContent,
  CardMedia
} from '@mui/material'
import { styled } from '@mui/material/styles'
import { useUploadFileMutation } from '@/store/api/apiSlice'

interface FileUploadWithTagsProps {
  onUploadComplete?: (file: any) => void
  accept?: Record<string, string[]>
  maxSize?: number
  category?: 'profile_picture' | 'content' | 'document' | 'game_asset' | 'artwork'
  childId?: string
  isPublic?: boolean
  className?: string
  requireTags?: boolean
  minTags?: number
}

// Enhanced tag suggestions with better categorization
const TAG_CATEGORIES = {
  'Popular': ['colorful', 'happy', 'bright', 'fun', 'creative', 'beautiful'],
  'Animals': ['animal', 'bird', 'dog', 'cat', 'fish', 'butterfly', 'dinosaur', 'lion', 'elephant'],
  'Colors': ['red', 'blue', 'green', 'yellow', 'orange', 'purple', 'pink', 'black', 'white', 'brown'],
  'Nature': ['tree', 'flower', 'sun', 'moon', 'star', 'cloud', 'mountain', 'ocean', 'river', 'forest'],
  'Objects': ['car', 'truck', 'airplane', 'train', 'boat', 'house', 'building', 'toy', 'ball', 'book'],
  'People': ['person', 'child', 'family', 'friend', 'baby', 'mother', 'father'],
  'Actions': ['running', 'jumping', 'playing', 'sleeping', 'eating', 'flying', 'swimming', 'dancing'],
  'Emotions': ['happy', 'sad', 'excited', 'calm', 'funny', 'surprised', 'proud'],
  'Art': ['drawing', 'painting', 'sketch', 'artwork', 'colorful', 'creative', 'design']
}

const ALL_TAGS = Object.values(TAG_CATEGORIES).flat()

// Styled Components using Material-UI
const DropZone = styled(Paper)<{ isDragActive: boolean; isLoading: boolean }>(({ theme, isDragActive, isLoading }) => ({
  border: `2px dashed ${isDragActive ? theme.palette.primary.main : theme.palette.divider}`,
  borderRadius: theme.spacing(2),
  padding: theme.spacing(6),
  textAlign: 'center',
  cursor: 'pointer',
  transition: 'all 0.2s ease-in-out',
  backgroundColor: isDragActive ? theme.palette.primary.light + '10' : theme.palette.background.paper,
  transform: isDragActive ? 'scale(1.02)' : 'scale(1)',
  opacity: isLoading ? 0.6 : 1,
  pointerEvents: isLoading ? 'none' : 'auto',
  '&:hover': {
    borderColor: theme.palette.primary.light,
    backgroundColor: theme.palette.grey[50],
  }
}))

const TagInputContainer = styled(Box)(({ theme }) => ({
  display: 'flex',
  flexWrap: 'wrap',
  alignItems: 'center',
  gap: theme.spacing(1),
  padding: theme.spacing(1, 1.5),
  border: `1px solid ${theme.palette.divider}`,
  borderRadius: theme.shape.borderRadius,
  minHeight: 56,
  '&:focus-within': {
    borderColor: theme.palette.primary.main,
    borderWidth: 2,
  }
}))

const TagSuggestionsPaper = styled(Paper)(({ theme }) => ({
  maxHeight: 300,
  overflow: 'auto',
  padding: theme.spacing(1),
  marginTop: theme.spacing(1),
}))

const UploadButton = styled(Button)<{ hasMinTags: boolean }>(({ theme, hasMinTags }) => ({
  marginTop: theme.spacing(2),
  padding: theme.spacing(1.5),
  fontSize: '1rem',
  fontWeight: 600,
  backgroundColor: hasMinTags ? theme.palette.primary.main : theme.palette.grey[300],
  color: hasMinTags ? theme.palette.primary.contrastText : theme.palette.text.disabled,
  '&:hover': {
    backgroundColor: hasMinTags ? theme.palette.primary.dark : theme.palette.grey[300],
  },
  '&:disabled': {
    backgroundColor: theme.palette.grey[300],
    color: theme.palette.text.disabled,
  }
}))

export const FileUploadWithTags: React.FC<FileUploadWithTagsProps> = ({
  onUploadComplete,
  accept = {
    'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'],
    'application/pdf': ['.pdf'],
  },
  maxSize = 10 * 1024 * 1024, // 10MB default
  category = 'content',
  childId,
  isPublic = false,
  className = '',
  requireTags = true,
  minTags = 2,
}) => {
  const [uploadedFile, setUploadedFile] = useState<any>(null)
  const [uploadProgress, setUploadProgress] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [tags, setTags] = useState<string[]>([])
  const [tagInput, setTagInput] = useState('')
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [uploadFile, { isLoading }] = useUploadFileMutation()
  const tagInputRef = useRef<HTMLInputElement>(null)
  const suggestionAnchorRef = useRef<HTMLDivElement>(null)
  const isInteractingWithSuggestions = useRef(false)

  const filteredSuggestions = ALL_TAGS.filter(
    tag => 
      tag.toLowerCase().includes(tagInput.toLowerCase()) && 
      !tags.includes(tag)
  ).slice(0, 12)

  const addTag = (tag: string) => {
    const normalizedTag = tag.toLowerCase().trim()
    if (normalizedTag && !tags.includes(normalizedTag) && normalizedTag.length <= 50) {
      if (!/^[a-zA-Z0-9-_\s]+$/.test(normalizedTag)) {
        setError('Tags can only contain letters, numbers, hyphens, underscores, and spaces')
        return
      }
      setTags([...tags, normalizedTag])
      setTagInput('')
      setShowSuggestions(false)
      setError(null)
      
      // Focus back to input for easier tag addition
      tagInputRef.current?.focus()
    }
  }

  const removeTag = (tagToRemove: string) => {
    setTags(tags.filter(tag => tag !== tagToRemove))
  }

  const handleTagInputKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && tagInput.trim()) {
      e.preventDefault()
      addTag(tagInput)
    } else if (e.key === 'Backspace' && !tagInput && tags.length > 0) {
      // Remove last tag on backspace if input is empty
      removeTag(tags[tags.length - 1])
    } else if (e.key === 'Escape') {
      setShowSuggestions(false)
    }
  }

  const handleUpload = async () => {
    if (!selectedFile) return
    
    if (requireTags && tags.length < minTags) {
      setError(`Please add at least ${minTags} tags to describe this file`)
      return
    }

    setError(null)
    setUploadProgress(0)

    const formData = new FormData()
    formData.append('file', selectedFile)

    try {
      // Simulate progress for demo
      const progressInterval = setInterval(() => {
        setUploadProgress(prev => {
          if (prev >= 90) {
            clearInterval(progressInterval)
            return prev
          }
          return prev + 10
        })
      }, 200)

      const result = await uploadFile({
        formData,
        category,
        childId: childId || undefined,
        isPublic,
        tags: tags.join(','),
      }).unwrap()
      
      clearInterval(progressInterval)
      setUploadProgress(100)
      setUploadedFile(result.data)
      
      if (onUploadComplete) {
        onUploadComplete({ ...result.data, tags })
      }
    } catch (err: any) {
      setError(err.data?.error?.message || 'Upload failed')
      setUploadProgress(0)
    }
  }

  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    if (acceptedFiles.length === 0) return
    setSelectedFile(acceptedFiles[0])
    setError(null)
  }, [])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept,
    maxSize,
    multiple: false,
  })

  const getFileIcon = (mimeType: string) => {
    if (mimeType.startsWith('image/')) return <Image size={24} />
    if (mimeType === 'application/pdf') return <FileText size={24} />
    return <File size={24} />
  }

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  const handleRemove = () => {
    setUploadedFile(null)
    setSelectedFile(null)
    setUploadProgress(0)
    setError(null)
    setTags([])
  }

  const hasMinimumTags = !requireTags || tags.length >= minTags

  // Get file preview if it's an image
  const getFilePreview = () => {
    if (selectedFile && selectedFile.type.startsWith('image/')) {
      return URL.createObjectURL(selectedFile)
    }
    return null
  }

  const renderTagSuggestions = () => {
    if (!showSuggestions || filteredSuggestions.length === 0) return null
    
    const categoryMatches = Object.entries(TAG_CATEGORIES).reduce((acc, [category, categoryTags]) => {
      const matches = categoryTags.filter(tag => 
        tag.toLowerCase().includes(tagInput.toLowerCase()) && 
        !tags.includes(tag)
      )
      if (matches.length > 0) {
        acc[category] = matches.slice(0, 4)
      }
      return acc
    }, {} as Record<string, string[]>)

    return (
      <Popper 
        open={showSuggestions && Object.keys(categoryMatches).length > 0}
        anchorEl={suggestionAnchorRef.current}
        placement="bottom-start"
        style={{ zIndex: 1300, width: suggestionAnchorRef.current?.offsetWidth }}
      >
        <TagSuggestionsPaper 
          elevation={3}
          onMouseEnter={() => { isInteractingWithSuggestions.current = true }}
          onMouseLeave={() => { 
            isInteractingWithSuggestions.current = false
            // Re-focus the input if it lost focus
            tagInputRef.current?.focus()
          }}>
          {Object.entries(categoryMatches).map(([category, categoryTags]) => (
            <Box key={category} sx={{ mb: 2 }}>
              <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', mb: 1, display: 'block' }}>
                {category}
              </Typography>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                {categoryTags.map(suggestion => (
                  <Chip
                    key={suggestion}
                    label={suggestion}
                    size="small"
                    onMouseDown={(e) => e.preventDefault()} // Prevent blur
                    onClick={() => {
                      addTag(suggestion)
                      isInteractingWithSuggestions.current = false
                      tagInputRef.current?.focus()
                    }}
                    sx={{ 
                      fontSize: '0.75rem',
                      cursor: 'pointer',
                      '&:hover': {
                        backgroundColor: 'primary.light',
                        color: 'primary.contrastText'
                      }
                    }}
                  />
                ))}
              </Box>
            </Box>
          ))}
        </TagSuggestionsPaper>
      </Popper>
    )
  }

  return (
    <Box className={className} sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      {!uploadedFile ? (
        <>
          {/* File Selection Area */}
          {!selectedFile ? (
            <DropZone
              {...getRootProps()}
              isDragActive={isDragActive}
              isLoading={isLoading}
              elevation={isDragActive ? 4 : 1}
            >
              <input {...getInputProps()} />
              
              <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                <Avatar 
                  sx={{ 
                    width: 64, 
                    height: 64, 
                    bgcolor: isDragActive ? 'primary.main' : 'grey.300',
                    transition: 'all 0.2s'
                  }}
                >
                  {isDragActive ? <Camera size={32} /> : <Upload size={32} />}
                </Avatar>
                
                {isDragActive ? (
                  <Box>
                    <Typography variant="h6" color="primary" sx={{ fontWeight: 600, mb: 0.5 }}>
                      Drop your file here!
                    </Typography>
                    <Typography variant="body2" color="primary">
                      Let's get it ready for upload
                    </Typography>
                  </Box>
                ) : (
                  <Box>
                    <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5 }}>
                      Click to upload or drag and drop
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                      Upload images for your stories
                    </Typography>
                    <Typography variant="caption" color="text.disabled">
                      Maximum file size: {formatFileSize(maxSize)}
                    </Typography>
                  </Box>
                )}
              </Box>
            </DropZone>
          ) : (
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {/* Selected File Display */}
              <Card>
                {/* File Preview */}
                {getFilePreview() ? (
                  <Box sx={{ position: 'relative' }}>
                    <CardMedia
                      component="img"
                      height="200"
                      image={getFilePreview()!}
                      alt="Preview"
                      sx={{ objectFit: 'contain', bgcolor: 'grey.50' }}
                    />
                    <IconButton
                      onClick={() => {
                        setSelectedFile(null)
                        setTags([])
                      }}
                      sx={{ 
                        position: 'absolute', 
                        top: 8, 
                        right: 8,
                        bgcolor: 'rgba(0,0,0,0.5)',
                        color: 'white',
                        '&:hover': {
                          bgcolor: 'rgba(0,0,0,0.7)'
                        }
                      }}
                    >
                      <X size={20} />
                    </IconButton>
                  </Box>
                ) : (
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Avatar sx={{ bgcolor: 'grey.100' }}>
                        {getFileIcon(selectedFile.type)}
                      </Avatar>
                      <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                        <Typography variant="body2" sx={{ fontWeight: 500 }} noWrap>
                          {selectedFile.name}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {formatFileSize(selectedFile.size)}
                        </Typography>
                      </Box>
                      <IconButton
                        onClick={() => {
                          setSelectedFile(null)
                          setTags([])
                        }}
                        size="small"
                      >
                        <X size={16} />
                      </IconButton>
                    </Box>
                  </CardContent>
                )}

                {/* Tag Input Section */}
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                    <Tag size={20} color="#1976d2" />
                    <Typography variant="subtitle2" sx={{ ml: 1, fontWeight: 600 }}>
                      Add Tags
                    </Typography>
                    {requireTags && (
                      <Chip 
                        label={`minimum ${minTags}`}
                        size="small"
                        color="primary"
                        variant="outlined"
                        sx={{ ml: 2, fontSize: '0.75rem' }}
                      />
                    )}
                  </Box>
                  
                  <Box ref={suggestionAnchorRef}>
                    <TagInputContainer>
                      {/* Existing Tags */}
                      {tags.map(tag => (
                        <Chip
                          key={tag}
                          label={tag}
                          onDelete={() => removeTag(tag)}
                          color="primary"
                          variant="filled"
                          size="small"
                          deleteIcon={<X size={14} />}
                        />
                      ))}
                      
                      {/* Tag Input */}
                      <TextField
                        inputRef={tagInputRef}
                        variant="standard"
                        placeholder={tags.length === 0 ? "Type a tag and press Enter..." : "Add another tag..."}
                        value={tagInput}
                        onChange={(e) => setTagInput(e.target.value)}
                        onKeyDown={handleTagInputKeyDown}
                        onFocus={() => setShowSuggestions(true)}
                        onBlur={() => {
                          setTimeout(() => {
                            if (!isInteractingWithSuggestions.current) {
                              setShowSuggestions(false)
                            }
                          }, 100)
                        }}
                        sx={{ 
                          flexGrow: 1, 
                          minWidth: 120,
                          '& .MuiInput-underline:before': { display: 'none' },
                          '& .MuiInput-underline:after': { display: 'none' }
                        }}
                        InputProps={{
                          disableUnderline: true,
                          endAdornment: tagInput && (
                            <IconButton
                              size="small"
                              onClick={() => addTag(tagInput)}
                              sx={{ p: 0.5 }}
                            >
                              <Plus size={16} />
                            </IconButton>
                          )
                        }}
                      />
                    </TagInputContainer>
                    
                    {/* Tag Suggestions */}
                    <ClickAwayListener onClickAway={() => setShowSuggestions(false)}>
                      <div>{renderTagSuggestions()}</div>
                    </ClickAwayListener>
                  </Box>

                  {/* Tag Count Indicator */}
                  <Box sx={{ display: 'flex', alignItems: 'center', mt: 2, gap: 1 }}>
                    {hasMinimumTags ? 
                      <Check size={16} color="#2e7d32" /> : 
                      <AlertCircle size={16} color="#ed6c02" />
                    }
                    <Typography 
                      variant="body2" 
                      sx={{ color: hasMinimumTags ? 'success.main' : 'warning.main' }}
                    >
                      {tags.length} tag{tags.length !== 1 ? 's' : ''} added
                      {requireTags && !hasMinimumTags && (
                        <Typography component="span" sx={{ ml: 1, fontWeight: 500 }}>
                          ({minTags - tags.length} more needed)
                        </Typography>
                      )}
                    </Typography>
                  </Box>
                </CardContent>
              </Card>

              {/* Upload Button */}
              <UploadButton
                onClick={handleUpload}
                disabled={isLoading || !hasMinimumTags}
                hasMinTags={hasMinimumTags && !isLoading}
                variant="contained"
                fullWidth
                size="large"
              >
                {isLoading ? (
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Loader2 size={20} className="animate-spin" />
                    <span>Uploading... {Math.round(uploadProgress)}%</span>
                  </Box>
                ) : (
                  'Upload File'
                )}
              </UploadButton>
            </Box>
          )}

          {/* Progress Bar */}
          {isLoading && (
            <LinearProgress 
              variant="determinate" 
              value={uploadProgress} 
              sx={{ 
                height: 8, 
                borderRadius: 4,
                bgcolor: 'grey.200',
                '& .MuiLinearProgress-bar': {
                  borderRadius: 4,
                  background: 'linear-gradient(90deg, #1976d2 0%, #1565c0 100%)'
                }
              }}
            />
          )}
        </>
      ) : (
        /* Upload Complete State */
        <Card sx={{ bgcolor: 'success.light', border: '2px solid', borderColor: 'success.main' }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
              <Avatar sx={{ bgcolor: 'success.main' }}>
                <Check size={24} />
              </Avatar>
              <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5 }}>
                  Upload Successful!
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {uploadedFile.originalName} • {formatFileSize(uploadedFile.fileSize)}
                </Typography>
                
                {tags.length > 0 && (
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5, mb: 2 }}>
                    {tags.map(tag => (
                      <Chip
                        key={tag}
                        label={tag}
                        size="small"
                        color="success"
                        variant="outlined"
                      />
                    ))}
                  </Box>
                )}
                
                {uploadedFile.url && (
                  <Button
                    href={uploadedFile.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    size="small"
                    sx={{ p: 0, textTransform: 'none' }}
                  >
                    View file →
                  </Button>
                )}
              </Box>
              <IconButton
                onClick={handleRemove}
                sx={{ color: 'text.secondary' }}
              >
                <X size={20} />
              </IconButton>
            </Box>
          </CardContent>
        </Card>
      )}

      {/* Error Display */}
      <Collapse in={!!error}>
        <Alert 
          severity="error" 
          action={
            <IconButton size="small" onClick={() => setError(null)}>
              <X size={16} />
            </IconButton>
          }
        >
          {error}
        </Alert>
      </Collapse>
    </Box>
  )
}

export default FileUploadWithTags