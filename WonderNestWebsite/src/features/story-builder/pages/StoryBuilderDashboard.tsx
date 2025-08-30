import React, { useState } from 'react'
import {
  Box,
  Container,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  CardMedia,
  CardActions,
  IconButton,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  CircularProgress,
  Alert,
  Fab,
  Menu,
  MenuProps,
  alpha,
} from '@mui/material'
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as PreviewIcon,
  Publish as PublishIcon,
  MoreVert as MoreIcon,
  AutoStories as BookIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'
import { useNavigate } from 'react-router-dom'

import { useMockGetDraftsQuery, useMockCreateDraftMutation, useDeleteDraftMutation } from '../api/storyBuilderApi'
import { StoryDraft } from '../types/story'

const StyledCard = styled(Card)(({ theme }) => ({
  height: '100%',
  display: 'flex',
  flexDirection: 'column',
  transition: 'transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out',
  '&:hover': {
    transform: 'translateY(-4px)',
    boxShadow: theme.shadows[8],
  },
}))

const StyledCardMedia = styled(CardMedia)(({ theme }) => ({
  height: 200,
  backgroundColor: theme.palette.grey[100],
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  position: 'relative',
}))

const StyledFab = styled(Fab)(({ theme }) => ({
  position: 'fixed',
  bottom: theme.spacing(3),
  right: theme.spacing(3),
  zIndex: 1000,
}))

const StyledMenu = styled((props: MenuProps) => (
  <Menu
    elevation={0}
    anchorOrigin={{
      vertical: 'bottom',
      horizontal: 'right',
    }}
    transformOrigin={{
      vertical: 'top',
      horizontal: 'right',
    }}
    {...props}
  />
))(({ theme }) => ({
  '& .MuiPaper-root': {
    borderRadius: 6,
    marginTop: theme.spacing(1),
    minWidth: 180,
    color:
      theme.palette.mode === 'light' ? 'rgb(55, 65, 81)' : theme.palette.grey[300],
    boxShadow:
      'rgb(255, 255, 255) 0px 0px 0px 0px, rgba(0, 0, 0, 0.05) 0px 0px 0px 1px, rgba(0, 0, 0, 0.1) 0px 10px 15px -3px, rgba(0, 0, 0, 0.05) 0px 4px 6px -2px',
    '& .MuiMenu-list': {
      padding: '4px 0',
    },
    '& .MuiMenuItem-root': {
      '& .MuiSvgIcon-root': {
        fontSize: 18,
        color: theme.palette.text.secondary,
        marginRight: theme.spacing(1.5),
      },
      '&:active': {
        backgroundColor: alpha(
          theme.palette.primary.main,
          theme.palette.action.selectedOpacity,
        ),
      },
    },
  },
}))

interface NewStoryDialogProps {
  open: boolean
  onClose: () => void
  onCreateStory: (title: string, description: string, targetAge: [number, number]) => void
  isLoading: boolean
}

const NewStoryDialog: React.FC<NewStoryDialogProps> = ({ open, onClose, onCreateStory, isLoading }) => {
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [minAge, setMinAge] = useState(4)
  const [maxAge, setMaxAge] = useState(6)

  const handleSubmit = () => {
    if (title.trim()) {
      onCreateStory(title.trim(), description.trim(), [minAge, maxAge])
      setTitle('')
      setDescription('')
      setMinAge(4)
      setMaxAge(6)
    }
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>Create New Story</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          <TextField
            label="Story Title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            fullWidth
            required
            placeholder="e.g., The Brave Little Bunny"
          />
          
          <TextField
            label="Description (Optional)"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            fullWidth
            multiline
            rows={3}
            placeholder="A brief description of your story..."
          />

          <Box sx={{ display: 'flex', gap: 2 }}>
            <TextField
              select
              label="Minimum Age"
              value={minAge}
              onChange={(e) => setMinAge(Number(e.target.value))}
              sx={{ flex: 1 }}
            >
              {[3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((age) => (
                <MenuItem key={age} value={age}>{age} years</MenuItem>
              ))}
            </TextField>

            <TextField
              select
              label="Maximum Age"
              value={maxAge}
              onChange={(e) => setMaxAge(Number(e.target.value))}
              sx={{ flex: 1 }}
            >
              {[3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((age) => (
                <MenuItem key={age} value={age} disabled={age <= minAge}>
                  {age} years
                </MenuItem>
              ))}
            </TextField>
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={isLoading}>
          Cancel
        </Button>
        <Button 
          onClick={handleSubmit} 
          variant="contained" 
          disabled={!title.trim() || isLoading}
          startIcon={isLoading ? <CircularProgress size={16} /> : <AddIcon />}
        >
          {isLoading ? 'Creating...' : 'Create Story'}
        </Button>
      </DialogActions>
    </Dialog>
  )
}

export const StoryBuilderDashboard: React.FC = () => {
  const navigate = useNavigate()
  const { data: draftsData, isLoading, error } = useMockGetDraftsQuery({})
  const [createDraft, { isLoading: isCreating }] = useMockCreateDraftMutation()
  const [deleteDraft] = useDeleteDraftMutation()

  const [newStoryOpen, setNewStoryOpen] = useState(false)
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
  const [selectedStory, setSelectedStory] = useState<StoryDraft | null>(null)

  const drafts = draftsData?.data || []

  const handleCreateStory = async (title: string, description: string, targetAge: [number, number]) => {
    try {
      const result = await createDraft({
        title,
        description,
        targetAge,
      }).unwrap()
      
      setNewStoryOpen(false)
      navigate(`/app/parent/story-builder/editor/${result.id}`)
    } catch (error) {
      console.error('Failed to create story:', error)
    }
  }

  const handleEditStory = (storyId: string) => {
    navigate(`/app/parent/story-builder/editor/${storyId}`)
    setAnchorEl(null)
  }

  const handleDeleteStory = async (storyId: string) => {
    if (window.confirm('Are you sure you want to delete this story? This action cannot be undone.')) {
      try {
        await deleteDraft(storyId).unwrap()
      } catch (error) {
        console.error('Failed to delete story:', error)
      }
    }
    setAnchorEl(null)
  }

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, story: StoryDraft) => {
    setAnchorEl(event.currentTarget)
    setSelectedStory(story)
  }

  const handleMenuClose = () => {
    setAnchorEl(null)
    setSelectedStory(null)
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft':
        return 'default'
      case 'published':
        return 'success'
      case 'archived':
        return 'secondary'
      default:
        return 'default'
    }
  }

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '60vh' }}>
        <CircularProgress />
      </Box>
    )
  }

  if (error) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4 }}>
        <Alert severity="error">
          Failed to load your stories. Please try again later.
        </Alert>
      </Container>
    )
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', alignItems: 'center', gap: 2 }}>
        <BookIcon sx={{ fontSize: 32, color: 'primary.main' }} />
        <Box sx={{ flexGrow: 1 }}>
          <Typography variant="h4" component="h1" gutterBottom>
            Story Builder
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Create interactive stories for your children to enjoy and learn from
          </Typography>
        </Box>
        <Button
          variant="contained"
          size="large"
          startIcon={<AddIcon />}
          onClick={() => setNewStoryOpen(true)}
          sx={{ display: { xs: 'none', sm: 'flex' } }}
        >
          New Story
        </Button>
      </Box>

      {/* Stories Grid */}
      {drafts.length === 0 ? (
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: 400,
            textAlign: 'center',
            gap: 2,
          }}
        >
          <BookIcon sx={{ fontSize: 64, color: 'text.secondary' }} />
          <Typography variant="h5" color="text.secondary">
            No stories yet
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
            Create your first story and bring imagination to life!
          </Typography>
          <Button
            variant="contained"
            size="large"
            startIcon={<AddIcon />}
            onClick={() => setNewStoryOpen(true)}
          >
            Create Your First Story
          </Button>
        </Box>
      ) : (
        <Grid container spacing={3}>
          {drafts.map((story) => (
            <Grid item xs={12} sm={6} md={4} lg={3} key={story.id}>
              <StyledCard>
                <StyledCardMedia>
                  {story.thumbnail ? (
                    <img 
                      src={story.thumbnail} 
                      alt={story.title}
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    />
                  ) : (
                    <BookIcon sx={{ fontSize: 48, color: 'text.secondary' }} />
                  )}
                </StyledCardMedia>
                
                <CardContent sx={{ flexGrow: 1, pb: 1 }}>
                  <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="h6" component="h3" sx={{ flexGrow: 1, mr: 1 }}>
                      {story.title}
                    </Typography>
                    <IconButton 
                      size="small" 
                      onClick={(e) => handleMenuClick(e, story)}
                    >
                      <MoreIcon />
                    </IconButton>
                  </Box>
                  
                  {story.description && (
                    <Typography 
                      variant="body2" 
                      color="text.secondary" 
                      sx={{ 
                        mb: 2, 
                        display: '-webkit-box',
                        WebkitLineClamp: 2,
                        WebkitBoxOrient: 'vertical',
                        overflow: 'hidden',
                      }}
                    >
                      {story.description}
                    </Typography>
                  )}

                  <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
                    <Chip 
                      label={story.status} 
                      size="small" 
                      color={getStatusColor(story.status) as any}
                    />
                    <Chip 
                      label={`${story.pageCount} page${story.pageCount !== 1 ? 's' : ''}`} 
                      size="small" 
                      variant="outlined"
                    />
                    <Chip 
                      label={`Ages ${story.metadata.targetAge[0]}-${story.metadata.targetAge[1]}`} 
                      size="small" 
                      variant="outlined"
                    />
                  </Box>

                  <Typography variant="caption" color="text.secondary">
                    Modified {new Date(story.lastModified).toLocaleDateString()}
                  </Typography>
                </CardContent>

                <CardActions sx={{ pt: 0, px: 2, pb: 2 }}>
                  <Button 
                    size="small" 
                    startIcon={<EditIcon />}
                    onClick={() => handleEditStory(story.id)}
                    variant="contained"
                    fullWidth
                  >
                    Edit
                  </Button>
                </CardActions>
              </StyledCard>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Floating Action Button for mobile */}
      <StyledFab
        color="primary"
        onClick={() => setNewStoryOpen(true)}
        sx={{ display: { xs: 'flex', sm: 'none' } }}
      >
        <AddIcon />
      </StyledFab>

      {/* Context Menu */}
      <StyledMenu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={() => selectedStory && handleEditStory(selectedStory.id)}>
          <EditIcon />
          Edit Story
        </MenuItem>
        <MenuItem onClick={() => console.log('Preview not implemented yet')}>
          <PreviewIcon />
          Preview
        </MenuItem>
        <MenuItem onClick={() => console.log('Publish not implemented yet')}>
          <PublishIcon />
          Publish
        </MenuItem>
        <MenuItem 
          onClick={() => selectedStory && handleDeleteStory(selectedStory.id)}
          sx={{ color: 'error.main' }}
        >
          <DeleteIcon />
          Delete
        </MenuItem>
      </StyledMenu>

      {/* New Story Dialog */}
      <NewStoryDialog
        open={newStoryOpen}
        onClose={() => setNewStoryOpen(false)}
        onCreateStory={handleCreateStory}
        isLoading={isCreating}
      />
    </Container>
  )
}