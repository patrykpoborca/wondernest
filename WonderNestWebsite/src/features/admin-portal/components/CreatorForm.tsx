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
  Select
} from '@mui/material'

import { adminApiService } from '@/services/adminApi'
import { ContentCreator, ContentCreatorForm } from '@/types/admin'

interface CreatorFormProps {
  open: boolean
  onClose: () => void
  onSuccess: () => void
  creator?: ContentCreator | null
}

const SPECIALIZATIONS = [
  'Educational Games',
  'Interactive Stories',
  'Art & Creativity',
  'Music & Audio',
  'STEM Activities',
  'Language Learning',
  'Social Skills',
  'Motor Skills',
  'Math & Numbers',
  'Reading & Writing',
  'Science Experiments',
  'Cultural Content'
]

export const CreatorForm: React.FC<CreatorFormProps> = ({
  open,
  onClose,
  onSuccess,
  creator
}) => {
  const [formData, setFormData] = useState<ContentCreatorForm>({
    name: '',
    email: '',
    specialization: '',
    description: ''
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const isEditMode = Boolean(creator)

  useEffect(() => {
    if (creator) {
      setFormData({
        name: creator.name,
        email: creator.email,
        specialization: creator.specialization,
        description: creator.description || ''
      })
    } else {
      setFormData({
        name: '',
        email: '',
        specialization: '',
        description: ''
      })
    }
    setError(null)
  }, [creator, open])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.name.trim() || !formData.email.trim() || !formData.specialization) {
      setError('Please fill in all required fields')
      return
    }

    try {
      setLoading(true)
      setError(null)

      if (isEditMode && creator) {
        await adminApiService.updateCreator(creator.id, formData)
      } else {
        await adminApiService.createCreatorQuick(formData)
      }

      onSuccess()
      handleClose()
    } catch (err: any) {
      setError(err.error || `Failed to ${isEditMode ? 'update' : 'create'} creator`)
    } finally {
      setLoading(false)
    }
  }

  const handleClose = () => {
    if (!loading) {
      onClose()
    }
  }

  const handleChange = (field: keyof ContentCreatorForm) => (
    event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    setFormData(prev => ({
      ...prev,
      [field]: event.target.value
    }))
    if (error) setError(null)
  }

  return (
    <Dialog 
      open={open} 
      onClose={handleClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 2 }
      }}
    >
      <form onSubmit={handleSubmit}>
        <DialogTitle>
          <Typography variant="h6" fontWeight={600}>
            {isEditMode ? 'Edit Creator' : 'Add New Creator'}
          </Typography>
          <Typography variant="body2" color="textSecondary">
            {isEditMode 
              ? 'Update creator information and settings'
              : 'Add a new content creator to the platform'
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
            {/* Name Field */}
            <TextField
              label="Creator Name"
              value={formData.name}
              onChange={handleChange('name')}
              required
              fullWidth
              disabled={loading}
              placeholder="Enter creator's full name"
            />

            {/* Email Field */}
            <TextField
              label="Email Address"
              type="email"
              value={formData.email}
              onChange={handleChange('email')}
              required
              fullWidth
              disabled={loading}
              placeholder="creator@example.com"
            />

            {/* Specialization Field */}
            <FormControl fullWidth required disabled={loading}>
              <InputLabel>Specialization</InputLabel>
              <Select
                value={formData.specialization}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  specialization: e.target.value 
                }))}
                label="Specialization"
              >
                {SPECIALIZATIONS.map((spec) => (
                  <MenuItem key={spec} value={spec}>
                    {spec}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            {/* Description Field */}
            <TextField
              label="Description"
              value={formData.description}
              onChange={handleChange('description')}
              multiline
              rows={3}
              fullWidth
              disabled={loading}
              placeholder="Brief description of the creator's background and expertise (optional)"
            />
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
              ? (isEditMode ? 'Updating...' : 'Creating...') 
              : (isEditMode ? 'Update Creator' : 'Create Creator')
            }
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  )
}