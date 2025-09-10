import React, { useState, useEffect } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  Alert,
  CircularProgress,
  MenuItem,
  FormControl,
  InputLabel,
  Select,
  Chip,
  OutlinedInput,
  SelectChangeEvent,
  Paper,
  Avatar
} from '@mui/material'
import {
  CloudUpload,
  AttachFile
} from '@mui/icons-material'

import { adminApiService } from '@/services/adminApi'
import { ContentItem, ContentUploadForm as ContentUploadFormType, ContentCreator } from '@/types/admin'

interface ContentUploadFormProps {
  open: boolean
  onClose: () => void
  onSuccess: () => void
  content?: ContentItem | null
}

const CONTENT_TYPES = [
  'Educational Game',
  'Interactive Story',
  'Art Activity',
  'Music Track',
  'STEM Activity',
  'Language Exercise',
  'Social Skills Game',
  'Motor Skills Activity',
  'Math Game',
  'Reading Material',
  'Science Experiment',
  'Cultural Content'
]

const AGE_GROUPS = [
  '2-3 years',
  '3-4 years',
  '4-5 years',
  '5-6 years',
  '6-7 years',
  '7-8 years',
  '8+ years'
]

const DIFFICULTY_LEVELS = [
  'Beginner',
  'Intermediate',
  'Advanced'
]

const EDUCATIONAL_OBJECTIVES = [
  'Problem Solving',
  'Creative Thinking',
  'Language Development',
  'Math Skills',
  'Science Understanding',
  'Social Skills',
  'Motor Skills',
  'Reading Comprehension',
  'Cultural Awareness',
  'Critical Thinking'
]

export const ContentUploadForm: React.FC<ContentUploadFormProps> = ({
  open,
  onClose,
  onSuccess,
  content
}) => {
  const [formData, setFormData] = useState<ContentUploadFormType>({
    title: '',
    description: '',
    content_type: '',
    creator_id: '',
    tags: [],
    age_groups: [],
    difficulty_level: '',
    educational_objectives: []
  })
  const [creators, setCreators] = useState<ContentCreator[]>([])
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [loading, setLoading] = useState(false)
  const [creatorsLoading, setCreatorsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [tagInput, setTagInput] = useState('')

  const isEditMode = Boolean(content)

  useEffect(() => {
    if (open) {
      loadCreators()
    }
  }, [open])

  useEffect(() => {
    if (content) {
      setFormData({
        title: content.title,
        description: content.description || '',
        content_type: content.content_type,
        creator_id: content.creator_id,
        tags: content.tags,
        age_groups: content.age_groups,
        difficulty_level: content.difficulty_level,
        educational_objectives: content.educational_objectives
      })
    } else {
      setFormData({
        title: '',
        description: '',
        content_type: '',
        creator_id: '',
        tags: [],
        age_groups: [],
        difficulty_level: '',
        educational_objectives: []
      })
    }
    setSelectedFile(null)
    setError(null)
  }, [content, open])

  const loadCreators = async () => {
    try {
      setCreatorsLoading(true)
      const data = await adminApiService.getCreatorsList()
      setCreators(data.filter(c => c.is_active))
    } catch (err: any) {
      console.error('Failed to load creators:', err)
    } finally {
      setCreatorsLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.title.trim() || !formData.content_type || !formData.creator_id) {
      setError('Please fill in all required fields')
      return
    }

    if (!isEditMode && !selectedFile) {
      setError('Please select a file to upload')
      return
    }

    try {
      setLoading(true)
      setError(null)

      if (isEditMode && content) {
        await adminApiService.updateContent(content.id, formData)
      } else {
        const uploadFormData = new FormData()
        uploadFormData.append('title', formData.title)
        uploadFormData.append('description', formData.description || '')
        uploadFormData.append('content_type', formData.content_type)
        uploadFormData.append('creator_id', formData.creator_id)
        uploadFormData.append('tags', JSON.stringify(formData.tags))
        uploadFormData.append('age_groups', JSON.stringify(formData.age_groups))
        uploadFormData.append('difficulty_level', formData.difficulty_level)
        uploadFormData.append('educational_objectives', JSON.stringify(formData.educational_objectives))
        
        if (selectedFile) {
          uploadFormData.append('file', selectedFile)
        }

        await adminApiService.uploadContent(uploadFormData)
      }

      onSuccess()
      handleClose()
    } catch (err: any) {
      setError(err.error || `Failed to ${isEditMode ? 'update' : 'upload'} content`)
    } finally {
      setLoading(false)
    }
  }

  const handleClose = () => {
    if (!loading) {
      onClose()
    }
  }

  const handleChange = (field: keyof ContentUploadFormType) => (
    event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    setFormData(prev => ({
      ...prev,
      [field]: event.target.value
    }))
    if (error) setError(null)
  }

  const handleSelectChange = (field: keyof ContentUploadFormType) => (
    event: SelectChangeEvent<string | string[]>
  ) => {
    setFormData(prev => ({
      ...prev,
      [field]: event.target.value
    }))
    if (error) setError(null)
  }

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      setSelectedFile(file)
      if (error) setError(null)
    }
  }

  const handleAddTag = () => {
    if (tagInput.trim() && !formData.tags.includes(tagInput.trim())) {
      setFormData(prev => ({
        ...prev,
        tags: [...prev.tags, tagInput.trim()]
      }))
      setTagInput('')
    }
  }

  const handleRemoveTag = (tagToRemove: string) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.filter(tag => tag !== tagToRemove)
    }))
  }

  const formatFileSize = (bytes: number) => {
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(1024))
    return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${sizes[i]}`
  }

  return (
    <Dialog 
      open={open} 
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 2, maxHeight: '90vh' }
      }}
    >
      <form onSubmit={handleSubmit}>
        <DialogTitle>
          <Typography variant="h6" fontWeight={600}>
            {isEditMode ? 'Edit Content' : 'Upload New Content'}
          </Typography>
          <Typography variant="body2" color="textSecondary">
            {isEditMode 
              ? 'Update content information and settings'
              : 'Upload new educational content to the platform'
            }
          </Typography>
        </DialogTitle>

        <DialogContent sx={{ pt: 2 }}>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            {/* File Upload (only for new content) */}
            {!isEditMode && (
              <Paper 
                sx={{ 
                  p: 3, 
                  border: '2px dashed', 
                  borderColor: selectedFile ? 'success.main' : 'grey.300',
                  bgcolor: selectedFile ? 'success.50' : 'grey.50',
                  textAlign: 'center',
                  cursor: 'pointer',
                  transition: 'all 0.2s'
                }}
                onClick={() => document.getElementById('file-upload')?.click()}
              >
                <input
                  id="file-upload"
                  type="file"
                  hidden
                  onChange={handleFileChange}
                  accept=".zip,.mp4,.png,.jpg,.jpeg,.pdf,.json"
                />
                <Avatar sx={{ 
                  mx: 'auto', 
                  mb: 2, 
                  bgcolor: selectedFile ? 'success.main' : 'primary.main',
                  width: 60,
                  height: 60
                }}>
                  {selectedFile ? <AttachFile /> : <CloudUpload />}
                </Avatar>
                {selectedFile ? (
                  <Box>
                    <Typography variant="h6" color="success.main">
                      File Selected
                    </Typography>
                    <Typography variant="body2">
                      {selectedFile.name} ({formatFileSize(selectedFile.size)})
                    </Typography>
                  </Box>
                ) : (
                  <Box>
                    <Typography variant="h6">
                      Click to Upload File
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Supported formats: ZIP, MP4, PNG, JPG, PDF, JSON
                    </Typography>
                  </Box>
                )}
              </Paper>
            )}

            {/* Title Field */}
            <TextField
              label="Content Title"
              value={formData.title}
              onChange={handleChange('title')}
              required
              fullWidth
              disabled={loading}
              placeholder="Enter a descriptive title for the content"
            />

            {/* Description Field */}
            <TextField
              label="Description"
              value={formData.description}
              onChange={handleChange('description')}
              multiline
              rows={3}
              fullWidth
              disabled={loading}
              placeholder="Describe what this content teaches and how it works"
            />

            {/* Content Type and Creator */}
            <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2 }}>
              <FormControl fullWidth required disabled={loading}>
                <InputLabel>Content Type</InputLabel>
                <Select
                  value={formData.content_type}
                  onChange={handleSelectChange('content_type')}
                  label="Content Type"
                >
                  {CONTENT_TYPES.map((type) => (
                    <MenuItem key={type} value={type}>
                      {type}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              <FormControl fullWidth required disabled={loading || creatorsLoading}>
                <InputLabel>Creator</InputLabel>
                <Select
                  value={formData.creator_id}
                  onChange={handleSelectChange('creator_id')}
                  label="Creator"
                >
                  {creators.map((creator) => (
                    <MenuItem key={creator.id} value={creator.id}>
                      {creator.name} ({creator.specialization})
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Box>

            {/* Age Groups and Difficulty */}
            <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2 }}>
              <FormControl fullWidth disabled={loading}>
                <InputLabel>Age Groups</InputLabel>
                <Select
                  multiple
                  value={formData.age_groups}
                  onChange={handleSelectChange('age_groups')}
                  input={<OutlinedInput label="Age Groups" />}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {selected.map((value) => (
                        <Chip key={value} label={value} size="small" />
                      ))}
                    </Box>
                  )}
                >
                  {AGE_GROUPS.map((age) => (
                    <MenuItem key={age} value={age}>
                      {age}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              <FormControl fullWidth disabled={loading}>
                <InputLabel>Difficulty Level</InputLabel>
                <Select
                  value={formData.difficulty_level}
                  onChange={handleSelectChange('difficulty_level')}
                  label="Difficulty Level"
                >
                  {DIFFICULTY_LEVELS.map((level) => (
                    <MenuItem key={level} value={level}>
                      {level}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Box>

            {/* Educational Objectives */}
            <FormControl fullWidth disabled={loading}>
              <InputLabel>Educational Objectives</InputLabel>
              <Select
                multiple
                value={formData.educational_objectives}
                onChange={handleSelectChange('educational_objectives')}
                input={<OutlinedInput label="Educational Objectives" />}
                renderValue={(selected) => (
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                    {selected.map((value) => (
                      <Chip key={value} label={value} size="small" />
                    ))}
                  </Box>
                )}
              >
                {EDUCATIONAL_OBJECTIVES.map((objective) => (
                  <MenuItem key={objective} value={objective}>
                    {objective}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            {/* Tags */}
            <Box>
              <Box sx={{ display: 'flex', gap: 1, mb: 1 }}>
                <TextField
                  label="Add Tags"
                  value={tagInput}
                  onChange={(e) => setTagInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
                  size="small"
                  fullWidth
                  disabled={loading}
                  placeholder="Type a tag and press Enter"
                />
                <Button 
                  onClick={handleAddTag}
                  variant="outlined"
                  disabled={loading || !tagInput.trim()}
                >
                  Add
                </Button>
              </Box>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                {formData.tags.map((tag) => (
                  <Chip
                    key={tag}
                    label={tag}
                    onDelete={() => handleRemoveTag(tag)}
                    size="small"
                    variant="outlined"
                  />
                ))}
              </Box>
            </Box>
          </Box>
        </DialogContent>

        <DialogActions sx={{ p: 3, pt: 2 }}>
          <Button 
            onClick={handleClose}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            variant="contained"
            disabled={loading}
            startIcon={loading ? <CircularProgress size={20} /> : null}
          >
            {loading 
              ? (isEditMode ? 'Updating...' : 'Uploading...') 
              : (isEditMode ? 'Update Content' : 'Upload Content')
            }
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  )
}