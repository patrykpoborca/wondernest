import { createTheme } from '@mui/material/styles'
import { wonderNestTheme, customColors } from './wonderNestTheme'

// Enhanced marketing-specific theme extensions
export const marketingTheme = createTheme({
  ...wonderNestTheme,
  components: {
    ...(wonderNestTheme.components || {}),

    // Feature Cards
    MuiCard: {
      styleOverrides: {
        root: {
          ...(wonderNestTheme.components?.MuiCard?.styleOverrides?.root as any || {}),
          '&.feature-card': {
            padding: '32px 24px',
            textAlign: 'center',
            border: `1px solid #E5E7EB`,
            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            '&:hover': {
              transform: 'translateY(-8px)',
              boxShadow: `0 20px 25px -5px rgb(0 0 0 / 0.1), 0 10px 10px -5px rgb(0 0 0 / 0.04)`,
              borderColor: customColors.primary,
              '& .feature-icon': {
                transform: 'scale(1.1)',
                color: customColors.primary,
              },
            },
            '& .feature-icon': {
              fontSize: '3rem',
              color: customColors.secondary,
              marginBottom: '16px',
              transition: 'all 0.3s ease',
            },
          },
          '&.pricing-card': {
            position: 'relative',
            padding: '40px 32px',
            textAlign: 'center',
            border: `2px solid #E5E7EB`,
            '&.popular': {
              borderColor: customColors.primary,
              transform: 'scale(1.05)',
              '&::before': {
                content: '"Most Popular"',
                position: 'absolute',
                top: '-12px',
                left: '50%',
                transform: 'translateX(-50%)',
                background: customColors.gradients.primary,
                color: 'white',
                padding: '6px 20px',
                borderRadius: '20px',
                fontSize: '0.875rem',
                fontWeight: 600,
              },
            },
          },
          '&.testimonial-card': {
            padding: '32px',
            background: 'rgba(255, 255, 255, 0.8)',
            backdropFilter: 'blur(10px)',
            border: `1px solid rgba(255, 255, 255, 0.2)`,
          },
        },
      },
    },

    // Enhanced Typography for Marketing
    MuiTypography: {
      styleOverrides: {
        root: {
          '&.hero-title': {
            fontSize: 'clamp(2.5rem, 6vw, 4rem)',
            fontWeight: 800,
            lineHeight: 1.1,
            background: `linear-gradient(135deg, ${customColors.primary} 0%, ${customColors.secondary} 100%)`,
            backgroundClip: 'text',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            marginBottom: '24px',
          },
          '&.hero-subtitle': {
            fontSize: 'clamp(1.125rem, 2.5vw, 1.5rem)',
            lineHeight: 1.6,
            color: customColors.textSecondary,
            marginBottom: '32px',
            maxWidth: '600px',
          },
          '&.section-title': {
            fontSize: 'clamp(2rem, 4vw, 3rem)',
            fontWeight: 700,
            color: customColors.textPrimary,
            textAlign: 'center',
            marginBottom: '16px',
          },
          '&.section-subtitle': {
            fontSize: '1.25rem',
            color: customColors.textSecondary,
            textAlign: 'center',
            marginBottom: '48px',
            maxWidth: '700px',
            marginLeft: 'auto',
            marginRight: 'auto',
          },
        },
      },
    },

    // Enhanced Buttons for Marketing CTAs
    MuiButton: {
      styleOverrides: {
        root: {
          ...(wonderNestTheme.components?.MuiButton?.styleOverrides?.root as any || {}),
          '&.cta-primary': {
            background: customColors.gradients.primary,
            color: 'white',
            fontSize: '1.125rem',
            fontWeight: 600,
            padding: '16px 32px',
            borderRadius: '12px',
            boxShadow: `0 8px 25px -5px ${customColors.primary}40`,
            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            '&:hover': {
              transform: 'translateY(-2px)',
              boxShadow: `0 16px 40px -5px ${customColors.primary}50`,
            },
          },
          '&.cta-secondary': {
            background: 'transparent',
            color: customColors.primary,
            border: `2px solid ${customColors.primary}`,
            fontSize: '1.125rem',
            fontWeight: 600,
            padding: '16px 32px',
            borderRadius: '12px',
            transition: 'all 0.3s ease',
            '&:hover': {
              background: customColors.primary,
              color: 'white',
              transform: 'translateY(-2px)',
            },
          },
          '&.pricing-cta': {
            width: '100%',
            padding: '16px',
            fontSize: '1.125rem',
            fontWeight: 600,
            marginTop: '24px',
          },
        },
      },
    },

    // Navigation Styles
    MuiAppBar: {
      styleOverrides: {
        root: {
          ...(wonderNestTheme.components?.MuiAppBar?.styleOverrides?.root as any || {}),
          '&.marketing-nav': {
            background: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(10px)',
            borderBottom: `1px solid #E5E7EB`,
            transition: 'all 0.3s ease',
            '&.scrolled': {
              boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
            },
          },
        },
      },
    },

    // Container Styles
    MuiContainer: {
      styleOverrides: {
        root: {
          '&.hero-container': {
            textAlign: 'center',
            padding: '0 24px',
          },
          '&.section-container': {
            padding: '0 24px',
            maxWidth: '1200px',
          },
        },
      },
    },

    // Chip Styles for Tags
    MuiChip: {
      styleOverrides: {
        root: {
          ...(wonderNestTheme.components?.MuiChip?.styleOverrides?.root as any || {}),
          '&.feature-tag': {
            background: `${customColors.primary}15`,
            color: customColors.primary,
            fontWeight: 600,
            marginBottom: '16px',
          },
          '&.pricing-feature': {
            background: `${customColors.secondary}15`,
            color: customColors.secondary,
            margin: '4px 0',
            justifyContent: 'flex-start',
          },
        },
      },
    },
  },
})

// Marketing-specific color extensions
export const marketingColors = {
  ...customColors,
  hero: {
    background: `linear-gradient(135deg, ${customColors.primary}15 0%, ${customColors.secondary}10 50%, ${customColors.accent}05 100%)`,
  },
  section: {
    light: customColors.background,
    white: '#FFFFFF',
    accent: `linear-gradient(135deg, ${customColors.primary}05 0%, ${customColors.secondary}05 100%)`,
  },
  trust: {
    badges: '#10B981',
    security: '#6366F1',
    coppa: '#F59E0B',
  },
}

// Utility functions for marketing components
export const getMarketingAnimation = (_type: 'fadeInUp' | 'fadeIn' | 'scaleIn') => {
  return {}
}