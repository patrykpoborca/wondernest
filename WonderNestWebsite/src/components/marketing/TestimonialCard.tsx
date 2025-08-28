import React from 'react'
import {
  Card,
  CardContent,
  Typography,
  Box,
  Avatar,
  Rating,
  Stack,
  useTheme,
} from '@mui/material'
import { FormatQuote as QuoteIcon } from '@mui/icons-material'

interface TestimonialCardProps {
  quote: string
  author: string
  role: string
  avatar?: string
  rating?: number
  childAge?: string
  location?: string
}

export const TestimonialCard: React.FC<TestimonialCardProps> = ({
  quote,
  author,
  role,
  avatar,
  rating = 5,
  childAge,
  location,
}) => {
  const theme = useTheme()

  // Generate initials if no avatar
  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase()
  }

  return (
    <Card className="testimonial-card" elevation={0}>
      <CardContent>
        {/* Quote Icon */}
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'center',
            mb: 2,
          }}
        >
          <QuoteIcon
            sx={{
              fontSize: '2rem',
              color: theme.palette.primary.main,
              opacity: 0.6,
            }}
          />
        </Box>

        {/* Rating */}
        <Box sx={{ display: 'flex', justifyContent: 'center', mb: 2 }}>
          <Rating value={rating} readOnly size="small" />
        </Box>

        {/* Quote */}
        <Typography
          variant="body1"
          sx={{
            fontStyle: 'italic',
            lineHeight: 1.6,
            color: 'text.primary',
            textAlign: 'center',
            mb: 3,
            fontSize: '1.1rem',
          }}
        >
          "{quote}"
        </Typography>

        {/* Author Info */}
        <Stack
          direction="column"
          alignItems="center"
          spacing={1}
          sx={{ mt: 'auto' }}
        >
          <Avatar
            src={avatar}
            sx={{
              width: 56,
              height: 56,
              bgcolor: theme.palette.primary.main,
              fontSize: '1.25rem',
              fontWeight: 600,
            }}
          >
            {!avatar && getInitials(author)}
          </Avatar>
          
          <Box sx={{ textAlign: 'center' }}>
            <Typography variant="subtitle1" fontWeight={600} color="primary">
              {author}
            </Typography>
            
            <Typography variant="body2" color="text.secondary">
              {role}
            </Typography>
            
            {childAge && (
              <Typography variant="caption" color="text.secondary">
                Child age: {childAge}
              </Typography>
            )}
            
            {location && (
              <Typography variant="caption" color="text.secondary" display="block">
                {location}
              </Typography>
            )}
          </Box>
        </Stack>
      </CardContent>
    </Card>
  )
}