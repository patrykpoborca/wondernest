import React, { useState } from 'react'
import {
  Box,
  Button,
  Card,
  CardContent,
  TextField,
  Typography,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip,
  Stack,
  Alert,
  CircularProgress,
  InputAdornment,
  Grid
} from '@mui/material'
import {
  CloudUpload,
  Save,
  Publish,
  AttachFile,
  Image as ImageIcon
} from '@mui/icons-material'
import adminApi from '@/services/adminApi'

export type ContentType = 'story' | 'sticker_pack' | 'game' | 'activity' | 'educational_pack' | 'template'

interface ContentUploadFormProps {
  onSuccess?: () => void
  onCancel?: () => void
}

export const ContentUploadForm: React.FC<ContentUploadFormProps> = ({ onSuccess, onCancel }) => {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  // Form state
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    contentType: 'story' as ContentType,
    price: '0.00',
    currency: 'USD',
    ageRangeMin: 3,
    ageRangeMax: 8,
    tags: [] as string[],
    searchKeywords: [] as string[],
    mainFile: null as File | null,
    thumbnailFile: null as File | null,
    additionalFiles: [] as File[]
  })

  const [tagInput, setTagInput] = useState('')
  const [keywordInput, setKeywordInput] = useState('')

  const handleInputChange = (field: string) => (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({
      ...formData,
      [field]: event.target.value
    })
  }

  const handleSelectChange = (field: string) => (event: any) => {
    setFormData({
      ...formData,
      [field]: event.target.value
    })
  }

  const handleFileChange = (field: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files
    if (files && files.length > 0) {
      if (field === 'additionalFiles') {
        setFormData({
          ...formData,
          additionalFiles: Array.from(files)
        })
      } else {
        setFormData({
          ...formData,
          [field]: files[0]
        })
      }
    }
  }

  const handleAddTag = () => {
    if (tagInput.trim() && !formData.tags.includes(tagInput.trim())) {
      setFormData({
        ...formData,
        tags: [...formData.tags, tagInput.trim()]
      })
      setTagInput('')
    }
  }

  const handleRemoveTag = (tag: string) => {
    setFormData({
      ...formData,
      tags: formData.tags.filter(t => t !== tag)
    })
  }

  const handleAddKeyword = () => {
    if (keywordInput.trim() && !formData.searchKeywords.includes(keywordInput.trim())) {
      setFormData({
        ...formData,
        searchKeywords: [...formData.searchKeywords, keywordInput.trim()]
      })
      setKeywordInput('')
    }
  }

  const handleRemoveKeyword = (keyword: string) => {
    setFormData({
      ...formData,
      searchKeywords: formData.searchKeywords.filter(k => k !== keyword)
    })
  }

  const handleSubmit = async (publish: boolean = false) => {
    setLoading(true)
    setError(null)
    setSuccess(false)

    try {
      // Create FormData for file upload
      const uploadData = new FormData()
      uploadData.append('title', formData.title)
      uploadData.append('description', formData.description)
      uploadData.append('contentType', formData.contentType)
      uploadData.append('price', formData.price)
      uploadData.append('currency', formData.currency)
      uploadData.append('ageRangeMin', formData.ageRangeMin.toString())
      uploadData.append('ageRangeMax', formData.ageRangeMax.toString())
      uploadData.append('tags', JSON.stringify(formData.tags))
      uploadData.append('searchKeywords', JSON.stringify(formData.searchKeywords))
      
      if (formData.mainFile) {
        uploadData.append('mainFile', formData.mainFile)
      }
      if (formData.thumbnailFile) {
        uploadData.append('thumbnailFile', formData.thumbnailFile)
      }
      formData.additionalFiles.forEach((file, index) => {
        uploadData.append(`additionalFile_${index}`, file)
      })

      // Submit to API
      const response = await adminApi.post('/api/admin/seed/content/upload', uploadData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      })

      if (publish && response.data.id) {
        // Publish immediately if requested
        await adminApi.post(`/api/admin/seed/content/${response.data.id}/publish`)
      }

      setSuccess(true)
      if (onSuccess) {
        setTimeout(onSuccess, 1500)
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to upload content')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card>
      <CardContent>
        <Typography variant="h5" fontWeight={600} sx={{ mb: 3 }}>
          Upload New Content
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
            {error}
          </Alert>
        )}

        {success && (
          <Alert severity="success" sx={{ mb: 2 }}>
            Content uploaded successfully!
          </Alert>
        )}

        <Grid container spacing={3}>
          {/* Basic Information */}
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Title"
              value={formData.title}
              onChange={handleInputChange('title')}
              required
              disabled={loading}
              sx={{ mb: 2 }}
            />

            <TextField
              fullWidth
              label="Description"
              value={formData.description}
              onChange={handleInputChange('description')}
              multiline
              rows={4}
              disabled={loading}
              sx={{ mb: 2 }}
            />

            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Content Type</InputLabel>
              <Select
                value={formData.contentType}
                onChange={handleSelectChange('contentType')}
                label="Content Type"
                disabled={loading}
              >
                <MenuItem value="story">Story</MenuItem>
                <MenuItem value="sticker_pack">Sticker Pack</MenuItem>
                <MenuItem value="game">Game</MenuItem>
                <MenuItem value="activity">Activity</MenuItem>
                <MenuItem value="educational_pack">Educational Pack</MenuItem>
                <MenuItem value="template">Template</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          {/* Pricing and Age */}
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Price"
              type="number"
              value={formData.price}
              onChange={handleInputChange('price')}
              InputProps={{
                startAdornment: <InputAdornment position="start">$</InputAdornment>
              }}
              disabled={loading}
              sx={{ mb: 2 }}
            />

            <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
              <TextField
                label="Min Age"
                type="number"
                value={formData.ageRangeMin}
                onChange={handleInputChange('ageRangeMin')}
                InputProps={{ inputProps: { min: 0, max: 18 } }}
                disabled={loading}
              />
              <TextField
                label="Max Age"
                type="number"
                value={formData.ageRangeMax}
                onChange={handleInputChange('ageRangeMax')}
                InputProps={{ inputProps: { min: 0, max: 18 } }}
                disabled={loading}
              />
            </Box>

            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Currency</InputLabel>
              <Select
                value={formData.currency}
                onChange={handleSelectChange('currency')}
                label="Currency"
                disabled={loading}
              >
                <MenuItem value="USD">USD</MenuItem>
                <MenuItem value="EUR">EUR</MenuItem>
                <MenuItem value="GBP">GBP</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          {/* Tags and Keywords */}
          <Grid item xs={12}>
            <Box sx={{ mb: 2 }}>
              <TextField
                label="Add Tags"
                value={tagInput}
                onChange={(e) => setTagInput(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
                disabled={loading}
                size="small"
                sx={{ mr: 1 }}
              />
              <Button onClick={handleAddTag} disabled={loading}>
                Add Tag
              </Button>
              <Stack direction="row" spacing={1} sx={{ mt: 1 }} flexWrap="wrap">
                {formData.tags.map(tag => (
                  <Chip
                    key={tag}
                    label={tag}
                    onDelete={() => handleRemoveTag(tag)}
                    size="small"
                    disabled={loading}
                  />
                ))}
              </Stack>
            </Box>

            <Box sx={{ mb: 2 }}>
              <TextField
                label="Add Search Keywords"
                value={keywordInput}
                onChange={(e) => setKeywordInput(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddKeyword())}
                disabled={loading}
                size="small"
                sx={{ mr: 1 }}
              />
              <Button onClick={handleAddKeyword} disabled={loading}>
                Add Keyword
              </Button>
              <Stack direction="row" spacing={1} sx={{ mt: 1 }} flexWrap="wrap">
                {formData.searchKeywords.map(keyword => (
                  <Chip
                    key={keyword}
                    label={keyword}
                    onDelete={() => handleRemoveKeyword(keyword)}
                    size="small"
                    color="secondary"
                    disabled={loading}
                  />
                ))}
              </Stack>
            </Box>
          </Grid>

          {/* File Uploads */}
          <Grid item xs={12}>
            <Typography variant="h6" sx={{ mb: 2 }}>
              Files
            </Typography>

            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', mb: 2 }}>
              <Button
                variant="outlined"
                component="label"
                startIcon={<AttachFile />}
                disabled={loading}
              >
                Main File
                <input
                  type="file"
                  hidden
                  onChange={handleFileChange('mainFile')}
                  accept=".pdf,.epub,.zip,.json"
                />
              </Button>
              {formData.mainFile && (
                <Chip label={formData.mainFile.name} onDelete={() => setFormData({ ...formData, mainFile: null })} />
              )}
            </Box>

            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', mb: 2 }}>
              <Button
                variant="outlined"
                component="label"
                startIcon={<ImageIcon />}
                disabled={loading}
              >
                Thumbnail
                <input
                  type="file"
                  hidden
                  onChange={handleFileChange('thumbnailFile')}
                  accept="image/*"
                />
              </Button>
              {formData.thumbnailFile && (
                <Chip label={formData.thumbnailFile.name} onDelete={() => setFormData({ ...formData, thumbnailFile: null })} />
              )}
            </Box>

            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <Button
                variant="outlined"
                component="label"
                startIcon={<CloudUpload />}
                disabled={loading}
              >
                Additional Files
                <input
                  type="file"
                  multiple
                  hidden
                  onChange={handleFileChange('additionalFiles')}
                />
              </Button>
              {formData.additionalFiles.map((file, index) => (
                <Chip
                  key={index}
                  label={file.name}
                  onDelete={() => setFormData({
                    ...formData,
                    additionalFiles: formData.additionalFiles.filter((_, i) => i !== index)
                  })}
                />
              ))}
            </Box>
          </Grid>

          {/* Action Buttons */}
          <Grid item xs={12}>
            <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
              <Button
                variant="outlined"
                onClick={onCancel}
                disabled={loading}
              >
                Cancel
              </Button>
              <Button
                variant="contained"
                startIcon={loading ? <CircularProgress size={20} /> : <Save />}
                onClick={() => handleSubmit(false)}
                disabled={loading || !formData.title}
              >
                Save as Draft
              </Button>
              <Button
                variant="contained"
                color="success"
                startIcon={loading ? <CircularProgress size={20} /> : <Publish />}
                onClick={() => handleSubmit(true)}
                disabled={loading || !formData.title}
              >
                Save & Publish
              </Button>
            </Box>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  )
}