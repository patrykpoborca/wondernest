import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Alert,
  LinearProgress,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Analytics as AnalyticsIcon,
  TrendingUp as TrendingUpIcon,
  Visibility as ViewsIcon,
  ThumbUp as LikesIcon,
  Share as SharesIcon,
  Download as DownloadsIcon,
  People as AudienceIcon,
  Schedule as TimeIcon,
  Assessment as ReportIcon,
  FilterList as FilterIcon,
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip as ChartTooltip, 
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell
} from 'recharts';

import { useCreatorAuth } from '@/contexts/CreatorAuthContext';
import { creatorApi } from '../services/creatorApi';

const StyledCard = styled(Card)(({ theme }) => ({
  height: '100%',
  display: 'flex',
  flexDirection: 'column',
}));

const MetricCard = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(3),
  textAlign: 'center',
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  gap: theme.spacing(1),
}));

interface AnalyticsData {
  overview: {
    total_views: number;
    total_likes: number;
    total_shares: number;
    total_downloads: number;
    engagement_rate: number;
    average_session_duration: number;
  };
  performance_over_time: Array<{
    date: string;
    views: number;
    engagement: number;
    downloads: number;
  }>;
  content_performance: Array<{
    content_id: string;
    title: string;
    views: number;
    likes: number;
    shares: number;
    downloads: number;
    engagement_rate: number;
  }>;
  audience_demographics: {
    age_groups: Array<{ age_range: string; percentage: number }>;
    device_types: Array<{ device: string; percentage: number }>;
    top_countries: Array<{ country: string; percentage: number }>;
  };
  trends: {
    views_change: number;
    engagement_change: number;
    downloads_change: number;
  };
}

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

const AnalyticsDashboard: React.FC = () => {
  const { creator } = useCreatorAuth();
  const [analyticsData, setAnalyticsData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [timeRange, setTimeRange] = useState('30d');

  useEffect(() => {
    loadAnalyticsData();
  }, [timeRange]);

  const loadAnalyticsData = async () => {
    try {
      setLoading(true);
      // This would be a real API call in production
      // For now, we'll mock the data
      const mockData: AnalyticsData = {
        overview: {
          total_views: 12543,
          total_likes: 1876,
          total_shares: 456,
          total_downloads: 2341,
          engagement_rate: 14.9,
          average_session_duration: 4.2,
        },
        performance_over_time: [
          { date: '2024-01-01', views: 145, engagement: 12, downloads: 23 },
          { date: '2024-01-02', views: 167, engagement: 18, downloads: 31 },
          { date: '2024-01-03', views: 234, engagement: 25, downloads: 42 },
          { date: '2024-01-04', views: 198, engagement: 22, downloads: 38 },
          { date: '2024-01-05', views: 289, engagement: 34, downloads: 56 },
          { date: '2024-01-06', views: 312, engagement: 41, downloads: 63 },
          { date: '2024-01-07', views: 278, engagement: 38, downloads: 52 },
        ],
        content_performance: [
          {
            content_id: '1',
            title: 'The Magic Garden',
            views: 3421,
            likes: 456,
            shares: 89,
            downloads: 234,
            engagement_rate: 13.3,
          },
          {
            content_id: '2',
            title: 'Ocean Adventure',
            views: 2876,
            likes: 387,
            shares: 67,
            downloads: 189,
            engagement_rate: 15.8,
          },
          {
            content_id: '3',
            title: 'Space Explorer',
            views: 4567,
            likes: 612,
            shares: 134,
            downloads: 345,
            engagement_rate: 16.4,
          },
        ],
        audience_demographics: {
          age_groups: [
            { age_range: '3-5', percentage: 35 },
            { age_range: '6-8', percentage: 40 },
            { age_range: '9-12', percentage: 25 },
          ],
          device_types: [
            { device: 'Mobile', percentage: 65 },
            { device: 'Tablet', percentage: 30 },
            { device: 'Desktop', percentage: 5 },
          ],
          top_countries: [
            { country: 'United States', percentage: 45 },
            { country: 'Canada', percentage: 20 },
            { country: 'United Kingdom', percentage: 15 },
            { country: 'Australia', percentage: 10 },
            { country: 'Other', percentage: 10 },
          ],
        },
        trends: {
          views_change: 12.5,
          engagement_change: 8.3,
          downloads_change: -2.1,
        },
      };
      
      setAnalyticsData(mockData);
    } catch (err) {
      console.error('Failed to load analytics data:', err);
      setError(err instanceof Error ? err.message : 'Failed to load analytics data');
    } finally {
      setLoading(false);
    }
  };

  const formatNumber = (num: number): string => {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
  };

  const getTrendColor = (change: number): 'success' | 'error' | 'default' => {
    if (change > 0) return 'success';
    if (change < 0) return 'error';
    return 'default';
  };

  const getTrendIcon = (change: number) => {
    return <TrendingUpIcon sx={{ transform: change < 0 ? 'rotate(180deg)' : 'none' }} />;
  };

  if (loading) {
    return (
      <Box sx={{ width: '100%', mt: 2 }}>
        <LinearProgress />
        <Typography variant="body2" sx={{ textAlign: 'center', mt: 2 }}>
          Loading analytics data...
        </Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error">
        {error}
      </Alert>
    );
  }

  if (!analyticsData) {
    return (
      <Alert severity="warning">
        No analytics data available
      </Alert>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <AnalyticsIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Box>
            <Typography variant="h4" component="h1" gutterBottom>
              Analytics Dashboard
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Track your content performance and audience insights
            </Typography>
          </Box>
        </Box>
        
        <FormControl sx={{ minWidth: 120 }}>
          <InputLabel>Time Range</InputLabel>
          <Select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            label="Time Range"
          >
            <MenuItem value="7d">Last 7 days</MenuItem>
            <MenuItem value="30d">Last 30 days</MenuItem>
            <MenuItem value="90d">Last 3 months</MenuItem>
            <MenuItem value="1y">Last year</MenuItem>
          </Select>
        </FormControl>
      </Box>

      {/* Key Metrics */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={2}>
          <MetricCard>
            <ViewsIcon color="primary" />
            <Typography variant="h5" fontWeight="bold">
              {formatNumber(analyticsData.overview.total_views)}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Total Views
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {getTrendIcon(analyticsData.trends.views_change)}
              <Typography 
                variant="caption" 
                color={`${getTrendColor(analyticsData.trends.views_change)}.main`}
              >
                {Math.abs(analyticsData.trends.views_change)}%
              </Typography>
            </Box>
          </MetricCard>
        </Grid>
        
        <Grid item xs={12} sm={6} md={2}>
          <MetricCard>
            <LikesIcon color="error" />
            <Typography variant="h5" fontWeight="bold">
              {formatNumber(analyticsData.overview.total_likes)}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Total Likes
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {getTrendIcon(analyticsData.trends.engagement_change)}
              <Typography 
                variant="caption" 
                color={`${getTrendColor(analyticsData.trends.engagement_change)}.main`}
              >
                {Math.abs(analyticsData.trends.engagement_change)}%
              </Typography>
            </Box>
          </MetricCard>
        </Grid>
        
        <Grid item xs={12} sm={6} md={2}>
          <MetricCard>
            <SharesIcon color="success" />
            <Typography variant="h5" fontWeight="bold">
              {formatNumber(analyticsData.overview.total_shares)}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Total Shares
            </Typography>
          </MetricCard>
        </Grid>
        
        <Grid item xs={12} sm={6} md={2}>
          <MetricCard>
            <DownloadsIcon color="info" />
            <Typography variant="h5" fontWeight="bold">
              {formatNumber(analyticsData.overview.total_downloads)}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Downloads
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {getTrendIcon(analyticsData.trends.downloads_change)}
              <Typography 
                variant="caption" 
                color={`${getTrendColor(analyticsData.trends.downloads_change)}.main`}
              >
                {Math.abs(analyticsData.trends.downloads_change)}%
              </Typography>
            </Box>
          </MetricCard>
        </Grid>
        
        <Grid item xs={12} sm={6} md={2}>
          <MetricCard>
            <Typography variant="h5" fontWeight="bold" color="primary">
              {analyticsData.overview.engagement_rate}%
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Engagement Rate
            </Typography>
          </MetricCard>
        </Grid>
        
        <Grid item xs={12} sm={6} md={2}>
          <MetricCard>
            <TimeIcon color="warning" />
            <Typography variant="h5" fontWeight="bold">
              {analyticsData.overview.average_session_duration}m
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Avg. Session
            </Typography>
          </MetricCard>
        </Grid>
      </Grid>

      {/* Performance Over Time Chart */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Performance Over Time
          </Typography>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={analyticsData.performance_over_time}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <ChartTooltip />
              <Area type="monotone" dataKey="views" stackId="1" stroke="#8884d8" fill="#8884d8" />
              <Area type="monotone" dataKey="engagement" stackId="1" stroke="#82ca9d" fill="#82ca9d" />
              <Area type="monotone" dataKey="downloads" stackId="1" stroke="#ffc658" fill="#ffc658" />
            </AreaChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        {/* Content Performance */}
        <Grid item xs={12} lg={8}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Top Performing Content
              </Typography>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Title</TableCell>
                      <TableCell align="right">Views</TableCell>
                      <TableCell align="right">Likes</TableCell>
                      <TableCell align="right">Downloads</TableCell>
                      <TableCell align="right">Engagement</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {analyticsData.content_performance.map((content) => (
                      <TableRow key={content.content_id}>
                        <TableCell>{content.title}</TableCell>
                        <TableCell align="right">{formatNumber(content.views)}</TableCell>
                        <TableCell align="right">{formatNumber(content.likes)}</TableCell>
                        <TableCell align="right">{formatNumber(content.downloads)}</TableCell>
                        <TableCell align="right">
                          <Chip 
                            label={`${content.engagement_rate}%`} 
                            size="small"
                            color={content.engagement_rate > 15 ? 'success' : content.engagement_rate > 10 ? 'warning' : 'default'}
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        {/* Age Groups */}
        <Grid item xs={12} lg={4}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Audience Age Groups
              </Typography>
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie
                    data={analyticsData.audience_demographics.age_groups}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ age_range, percentage }) => `${age_range}: ${percentage}%`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="percentage"
                  >
                    {analyticsData.audience_demographics.age_groups.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <ChartTooltip />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Device Types and Countries */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Device Types
              </Typography>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={analyticsData.audience_demographics.device_types}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="device" />
                  <YAxis />
                  <ChartTooltip />
                  <Bar dataKey="percentage" fill="#8884d8" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Top Countries
              </Typography>
              <Box sx={{ mt: 2 }}>
                {analyticsData.audience_demographics.top_countries.map((country, index) => (
                  <Box key={country.country} sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="body2">{country.country}</Typography>
                    <Typography variant="body2" fontWeight="bold">{country.percentage}%</Typography>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Container>
  );
};

export default AnalyticsDashboard;