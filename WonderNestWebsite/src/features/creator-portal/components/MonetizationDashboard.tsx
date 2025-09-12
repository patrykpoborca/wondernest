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
  Divider,
  Switch,
  FormControlLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  MonetizationOn as MonetizeIcon,
  TrendingUp as TrendingUpIcon,
  AccountBalance as PayoutIcon,
  Settings as SettingsIcon,
  Info as InfoIcon,
  Upgrade as UpgradeIcon,
  AttachMoney as DollarIcon,
  Schedule as PendingIcon,
  CheckCircle as CompletedIcon,
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';

import { useCreatorAuth } from '@/contexts/CreatorAuthContext';
import { creatorApi } from '../services/creatorApi';

const StyledCard = styled(Card)(({ theme }) => ({
  height: '100%',
  display: 'flex',
  flexDirection: 'column',
}));

const StyledMetricCard = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(3),
  textAlign: 'center',
  background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
  color: theme.palette.primary.contrastText,
}));

interface MonetizationData {
  total_earnings: number;
  pending_earnings: number;
  available_balance: number;
  revenue_share_rate: number;
  total_content_sold: number;
  monthly_earnings: Array<{
    month: string;
    earnings: number;
    sales_count: number;
  }>;
  payouts: Array<{
    id: string;
    amount: number;
    status: 'pending' | 'processing' | 'completed' | 'failed';
    created_at: string;
    completed_at?: string;
  }>;
  content_performance: Array<{
    content_id: string;
    title: string;
    total_sales: number;
    total_earnings: number;
    pricing_tier: string;
  }>;
}

interface PayoutRequestDialogProps {
  open: boolean;
  onClose: () => void;
  availableBalance: number;
  onRequestPayout: (amount: number, method: string) => void;
  isLoading: boolean;
}

const PayoutRequestDialog: React.FC<PayoutRequestDialogProps> = ({
  open,
  onClose,
  availableBalance,
  onRequestPayout,
  isLoading,
}) => {
  const [amount, setAmount] = useState(availableBalance);
  const [method, setMethod] = useState('paypal');

  const handleSubmit = () => {
    if (amount > 0 && amount <= availableBalance) {
      onRequestPayout(amount, method);
      setAmount(availableBalance);
      setMethod('paypal');
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Request Payout</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          <TextField
            label="Amount to withdraw"
            type="number"
            value={amount}
            onChange={(e) => setAmount(Math.max(0, Math.min(availableBalance, Number(e.target.value))))}
            fullWidth
            InputProps={{
              startAdornment: '$',
            }}
            helperText={`Available balance: $${availableBalance.toFixed(2)} (minimum $10.00)`}
          />
          
          <TextField
            select
            label="Payout Method"
            value={method}
            onChange={(e) => setMethod(e.target.value)}
            fullWidth
          >
            <MenuItem value="paypal">PayPal</MenuItem>
            <MenuItem value="bank_transfer">Bank Transfer</MenuItem>
            <MenuItem value="stripe">Stripe</MenuItem>
          </TextField>

          <Alert severity="info">
            Payouts typically take 3-5 business days to process. A 2% processing fee applies.
          </Alert>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={isLoading}>
          Cancel
        </Button>
        <Button
          onClick={handleSubmit}
          variant="contained"
          disabled={amount < 10 || amount > availableBalance || isLoading}
        >
          {isLoading ? 'Processing...' : 'Request Payout'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

const MonetizationDashboard: React.FC = () => {
  const { creator } = useCreatorAuth();
  const [monetizationData, setMonetizationData] = useState<MonetizationData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [payoutDialogOpen, setPayoutDialogOpen] = useState(false);
  const [requestingPayout, setRequestingPayout] = useState(false);

  useEffect(() => {
    loadMonetizationData();
  }, []);

  const loadMonetizationData = async () => {
    try {
      setLoading(true);
      // This would be a real API call in production
      // For now, we'll mock the data
      const mockData: MonetizationData = {
        total_earnings: 1247.50,
        pending_earnings: 125.30,
        available_balance: 89.20,
        revenue_share_rate: 70,
        total_content_sold: 156,
        monthly_earnings: [
          { month: 'January', earnings: 245.30, sales_count: 32 },
          { month: 'February', earnings: 312.80, sales_count: 41 },
          { month: 'March', earnings: 189.40, sales_count: 28 },
          { month: 'April', earnings: 401.20, sales_count: 55 },
        ],
        payouts: [
          {
            id: '1',
            amount: 150.00,
            status: 'completed',
            created_at: '2024-01-15T10:00:00Z',
            completed_at: '2024-01-18T14:30:00Z',
          },
          {
            id: '2',
            amount: 200.50,
            status: 'pending',
            created_at: '2024-02-01T09:15:00Z',
          },
        ],
        content_performance: [
          {
            content_id: '1',
            title: 'The Magic Garden',
            total_sales: 45,
            total_earnings: 89.10,
            pricing_tier: 'premium',
          },
          {
            content_id: '2',
            title: 'Ocean Adventure',
            total_sales: 32,
            total_earnings: 63.40,
            pricing_tier: 'premium',
          },
        ],
      };
      
      setMonetizationData(mockData);
    } catch (err) {
      console.error('Failed to load monetization data:', err);
      setError(err instanceof Error ? err.message : 'Failed to load monetization data');
    } finally {
      setLoading(false);
    }
  };

  const handleRequestPayout = async (amount: number, method: string) => {
    try {
      setRequestingPayout(true);
      // This would be a real API call
      console.log('Requesting payout:', { amount, method });
      
      // Mock success
      setTimeout(() => {
        setRequestingPayout(false);
        setPayoutDialogOpen(false);
        // Refresh data
        loadMonetizationData();
      }, 1000);
    } catch (err) {
      console.error('Failed to request payout:', err);
      setError(err instanceof Error ? err.message : 'Failed to request payout');
      setRequestingPayout(false);
    }
  };

  const getStatusChip = (status: string) => {
    switch (status) {
      case 'completed':
        return <Chip icon={<CompletedIcon />} label="Completed" color="success" size="small" />;
      case 'pending':
        return <Chip icon={<PendingIcon />} label="Pending" color="warning" size="small" />;
      case 'processing':
        return <Chip label="Processing" color="info" size="small" />;
      case 'failed':
        return <Chip label="Failed" color="error" size="small" />;
      default:
        return <Chip label={status} size="small" />;
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
          Loading monetization data...
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

  // Show upgrade message for Tier 1 creators
  if (creator?.creator_tier === 'tier_1') {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <UpgradeIcon sx={{ fontSize: 64, color: 'primary.main', mb: 2 }} />
          <Typography variant="h4" gutterBottom>
            Unlock Monetization Features
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
            Upgrade to Tier 2 or higher to start earning revenue from your content
          </Typography>
          <Button variant="contained" size="large" startIcon={<UpgradeIcon />}>
            Upgrade Now
          </Button>
        </Paper>
      </Container>
    );
  }

  if (!monetizationData) {
    return (
      <Alert severity="warning">
        No monetization data available
      </Alert>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', alignItems: 'center', gap: 2 }}>
        <MonetizeIcon sx={{ fontSize: 32, color: 'primary.main' }} />
        <Box sx={{ flexGrow: 1 }}>
          <Typography variant="h4" component="h1" gutterBottom>
            Monetization Dashboard
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Track your earnings and manage payouts
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<PayoutIcon />}
          onClick={() => setPayoutDialogOpen(true)}
          disabled={monetizationData.available_balance < 10}
        >
          Request Payout
        </Button>
      </Box>

      {/* Key Metrics */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StyledMetricCard>
            <Typography variant="h4" gutterBottom>
              ${monetizationData.total_earnings.toFixed(2)}
            </Typography>
            <Typography variant="body2">
              Total Earnings
            </Typography>
          </StyledMetricCard>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ p: 3, textAlign: 'center' }}>
            <Typography variant="h4" color="warning.main" gutterBottom>
              ${monetizationData.pending_earnings.toFixed(2)}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Pending Earnings
            </Typography>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ p: 3, textAlign: 'center' }}>
            <Typography variant="h4" color="success.main" gutterBottom>
              ${monetizationData.available_balance.toFixed(2)}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Available Balance
            </Typography>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ p: 3, textAlign: 'center' }}>
            <Typography variant="h4" gutterBottom>
              {monetizationData.total_content_sold}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Content Sales
            </Typography>
          </Card>
        </Grid>
      </Grid>

      {/* Revenue Share Info */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
            <InfoIcon color="primary" />
            <Typography variant="h6">
              Revenue Share: {monetizationData.revenue_share_rate}%
            </Typography>
          </Box>
          <Typography variant="body2" color="text.secondary">
            You earn {monetizationData.revenue_share_rate}% of net revenue from your content sales. 
            Revenue share rates increase with higher creator tiers.
          </Typography>
        </CardContent>
      </Card>

      {/* Content Performance */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Top Performing Content
          </Typography>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Title</TableCell>
                  <TableCell align="right">Sales</TableCell>
                  <TableCell align="right">Earnings</TableCell>
                  <TableCell>Pricing</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {monetizationData.content_performance.map((content) => (
                  <TableRow key={content.content_id}>
                    <TableCell>{content.title}</TableCell>
                    <TableCell align="right">{content.total_sales}</TableCell>
                    <TableCell align="right">${content.total_earnings.toFixed(2)}</TableCell>
                    <TableCell>
                      <Chip label={content.pricing_tier} size="small" variant="outlined" />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Payout History */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Payout History
          </Typography>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Amount</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Requested</TableCell>
                  <TableCell>Completed</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {monetizationData.payouts.map((payout) => (
                  <TableRow key={payout.id}>
                    <TableCell>${payout.amount.toFixed(2)}</TableCell>
                    <TableCell>{getStatusChip(payout.status)}</TableCell>
                    <TableCell>{formatDate(payout.created_at)}</TableCell>
                    <TableCell>
                      {payout.completed_at ? formatDate(payout.completed_at) : '-'}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Payout Request Dialog */}
      <PayoutRequestDialog
        open={payoutDialogOpen}
        onClose={() => setPayoutDialogOpen(false)}
        availableBalance={monetizationData.available_balance}
        onRequestPayout={handleRequestPayout}
        isLoading={requestingPayout}
      />
    </Container>
  );
};

export default MonetizationDashboard;