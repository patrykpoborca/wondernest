import React, { useState } from 'react'
import {
  Box,
  Paper,
  Typography,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  ListItemAvatar,
  Tooltip,
  Button,
  Menu,
  MenuItem,
  Divider,
  Alert,
} from '@mui/material'
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  DragIndicator as DragIcon,
  MoreVert as MoreIcon,
  AutoStories as PageIcon,
  Image as ImageIcon,
  TextFields as TextIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'

import { StoryPage } from '../types/story'

const StyledPaper = styled(Paper)(({ theme }) => ({
  width: '100%',
  maxWidth: 320,
  height: '100%',
  display: 'flex',
  flexDirection: 'column',
  borderRight: `1px solid ${theme.palette.divider}`,
}))

const StyledListItem = styled(ListItem)<{ selected?: boolean }>(({ theme, selected }) => ({
  padding: 0,
  '& .MuiListItemButton-root': {
    borderRadius: theme.spacing(1),
    margin: theme.spacing(0.5, 1),
    backgroundColor: selected ? theme.palette.action.selected : 'transparent',
    '&:hover': {
      backgroundColor: selected 
        ? theme.palette.action.selected 
        : theme.palette.action.hover,
    },
  },
}))


const PagePreview = styled(Box)(({ theme }) => ({
  width: 60,
  height: 40,
  backgroundColor: theme.palette.grey[100],
  border: `2px solid ${theme.palette.divider}`,
  borderRadius: theme.spacing(1),
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  position: 'relative',
  overflow: 'hidden',
}))

const ContentIndicator = styled(Box)(({ theme }) => ({
  position: 'absolute',
  bottom: 2,
  right: 2,
  display: 'flex',
  gap: 2,
  '& .MuiSvgIcon-root': {
    fontSize: 12,
    color: theme.palette.text.secondary,
  },
}))

interface PageNavigatorProps {
  pages: StoryPage[]
  currentPageIndex: number
  onPageSelect: (pageIndex: number) => void
  onPageAdd: () => void
  onPageDelete: (pageIndex: number) => void
  onPageReorder: (fromIndex: number, toIndex: number) => void
  isReadOnly?: boolean
}

export const PageNavigator: React.FC<PageNavigatorProps> = ({
  pages,
  currentPageIndex,
  onPageSelect,
  onPageAdd,
  onPageDelete,
  isReadOnly = false,
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
  const [selectedPageIndex, setSelectedPageIndex] = useState<number | null>(null)

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, pageIndex: number) => {
    event.stopPropagation()
    setAnchorEl(event.currentTarget)
    setSelectedPageIndex(pageIndex)
  }

  const handleMenuClose = () => {
    setAnchorEl(null)
    setSelectedPageIndex(null)
  }

  const handleDeletePage = () => {
    if (selectedPageIndex !== null && pages.length > 1) {
      onPageDelete(selectedPageIndex)
    }
    handleMenuClose()
  }

  const canDeletePages = pages.length > 1

  const getPageContentSummary = (page: StoryPage) => {
    const hasText = page.textBlocks.length > 0
    const hasImages = page.popupImages.length > 0 || page.background
    const textCount = page.textBlocks.length
    const imageCount = page.popupImages.length + (page.background ? 1 : 0)

    return { hasText, hasImages, textCount, imageCount }
  }

  return (
    <StyledPaper elevation={0}>
      {/* Header */}
      <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
          <Typography variant="h6" component="h2">
            Pages
          </Typography>
          {!isReadOnly && (
            <Tooltip title="Add new page">
              <IconButton
                size="small"
                onClick={onPageAdd}
                color="primary"
              >
                <AddIcon />
              </IconButton>
            </Tooltip>
          )}
        </Box>
        
        <Typography variant="body2" color="text.secondary">
          {pages.length} page{pages.length !== 1 ? 's' : ''}
        </Typography>
      </Box>

      {/* Page List */}
      <Box sx={{ flexGrow: 1, overflow: 'auto' }}>
        {pages.length === 0 ? (
          <Box sx={{ p: 3, textAlign: 'center' }}>
            <PageIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
            <Typography variant="body2" color="text.secondary">
              No pages yet
            </Typography>
            {!isReadOnly && (
              <Button
                size="small"
                startIcon={<AddIcon />}
                onClick={onPageAdd}
                sx={{ mt: 1 }}
              >
                Add First Page
              </Button>
            )}
          </Box>
        ) : (
          <List sx={{ p: 1 }}>
            {pages.map((page, index) => {
              const { hasText, hasImages, textCount, imageCount } = getPageContentSummary(page)
              const isSelected = index === currentPageIndex

              return (
                <StyledListItem key={page.pageNumber} selected={isSelected}>
                  <ListItemButton
                    onClick={() => onPageSelect(index)}
                    sx={{ py: 1.5 }}
                  >
                    {/* Drag Handle */}
                    {!isReadOnly && (
                      <Box sx={{ mr: 1, cursor: 'grab' }}>
                        <DragIcon sx={{ fontSize: 16, color: 'text.disabled' }} />
                      </Box>
                    )}

                    {/* Page Preview */}
                    <ListItemAvatar sx={{ minWidth: 48 }}>
                      <PagePreview>
                        <PageIcon sx={{ fontSize: 20, color: 'text.disabled' }} />
                        <ContentIndicator>
                          {hasText && <TextIcon />}
                          {hasImages && <ImageIcon />}
                        </ContentIndicator>
                      </PagePreview>
                    </ListItemAvatar>

                    {/* Page Info */}
                    <ListItemText
                      primary={`Page ${page.pageNumber}`}
                      secondary={
                        <Box component="span" sx={{ display: 'block' }}>
                          {textCount > 0 && (
                            <Typography variant="caption" component="span">
                              {textCount} text block{textCount !== 1 ? 's' : ''}
                            </Typography>
                          )}
                          {textCount > 0 && imageCount > 0 && (
                            <Typography variant="caption" component="span">
                              {' • '}
                            </Typography>
                          )}
                          {imageCount > 0 && (
                            <Typography variant="caption" component="span">
                              {imageCount} image{imageCount !== 1 ? 's' : ''}
                            </Typography>
                          )}
                          {textCount === 0 && imageCount === 0 && (
                            <Typography variant="caption" component="span" color="text.disabled">
                              Empty
                            </Typography>
                          )}
                        </Box>
                      }
                      primaryTypographyProps={{
                        variant: 'body2',
                        fontWeight: isSelected ? 600 : 400,
                      }}
                      secondaryTypographyProps={{
                        variant: 'caption',
                      }}
                    />

                    {/* More Menu */}
                    {!isReadOnly && (
                      <IconButton
                        size="small"
                        onClick={(e) => handleMenuClick(e, index)}
                        sx={{ ml: 1 }}
                      >
                        <MoreIcon sx={{ fontSize: 16 }} />
                      </IconButton>
                    )}
                  </ListItemButton>
                </StyledListItem>
              )
            })}
          </List>
        )}
      </Box>

      {/* Footer */}
      {!isReadOnly && pages.length > 0 && (
        <Box sx={{ p: 2, borderTop: 1, borderColor: 'divider' }}>
          <Button
            fullWidth
            variant="outlined"
            startIcon={<AddIcon />}
            onClick={onPageAdd}
            size="small"
          >
            Add Page
          </Button>
        </Box>
      )}

      {/* Context Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
      >
        <MenuItem onClick={handleMenuClose}>
          <DragIcon sx={{ mr: 1 }} />
          Move Page
        </MenuItem>
        <MenuItem onClick={handleMenuClose}>
          Duplicate Page
        </MenuItem>
        <Divider />
        <MenuItem
          onClick={handleDeletePage}
          disabled={!canDeletePages}
          sx={{ color: canDeletePages ? 'error.main' : 'text.disabled' }}
        >
          <DeleteIcon sx={{ mr: 1 }} />
          Delete Page
        </MenuItem>
      </Menu>

      {/* Warning for single page */}
      {pages.length === 1 && selectedPageIndex === 0 && Boolean(anchorEl) && (
        <Box sx={{ position: 'absolute', bottom: 0, left: 0, right: 0, p: 2 }}>
          <Alert severity="info" sx={{ fontSize: '0.75rem' }}>
            Stories must have at least one page
          </Alert>
        </Box>
      )}
    </StyledPaper>
  )
}