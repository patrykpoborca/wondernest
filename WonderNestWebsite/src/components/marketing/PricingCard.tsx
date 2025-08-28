import React from 'react'
import {
  Card,
  CardContent,
  Typography,
  Button,
  Box,
  Chip,
  Stack,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  useTheme,
} from '@mui/material'
import { Check as CheckIcon } from '@mui/icons-material'

interface PricingCardProps {
  title: string
  price: string
  period?: string
  description: string
  features: string[]
  isPopular?: boolean
  buttonText?: string
  buttonVariant?: 'contained' | 'outlined'
  onSelect?: () => void
  badge?: string
  originalPrice?: string
}

export const PricingCard: React.FC<PricingCardProps> = ({
  title,
  price,
  period = 'month',
  description,
  features,
  isPopular = false,
  buttonText = 'Get Started',
  buttonVariant = 'contained',
  onSelect,
  badge,
  originalPrice,
}) => {
  const theme = useTheme()

  return (
    <Card 
      className={`pricing-card ${isPopular ? 'popular' : ''}`}
      elevation={isPopular ? 8 : 2}
      sx={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        ...(isPopular && {
          boxShadow: `0 20px 25px -5px ${theme.palette.primary.main}20, 0 10px 10px -5px ${theme.palette.primary.main}10`,
        }),
      }}
    >
      <CardContent sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Header */}
        <Box sx={{ textAlign: 'center', mb: 3 }}>
          {badge && (
            <Chip
              label={badge}
              color="secondary"
              size="small"
              sx={{ mb: 2 }}
            />
          )}
          
          <Typography variant="h5" component="h3" fontWeight={700} gutterBottom>
            {title}
          </Typography>
          
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            {description}
          </Typography>

          {/* Price */}
          <Stack direction="row" alignItems="baseline" justifyContent="center" spacing={0.5}>
            {originalPrice && (
              <Typography
                variant="h6"
                sx={{
                  textDecoration: 'line-through',
                  color: 'text.disabled',
                }}
              >
                ${originalPrice}
              </Typography>
            )}
            <Typography
              variant="h3"
              component="span"
              fontWeight={800}
              color="primary"
            >
              ${price}
            </Typography>
            <Typography variant="body1" color="text.secondary">
              /{period}
            </Typography>
          </Stack>
        </Box>

        {/* Features */}
        <Box sx={{ flexGrow: 1, mb: 3 }}>
          <List dense sx={{ py: 0 }}>
            {features.map((feature, index) => (
              <ListItem key={index} sx={{ px: 0, py: 0.5 }}>
                <ListItemIcon sx={{ minWidth: 32 }}>
                  <CheckIcon 
                    color="secondary" 
                    sx={{ fontSize: '1.25rem' }} 
                  />
                </ListItemIcon>
                <ListItemText
                  primary={feature}
                  primaryTypographyProps={{
                    variant: 'body2',
                    color: 'text.primary',
                  }}
                />
              </ListItem>
            ))}
          </List>
        </Box>

        {/* CTA Button */}
        <Button
          className="pricing-cta"
          variant={isPopular ? 'contained' : buttonVariant}
          color="primary"
          size="large"
          onClick={onSelect}
          fullWidth
          sx={{
            ...(isPopular && {
              background: theme.palette.primary.main,
              '&:hover': {
                background: theme.palette.primary.dark,
              },
            }),
          }}
        >
          {buttonText}
        </Button>

        {/* Additional Info */}
        <Typography
          variant="caption"
          color="text.secondary"
          textAlign="center"
          sx={{ mt: 2 }}
        >
          No commitment • Cancel anytime
        </Typography>
      </CardContent>
    </Card>
  )
}