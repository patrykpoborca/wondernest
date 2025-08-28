// User roles and permissions types
export enum UserRole {
  PARENT = 'parent',
  ADMIN = 'admin',
  SUPER_ADMIN = 'super_admin',
  CONTENT_MANAGER = 'content_manager',
  CONTENT_MODERATOR = 'content_moderator',
  ANALYTICS_VIEWER = 'analytics_viewer',
  SUPPORT_AGENT = 'support_agent'
}

export enum Permission {
  // Parent permissions
  VIEW_CHILD_PROGRESS = 'view_child_progress',
  MANAGE_CHILD_SETTINGS = 'manage_child_settings',
  MANAGE_BOOKMARKS = 'manage_bookmarks',
  APPROVE_PURCHASES = 'approve_purchases',
  VIEW_CHILD_CONTENT = 'view_child_content',
  MANAGE_CONTENT_FILTERS = 'manage_content_filters',
  VIEW_ANALYTICS = 'view_analytics',
  MANAGE_FAMILY_SETTINGS = 'manage_family_settings',

  // Admin permissions
  MANAGE_USERS = 'manage_users',
  VIEW_USER_DATA = 'view_user_data',
  MODERATE_USER_CONTENT = 'moderate_user_content',
  
  // Content management
  CREATE_CONTENT = 'create_content',
  EDIT_CONTENT = 'edit_content',
  PUBLISH_CONTENT = 'publish_content',
  MODERATE_CONTENT = 'moderate_content',
  DELETE_CONTENT = 'delete_content',
  
  // Analytics & reporting
  VIEW_PLATFORM_ANALYTICS = 'view_platform_analytics',
  EXPORT_DATA = 'export_data',
  VIEW_FINANCIAL_DATA = 'view_financial_data',
  
  // System administration
  MANAGE_SYSTEM_SETTINGS = 'manage_system_settings',
  VIEW_AUDIT_LOGS = 'view_audit_logs',
  MANAGE_ADMIN_USERS = 'manage_admin_users',
  
  // Security
  MANAGE_SECURITY_SETTINGS = 'manage_security_settings',
  VIEW_SECURITY_LOGS = 'view_security_logs',
  FORCE_PASSWORD_RESET = 'force_password_reset'
}

// Authentication interfaces
export interface User {
  id: string
  email: string
  firstName: string
  lastName: string
  userType: UserRole
  permissions: Permission[]
  familyId?: string // For parents
  twoFactorEnabled: boolean
  profileImage?: string
}

export interface AuthState {
  user: User | null
  token: string | null
  refreshToken: string | null
  isAuthenticated: boolean
  isLoading: boolean
  error: string | null
}

export interface LoginCredentials {
  email: string
  password: string
  twoFactorCode?: string
}

export interface LoginResponse {
  accessToken: string
  refreshToken: string
  user: User
  permissions: Permission[]
  expiresIn: number
  requiresTwoFactor?: boolean
}

export interface ApiError {
  error: string
  message?: string
  timestamp: number
}

export interface RefreshTokenRequest {
  refreshToken: string
}

export interface SessionInfo {
  id: string
  ipAddress: string
  userAgent?: string
  lastActivity: string
  createdAt: string
  isActive: boolean
}