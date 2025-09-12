import React, { useState, ReactNode } from 'react';
import {
  Box,
  Drawer,
  AppBar,
  Toolbar,
  Typography,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  IconButton,
  Avatar,
  Menu,
  MenuItem,
  Divider,
  Badge,
  Chip,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import {
  Dashboard,
  Create,
  Analytics,
  MonetizationOn,
  Settings,
  Logout,
  Menu as MenuIcon,
  Notifications,
  AccountCircle,
  BookOnline,
  Upload,
  Assessment,
} from '@mui/icons-material';
import { useLocation, useNavigate } from 'react-router-dom';
import { useCreatorAuth } from '@/contexts/CreatorAuthContext';

const DRAWER_WIDTH = 280;

interface CreatorLayoutProps {
  children: ReactNode;
}

const CreatorLayout: React.FC<CreatorLayoutProps> = ({ children }) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const location = useLocation();
  const navigate = useNavigate();
  const { creator, logout } = useCreatorAuth();
  
  const [mobileOpen, setMobileOpen] = useState(false);
  const [profileMenuAnchor, setProfileMenuAnchor] = useState<null | HTMLElement>(null);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleProfileMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setProfileMenuAnchor(event.currentTarget);
  };

  const handleProfileMenuClose = () => {
    setProfileMenuAnchor(null);
  };

  const handleLogout = async () => {
    handleProfileMenuClose();
    await logout();
  };

  const navigationItems = [
    {
      text: 'Dashboard',
      icon: <Dashboard />,
      path: '/creator/dashboard',
      description: 'Overview & stats'
    },
    {
      text: 'Create Story',
      icon: <BookOnline />,
      path: '/creator/stories/create',
      description: 'New story creation',
      highlight: true
    },
    {
      text: 'My Stories',
      icon: <Create />,
      path: '/creator/stories',
      description: 'Manage your stories'
    },
    {
      text: 'Content Library',
      icon: <Upload />,
      path: '/creator/content',
      description: 'All submissions'
    },
    {
      text: 'Analytics',
      icon: <Analytics />,
      path: '/creator/analytics',
      description: 'Performance insights'
    },
    {
      text: 'Monetization',
      icon: <MonetizationOn />,
      path: '/creator/monetization',
      description: 'Earnings & payouts',
      badge: creator?.creator_tier === 'tier_1' ? 'Upgrade' : undefined
    },
    {
      text: 'Reports',
      icon: <Assessment />,
      path: '/creator/reports',
      description: 'Detailed reports'
    }
  ];

  const isActiveRoute = (path: string) => {
    return location.pathname === path || location.pathname.startsWith(path + '/');
  };

  const drawer = (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Logo Section */}
      <Box sx={{ p: 3, borderBottom: 1, borderColor: 'divider' }}>
        <Typography variant="h6" color="primary" fontWeight="bold">
          WonderNest Creator
        </Typography>
        <Typography variant="caption" color="text.secondary">
          Content Creation Studio
        </Typography>
      </Box>

      {/* Creator Status */}
      <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
          <Avatar
            src={creator?.avatar_url}
            sx={{ width: 32, height: 32 }}
          >
            {creator?.display_name?.charAt(0)?.toUpperCase()}
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography variant="body2" fontWeight="medium" noWrap>
              {creator?.display_name}
            </Typography>
            <Typography variant="caption" color="text.secondary" noWrap>
              {creator?.creator_tier?.replace('_', ' ') || 'Creator'}
            </Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Chip 
            label={creator?.status?.replace('_', ' ') || 'Active'} 
            size="small" 
            color={creator?.status === 'active' ? 'success' : 'default'}
            sx={{ fontSize: '0.7rem' }}
          />
          {creator?.email_verified && (
            <Chip 
              label="Verified" 
              size="small" 
              color="primary"
              sx={{ fontSize: '0.7rem' }}
            />
          )}
        </Box>
      </Box>

      {/* Navigation */}
      <List sx={{ flex: 1, py: 1 }}>
        {navigationItems.map((item) => (
          <ListItem key={item.text} disablePadding sx={{ px: 1 }}>
            <ListItemButton
              onClick={() => navigate(item.path)}
              selected={isActiveRoute(item.path)}
              sx={{
                borderRadius: 2,
                mb: 0.5,
                minHeight: 48,
                bgcolor: item.highlight ? 'primary.50' : 'inherit',
                border: item.highlight ? 1 : 0,
                borderColor: item.highlight ? 'primary.200' : 'transparent',
                '&:hover': {
                  bgcolor: item.highlight ? 'primary.100' : 'action.hover',
                },
                '&.Mui-selected': {
                  bgcolor: 'primary.100',
                  '&:hover': {
                    bgcolor: 'primary.200',
                  },
                },
              }}
            >
              <ListItemIcon sx={{ 
                color: isActiveRoute(item.path) ? 'primary.main' : 'inherit',
                minWidth: 40 
              }}>
                {item.badge ? (
                  <Badge badgeContent={item.badge} color="secondary" variant="dot">
                    {item.icon}
                  </Badge>
                ) : (
                  item.icon
                )}
              </ListItemIcon>
              <ListItemText 
                primary={item.text}
                secondary={item.description}
                primaryTypographyProps={{
                  fontWeight: isActiveRoute(item.path) ? 600 : 400,
                  color: isActiveRoute(item.path) ? 'primary.main' : 'inherit'
                }}
                secondaryTypographyProps={{
                  fontSize: '0.75rem'
                }}
              />
            </ListItemButton>
          </ListItem>
        ))}
      </List>

      {/* Bottom Section */}
      <Box sx={{ p: 1, borderTop: 1, borderColor: 'divider' }}>
        <ListItemButton
          onClick={() => navigate('/creator/settings')}
          sx={{ borderRadius: 2, minHeight: 48 }}
        >
          <ListItemIcon sx={{ minWidth: 40 }}>
            <Settings />
          </ListItemIcon>
          <ListItemText 
            primary="Settings"
            secondary="Account & preferences"
            secondaryTypographyProps={{ fontSize: '0.75rem' }}
          />
        </ListItemButton>
      </Box>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex', height: '100vh' }}>
      {/* App Bar */}
      <AppBar
        position="fixed"
        sx={{
          width: { md: `calc(100% - ${DRAWER_WIDTH}px)` },
          ml: { md: `${DRAWER_WIDTH}px` },
          bgcolor: 'background.paper',
          color: 'text.primary',
          borderBottom: 1,
          borderColor: 'divider',
          boxShadow: 'none',
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { md: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          
          <Box sx={{ flexGrow: 1 }} />
          
          <IconButton color="inherit" sx={{ mr: 1 }}>
            <Badge badgeContent={3} color="error">
              <Notifications />
            </Badge>
          </IconButton>
          
          <IconButton
            size="large"
            onClick={handleProfileMenuOpen}
            color="inherit"
          >
            <Avatar
              src={creator?.avatar_url}
              sx={{ width: 32, height: 32 }}
            >
              {creator?.display_name?.charAt(0)?.toUpperCase()}
            </Avatar>
          </IconButton>
        </Toolbar>
      </AppBar>

      {/* Navigation Drawer */}
      <Box
        component="nav"
        sx={{ width: { md: DRAWER_WIDTH }, flexShrink: { md: 0 } }}
      >
        <Drawer
          variant={isMobile ? 'temporary' : 'permanent'}
          open={isMobile ? mobileOpen : true}
          onClose={handleDrawerToggle}
          ModalProps={{ keepMounted: true }}
          sx={{
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: DRAWER_WIDTH,
              borderRight: 1,
              borderColor: 'divider',
            },
          }}
        >
          {drawer}
        </Drawer>
      </Box>

      {/* Main Content */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { md: `calc(100% - ${DRAWER_WIDTH}px)` },
          bgcolor: 'background.default',
          overflow: 'auto',
        }}
      >
        <Toolbar />
        <Box sx={{ p: 3 }}>
          {children}
        </Box>
      </Box>

      {/* Profile Menu */}
      <Menu
        anchorEl={profileMenuAnchor}
        open={Boolean(profileMenuAnchor)}
        onClose={handleProfileMenuClose}
        onClick={handleProfileMenuClose}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        <MenuItem onClick={() => navigate('/creator/profile')}>
          <AccountCircle sx={{ mr: 2 }} />
          Profile
        </MenuItem>
        <MenuItem onClick={() => navigate('/creator/settings')}>
          <Settings sx={{ mr: 2 }} />
          Settings
        </MenuItem>
        <Divider />
        <MenuItem onClick={handleLogout}>
          <Logout sx={{ mr: 2 }} />
          Sign out
        </MenuItem>
      </Menu>
    </Box>
  );
};

export default CreatorLayout;