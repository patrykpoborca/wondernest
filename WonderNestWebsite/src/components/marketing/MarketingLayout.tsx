import React, { useState, useEffect } from 'react'
import {
  Box,
  AppBar,
  Toolbar,
  Typography,
  Button,
  Container,
  Stack,
  IconButton,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  Divider,
  useTheme,
  useMediaQuery,
  Chip,
} from '@mui/material'
import {
  Menu as MenuIcon,
  Close as CloseIcon,
  Security as SecurityIcon,
  School as SchoolIcon,
  FamilyRestroom as FamilyIcon,
} from '@mui/icons-material'
import { Link, useLocation } from 'react-router-dom'

interface MarketingLayoutProps {
  children: React.ReactNode
}

export const MarketingLayout: React.FC<MarketingLayoutProps> = ({ children }) => {
  const theme = useTheme()
  const isMobile = useMediaQuery(theme.breakpoints.down('lg'))
  const location = useLocation()
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  // Handle scroll effect for navbar
  useEffect(() => {
    const handleScroll = () => {
      const isScrolled = window.scrollY > 50
      setScrolled(isScrolled)
    }

    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const navigationItems = [
    { label: 'Home', href: '/', exact: true },
    { label: 'Features', href: '/features' },
    { label: 'Pricing', href: '/pricing' },
    { label: 'Safety', href: '/safety' },
    { label: 'About', href: '/about' },
    { label: 'Resources', href: '/resources' },
    { label: 'Contact', href: '/contact' },
  ]

  const isActiveRoute = (href: string, exact = false) => {
    if (exact) {
      return location.pathname === href
    }
    return location.pathname.startsWith(href)
  }

  const handleMobileMenuToggle = () => {
    setMobileMenuOpen(!mobileMenuOpen)
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      {/* Navigation */}
      <AppBar 
        className={`marketing-nav ${scrolled ? 'scrolled' : ''}`}
        position="fixed"
        elevation={0}
      >
        <Container maxWidth="lg">
          <Toolbar sx={{ px: { xs: 0, sm: 2 }, justifyContent: 'space-between' }}>
            {/* Logo */}
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <Link to="/" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center' }}>
                <SchoolIcon sx={{ fontSize: '2rem', color: theme.palette.primary.main, mr: 1 }} />
                <Typography
                  variant="h5"
                  component="div"
                  fontWeight={700}
                  sx={{
                    background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`,
                    backgroundClip: 'text',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                  }}
                >
                  WonderNest
                </Typography>
              </Link>
            </Box>

            {/* Desktop Navigation */}
            {!isMobile && (
              <Stack direction="row" spacing={0.5} alignItems="center">
                {navigationItems.map((item) => (
                  <Button
                    key={item.href}
                    component={Link}
                    to={item.href}
                    sx={{
                      color: isActiveRoute(item.href, item.exact) ? theme.palette.primary.main : 'text.primary',
                      fontWeight: isActiveRoute(item.href, item.exact) ? 600 : 400,
                      px: 2,
                      py: 1,
                      borderRadius: 2,
                      '&:hover': {
                        backgroundColor: `${theme.palette.primary.main}08`,
                      },
                    }}
                  >
                    {item.label}
                  </Button>
                ))}
              </Stack>
            )}

            {/* CTA Buttons */}
            <Stack direction="row" spacing={1} alignItems="center">
              {!isMobile && (
                <>
                  <Button
                    component={Link}
                    to="/app/login"
                    color="primary"
                    variant="outlined"
                    size="small"
                  >
                    Sign In
                  </Button>
                  <Button
                    component={Link}
                    to="/app/signup"
                    color="primary"
                    variant="contained"
                    size="small"
                  >
                    Start Free Trial
                  </Button>
                </>
              )}

              {/* Mobile Menu Button */}
              {isMobile && (
                <IconButton
                  color="primary"
                  onClick={handleMobileMenuToggle}
                  edge="end"
                >
                  <MenuIcon />
                </IconButton>
              )}
            </Stack>
          </Toolbar>
        </Container>
      </AppBar>

      {/* Mobile Drawer */}
      <Drawer
        anchor="right"
        open={mobileMenuOpen}
        onClose={handleMobileMenuToggle}
        sx={{
          '& .MuiDrawer-paper': {
            width: 280,
            bgcolor: 'background.paper',
          },
        }}
      >
        <Box sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6" fontWeight={600} color="primary">
            Menu
          </Typography>
          <IconButton onClick={handleMobileMenuToggle}>
            <CloseIcon />
          </IconButton>
        </Box>
        <Divider />
        <List>
          {navigationItems.map((item) => (
            <ListItem key={item.href} disablePadding>
              <ListItemButton
                component={Link}
                to={item.href}
                onClick={handleMobileMenuToggle}
                selected={isActiveRoute(item.href, item.exact)}
              >
                <ListItemText primary={item.label} />
              </ListItemButton>
            </ListItem>
          ))}
        </List>
        <Divider />
        <Box sx={{ p: 2 }}>
          <Stack spacing={2}>
            <Button
              component={Link}
              to="/app/login"
              color="primary"
              variant="outlined"
              fullWidth
              onClick={handleMobileMenuToggle}
            >
              Sign In
            </Button>
            <Button
              component={Link}
              to="/app/signup"
              color="primary"
              variant="contained"
              fullWidth
              onClick={handleMobileMenuToggle}
            >
              Start Free Trial
            </Button>
          </Stack>
        </Box>
      </Drawer>

      {/* Main Content */}
      <Box sx={{ flexGrow: 1, pt: { xs: '64px', sm: '70px' } }}>
        {children}
      </Box>

      {/* Footer */}
      <Box
        sx={{
          background: `linear-gradient(135deg, ${theme.palette.grey[900]} 0%, ${theme.palette.grey[800]} 100%)`,
          color: 'white',
          py: 6,
          mt: 'auto',
        }}
      >
        <Container maxWidth="lg">
          <Stack spacing={4}>
            {/* Footer Header */}
            <Box sx={{ textAlign: 'center' }}>
              <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', mb: 2 }}>
                <SchoolIcon sx={{ fontSize: '2rem', color: theme.palette.primary.main, mr: 1 }} />
                <Typography variant="h5" fontWeight={700}>
                  WonderNest
                </Typography>
              </Box>
              <Typography variant="body1" color="rgba(255, 255, 255, 0.8)">
                Safe, educational, and engaging digital experiences for children aged 3-12
              </Typography>
            </Box>

            {/* Trust Badges */}
            <Box sx={{ display: 'flex', justifyContent: 'center', gap: 2, flexWrap: 'wrap' }}>
              <Chip
                icon={<SecurityIcon />}
                label="COPPA Compliant"
                sx={{ bgcolor: `${theme.palette.primary.main}20`, color: 'white' }}
              />
              <Chip
                icon={<FamilyIcon />}
                label="Family Safe"
                sx={{ bgcolor: `${theme.palette.secondary.main}20`, color: 'white' }}
              />
              <Chip
                icon={<SchoolIcon />}
                label="Educational"
                sx={{ bgcolor: `${theme.palette.warning.main}20`, color: 'white' }}
              />
            </Box>

            {/* Footer Links */}
            <Stack
              direction={{ xs: 'column', md: 'row' }}
              justifyContent="center"
              spacing={3}
              sx={{ textAlign: 'center' }}
            >
              {navigationItems.map((item) => (
                <Button
                  key={item.href}
                  component={Link}
                  to={item.href}
                  sx={{ color: 'rgba(255, 255, 255, 0.8)', '&:hover': { color: 'white' } }}
                >
                  {item.label}
                </Button>
              ))}
            </Stack>

            <Divider sx={{ bgcolor: 'rgba(255, 255, 255, 0.1)' }} />

            {/* Copyright */}
            <Typography
              variant="body2"
              color="rgba(255, 255, 255, 0.6)"
              textAlign="center"
            >
              © {new Date().getFullYear()} WonderNest. All rights reserved. 
              Built with ❤️ for families creating safe digital learning experiences.
            </Typography>
          </Stack>
        </Container>
      </Box>
    </Box>
  )
}