import React, { useState } from 'react'
import { 
  Button, 
  Dialog, 
  DialogActions, 
  DialogContent, 
  DialogContentText, 
  DialogTitle,
  IconButton,
  Tooltip
} from '@mui/material'
import { Logout as LogoutIcon } from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'
import { useDispatch } from 'react-redux'
import { logout } from '@/store/slices/authSlice'
import { useLogoutMutation } from '@/store/api/apiSlice'
import { useAuth } from '@/hooks/useAuth'
import { UserRole } from '@/types/auth'

interface LogoutButtonProps {
  variant?: 'button' | 'icon'
  fullWidth?: boolean
  showText?: boolean
}

export const LogoutButton: React.FC<LogoutButtonProps> = ({ 
  variant = 'button',
  fullWidth = false,
  showText = true 
}) => {
  const [open, setOpen] = useState(false)
  const [isLoggingOut, setIsLoggingOut] = useState(false)
  const navigate = useNavigate()
  const dispatch = useDispatch()
  const { user } = useAuth()
  const [logoutMutation] = useLogoutMutation()

  const handleClickOpen = () => {
    setOpen(true)
  }

  const handleClose = () => {
    if (!isLoggingOut) {
      setOpen(false)
    }
  }

  const handleLogout = async () => {
    setIsLoggingOut(true)
    
    try {
      // Determine user type for appropriate logout endpoint
      const userType = user?.userType === UserRole.PARENT ? 'parent' : 'admin'
      
      // Call backend logout endpoint
      await logoutMutation({ userType }).unwrap()
    } catch (error) {
      // Even if backend logout fails, proceed with local logout
      console.error('Backend logout error:', error)
    } finally {
      // Clear local state
      dispatch(logout())
      
      // Clear any session storage
      sessionStorage.clear()
      
      // Navigate to login page
      navigate('/app/login')
      
      setIsLoggingOut(false)
      setOpen(false)
    }
  }

  if (variant === 'icon') {
    return (
      <>
        <Tooltip title="Logout">
          <IconButton 
            color="inherit" 
            onClick={handleClickOpen}
            disabled={isLoggingOut}
          >
            <LogoutIcon />
          </IconButton>
        </Tooltip>
        
        <Dialog
          open={open}
          onClose={handleClose}
          aria-labelledby="logout-dialog-title"
          aria-describedby="logout-dialog-description"
        >
          <DialogTitle id="logout-dialog-title">
            Confirm Logout
          </DialogTitle>
          <DialogContent>
            <DialogContentText id="logout-dialog-description">
              Are you sure you want to logout? You'll need to sign in again to access your account.
            </DialogContentText>
          </DialogContent>
          <DialogActions>
            <Button 
              onClick={handleClose} 
              disabled={isLoggingOut}
            >
              Cancel
            </Button>
            <Button 
              onClick={handleLogout} 
              variant="contained" 
              color="primary"
              disabled={isLoggingOut}
            >
              {isLoggingOut ? 'Logging out...' : 'Logout'}
            </Button>
          </DialogActions>
        </Dialog>
      </>
    )
  }

  return (
    <>
      <Button
        variant="outlined"
        color="primary"
        startIcon={showText && <LogoutIcon />}
        onClick={handleClickOpen}
        fullWidth={fullWidth}
        disabled={isLoggingOut}
        sx={{ 
          justifyContent: fullWidth ? 'flex-start' : 'center',
          textTransform: 'none'
        }}
      >
        {showText ? 'Logout' : <LogoutIcon />}
      </Button>
      
      <Dialog
        open={open}
        onClose={handleClose}
        aria-labelledby="logout-dialog-title"
        aria-describedby="logout-dialog-description"
      >
        <DialogTitle id="logout-dialog-title">
          Confirm Logout
        </DialogTitle>
        <DialogContent>
          <DialogContentText id="logout-dialog-description">
            Are you sure you want to logout? You'll need to sign in again to access your account.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={handleClose} 
            disabled={isLoggingOut}
          >
            Cancel
          </Button>
          <Button 
            onClick={handleLogout} 
            variant="contained" 
            color="primary"
            disabled={isLoggingOut}
          >
            {isLoggingOut ? 'Logging out...' : 'Logout'}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}