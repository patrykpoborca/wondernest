import React, { useState, useEffect } from 'react';
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
  Switch,
  FormControlLabel,
  FormControl,
  InputLabel,
  Select,
  Checkbox,
  ListItemText,
  OutlinedInput,
  Alert,
  CircularProgress,
  Divider,
  Stepper,
  Step,
  StepLabel,
  Paper,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as PreviewIcon,
  Publish as PublishIcon,
  MonetizationOn as MonetizeIcon,
  Category as CategoryIcon,
  Schedule as DraftIcon,
  CloudUpload as SubmitIcon,
  AutoStories as BookIcon,
  ArrowBack as ArrowBackIcon,
  ArrowForward as ArrowForwardIcon,
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import { useNavigate } from 'react-router-dom';

import { creatorApi, ContentSubmission } from '../services/creatorApi';
import { useCreatorAuth } from '@/contexts/CreatorAuthContext';

const StyledCard = styled(Card)(({ theme }) => ({
  height: '100%',
  display: 'flex',
  flexDirection: 'column',
  transition: 'transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out',
  '&:hover': {
    transform: 'translateY(-4px)',
    boxShadow: theme.shadows[8],
  },
}));

const StyledCardMedia = styled(CardMedia)(({ theme }) => ({
  height: 200,
  backgroundColor: theme.palette.grey[100],
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  position: 'relative',
}));

interface StoryFormData {
  title: string;
  description: string;
  content_type: 'story' | 'interactive';
  target_age_groups: string[];
  categories: string[];
  languages: string[];
  monetization_enabled: boolean;
  pricing_tier: 'free' | 'premium' | 'subscription';
  license_type: 'exclusive' | 'non_exclusive' | 'creative_commons';
  submission_data: {
    pages: any[];
    interactive_elements: any[];
    educational_objectives: string[];
  };
}

interface NewStoryDialogProps {
  open: boolean;
  onClose: () => void;
  onCreateStory: (data: StoryFormData) => void;
  isLoading: boolean;
}

const AGE_GROUPS = ['3-4', '4-6', '6-8', '8-10', '10-12'];
const CATEGORIES = ['Adventure', 'Educational', 'Fantasy', 'Science', 'Animals', 'Family', 'Friendship', 'Problem Solving'];
const LANGUAGES = ['English', 'Spanish', 'French', 'Mandarin', 'German'];

const steps = ['Story Details', 'Content & Categories', 'Monetization Settings'];

const NewStoryDialog: React.FC<NewStoryDialogProps> = ({ 
  open, 
  onClose, 
  onCreateStory, 
  isLoading 
}) => {
  const [activeStep, setActiveStep] = useState(0);
  const [formData, setFormData] = useState<StoryFormData>({
    title: '',
    description: '',
    content_type: 'story',
    target_age_groups: [],
    categories: [],
    languages: ['English'],
    monetization_enabled: false,
    pricing_tier: 'free',
    license_type: 'non_exclusive',
    submission_data: {
      pages: [],
      interactive_elements: [],
      educational_objectives: [],
    },
  });

  const { creator } = useCreatorAuth();

  const handleNext = () => {
    setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const handleSubmit = () => {
    if (formData.title.trim()) {
      onCreateStory(formData);
      setActiveStep(0);
      setFormData({
        title: '',
        description: '',
        content_type: 'story',
        target_age_groups: [],
        categories: [],
        languages: ['English'],
        monetization_enabled: false,
        pricing_tier: 'free',
        license_type: 'non_exclusive',
        submission_data: {
          pages: [],
          interactive_elements: [],
          educational_objectives: [],
        },
      });
    }
  };

  const handleClose = () => {
    setActiveStep(0);
    onClose();
  };

  const handleInputChange = (field: keyof StoryFormData, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
  };

  const isStepValid = (step: number): boolean => {
    switch (step) {
      case 0:
        return formData.title.trim() !== '' && formData.description.trim() !== '';
      case 1:
        return formData.target_age_groups.length > 0 && formData.categories.length > 0;
      case 2:
        return true; // Monetization settings are optional
      default:
        return false;
    }
  };

  const renderStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <TextField
                label="Story Title"
                value={formData.title}
                onChange={(e) => handleInputChange('title', e.target.value)}
                fullWidth
                required
                placeholder="e.g., The Magical Forest Adventure"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                label="Description"
                value={formData.description}
                onChange={(e) => handleInputChange('description', e.target.value)}
                fullWidth
                multiline
                rows={4}
                required
                placeholder="A brief description of your story and its educational value..."
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Content Type</InputLabel>
                <Select
                  value={formData.content_type}
                  onChange={(e) => handleInputChange('content_type', e.target.value)}
                  label="Content Type"
                >
                  <MenuItem value="story">Traditional Story</MenuItem>
                  <MenuItem value="interactive">Interactive Story</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        );
      
      case 1:
        return (
          <Grid container spacing={3}>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Target Age Groups</InputLabel>
                <Select
                  multiple
                  value={formData.target_age_groups}
                  onChange={(e) => handleInputChange('target_age_groups', e.target.value)}
                  input={<OutlinedInput label="Target Age Groups" />}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {(selected as string[]).map((value) => (
                        <Chip key={value} label={`${value} years`} size="small" />
                      ))}
                    </Box>
                  )}
                >
                  {AGE_GROUPS.map((age) => (
                    <MenuItem key={age} value={age}>
                      <Checkbox checked={formData.target_age_groups.indexOf(age) > -1} />
                      <ListItemText primary={`${age} years`} />
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Categories</InputLabel>
                <Select
                  multiple
                  value={formData.categories}
                  onChange={(e) => handleInputChange('categories', e.target.value)}
                  input={<OutlinedInput label="Categories" />}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {(selected as string[]).map((value) => (
                        <Chip key={value} label={value} size="small" />
                      ))}
                    </Box>
                  )}
                >
                  {CATEGORIES.map((category) => (
                    <MenuItem key={category} value={category}>
                      <Checkbox checked={formData.categories.indexOf(category) > -1} />
                      <ListItemText primary={category} />
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Languages</InputLabel>
                <Select
                  multiple
                  value={formData.languages}
                  onChange={(e) => handleInputChange('languages', e.target.value)}
                  input={<OutlinedInput label="Languages" />}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {(selected as string[]).map((value) => (
                        <Chip key={value} label={value} size="small" />
                      ))}
                    </Box>
                  )}
                >
                  {LANGUAGES.map((language) => (
                    <MenuItem key={language} value={language}>
                      <Checkbox checked={formData.languages.indexOf(language) > -1} />
                      <ListItemText primary={language} />
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        );
      
      case 2:
        return (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.monetization_enabled}
                    onChange={(e) => handleInputChange('monetization_enabled', e.target.checked)}
                    disabled={creator?.creator_tier === 'tier_1'}
                  />
                }
                label="Enable Monetization"
              />
              {creator?.creator_tier === 'tier_1' && (
                <Typography variant="caption" color="text.secondary" display="block">
                  Upgrade to Tier 2+ to enable monetization
                </Typography>
              )}
            </Grid>
            
            {formData.monetization_enabled && (
              <>
                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth>
                    <InputLabel>Pricing Tier</InputLabel>
                    <Select
                      value={formData.pricing_tier}
                      onChange={(e) => handleInputChange('pricing_tier', e.target.value)}
                      label="Pricing Tier"
                    >
                      <MenuItem value="free">Free</MenuItem>
                      <MenuItem value="premium">Premium ($0.99-$4.99)</MenuItem>
                      <MenuItem value="subscription">Subscription Only</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                
                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth>
                    <InputLabel>License Type</InputLabel>
                    <Select
                      value={formData.license_type}
                      onChange={(e) => handleInputChange('license_type', e.target.value)}
                      label="License Type"
                    >
                      <MenuItem value="exclusive">Exclusive (Higher Revenue Share)</MenuItem>
                      <MenuItem value="non_exclusive">Non-Exclusive</MenuItem>
                      <MenuItem value="creative_commons">Creative Commons</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
              </>
            )}
          </Grid>
        );
      
      default:
        return 'Unknown step';
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>Create New Story</DialogTitle>
      <DialogContent>
        <Box sx={{ mt: 2, mb: 4 }}>
          <Stepper activeStep={activeStep}>
            {steps.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>
        </Box>
        
        <Box sx={{ mt: 3 }}>
          {renderStepContent(activeStep)}
        </Box>
      </DialogContent>
      
      <DialogActions>
        <Button onClick={handleClose} disabled={isLoading}>
          Cancel
        </Button>
        <Box sx={{ flex: '1 1 auto' }} />
        {activeStep > 0 && (
          <Button onClick={handleBack} disabled={isLoading}>
            Back
          </Button>
        )}
        {activeStep < steps.length - 1 ? (
          <Button
            variant="contained"
            onClick={handleNext}
            disabled={!isStepValid(activeStep)}
          >
            Next
            <ArrowForwardIcon sx={{ ml: 1 }} />
          </Button>
        ) : (
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={!isStepValid(activeStep) || isLoading}
            startIcon={isLoading ? <CircularProgress size={16} /> : <AddIcon />}
          >
            {isLoading ? 'Creating...' : 'Create Story'}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

const StoryCreation: React.FC = () => {
  const navigate = useNavigate();
  const { creator } = useCreatorAuth();
  const [submissions, setSubmissions] = useState<ContentSubmission[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newStoryOpen, setNewStoryOpen] = useState(false);
  const [isCreating, setIsCreating] = useState(false);

  useEffect(() => {
    loadStories();
  }, []);

  const loadStories = async () => {
    try {
      setLoading(true);
      const stories = await creatorApi.getContentSubmissions();
      setSubmissions(stories.filter(s => s.content_type === 'story' || s.content_type === 'interactive'));
    } catch (err) {
      console.error('Failed to load stories:', err);
      setError(err instanceof Error ? err.message : 'Failed to load stories');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateStory = async (storyData: StoryFormData) => {
    try {
      setIsCreating(true);
      
      const submission: Partial<ContentSubmission> = {
        title: storyData.title,
        description: storyData.description,
        content_type: storyData.content_type,
        status: 'draft',
        submission_data: {
          ...storyData.submission_data,
          target_age_groups: storyData.target_age_groups,
          categories: storyData.categories,
          languages: storyData.languages,
          monetization: {
            enabled: storyData.monetization_enabled,
            pricing_tier: storyData.pricing_tier,
            license_type: storyData.license_type,
          },
        },
      };

      const newSubmission = await creatorApi.submitContent(submission);
      
      setSubmissions(prev => [newSubmission, ...prev]);
      setNewStoryOpen(false);
      
      // Navigate to story editor (to be implemented)
      navigate(`/creator/stories/edit/${newSubmission.id}`);
    } catch (err) {
      console.error('Failed to create story:', err);
      setError(err instanceof Error ? err.message : 'Failed to create story');
    } finally {
      setIsCreating(false);
    }
  };

  const getStatusColor = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
    switch (status) {
      case 'published':
        return 'success';
      case 'under_review':
      case 'submitted':
        return 'warning';
      case 'rejected':
        return 'error';
      case 'approved':
        return 'info';
      default:
        return 'default';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '60vh' }}>
        <CircularProgress />
        <Typography variant="body2" sx={{ ml: 2 }}>
          Loading your stories...
        </Typography>
      </Box>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', alignItems: 'center', gap: 2 }}>
        <BookIcon sx={{ fontSize: 32, color: 'primary.main' }} />
        <Box sx={{ flexGrow: 1 }}>
          <Typography variant="h4" component="h1" gutterBottom>
            Story Creation Studio
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Create engaging educational stories for children and families
          </Typography>
        </Box>
        <Button
          variant="contained"
          size="large"
          startIcon={<AddIcon />}
          onClick={() => setNewStoryOpen(true)}
        >
          New Story
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Creator Tier Info */}
      {creator?.creator_tier === 'tier_1' && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="body2">
            You're on Tier 1. Upgrade to enable monetization features and reach a wider audience.
          </Typography>
        </Alert>
      )}

      {/* Stories Grid */}
      {submissions.length === 0 ? (
        <Paper
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: 400,
            textAlign: 'center',
            p: 4,
          }}
        >
          <BookIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
          <Typography variant="h5" color="text.secondary" gutterBottom>
            No stories yet
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
            Start creating engaging educational content for children!
          </Typography>
          <Button
            variant="contained"
            size="large"
            startIcon={<AddIcon />}
            onClick={() => setNewStoryOpen(true)}
          >
            Create Your First Story
          </Button>
        </Paper>
      ) : (
        <Grid container spacing={3}>
          {submissions.map((story) => (
            <Grid item xs={12} sm={6} md={4} lg={3} key={story.id}>
              <StyledCard>
                <StyledCardMedia>
                  {story.submission_data?.thumbnail ? (
                    <img 
                      src={story.submission_data.thumbnail} 
                      alt={story.title}
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    />
                  ) : (
                    <BookIcon sx={{ fontSize: 48, color: 'text.secondary' }} />
                  )}
                </StyledCardMedia>
                
                <CardContent sx={{ flexGrow: 1, pb: 1 }}>
                  <Typography variant="h6" component="h3" gutterBottom>
                    {story.title}
                  </Typography>
                  
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
                      label={story.status.replace('_', ' ')} 
                      size="small" 
                      color={getStatusColor(story.status)}
                    />
                    <Chip 
                      label={story.content_type} 
                      size="small" 
                      variant="outlined"
                    />
                    {story.submission_data?.monetization?.enabled && (
                      <Chip 
                        icon={<MonetizeIcon />}
                        label="Monetized" 
                        size="small" 
                        color="success"
                        variant="outlined"
                      />
                    )}
                  </Box>

                  <Typography variant="caption" color="text.secondary">
                    Created {formatDate(story.created_at)}
                  </Typography>
                </CardContent>

                <CardActions sx={{ pt: 0, px: 2, pb: 2 }}>
                  <Button 
                    size="small" 
                    startIcon={<EditIcon />}
                    onClick={() => navigate(`/creator/stories/edit/${story.id}`)}
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

      {/* New Story Dialog */}
      <NewStoryDialog
        open={newStoryOpen}
        onClose={() => setNewStoryOpen(false)}
        onCreateStory={handleCreateStory}
        isLoading={isCreating}
      />
    </Container>
  );
};

export default StoryCreation;