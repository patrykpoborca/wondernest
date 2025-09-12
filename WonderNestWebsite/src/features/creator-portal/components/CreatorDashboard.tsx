import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  Avatar,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Menu,
  MenuItem,
  Alert,
  LinearProgress,
} from '@mui/material';
import {
  Add,
  MoreVert,
  Analytics,
  Upload,
  Edit,
  Delete,
  Visibility,
  CheckCircle,
  Warning,
  Schedule,
  Block,
} from '@mui/icons-material';

import { creatorApi, CreatorAccount, ContentSubmission } from '../services/creatorApi';

const CreatorDashboard: React.FC = () => {
  const navigate = useNavigate();
  const [creator, setCreator] = useState<CreatorAccount | null>(null);
  const [submissions, setSubmissions] = useState<ContentSubmission[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [menuAnchorEl, setMenuAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedSubmission, setSelectedSubmission] = useState<string | null>(null);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const [creatorProfile, contentSubmissions] = await Promise.all([
        creatorApi.getProfile(),
        creatorApi.getContentSubmissions(),
      ]);
      
      setCreator(creatorProfile);
      setSubmissions(contentSubmissions);
    } catch (err) {
      console.error('Failed to load dashboard:', err);
      setError(err instanceof Error ? err.message : 'Failed to load dashboard');
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    try {
      await creatorApi.logout();
      navigate('/creator/login');
    } catch (err) {
      console.error('Logout failed:', err);
      // Force logout even if API call fails
      navigate('/creator/login');
    }
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, submissionId: string) => {
    setMenuAnchorEl(event.currentTarget);
    setSelectedSubmission(submissionId);
  };

  const handleMenuClose = () => {
    setMenuAnchorEl(null);
    setSelectedSubmission(null);
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved':
      case 'published':
        return <CheckCircle color="success" />;
      case 'under_review':
      case 'submitted':
        return <Schedule color="warning" />;
      case 'rejected':
        return <Block color="error" />;
      case 'draft':
        return <Edit color="action" />;
      default:
        return <Warning color="action" />;
    }
  };

  const getStatusColor = (status: string): 'success' | 'warning' | 'error' | 'default' => {
    switch (status) {
      case 'approved':
      case 'published':
        return 'success';
      case 'under_review':
      case 'submitted':
        return 'warning';
      case 'rejected':
        return 'error';
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
      <Box sx={{ width: '100%', mt: 2 }}>
        <LinearProgress />
        <Typography variant="body2" sx={{ textAlign: 'center', mt: 2 }}>
          Loading your creator dashboard...
        </Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">{error}</Alert>
      </Box>
    );
  }

  if (!creator) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="warning">Creator profile not found</Alert>
      </Box>
    );
  }

  return (
    <Box>
      {/* Welcome Section */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Welcome back, {creator.display_name}
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Here's your creator dashboard overview
        </Typography>
      </Box>

      {/* Quick Stats */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Typography variant="h3" color="primary">
                {submissions.length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total Submissions
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Typography variant="h3" color="success.main">
                {submissions.filter(s => s.status === 'published').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Published Content
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Typography variant="h3" color="warning.main">
                {submissions.filter(s => s.status === 'under_review').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Under Review
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Typography variant="h3" color="text.secondary">
                {submissions.filter(s => s.status === 'draft').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Drafts
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Action Buttons */}
      <Box sx={{ mb: 4, display: 'flex', gap: 2 }}>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => navigate('/creator/stories/create')}
        >
          Create New Story
        </Button>
        <Button
          variant="outlined"
          startIcon={<Analytics />}
          onClick={() => navigate('/creator/analytics')}
        >
          View Analytics
        </Button>
        <Button
          variant="outlined"
          startIcon={<Upload />}
          onClick={() => navigate('/creator/stories')}
        >
          My Stories
        </Button>
      </Box>

      {/* Content Submissions Table */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Recent Content Submissions
          </Typography>
          
          {submissions.length === 0 ? (
            <Box sx={{ textAlign: 'center', py: 4 }}>
              <Typography variant="body1" color="text.secondary" gutterBottom>
                No content submissions yet
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Start creating engaging educational content for children and families
              </Typography>
              <Button
                variant="contained"
                startIcon={<Add />}
                onClick={() => navigate('/creator/stories/create')}
              >
                Create Your First Story
              </Button>
            </Box>
          ) : (
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Title</TableCell>
                    <TableCell>Type</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Created</TableCell>
                    <TableCell>Updated</TableCell>
                    <TableCell width={48}></TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {submissions.map((submission) => (
                    <TableRow key={submission.id} hover>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          {getStatusIcon(submission.status)}
                          <Typography variant="body2" fontWeight="medium">
                            {submission.title}
                          </Typography>
                        </Box>
                        <Typography variant="caption" color="text.secondary">
                          {submission.description.length > 100
                            ? `${submission.description.substring(0, 100)}...`
                            : submission.description
                          }
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip 
                          label={submission.content_type} 
                          size="small" 
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell>
                        <Chip 
                          label={submission.status.replace('_', ' ')} 
                          size="small" 
                          color={getStatusColor(submission.status)}
                        />
                      </TableCell>
                      <TableCell>{formatDate(submission.created_at)}</TableCell>
                      <TableCell>{formatDate(submission.updated_at)}</TableCell>
                      <TableCell>
                        <IconButton
                          size="small"
                          onClick={(e) => handleMenuOpen(e, submission.id)}
                        >
                          <MoreVert />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>

      {/* Context Menu */}
      <Menu
        anchorEl={menuAnchorEl}
        open={Boolean(menuAnchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={() => {
          navigate(`/creator/content/${selectedSubmission}`);
          handleMenuClose();
        }}>
          <Visibility sx={{ mr: 1 }} />
          View Details
        </MenuItem>
        <MenuItem onClick={() => {
          navigate(`/creator/content/${selectedSubmission}/edit`);
          handleMenuClose();
        }}>
          <Edit sx={{ mr: 1 }} />
          Edit
        </MenuItem>
        <MenuItem onClick={() => {
          navigate(`/creator/content/${selectedSubmission}/analytics`);
          handleMenuClose();
        }}>
          <Analytics sx={{ mr: 1 }} />
          Analytics
        </MenuItem>
        <MenuItem onClick={handleMenuClose} sx={{ color: 'error.main' }}>
          <Delete sx={{ mr: 1 }} />
          Delete
        </MenuItem>
      </Menu>
    </Box>
  );
};

export default CreatorDashboard;