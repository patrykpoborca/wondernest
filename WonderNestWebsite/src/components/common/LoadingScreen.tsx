import React from 'react'
import { Box, CircularProgress, Typography } from '@mui/material'
import { customColors } from '@/theme/wonderNestTheme'

interface LoadingScreenProps {
  message?: string
  fullScreen?: boolean
}

export const LoadingScreen: React.FC<LoadingScreenProps> = ({ 
  message = 'Loading...', 
  fullScreen = true 
}) => {
  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        height: fullScreen ? '100vh' : '200px',
        width: '100%',
        backgroundColor: fullScreen ? customColors.background : 'transparent',
        gap: 2,
      }}
    >
      <CircularProgress 
        size={60} 
        thickness={4}
        sx={{
          color: customColors.primary,
        }}
      />
      <Typography 
        variant="h6" 
        color="textSecondary"
        sx={{ 
          fontWeight: 400,
          textAlign: 'center',
        }}
      >
        {message}
      </Typography>
    </Box>
  )
}