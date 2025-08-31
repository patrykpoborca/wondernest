import React, { useEffect, useState, useCallback, useRef } from 'react'
import {
  Box,
  AppBar,
  Toolbar,
  Typography,
  Button,
  IconButton,
  Alert,
  Snackbar,
  LinearProgress,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
} from '@mui/material'
import {
  ArrowBack as BackIcon,
  Save as SaveIcon,
  Visibility as PreviewIcon,
  Publish as PublishIcon,
  MoreVert as MoreIcon,
  Settings as SettingsIcon,
  CloudDone as SavedIcon,
  Warning as UnsavedIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'
import { useParams, useNavigate } from 'react-router-dom'
import { useDispatch, useSelector } from 'react-redux'

import { 
  useGetStoryDraftQuery,
  useUpdateStoryDraftMutation
} from '../api/storyGameDataApi'
import { 
  setCurrentDraft, 
  updateCurrentDraftContent,
  addPageToCurrentDraft,
  removePageFromCurrentDraft,
  reorderPages,
  setError,
  clearError,
  setSavingLoading,
  setLastAutoSave,
} from '../../../store/slices/storyBuilderSlice'
import { RootState } from '../../../store'
import { StoryPage, StoryContent } from '../types/story'
import { PageNavigator } from '../components/PageNavigator'
import { StoryCanvas } from '../components/StoryCanvas'
import { LogoutButton } from '@/components/common/LogoutButton'

const EditorContainer = styled(Box)(({ theme }) => ({
  display: 'flex',
  flexDirection: 'column',
  height: '100vh',
  backgroundColor: theme.palette.grey[50],
}))

const EditorAppBar = styled(AppBar)(({ theme }) => ({
  backgroundColor: theme.palette.background.paper,
  color: theme.palette.text.primary,
  boxShadow: theme.shadows[1],
}))

const SaveStatusIndicator = styled(Box, {
  shouldForwardProp: (prop) => prop !== 'saved',
})<{ saved: boolean }>(({ theme, saved }) => ({
  display: 'flex',
  alignItems: 'center',
  gap: theme.spacing(0.5),
  color: saved ? theme.palette.success.main : theme.palette.warning.main,
  fontSize: '0.875rem',
}))

const AUTO_SAVE_DELAY = 2000 // 2 seconds

export const StoryEditor: React.FC = () => {
  const { draftId } = useParams<{ draftId: string }>()
  const navigate = useNavigate()
  const dispatch = useDispatch()
  
  const { currentDraft, loading, error, lastAutoSave } = useSelector(
    (state: RootState) => state.storyBuilder
  )
  
  // Load draft from backend
  const { data: backendDraft, isLoading: isDraftLoading, error: draftError } = useGetStoryDraftQuery(
    draftId || '', 
    { skip: !draftId }
  )
  const [updateDraft] = useUpdateStoryDraftMutation()
  const [currentPageIndex, setCurrentPageIndex] = useState(0)
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false)
  const [saveSuccess, setSaveSuccess] = useState(false)
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null)
  
  const autoSaveTimeoutRef = useRef<number | null>(null)
  const lastSavedContentRef = useRef<string>('')

  // Load draft from backend when available
  useEffect(() => {
    if (backendDraft && (!currentDraft || currentDraft.id !== backendDraft.id)) {
      dispatch(setCurrentDraft(backendDraft))
      lastSavedContentRef.current = JSON.stringify(backendDraft.content)
    }
  }, [backendDraft, currentDraft, dispatch])

  // Handle browser refresh/close with unsaved changes
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (hasUnsavedChanges) {
        const message = 'You have unsaved changes. Are you sure you want to leave?'
        e.preventDefault()
        e.returnValue = message
        return message
      }
    }

    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [hasUnsavedChanges])

  // Custom navigation handler with unsaved changes check
  const handleNavigateWithCheck = useCallback((path: string) => {
    if (hasUnsavedChanges) {
      const confirm = window.confirm(
        'You have unsaved changes. Are you sure you want to leave?'
      )
      if (confirm) {
        navigate(path)
      }
    } else {
      navigate(path)
    }
  }, [hasUnsavedChanges, navigate])

  // Log error for debugging
  useEffect(() => {
    if (draftError) {
      console.error('Failed to load story draft:', draftError)
    }
  }, [draftError])

  // Auto-save logic
  const triggerAutoSave = useCallback(async () => {
    if (!currentDraft || !draftId) return

    try {
      dispatch(setSavingLoading(true))
      
      await updateDraft({
        id: draftId,
        data: {
          title: currentDraft.title,
          description: currentDraft.description,
          content: currentDraft.content,
          metadata: currentDraft.metadata,
        }
      }).unwrap()

      dispatch(setLastAutoSave(new Date().toISOString()))
      setHasUnsavedChanges(false)
      lastSavedContentRef.current = JSON.stringify(currentDraft.content)
      
    } catch (error) {
      console.error('Auto-save failed:', error)
      dispatch(setError('Failed to save changes'))
    } finally {
      dispatch(setSavingLoading(false))
    }
  }, [currentDraft, draftId, updateDraft, dispatch])

  // Set up auto-save when content changes
  useEffect(() => {
    if (!currentDraft) return

    const currentContentString = JSON.stringify(currentDraft.content)
    if (currentContentString !== lastSavedContentRef.current) {
      setHasUnsavedChanges(true)
      
      if (autoSaveTimeoutRef.current) {
        clearTimeout(autoSaveTimeoutRef.current)
      }
      
      autoSaveTimeoutRef.current = setTimeout(() => {
        triggerAutoSave()
      }, AUTO_SAVE_DELAY)
    }

    return () => {
      if (autoSaveTimeoutRef.current) {
        clearTimeout(autoSaveTimeoutRef.current)
      }
    }
  }, [currentDraft, triggerAutoSave])

  const handleManualSave = async () => {
    await triggerAutoSave()
    setSaveSuccess(true)
  }

  const handleBack = () => {
    handleNavigateWithCheck('/app/parent/story-builder')
  }

  const handlePageSelect = (pageIndex: number) => {
    setCurrentPageIndex(pageIndex)
  }

  const handlePageAdd = () => {
    dispatch(addPageToCurrentDraft())
    if (currentDraft) {
      setCurrentPageIndex(currentDraft.content.pages.length) // Navigate to new page
    }
  }

  const handlePageDelete = (pageIndex: number) => {
    if (!currentDraft || currentDraft.content.pages.length <= 1) return
    
    dispatch(removePageFromCurrentDraft(pageIndex + 1)) // Convert to 1-based page number
    
    // Adjust current page index if necessary
    if (currentPageIndex >= pageIndex && currentPageIndex > 0) {
      setCurrentPageIndex(currentPageIndex - 1)
    }
  }

  const handlePageReorder = (fromIndex: number, toIndex: number) => {
    dispatch(reorderPages({ fromIndex, toIndex }))
  }

  const handlePageUpdate = useCallback((updatedPage: StoryPage) => {
    if (!currentDraft) return

    const updatedPages = [...currentDraft.content.pages]
    updatedPages[currentPageIndex] = updatedPage

    const updatedContent: StoryContent = {
      ...currentDraft.content,
      pages: updatedPages,
    }

    dispatch(updateCurrentDraftContent(updatedContent))
  }, [currentDraft, currentPageIndex, dispatch])

  const handlePreview = () => {
    // TODO: Implement preview functionality
    console.log('Preview functionality not yet implemented')
  }

  const handlePublish = () => {
    // TODO: Implement publish functionality
    console.log('Publish functionality not yet implemented')
  }

  const handleSettings = () => {
    // TODO: Implement story settings
    console.log('Story settings not yet implemented')
  }

  if (isDraftLoading) {
    return (
      <EditorContainer>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: '100%' }}>
          <Typography variant="h6" color="text.secondary">
            Loading story...
          </Typography>
        </Box>
      </EditorContainer>
    )
  }

  if (draftError) {
    return (
      <EditorContainer>
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', width: '100%', gap: 2 }}>
          <Typography variant="h6" color="error">
            Failed to load story
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {(draftError as any)?.data?.message || 'Story not found or you don\'t have permission to edit it.'}
          </Typography>
          <Button variant="contained" onClick={() => handleNavigateWithCheck('/app/parent/story-builder')}>
            Back to Stories
          </Button>
        </Box>
      </EditorContainer>
    )
  }

  if (!currentDraft) {
    return (
      <EditorContainer>
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', width: '100%', gap: 2 }}>
          <Typography variant="h6" color="text.secondary">
            Story not found
          </Typography>
          <Button variant="contained" onClick={() => handleNavigateWithCheck('/app/parent/story-builder')}>
            Back to Stories
          </Button>
        </Box>
      </EditorContainer>
    )
  }

  const currentPage = currentDraft.content.pages[currentPageIndex] || null
  const isSaving = loading.saving

  return (
    <EditorContainer>
      {/* App Bar */}
      <EditorAppBar position="static" elevation={0}>
        <Toolbar>
          <IconButton
            edge="start"
            color="inherit"
            onClick={handleBack}
            sx={{ mr: 2 }}
          >
            <BackIcon />
          </IconButton>

          <Box sx={{ flexGrow: 1 }}>
            <Typography variant="h6" component="h1" noWrap>
              {currentDraft.title}
            </Typography>
            <SaveStatusIndicator saved={!hasUnsavedChanges && !isSaving}>
              {isSaving ? (
                <>
                  <UnsavedIcon sx={{ fontSize: 16 }} />
                  Saving...
                </>
              ) : hasUnsavedChanges ? (
                <>
                  <UnsavedIcon sx={{ fontSize: 16 }} />
                  Unsaved changes
                </>
              ) : (
                <>
                  <SavedIcon sx={{ fontSize: 16 }} />
                  {lastAutoSave && `Saved ${new Date(lastAutoSave).toLocaleTimeString()}`}
                </>
              )}
            </SaveStatusIndicator>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Button
              variant="outlined"
              startIcon={<SaveIcon />}
              onClick={handleManualSave}
              disabled={isSaving || !hasUnsavedChanges}
              size="small"
            >
              Save
            </Button>

            <Button
              variant="outlined"
              startIcon={<PreviewIcon />}
              onClick={handlePreview}
              size="small"
            >
              Preview
            </Button>

            <Button
              variant="contained"
              startIcon={<PublishIcon />}
              onClick={handlePublish}
              size="small"
            >
              Publish
            </Button>

            <LogoutButton variant="icon" />
            <IconButton
              onClick={(e) => setMenuAnchor(e.currentTarget)}
              color="inherit"
            >
              <MoreIcon />
            </IconButton>
          </Box>
        </Toolbar>

        {isSaving && <LinearProgress />}
      </EditorAppBar>

      {/* Main Editor */}
      <Box sx={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        {/* Page Navigator */}
        <PageNavigator
          pages={currentDraft.content.pages}
          currentPageIndex={currentPageIndex}
          onPageSelect={handlePageSelect}
          onPageAdd={handlePageAdd}
          onPageDelete={handlePageDelete}
          onPageReorder={handlePageReorder}
        />

        {/* Story Canvas */}
        <StoryCanvas
          page={currentPage}
          onPageUpdate={handlePageUpdate}
        />
      </Box>

      {/* More Options Menu */}
      <Menu
        anchorEl={menuAnchor}
        open={Boolean(menuAnchor)}
        onClose={() => setMenuAnchor(null)}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
      >
        <MenuItem onClick={handleSettings}>
          <ListItemIcon>
            <SettingsIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Story Settings</ListItemText>
        </MenuItem>
      </Menu>

      {/* Error Snackbar */}
      <Snackbar
        open={!!error}
        autoHideDuration={6000}
        onClose={() => dispatch(clearError())}
      >
        <Alert 
          onClose={() => dispatch(clearError())} 
          severity="error" 
          sx={{ width: '100%' }}
        >
          {error}
        </Alert>
      </Snackbar>

      {/* Success Snackbar */}
      <Snackbar
        open={saveSuccess}
        autoHideDuration={3000}
        onClose={() => setSaveSuccess(false)}
      >
        <Alert 
          onClose={() => setSaveSuccess(false)} 
          severity="success" 
          sx={{ width: '100%' }}
        >
          Story saved successfully!
        </Alert>
      </Snackbar>
    </EditorContainer>
  )
}