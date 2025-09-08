// Admin Portal Types for WonderNest Website
// Aligned with Rust backend admin system

export interface AdminLoginRequest {
  email: string
  password: string
}

export interface AdminLoginResponse {
  admin: AdminInfo
  access_token: string
  refresh_token: string
  expires_in: number // seconds until token expires
  token_type: string // "Bearer"
}

export interface AdminInfo {
  id: string
  email: string
  first_name?: string
  last_name?: string
  role: string
  role_level: number // 1-5 (Support → Platform → Content → Analytics → Root)
  permissions: string[]
  last_login?: string
  mfa_enabled: boolean
  account_status: string
}

export interface AdminSession {
  admin: AdminInfo
  access_token: string
  refresh_token: string
  expires_at: number // timestamp when token expires
  permissions: string[]
  is_root_admin: boolean
}

export interface MessageResponse {
  message: string
}

export interface ApiError {
  error: string
  status: number
  details?: any
}

// Admin Dashboard Data Types
export interface DashboardMetrics {
  total_families: number
  active_families: number
  total_children: number
  total_content_items: number
  pending_moderation: number
  system_health: 'healthy' | 'warning' | 'critical'
  recent_activity: ActivityItem[]
}

export interface ActivityItem {
  id: string
  type: string
  description: string
  timestamp: string
  severity: 'info' | 'warning' | 'error'
}

// Permission Constants
export const ADMIN_PERMISSIONS = {
  // Root Admin (Level 5)
  ADMIN_ACCOUNTS_VIEW: 'admin_accounts_view',
  ADMIN_ACCOUNTS_CREATE: 'admin_accounts_create',
  ADMIN_ACCOUNTS_UPDATE: 'admin_accounts_update',
  ADMIN_ACCOUNTS_DISABLE: 'admin_accounts_disable',
  SYSTEM_CONFIG_VIEW: 'system_config_view',
  SYSTEM_CONFIG_UPDATE: 'system_config_update',
  SYSTEM_MAINTENANCE: 'system_maintenance',
  
  // Platform Admin (Level 4)
  USERS_VIEW: 'users_view',
  USERS_UPDATE: 'users_update',
  USERS_DISABLE: 'users_disable',
  FAMILIES_VIEW: 'families_view',
  FAMILIES_UPDATE: 'families_update',
  
  // Content Admin (Level 3)
  CONTENT_APPROVE: 'content_approve',
  CONTENT_REJECT: 'content_reject',
  CONTENT_MODERATION_QUEUE: 'content_moderation_queue',
  CONTENT_TEMPLATES_MANAGE: 'content_templates_manage',
  
  // Analytics Admin (Level 2)
  ANALYTICS_VIEW: 'analytics_view',
  ANALYTICS_EXPORT: 'analytics_export',
  REPORTS_GENERATE: 'reports_generate',
  
  // Support Admin (Level 1)
  AUDIT_LOGS_VIEW: 'audit_logs_view',
  USER_SUPPORT: 'user_support',
} as const

export type AdminPermission = typeof ADMIN_PERMISSIONS[keyof typeof ADMIN_PERMISSIONS]