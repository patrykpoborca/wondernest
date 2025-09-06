import React, { useState } from 'react'
import {
  Box,
  Paper,
  Typography,
  Grid,
  Card,
  CardContent,
  CardMedia,
  CardActions,
  IconButton,
  Button,
  TextField,
  InputAdornment,
  ToggleButton,
  ToggleButtonGroup,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  ListItemSecondaryAction,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Skeleton,
  Alert,
  Chip,
  Tooltip,
  Avatar,
  alpha,
} from '@mui/material'
import {
  Delete as DeleteIcon,
  Download as DownloadIcon,
  GridView as GridIcon,
  ViewList as ListIcon,
  Search as SearchIcon,
  InsertDriveFile as FileIcon,
  Image as ImageIcon,
  PictureAsPdf as PdfIcon,
  Close as CloseIcon,
  CloudUpload as UploadIcon,
  Folder as FolderIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'
import { useListUserFilesQuery, useDeleteFileMutation } from '@/store/api/apiSlice'
import { FileUploadWithTags } from './FileUploadWithTags'

const StyledCard = styled(Card)(({ theme }) => ({
  height: '100%',
  display: 'flex',
  flexDirection: 'column',
  transition: 'all 0.2s ease-in-out',
  cursor: 'pointer',
  '&:hover': {
    transform: 'translateY(-2px)',
    boxShadow: theme.shadows[4],
  },
}))

const ImagePreview = styled('img')(({ theme }) => ({
  width: '100%',
  height: 140,
  objectFit: 'cover',
  backgroundColor: theme.palette.grey[100],
}))

const FileIconContainer = styled(Box)(({ theme }) => ({
  width: '100%',
  height: 140,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  backgroundColor: theme.palette.grey[50],
  borderBottom: `1px solid ${theme.palette.divider}`,
}))

interface FileManagerProps {
  childId?: string
  category?: 'profile_picture' | 'content' | 'document' | 'game_asset' | 'artwork'
  showUpload?: boolean
  className?: string
}

export const FileManager: React.FC<FileManagerProps> = ({
  childId,
  category,
  showUpload = true,
  className = '',
}) => {
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedFile, setSelectedFile] = useState<any>(null)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [fileToDelete, setFileToDelete] = useState<string | null>(null)
  
  const { data: filesData, isLoading, refetch } = useListUserFilesQuery({
    category,
    childId,
    limit: 100,
    offset: 0,
  })
  
  const [deleteFile, { isLoading: isDeleting }] = useDeleteFileMutation()

  const files = filesData?.data || []
  
  // Debug: log files data to check for id field
  console.log('Files data:', files.slice(0, 3)) // Log first 3 files for debugging
  
  const filteredFiles = files.filter((file: any) =>
    file.originalName.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const getFileIcon = (mimeType: string, size: 'small' | 'large' = 'small') => {
    const iconSize = size === 'large' ? 48 : 24
    
    if (mimeType.startsWith('image/')) {
      return <ImageIcon sx={{ fontSize: iconSize, color: 'primary.main' }} />
    }
    if (mimeType === 'application/pdf') {
      return <PdfIcon sx={{ fontSize: iconSize, color: 'error.main' }} />
    }
    return <FileIcon sx={{ fontSize: iconSize, color: 'action.active' }} />
  }

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  const handleDeleteClick = (fileId: string) => {
    console.log('Delete clicked for fileId:', fileId)
    setFileToDelete(fileId)
    setDeleteDialogOpen(true)
  }

  const handleDeleteConfirm = async () => {
    if (fileToDelete) {
      console.log('Attempting to delete file with ID:', fileToDelete)
      try {
        const result = await deleteFile({ fileId: fileToDelete }).unwrap()
        console.log('Delete result:', result)
        refetch()
        setDeleteDialogOpen(false)
        setFileToDelete(null)
        if (selectedFile?.id === fileToDelete) {
          setSelectedFile(null)
        }
      } catch (error) {
        console.error('Failed to delete file:', error)
      }
    } else {
      console.error('No fileToDelete set when trying to delete')
    }
  }

  const handleDownload = (file: any) => {
    if (file.url) {
      window.open(file.url, '_blank')
    }
  }

  const handleUploadComplete = () => {
    refetch()
  }

  const handleViewModeChange = (
    _: React.MouseEvent<HTMLElement>,
    newMode: 'grid' | 'list' | null,
  ) => {
    if (newMode !== null) {
      setViewMode(newMode)
    }
  }

  return (
    <Box className={className}>
      {/* Upload Section */}
      {showUpload && (
        <Paper elevation={2} sx={{ p: 3, mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <UploadIcon sx={{ mr: 2, color: 'primary.main' }} />
            <Typography variant="h6" component="h3">
              Upload Files
            </Typography>
          </Box>
          <FileUploadWithTags
            category={category}
            childId={childId}
            onUploadComplete={handleUploadComplete}
            isPublic={false}
            requireTags={false}
          />
        </Paper>
      )}

      {/* Files List Section */}
      <Paper elevation={2}>
        <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <FolderIcon sx={{ mr: 2, color: 'primary.main' }} />
              <Typography variant="h6" component="h3">
                Files ({filteredFiles.length})
              </Typography>
            </Box>
            
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              {/* Search */}
              <TextField
                size="small"
                placeholder="Search files..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon />
                    </InputAdornment>
                  ),
                }}
                sx={{ minWidth: 200 }}
              />
              
              {/* View Mode Toggle */}
              <ToggleButtonGroup
                value={viewMode}
                exclusive
                onChange={handleViewModeChange}
                size="small"
              >
                <ToggleButton value="grid" aria-label="grid view">
                  <Tooltip title="Grid View">
                    <GridIcon />
                  </Tooltip>
                </ToggleButton>
                <ToggleButton value="list" aria-label="list view">
                  <Tooltip title="List View">
                    <ListIcon />
                  </Tooltip>
                </ToggleButton>
              </ToggleButtonGroup>
            </Box>
          </Box>
        </Box>

        <Box sx={{ p: 3, minHeight: 400 }}>
          {isLoading ? (
            <Grid container spacing={2}>
              {[...Array(8)].map((_, i) => (
                <Grid item xs={12} sm={6} md={4} lg={3} key={i}>
                  <Skeleton variant="rectangular" height={200} />
                  <Skeleton variant="text" sx={{ mt: 1 }} />
                  <Skeleton variant="text" width="60%" />
                </Grid>
              ))}
            </Grid>
          ) : filteredFiles.length === 0 ? (
            <Box sx={{ 
              textAlign: 'center', 
              py: 8,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 2
            }}>
              <Avatar sx={{ width: 64, height: 64, bgcolor: 'grey.200' }}>
                <FileIcon sx={{ fontSize: 32, color: 'grey.500' }} />
              </Avatar>
              <Typography variant="h6" color="text.secondary">
                No files found
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {searchTerm ? 'Try adjusting your search' : 'Upload your first file to get started'}
              </Typography>
            </Box>
          ) : viewMode === 'grid' ? (
            <Grid container spacing={2}>
              {filteredFiles.map((file: any) => (
                <Grid item xs={12} sm={6} md={4} lg={3} key={file.id}>
                  <StyledCard onClick={() => setSelectedFile(file)}>
                    {file.mimeType.startsWith('image/') ? (
                      <ImagePreview 
                        src={file.url} 
                        alt={file.originalName}
                        loading="lazy"
                      />
                    ) : (
                      <FileIconContainer>
                        {getFileIcon(file.mimeType, 'large')}
                      </FileIconContainer>
                    )}
                    <CardContent sx={{ flexGrow: 1, p: 2 }}>
                      <Typography 
                        variant="body2" 
                        component="div" 
                        noWrap
                        title={file.originalName}
                        sx={{ fontWeight: 500, mb: 0.5 }}
                      >
                        {file.originalName}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {formatFileSize(file.fileSize)}
                      </Typography>
                    </CardContent>
                    <CardActions sx={{ p: 1, pt: 0 }}>
                      <IconButton 
                        size="small" 
                        onClick={(e) => {
                          e.stopPropagation()
                          handleDownload(file)
                        }}
                        title="Download"
                      >
                        <DownloadIcon fontSize="small" />
                      </IconButton>
                      <IconButton 
                        size="small" 
                        onClick={(e) => {
                          e.stopPropagation()
                          handleDeleteClick(file.id)
                        }}
                        title="Delete"
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </CardActions>
                  </StyledCard>
                </Grid>
              ))}
            </Grid>
          ) : (
            <List>
              {filteredFiles.map((file: any) => (
                <ListItem
                  key={file.id}
                  button
                  onClick={() => setSelectedFile(file)}
                  sx={{ 
                    mb: 1, 
                    bgcolor: 'background.paper',
                    border: 1,
                    borderColor: 'divider',
                    borderRadius: 1,
                    '&:hover': {
                      bgcolor: alpha('#000', 0.02)
                    }
                  }}
                >
                  <ListItemIcon>
                    {file.mimeType.startsWith('image/') ? (
                      <Avatar 
                        src={file.url} 
                        variant="rounded"
                        sx={{ width: 40, height: 40 }}
                      >
                        {getFileIcon(file.mimeType)}
                      </Avatar>
                    ) : (
                      getFileIcon(file.mimeType)
                    )}
                  </ListItemIcon>
                  <ListItemText
                    primary={file.originalName}
                    secondary={`${formatFileSize(file.fileSize)} • ${formatDate(file.uploadedAt)}`}
                  />
                  <ListItemSecondaryAction>
                    <IconButton
                      edge="end"
                      onClick={(e) => {
                        e.stopPropagation()
                        handleDownload(file)
                      }}
                      sx={{ mr: 1 }}
                    >
                      <DownloadIcon />
                    </IconButton>
                    <IconButton
                      edge="end"
                      onClick={(e) => {
                        e.stopPropagation()
                        handleDeleteClick(file.id)
                      }}
                    >
                      <DeleteIcon />
                    </IconButton>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          )}
        </Box>
      </Paper>

      {/* File Details Dialog */}
      <Dialog
        open={!!selectedFile}
        onClose={() => setSelectedFile(null)}
        maxWidth="md"
        fullWidth
      >
        {selectedFile && (
          <>
            <DialogTitle sx={{ m: 0, p: 2 }}>
              File Details
              <IconButton
                aria-label="close"
                onClick={() => setSelectedFile(null)}
                sx={{
                  position: 'absolute',
                  right: 8,
                  top: 8,
                  color: (theme) => theme.palette.grey[500],
                }}
              >
                <CloseIcon />
              </IconButton>
            </DialogTitle>
            <DialogContent dividers>
              {selectedFile.mimeType.startsWith('image/') && (
                <Box sx={{ mb: 3, textAlign: 'center' }}>
                  <img 
                    src={selectedFile.url} 
                    alt={selectedFile.originalName}
                    style={{ 
                      maxWidth: '100%', 
                      maxHeight: 400, 
                      objectFit: 'contain',
                      borderRadius: 4
                    }}
                  />
                </Box>
              )}
              
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <Typography variant="caption" color="text.secondary" display="block">
                    File Name
                  </Typography>
                  <Typography variant="body1" sx={{ mb: 2 }}>
                    {selectedFile.originalName}
                  </Typography>
                </Grid>
                
                <Grid item xs={12} sm={6}>
                  <Typography variant="caption" color="text.secondary" display="block">
                    File Size
                  </Typography>
                  <Typography variant="body1" sx={{ mb: 2 }}>
                    {formatFileSize(selectedFile.fileSize)}
                  </Typography>
                </Grid>
                
                <Grid item xs={12} sm={6}>
                  <Typography variant="caption" color="text.secondary" display="block">
                    File Type
                  </Typography>
                  <Typography variant="body1" sx={{ mb: 2 }}>
                    {selectedFile.mimeType}
                  </Typography>
                </Grid>
                
                <Grid item xs={12} sm={6}>
                  <Typography variant="caption" color="text.secondary" display="block">
                    Uploaded Date
                  </Typography>
                  <Typography variant="body1" sx={{ mb: 2 }}>
                    {formatDate(selectedFile.uploadedAt)}
                  </Typography>
                </Grid>
                
                <Grid item xs={12}>
                  <Typography variant="caption" color="text.secondary" display="block">
                    Category
                  </Typography>
                  <Chip 
                    label={selectedFile.category} 
                    size="small" 
                    color="primary"
                    sx={{ mt: 0.5 }}
                  />
                </Grid>
              </Grid>
            </DialogContent>
            <DialogActions sx={{ p: 2 }}>
              <Button
                variant="contained"
                startIcon={<DownloadIcon />}
                onClick={() => handleDownload(selectedFile)}
              >
                Download
              </Button>
              <Button
                variant="outlined"
                color="error"
                startIcon={<DeleteIcon />}
                onClick={() => {
                  setSelectedFile(null)
                  handleDeleteClick(selectedFile.id)
                }}
              >
                Delete
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
      >
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete this file? This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>
            Cancel
          </Button>
          <Button 
            onClick={handleDeleteConfirm} 
            color="error" 
            variant="contained"
            disabled={isDeleting}
          >
            {isDeleting ? 'Deleting...' : 'Delete'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default FileManager