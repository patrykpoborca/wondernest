import React, { useState, useCallback, useEffect } from 'react'
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  IconButton,
  ToggleButton,
  ToggleButtonGroup,
  Chip,
  CircularProgress,
  Alert,
  Fade,
  Collapse,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  Tooltip,
  Divider,
  Card,
  CardContent,
  CardActions,
  LinearProgress,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material'
import {
  AutoAwesome as AIIcon,
  Speed as QuickIcon,
  Build as BuilderIcon,
  CenterFocusStrong as FocusIcon,
  Send as SendIcon,
  Clear as ClearIcon,
  ThumbUp as AcceptIcon,
  ThumbDown as RejectIcon,
  Edit as EditIcon,
  Refresh as RefreshIcon,
  ExpandMore as ExpandIcon,
  School as EducationIcon,
  Psychology as SuggestionIcon,
  Lightbulb as IdeaIcon,
  History as HistoryIcon,
  Close as CloseIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'
import { useDispatch, useSelector } from 'react-redux'
import { RootState } from '../../../store'
import {
  toggleAI,
  setAIMode,
  startAIGeneration,
  completeAIGeneration,
  acceptAISuggestion,
  rejectAISuggestion,
  clearAISuggestion,
  updateAIMetadata,
} from '../../../store/slices/storyBuilderSlice'
import { 
  useGenerateStoryMutation,
  useEnhanceTextMutation,
  useGetSuggestionsMutation,
} from '../api/storyGameDataApi'

const PanelContainer = styled(Paper)(({ theme }) => ({
  height: '100%',
  display: 'flex',
  flexDirection: 'column',
  backgroundColor: theme.palette.background.paper,
  borderRadius: 0,
}))

const PanelHeader = styled(Box)(({ theme }) => ({
  padding: theme.spacing(2),
  borderBottom: `1px solid ${theme.palette.divider}`,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
}))

const PanelContent = styled(Box)(({ theme }) => ({
  flex: 1,
  overflow: 'auto',
  padding: theme.spacing(2),
}))

const ModeSelector = styled(ToggleButtonGroup)(({ theme }) => ({
  width: '100%',
  '& .MuiToggleButton-root': {
    flex: 1,
    py: 1,
    textTransform: 'none',
  },
}))

const PromptInput = styled(TextField)(({ theme }) => ({
  '& .MuiOutlinedInput-root': {
    backgroundColor: theme.palette.grey[50],
  },
}))

const SuggestionCard = styled(Card)(({ theme }) => ({
  marginBottom: theme.spacing(2),
  backgroundColor: theme.palette.primary.main + '08',
  border: `1px solid ${theme.palette.primary.main}40`,
}))

const MetadataBox = styled(Box)(({ theme }) => ({
  padding: theme.spacing(1.5),
  backgroundColor: theme.palette.grey[100],
  borderRadius: theme.spacing(1),
  marginBottom: theme.spacing(2),
}))

const HistoryItem = styled(ListItem)(({ theme }) => ({
  borderRadius: theme.spacing(1),
  marginBottom: theme.spacing(1),
  '&:hover': {
    backgroundColor: theme.palette.action.hover,
  },
}))

interface AIAssistantPanelProps {
  onClose?: () => void
  currentPageContent?: string
  selectedText?: string
  onApplySuggestion?: (text: string) => void
}

export const AIAssistantPanel: React.FC<AIAssistantPanelProps> = ({
  onClose,
  currentPageContent,
  selectedText,
  onApplySuggestion,
}) => {
  const dispatch = useDispatch()
  const { aiState, currentDraft } = useSelector((state: RootState) => state.storyBuilder)
  const [prompt, setPrompt] = useState('')
  const [showHistory, setShowHistory] = useState(false)
  const [educationalGoals, setEducationalGoals] = useState<string[]>([])
  const [vocabularyLevel, setVocabularyLevel] = useState('grade_2')

  const [generateStory] = useGenerateStoryMutation()
  const [enhanceText] = useEnhanceTextMutation()
  const [getSuggestions] = useGetSuggestionsMutation()

  // Mode descriptions
  const modeDescriptions = {
    quick: 'Quick suggestions and enhancements for selected text',
    builder: 'Full story generation with educational goals',
    focus: 'Focused assistance on specific story elements'
  }

  const handleModeChange = (event: React.MouseEvent<HTMLElement>, newMode: string | null) => {
    if (newMode) {
      dispatch(setAIMode(newMode as 'quick' | 'builder' | 'focus'))
    }
  }

  const handleGenerateStory = async () => {
    if (!prompt.trim()) return

    try {
      dispatch(startAIGeneration({
        prompt: prompt.trim(),
        title: currentDraft?.title,
        ageRange: currentDraft?.metadata?.targetAge?.join('-') || '5-8',
        educationalGoals,
        vocabularyLevel,
      }))

      const response = await generateStory({
        prompt: prompt.trim(),
        title: currentDraft?.title,
        age_range: currentDraft?.metadata?.targetAge?.join('-') || '5-8',
        educational_goals: educationalGoals,
        vocabulary_level: vocabularyLevel,
        include_images: true,
      }).unwrap()

      // Create suggestion from response
      const suggestion = {
        id: Date.now().toString(),
        text: response.pages.map(p => p.content).join('\n\n'),
        type: 'full_story' as const,
        reasoning: 'AI generated full story based on your prompt',
        confidence: 0.9,
        createdAt: new Date().toISOString(),
      }

      dispatch(completeAIGeneration({
        suggestion,
        history: {
          id: Date.now().toString(),
          type: 'generation',
          input: prompt,
          output: suggestion.text,
          accepted: false,
          timestamp: new Date().toISOString(),
        }
      }))

      // Update metadata
      dispatch(updateAIMetadata({
        percentAIGenerated: 100,
        lastAIAssistTime: new Date().toISOString(),
        educationalGoals,
        vocabularyLevel,
      }))

      setPrompt('')
    } catch (error) {
      console.error('Failed to generate story:', error)
      dispatch(completeAIGeneration({ suggestion: null }))
    }
  }

  const handleEnhanceText = async (mode: 'simplify' | 'elaborate' | 'vocabulary' | 'exciting' | 'educational') => {
    if (!selectedText) return

    try {
      dispatch(startAIGeneration({
        prompt: selectedText,
        mode,
      }))

      const modeMap = {
        simplify: 'simplify',
        elaborate: 'elaborate',
        vocabulary: 'add_vocabulary',
        exciting: 'make_exciting',
        educational: 'add_educational',
      }

      const response = await enhanceText({
        text: selectedText,
        mode: modeMap[mode] as any,
        context: currentPageContent,
      }).unwrap()

      const suggestion = {
        id: Date.now().toString(),
        text: response.enhanced_text,
        type: 'enhancement' as const,
        reasoning: response.changes_made.join(', '),
        confidence: 0.85,
        createdAt: new Date().toISOString(),
      }

      dispatch(completeAIGeneration({
        suggestion,
        history: {
          id: Date.now().toString(),
          type: 'enhancement',
          input: selectedText,
          output: suggestion.text,
          accepted: false,
          timestamp: new Date().toISOString(),
        }
      }))

    } catch (error) {
      console.error('Failed to enhance text:', error)
      dispatch(completeAIGeneration({ suggestion: null }))
    }
  }

  const handleGetSuggestion = async (type: 'next_sentence' | 'plot_twist' | 'dialogue' | 'ending') => {
    try {
      dispatch(startAIGeneration({ prompt: currentPageContent || '', mode: 'quick' }))

      const typeMap = {
        next_sentence: 'next_sentence',
        plot_twist: 'plot_twist',
        dialogue: 'dialogue',
        ending: 'ending',
      }

      const response = await getSuggestions({
        context: {
          current_text: currentPageContent || '',
          story_title: currentDraft?.title || '',
          target_age: currentDraft?.metadata?.targetAge?.join('-') || '5-8',
        },
        suggestion_type: typeMap[type] as any,
      }).unwrap()

      if (response.suggestions.length > 0) {
        const firstSuggestion = response.suggestions[0]
        const suggestion = {
          id: Date.now().toString(),
          text: firstSuggestion.text,
          type: 'sentence' as const,
          reasoning: firstSuggestion.reasoning,
          educationalValue: firstSuggestion.educational_value,
          confidence: response.confidence_score,
          createdAt: new Date().toISOString(),
        }

        dispatch(completeAIGeneration({
          suggestion,
          history: {
            id: Date.now().toString(),
            type: 'suggestion',
            input: currentPageContent || '',
            output: suggestion.text,
            accepted: false,
            timestamp: new Date().toISOString(),
          }
        }))
      }

    } catch (error) {
      console.error('Failed to get suggestion:', error)
      dispatch(completeAIGeneration({ suggestion: null }))
    }
  }

  const handleAcceptSuggestion = () => {
    if (aiState.currentSuggestion && onApplySuggestion) {
      onApplySuggestion(aiState.currentSuggestion.text)
      dispatch(acceptAISuggestion())
    }
  }

  const handleRejectSuggestion = () => {
    dispatch(rejectAISuggestion())
  }

  const renderQuickMode = () => (
    <Box>
      {selectedText ? (
        <>
          <Alert severity="info" sx={{ mb: 2 }}>
            Text selected: "{selectedText.substring(0, 50)}..."
          </Alert>
          
          <Typography variant="subtitle2" gutterBottom>
            Quick Enhancements
          </Typography>
          
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mb: 2 }}>
            <Button
              size="small"
              variant="outlined"
              onClick={() => handleEnhanceText('simplify')}
              disabled={aiState.isGenerating}
            >
              Simplify
            </Button>
            <Button
              size="small"
              variant="outlined"
              onClick={() => handleEnhanceText('elaborate')}
              disabled={aiState.isGenerating}
            >
              Elaborate
            </Button>
            <Button
              size="small"
              variant="outlined"
              onClick={() => handleEnhanceText('vocabulary')}
              disabled={aiState.isGenerating}
            >
              Add Vocabulary
            </Button>
            <Button
              size="small"
              variant="outlined"
              onClick={() => handleEnhanceText('exciting')}
              disabled={aiState.isGenerating}
            >
              Make Exciting
            </Button>
          </Box>
        </>
      ) : (
        <Alert severity="info">
          Select text in the editor to see enhancement options
        </Alert>
      )}
      
      <Divider sx={{ my: 2 }} />
      
      <Typography variant="subtitle2" gutterBottom>
        Quick Suggestions
      </Typography>
      
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
        <Button
          size="small"
          variant="outlined"
          onClick={() => handleGetSuggestion('next_sentence')}
          disabled={aiState.isGenerating}
        >
          Next Sentence
        </Button>
        <Button
          size="small"
          variant="outlined"
          onClick={() => handleGetSuggestion('dialogue')}
          disabled={aiState.isGenerating}
        >
          Add Dialogue
        </Button>
        <Button
          size="small"
          variant="outlined"
          onClick={() => handleGetSuggestion('plot_twist')}
          disabled={aiState.isGenerating}
        >
          Plot Twist
        </Button>
        <Button
          size="small"
          variant="outlined"
          onClick={() => handleGetSuggestion('ending')}
          disabled={aiState.isGenerating}
        >
          Story Ending
        </Button>
      </Box>
    </Box>
  )

  const renderBuilderMode = () => (
    <Box>
      <PromptInput
        fullWidth
        multiline
        rows={4}
        variant="outlined"
        placeholder="Describe your story idea..."
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        sx={{ mb: 2 }}
      />
      
      <Box sx={{ mb: 2 }}>
        <Typography variant="subtitle2" gutterBottom>
          Educational Goals
        </Typography>
        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
          {['Vocabulary', 'Reading', 'Empathy', 'Problem Solving', 'Creativity'].map((goal) => (
            <Chip
              key={goal}
              label={goal}
              onClick={() => {
                if (educationalGoals.includes(goal)) {
                  setEducationalGoals(educationalGoals.filter(g => g !== goal))
                } else {
                  setEducationalGoals([...educationalGoals, goal])
                }
              }}
              color={educationalGoals.includes(goal) ? 'primary' : 'default'}
              variant={educationalGoals.includes(goal) ? 'filled' : 'outlined'}
              size="small"
            />
          ))}
        </Box>
      </Box>
      
      <Box sx={{ mb: 2 }}>
        <Typography variant="subtitle2" gutterBottom>
          Vocabulary Level
        </Typography>
        <ToggleButtonGroup
          value={vocabularyLevel}
          exclusive
          onChange={(e, value) => value && setVocabularyLevel(value)}
          fullWidth
          size="small"
        >
          <ToggleButton value="kindergarten">K</ToggleButton>
          <ToggleButton value="grade_1">1st</ToggleButton>
          <ToggleButton value="grade_2">2nd</ToggleButton>
          <ToggleButton value="grade_3">3rd</ToggleButton>
        </ToggleButtonGroup>
      </Box>
      
      <Button
        fullWidth
        variant="contained"
        startIcon={<AIIcon />}
        onClick={handleGenerateStory}
        disabled={!prompt.trim() || aiState.isGenerating}
      >
        Generate Story
      </Button>
    </Box>
  )

  const renderFocusMode = () => (
    <Box>
      <Alert severity="info" sx={{ mb: 2 }}>
        Focus mode provides targeted assistance for specific story elements
      </Alert>
      
      <List>
        <ListItem button onClick={() => handleGetSuggestion('next_sentence')}>
          <ListItemIcon>
            <IdeaIcon />
          </ListItemIcon>
          <ListItemText
            primary="Character Development"
            secondary="Get help developing your characters"
          />
        </ListItem>
        
        <ListItem button onClick={() => handleGetSuggestion('plot_twist')}>
          <ListItemIcon>
            <SuggestionIcon />
          </ListItemIcon>
          <ListItemText
            primary="Plot Structure"
            secondary="Improve your story's narrative flow"
          />
        </ListItem>
        
        <ListItem button onClick={() => handleGetSuggestion('dialogue')}>
          <ListItemIcon>
            <EducationIcon />
          </ListItemIcon>
          <ListItemText
            primary="Educational Content"
            secondary="Add learning opportunities"
          />
        </ListItem>
      </List>
    </Box>
  )

  const renderCurrentSuggestion = () => {
    if (!aiState.currentSuggestion) return null

    return (
      <Fade in={true}>
        <SuggestionCard>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
              <AIIcon sx={{ mr: 1, color: 'primary.main' }} />
              <Typography variant="subtitle1" sx={{ flex: 1 }}>
                AI Suggestion
              </Typography>
              <Chip
                label={`${Math.round(aiState.currentSuggestion.confidence * 100)}% confidence`}
                size="small"
                color="primary"
                variant="outlined"
              />
            </Box>
            
            <Typography variant="body2" sx={{ mb: 2 }}>
              {aiState.currentSuggestion.text}
            </Typography>
            
            {aiState.currentSuggestion.reasoning && (
              <Typography variant="caption" color="text.secondary">
                {aiState.currentSuggestion.reasoning}
              </Typography>
            )}
          </CardContent>
          
          <CardActions>
            <Button
              size="small"
              startIcon={<AcceptIcon />}
              onClick={handleAcceptSuggestion}
              color="success"
            >
              Accept
            </Button>
            <Button
              size="small"
              startIcon={<EditIcon />}
              onClick={() => {
                setPrompt(aiState.currentSuggestion?.text || '')
                dispatch(clearAISuggestion())
              }}
            >
              Edit
            </Button>
            <Button
              size="small"
              startIcon={<RejectIcon />}
              onClick={handleRejectSuggestion}
              color="error"
            >
              Reject
            </Button>
          </CardActions>
        </SuggestionCard>
      </Fade>
    )
  }

  const renderHistory = () => (
    <Box>
      <List>
        {aiState.history.slice(-5).reverse().map((item) => (
          <HistoryItem key={item.id}>
            <ListItemIcon>
              {item.type === 'generation' ? <AIIcon /> : <EditIcon />}
            </ListItemIcon>
            <ListItemText
              primary={item.output.substring(0, 50) + '...'}
              secondary={new Date(item.timestamp).toLocaleTimeString()}
            />
            <ListItemSecondaryAction>
              {item.accepted ? (
                <Chip label="Used" size="small" color="success" />
              ) : (
                <Chip label="Discarded" size="small" />
              )}
            </ListItemSecondaryAction>
          </HistoryItem>
        ))}
      </List>
    </Box>
  )

  return (
    <PanelContainer elevation={0}>
      <PanelHeader>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <AIIcon sx={{ color: 'primary.main' }} />
          <Typography variant="h6">AI Assistant</Typography>
        </Box>
        {onClose && (
          <IconButton onClick={onClose} size="small">
            <CloseIcon />
          </IconButton>
        )}
      </PanelHeader>
      
      <Box sx={{ px: 2, pt: 2 }}>
        <ModeSelector
          value={aiState.mode}
          exclusive
          onChange={handleModeChange}
          aria-label="AI mode"
        >
          <ToggleButton value="quick">
            <QuickIcon sx={{ mr: 0.5, fontSize: 18 }} />
            Quick
          </ToggleButton>
          <ToggleButton value="builder">
            <BuilderIcon sx={{ mr: 0.5, fontSize: 18 }} />
            Builder
          </ToggleButton>
          <ToggleButton value="focus">
            <FocusIcon sx={{ mr: 0.5, fontSize: 18 }} />
            Focus
          </ToggleButton>
        </ModeSelector>
        
        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1, mb: 2 }}>
          {modeDescriptions[aiState.mode]}
        </Typography>
      </Box>
      
      <PanelContent>
        {aiState.isGenerating && (
          <Box sx={{ mb: 2 }}>
            <LinearProgress />
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1 }}>
              Generating AI content...
            </Typography>
          </Box>
        )}
        
        {renderCurrentSuggestion()}
        
        {aiState.mode === 'quick' && renderQuickMode()}
        {aiState.mode === 'builder' && renderBuilderMode()}
        {aiState.mode === 'focus' && renderFocusMode()}
        
        {aiState.metadata && (
          <MetadataBox sx={{ mt: 3 }}>
            <Typography variant="caption" color="text.secondary">
              AI Usage: {aiState.metadata.percentAIGenerated}% AI-generated •
              {' '}{aiState.metadata.totalSuggestionsAccepted} suggestions accepted
            </Typography>
          </MetadataBox>
        )}
        
        <Accordion sx={{ mt: 2 }}>
          <AccordionSummary expandIcon={<ExpandIcon />}>
            <Typography variant="subtitle2">
              <HistoryIcon sx={{ mr: 1, fontSize: 18, verticalAlign: 'middle' }} />
              Recent AI Activity
            </Typography>
          </AccordionSummary>
          <AccordionDetails>
            {aiState.history.length > 0 ? renderHistory() : (
              <Typography variant="body2" color="text.secondary">
                No AI activity yet
              </Typography>
            )}
          </AccordionDetails>
        </Accordion>
      </PanelContent>
    </PanelContainer>
  )
}