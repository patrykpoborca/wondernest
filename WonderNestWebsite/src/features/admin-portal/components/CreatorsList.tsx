import React, { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Avatar,
  Alert,
  CircularProgress,
  Menu,
  MenuItem,
  Tooltip
} from '@mui/material'
import {
  Add,
  Edit,
  MoreVert,
  Person,
  Verified,
  CloudUpload
} from '@mui/icons-material'

import { adminApiService } from '@/services/adminApi'
import { ContentCreator } from '@/types/admin'

interface CreatorsListProps {
  onCreateCreator: () => void
  onEditCreator: (creator: ContentCreator) => void
}

export const CreatorsList: React.FC<CreatorsListProps> = ({
  onCreateCreator,
  onEditCreator
}) => {
  const [creators, setCreators] = useState<ContentCreator[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null)
  const [selectedCreator, setSelectedCreator] = useState<ContentCreator | null>(null)

  useEffect(() => {
    loadCreators()
  }, [])

  const loadCreators = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await adminApiService.getCreatorsList()
      setCreators(data)
    } catch (err: any) {
      setError(err.error || 'Failed to load creators')
    } finally {
      setLoading(false)
    }
  }

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, creator: ContentCreator) => {
    setMenuAnchor(event.currentTarget)
    setSelectedCreator(creator)
  }

  const handleMenuClose = () => {
    setMenuAnchor(null)
    setSelectedCreator(null)
  }

  const handleEditCreator = () => {
    if (selectedCreator) {
      onEditCreator(selectedCreator)
    }
    handleMenuClose()
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString()
  }

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    )
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={600}>
            Content Creators
          </Typography>
          <Typography variant="body2" color="textSecondary">
            Manage content creators and their contributions
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={onCreateCreator}
        >
          Add Creator
        </Button>
      </Box>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Stats Cards */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2, mb: 3 }}>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Avatar sx={{ bgcolor: 'primary.main', width: 40, height: 40 }}>
                <Person />
              </Avatar>
              <Box>
                <Typography variant="h6">{creators.length}</Typography>
                <Typography variant="body2" color="textSecondary">Total Creators</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Avatar sx={{ bgcolor: 'success.main', width: 40, height: 40 }}>
                <Verified />
              </Avatar>
              <Box>
                <Typography variant="h6">
                  {creators.filter(c => c.is_verified).length}
                </Typography>
                <Typography variant="body2" color="textSecondary">Verified</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Avatar sx={{ bgcolor: 'secondary.main', width: 40, height: 40 }}>
                <CloudUpload />
              </Avatar>
              <Box>
                <Typography variant="h6">
                  {creators.reduce((sum, c) => sum + (c.total_content_uploaded || 0), 0)}
                </Typography>
                <Typography variant="body2" color="textSecondary">Total Content</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Box>

      {/* Creators Table */}
      <Card>
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Creator</TableCell>
                <TableCell>Specialization</TableCell>
                <TableCell>Status</TableCell>
                <TableCell align="center">Content</TableCell>
                <TableCell align="center">Published</TableCell>
                <TableCell>Join Date</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {creators.map((creator) => (
                <TableRow key={creator.id} hover>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Avatar 
                        src={creator.profile_image_url} 
                        sx={{ width: 40, height: 40 }}
                      >
                        {creator.name ? creator.name[0] : creator.email?.[0] || '?'}
                      </Avatar>
                      <Box>
                        <Typography variant="body1" fontWeight={500}>
                          {creator.name || creator.email || 'Unknown'}
                        </Typography>
                        <Typography variant="body2" color="textSecondary">
                          {creator.email}
                        </Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {creator.specialization}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                      {creator.is_verified && (
                        <Chip
                          size="small"
                          label="Verified"
                          color="success"
                          variant="outlined"
                          icon={<Verified />}
                        />
                      )}
                      <Chip
                        size="small"
                        label={creator.is_active ? "Active" : "Inactive"}
                        color={creator.is_active ? "success" : "default"}
                        variant="outlined"
                      />
                    </Box>
                  </TableCell>
                  <TableCell align="center">
                    <Typography variant="body2">
                      {creator.total_content_uploaded || 0}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Typography variant="body2">
                      {creator.total_content_published || 0}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {creator.join_date ? formatDate(creator.join_date) : 'N/A'}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Tooltip title="More actions">
                      <IconButton
                        onClick={(e) => handleMenuOpen(e, creator)}
                      >
                        <MoreVert />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
              {creators.length === 0 && !loading && (
                <TableRow>
                  <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                    <Typography color="textSecondary">
                      No creators found. Add your first content creator to get started.
                    </Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>

      {/* Action Menu */}
      <Menu
        anchorEl={menuAnchor}
        open={Boolean(menuAnchor)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={handleEditCreator}>
          <Edit sx={{ mr: 1 }} />
          Edit Creator
        </MenuItem>
      </Menu>
    </Box>
  )
}