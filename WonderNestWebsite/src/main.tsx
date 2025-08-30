import React from 'react'
import ReactDOM from 'react-dom/client'
import { Provider } from 'react-redux'
import { BrowserRouter } from 'react-router-dom'
import { ThemeProvider } from '@mui/material/styles'
import CssBaseline from '@mui/material/CssBaseline'

import App from './App'
import { store } from './store'
import { marketingTheme } from './theme/marketingTheme'
import { loginSuccess } from './store/slices/authSlice'
import { UserRole, Permission } from './types/auth'

// Development-only mock authentication
if (import.meta.env.DEV) {
  const mockUser = {
    id: 'dev-user-123',
    email: 'dev@wondernest.com',
    firstName: 'Developer',
    lastName: 'User',
    userType: UserRole.PARENT,
    permissions: [
      Permission.VIEW_CHILD_PROGRESS,
      Permission.MANAGE_CHILD_SETTINGS,
      Permission.MANAGE_BOOKMARKS,
      Permission.VIEW_CHILD_CONTENT,
      Permission.MANAGE_CONTENT_FILTERS,
      Permission.VIEW_ANALYTICS,
      Permission.MANAGE_FAMILY_SETTINGS,
    ],
    twoFactorEnabled: false,
    familyId: 'dev-family-123',
  }

  const mockLoginResponse = {
    accessToken: 'dev-token-123',
    refreshToken: 'dev-refresh-123',
    user: mockUser,
    permissions: mockUser.permissions,
    expiresIn: 3600,
    requiresTwoFactor: false,
  }

  store.dispatch(loginSuccess(mockLoginResponse))
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <Provider store={store}>
      <BrowserRouter>
        <ThemeProvider theme={marketingTheme}>
          <CssBaseline />
          <App />
        </ThemeProvider>
      </BrowserRouter>
    </Provider>
  </React.StrictMode>,
)