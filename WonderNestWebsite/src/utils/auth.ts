import { jwtDecode } from 'jwt-decode'

interface JwtPayload {
  exp?: number
  iat?: number
  userId?: string
  email?: string
  role?: string
}

/**
 * Check if a JWT token is expired or about to expire
 * @param token JWT token string
 * @param bufferSeconds Number of seconds before actual expiration to consider token expired (default 60)
 * @returns true if token is expired or about to expire
 */
export const isTokenExpired = (token: string | null, bufferSeconds: number = 60): boolean => {
  if (!token) return true
  
  try {
    const decoded = jwtDecode<JwtPayload>(token)
    if (!decoded.exp) return true
    
    const now = Date.now() / 1000
    const expirationTime = decoded.exp - bufferSeconds
    
    return now >= expirationTime
  } catch (error) {
    console.error('Error decoding token:', error)
    return true
  }
}

/**
 * Get the remaining time until token expiration in milliseconds
 * @param token JWT token string
 * @returns Time in milliseconds until expiration, or 0 if expired
 */
export const getTokenExpirationTime = (token: string | null): number => {
  if (!token) return 0
  
  try {
    const decoded = jwtDecode<JwtPayload>(token)
    if (!decoded.exp) return 0
    
    const now = Date.now()
    const expirationTime = decoded.exp * 1000 // Convert to milliseconds
    const remaining = expirationTime - now
    
    return remaining > 0 ? remaining : 0
  } catch (error) {
    console.error('Error decoding token:', error)
    return 0
  }
}

/**
 * Calculate when to refresh token (at 75% of token lifetime)
 * @param token JWT token string
 * @returns Time in milliseconds until refresh should occur
 */
export const getTokenRefreshTime = (token: string | null): number => {
  if (!token) return 0
  
  try {
    const decoded = jwtDecode<JwtPayload>(token)
    if (!decoded.exp || !decoded.iat) return 0
    
    const now = Date.now() / 1000
    const tokenLifetime = decoded.exp - decoded.iat
    const refreshAt = decoded.iat + (tokenLifetime * 0.75) // Refresh at 75% of lifetime
    const timeUntilRefresh = (refreshAt - now) * 1000 // Convert to milliseconds
    
    return timeUntilRefresh > 0 ? timeUntilRefresh : 0
  } catch (error) {
    console.error('Error calculating refresh time:', error)
    return 0
  }
}

/**
 * Extract user info from JWT token
 * @param token JWT token string
 * @returns User info from token payload
 */
export const getUserFromToken = (token: string | null): Partial<JwtPayload> | null => {
  if (!token) return null
  
  try {
    const decoded = jwtDecode<JwtPayload>(token)
    return {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role,
    }
  } catch (error) {
    console.error('Error extracting user from token:', error)
    return null
  }
}