import { createTheme, ThemeOptions } from '@mui/material/styles'

// WonderNest brand colors from the UI/UX recommendations
const brandColors = {
  primary: '#6366F1',        // Indigo - trust and reliability
  secondary: '#10B981',      // Emerald - growth and learning
  accent: '#F59E0B',         // Amber - creativity and engagement
  background: '#F8FAFC',     // Soft gray background
  cardBackground: '#FFFFFF', // Clean white cards
  textPrimary: '#1F2937',    // Dark gray for readability
  textSecondary: '#6B7280',  // Medium gray for secondary text
}

// Additional color palette for different child contexts
const childColors = {
  child1: '#8B5CF6',  // Purple
  child2: '#06B6D4',  // Cyan
  child3: '#EF4444',  // Red
  child4: '#F97316',  // Orange
}

// Typography scale
const typography = {
  fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif",
  h1: {
    fontFamily: "'Poppins', 'Inter', sans-serif",
    fontSize: '1.875rem', // 30px
    fontWeight: 700,
  },
  h2: {
    fontFamily: "'Poppins', 'Inter', sans-serif", 
    fontSize: '1.5rem',   // 24px
    fontWeight: 600,
  },
  h3: {
    fontFamily: "'Poppins', 'Inter', sans-serif",
    fontSize: '1.25rem',  // 20px
    fontWeight: 600,
  },
  h4: {
    fontSize: '1.125rem', // 18px
    fontWeight: 600,
  },
  body1: {
    fontSize: '1rem',     // 16px
    lineHeight: 1.5,
  },
  body2: {
    fontSize: '0.875rem', // 14px
    lineHeight: 1.43,
  },
  caption: {
    fontSize: '0.75rem',  // 12px
    lineHeight: 1.4,
  }
}

const themeOptions: ThemeOptions = {
  palette: {
    mode: 'light',
    primary: {
      main: brandColors.primary,
      light: '#8B7EF7',
      dark: '#4F46E5',
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: brandColors.secondary,
      light: '#34D399',
      dark: '#059669',
      contrastText: '#FFFFFF',
    },
    error: {
      main: '#EF4444',
      light: '#F87171',
      dark: '#DC2626',
    },
    warning: {
      main: brandColors.accent,
      light: '#FBC659',
      dark: '#D97706',
    },
    success: {
      main: brandColors.secondary,
      light: '#34D399',
      dark: '#059669',
    },
    background: {
      default: brandColors.background,
      paper: brandColors.cardBackground,
    },
    text: {
      primary: brandColors.textPrimary,
      secondary: brandColors.textSecondary,
    },
    grey: {
      50: '#F9FAFB',
      100: '#F3F4F6',
      200: '#E5E7EB',
      300: '#D1D5DB',
      400: '#9CA3AF',
      500: brandColors.textSecondary,
      600: '#4B5563',
      700: '#374151',
      800: '#1F2937',
      900: '#111827',
    },
  },
  typography,
  shape: {
    borderRadius: 8,
  },
  spacing: 8,
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          backgroundColor: brandColors.background,
          fontFamily: typography.fontFamily,
        },
        '*': {
          '&::-webkit-scrollbar': {
            width: '8px',
          },
          '&::-webkit-scrollbar-track': {
            backgroundColor: '#F3F4F6',
            borderRadius: '4px',
          },
          '&::-webkit-scrollbar-thumb': {
            backgroundColor: '#D1D5DB',
            borderRadius: '4px',
            '&:hover': {
              backgroundColor: '#9CA3AF',
            },
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: '12px',
          boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
          transition: 'box-shadow 0.2s ease-in-out, transform 0.2s ease-in-out',
          '&:hover': {
            boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
            transform: 'translateY(-1px)',
          },
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: '8px',
          textTransform: 'none',
          fontWeight: 500,
          fontSize: '0.875rem',
          padding: '10px 20px',
          transition: 'all 0.2s ease-in-out',
        },
        containedPrimary: {
          background: `linear-gradient(135deg, ${brandColors.primary} 0%, #8B7EF7 100%)`,
          boxShadow: '0 4px 6px -1px rgb(99 102 241 / 0.25)',
          '&:hover': {
            boxShadow: '0 10px 15px -3px rgb(99 102 241 / 0.25), 0 4px 6px -2px rgb(99 102 241 / 0.05)',
            transform: 'translateY(-1px)',
          },
        },
        containedSecondary: {
          background: `linear-gradient(135deg, ${brandColors.secondary} 0%, #34D399 100%)`,
          boxShadow: '0 4px 6px -1px rgb(16 185 129 / 0.25)',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: '8px',
            transition: 'all 0.2s ease-in-out',
            '&:hover .MuiOutlinedInput-notchedOutline': {
              borderColor: brandColors.primary,
            },
            '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
              borderWidth: '2px',
              borderColor: brandColors.primary,
            },
          },
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
        },
        elevation1: {
          boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
        },
        elevation2: {
          boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
        },
        elevation3: {
          boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: '6px',
          fontWeight: 500,
          fontSize: '0.75rem',
        },
        colorPrimary: {
          backgroundColor: `${brandColors.primary}20`,
          color: brandColors.primary,
        },
        colorSecondary: {
          backgroundColor: `${brandColors.secondary}20`,
          color: brandColors.secondary,
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: brandColors.cardBackground,
          color: brandColors.textPrimary,
          boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
        },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          backgroundColor: brandColors.cardBackground,
          borderRight: `1px solid #E5E7EB`,
        },
      },
    },
    MuiListItemButton: {
      styleOverrides: {
        root: {
          borderRadius: '8px',
          margin: '2px 8px',
          '&.Mui-selected': {
            backgroundColor: `${brandColors.primary}15`,
            color: brandColors.primary,
            '& .MuiListItemIcon-root': {
              color: brandColors.primary,
            },
            '&:hover': {
              backgroundColor: `${brandColors.primary}20`,
            },
          },
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          backgroundColor: '#F9FAFB',
          fontWeight: 600,
          fontSize: '0.875rem',
          color: brandColors.textPrimary,
          borderBottom: `1px solid #E5E7EB`,
        },
        body: {
          borderBottom: `1px solid #F3F4F6`,
        },
      },
    },
  },
}

// Create the theme
export const wonderNestTheme = createTheme(themeOptions)

// Custom theme extensions for specific use cases
export const customColors = {
  ...brandColors,
  childColors,
  status: {
    online: '#10B981',
    offline: '#6B7280', 
    busy: '#F59E0B',
    error: '#EF4444',
  },
  gradients: {
    primary: `linear-gradient(135deg, ${brandColors.primary} 0%, #8B7EF7 100%)`,
    secondary: `linear-gradient(135deg, ${brandColors.secondary} 0%, #34D399 100%)`,
    accent: `linear-gradient(135deg, ${brandColors.accent} 0%, #FBC659 100%)`,
  },
}

// Utility function to get child-specific colors
export const getChildColor = (index: number): string => {
  const colors = Object.values(childColors)
  return colors[index % colors.length]
}