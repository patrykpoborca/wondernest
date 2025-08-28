import React from 'react'
import {
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  useTheme,
} from '@mui/material'

interface FeatureCardProps {
  icon: React.ReactNode
  title: string
  description: string
  features?: string[]
  tag?: string
  tagColor?: string
}

export const FeatureCard: React.FC<FeatureCardProps> = ({
  icon,
  title,
  description,
  features = [],
  tag,
  tagColor,
}) => {
  const theme = useTheme()

  return (
    <Card className="feature-card" elevation={0}>
      <CardContent>
        {tag && (
          <Chip
            label={tag}
            size="small"
            className="feature-tag"
            sx={{
              backgroundColor: tagColor ? `${tagColor}15` : undefined,
              color: tagColor || theme.palette.primary.main,
              mb: 2,
            }}
          />
        )}
        
        <Box className="feature-icon" sx={{ mb: 2 }}>
          {icon}
        </Box>

        <Typography
          variant="h5"
          component="h3"
          fontWeight={600}
          color="primary"
          gutterBottom
        >
          {title}
        </Typography>

        <Typography
          variant="body1"
          color="text.secondary"
          sx={{ mb: features.length > 0 ? 3 : 0, lineHeight: 1.6 }}
        >
          {description}
        </Typography>

        {features.length > 0 && (
          <Box>
            {features.map((feature, index) => (
              <Typography
                key={index}
                variant="body2"
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  mb: 1,
                  color: 'text.secondary',
                  '&:before': {
                    content: '"✓"',
                    color: theme.palette.secondary.main,
                    fontWeight: 'bold',
                    marginRight: 1,
                  },
                }}
              >
                {feature}
              </Typography>
            ))}
          </Box>
        )}
      </CardContent>
    </Card>
  )
}