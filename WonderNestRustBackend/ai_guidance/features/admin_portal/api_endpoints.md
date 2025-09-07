# Admin Portal API Endpoints

## Overview
This document defines the RESTful API endpoints for the WonderNest Admin Portal. All endpoints are protected by admin authentication and role-based access control (RBAC).

## Base URL
All admin API endpoints are prefixed with `/api/admin/`

## Authentication
Admin endpoints use JWT-based authentication with role-based permissions. Each request must include:
```
Authorization: Bearer <admin_jwt_token>
```

## Admin Role Hierarchy
1. **Root Administrator** (Level 5) - Full system access
2. **Platform Administrator** (Level 4) - Platform operations
3. **Content Administrator** (Level 3) - Content oversight
4. **Analytics Administrator** (Level 2) - Data and insights
5. **Support Administrator** (Level 1) - User support

## Error Responses
All endpoints follow standard HTTP status codes with consistent error format:
```json
{
  "error": "error_code",
  "message": "Human readable error message",
  "details": "Additional context when available"
}
```

## Admin Authentication Endpoints

### POST /api/admin/auth/login
Authenticate admin user and create session.

**Required Role**: None (public endpoint)

**Request Body**:
```json
{
  "email": "admin@wondernest.com",
  "password": "secure_password",
  "mfa_token": "123456"  // Optional, required if MFA enabled
}
```

**Response (200)**:
```json
{
  "access_token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token",
  "expires_in": 3600,
  "admin": {
    "id": "admin_uuid",
    "email": "admin@wondernest.com",
    "role": "platform_administrator",
    "role_level": 4,
    "permissions": ["user_management", "platform_config"],
    "last_login": "2025-09-07T10:00:00Z",
    "mfa_enabled": true
  }
}
```

**Errors**:
- `401` - Invalid credentials or account locked
- `403` - Account disabled or requires MFA
- `429` - Too many login attempts

### POST /api/admin/auth/logout
Logout admin user and invalidate session.

**Required Role**: Any authenticated admin

**Request**: No body required

**Response (200)**:
```json
{
  "message": "Successfully logged out"
}
```

### POST /api/admin/auth/refresh
Refresh admin JWT token.

**Required Role**: Any authenticated admin (with valid refresh token)

**Request Body**:
```json
{
  "refresh_token": "jwt_refresh_token"
}
```

**Response (200)**:
```json
{
  "access_token": "new_jwt_access_token",
  "expires_in": 3600
}
```

### GET /api/admin/auth/profile
Get current admin profile information.

**Required Role**: Any authenticated admin

**Response (200)**:
```json
{
  "id": "admin_uuid",
  "email": "admin@wondernest.com",
  "role": "platform_administrator",
  "role_level": 4,
  "permissions": ["user_management", "platform_config"],
  "created_at": "2025-09-01T10:00:00Z",
  "last_login": "2025-09-07T10:00:00Z",
  "mfa_enabled": true,
  "login_count": 42,
  "account_status": "active"
}
```

### PUT /api/admin/auth/profile
Update current admin profile.

**Required Role**: Any authenticated admin

**Request Body**:
```json
{
  "email": "new_email@wondernest.com",  // Optional
  "first_name": "John",                // Optional
  "last_name": "Doe"                   // Optional
}
```

**Response (200)**:
```json
{
  "message": "Profile updated successfully",
  "admin": {
    "id": "admin_uuid",
    "email": "new_email@wondernest.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "platform_administrator"
  }
}
```

### POST /api/admin/auth/change-password
Change admin password.

**Required Role**: Any authenticated admin

**Request Body**:
```json
{
  "current_password": "old_password",
  "new_password": "new_secure_password",
  "confirm_password": "new_secure_password"
}
```

**Response (200)**:
```json
{
  "message": "Password changed successfully"
}
```

## Admin Account Management Endpoints

### GET /api/admin/accounts
List admin accounts.

**Required Role**: Root Administrator or Platform Administrator

**Query Parameters**:
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 20, max: 100)
- `role` (string): Filter by role
- `status` (string): Filter by status (active, disabled, pending)
- `search` (string): Search by email or name

**Response (200)**:
```json
{
  "admins": [
    {
      "id": "admin_uuid",
      "email": "admin@wondernest.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "platform_administrator",
      "role_level": 4,
      "status": "active",
      "created_at": "2025-09-01T10:00:00Z",
      "last_login": "2025-09-07T10:00:00Z",
      "login_count": 42,
      "created_by": "root_admin_uuid"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 15,
    "total_pages": 1
  }
}
```

### POST /api/admin/accounts
Create new admin account.

**Required Role**: Root Administrator or Platform Administrator

**Request Body**:
```json
{
  "email": "newadmin@wondernest.com",
  "first_name": "Jane",
  "last_name": "Smith",
  "role": "content_administrator",
  "send_invitation": true,  // Optional, default true
  "permissions": ["content_moderation", "creator_management"]  // Optional, defaults based on role
}
```

**Response (201)**:
```json
{
  "admin": {
    "id": "new_admin_uuid",
    "email": "newadmin@wondernest.com",
    "first_name": "Jane",
    "last_name": "Smith",
    "role": "content_administrator",
    "role_level": 3,
    "status": "pending",
    "created_at": "2025-09-07T10:00:00Z",
    "invitation_sent": true,
    "invitation_expires": "2025-09-14T10:00:00Z"
  }
}
```

### GET /api/admin/accounts/{admin_id}
Get specific admin account details.

**Required Role**: Root Administrator or Platform Administrator

**Response (200)**:
```json
{
  "id": "admin_uuid",
  "email": "admin@wondernest.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "platform_administrator",
  "role_level": 4,
  "permissions": ["user_management", "platform_config"],
  "status": "active",
  "created_at": "2025-09-01T10:00:00Z",
  "last_login": "2025-09-07T10:00:00Z",
  "login_count": 42,
  "mfa_enabled": true,
  "created_by": "root_admin_uuid",
  "ip_restrictions": ["192.168.1.0/24"],
  "recent_sessions": [
    {
      "ip_address": "192.168.1.100",
      "user_agent": "Mozilla/5.0...",
      "created_at": "2025-09-07T10:00:00Z",
      "expires_at": "2025-09-07T14:00:00Z"
    }
  ]
}
```

### PUT /api/admin/accounts/{admin_id}
Update admin account.

**Required Role**: Root Administrator or Platform Administrator

**Request Body**:
```json
{
  "first_name": "John",           // Optional
  "last_name": "Updated",         // Optional
  "role": "analytics_administrator", // Optional, requires higher role
  "status": "disabled",           // Optional: active, disabled
  "permissions": ["analytics_view", "report_generation"], // Optional
  "ip_restrictions": ["10.0.0.0/8"] // Optional
}
```

**Response (200)**:
```json
{
  "message": "Admin account updated successfully",
  "admin": {
    "id": "admin_uuid",
    "email": "admin@wondernest.com",
    "first_name": "John",
    "last_name": "Updated",
    "role": "analytics_administrator",
    "status": "active"
  }
}
```

### DELETE /api/admin/accounts/{admin_id}
Disable admin account (soft delete).

**Required Role**: Root Administrator

**Response (200)**:
```json
{
  "message": "Admin account disabled successfully"
}
```

### POST /api/admin/accounts/{admin_id}/reset-password
Reset admin password and send new credentials.

**Required Role**: Root Administrator or Platform Administrator

**Request Body**:
```json
{
  "send_email": true,  // Optional, default true
  "temporary_password": "temp123"  // Optional, auto-generated if not provided
}
```

**Response (200)**:
```json
{
  "message": "Password reset successfully",
  "temporary_password": "temp123456",  // Only if send_email is false
  "password_reset_required": true
}
```

## Admin Invitation System Endpoints

### POST /api/admin/invitations
Send admin invitation.

**Required Role**: Root Administrator or Platform Administrator

**Request Body**:
```json
{
  "email": "invite@wondernest.com",
  "role": "support_administrator",
  "first_name": "New",  // Optional
  "last_name": "Admin", // Optional
  "expires_in_days": 7, // Optional, default 7
  "message": "Welcome to the admin team!" // Optional
}
```

**Response (201)**:
```json
{
  "invitation": {
    "id": "invitation_uuid",
    "email": "invite@wondernest.com",
    "role": "support_administrator",
    "token": "secure_invitation_token",
    "expires_at": "2025-09-14T10:00:00Z",
    "created_by": "admin_uuid",
    "status": "pending"
  }
}
```

### GET /api/admin/invitations
List pending invitations.

**Required Role**: Root Administrator or Platform Administrator

**Query Parameters**:
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 20)
- `status` (string): Filter by status (pending, expired, accepted)

**Response (200)**:
```json
{
  "invitations": [
    {
      "id": "invitation_uuid",
      "email": "invite@wondernest.com",
      "role": "support_administrator",
      "expires_at": "2025-09-14T10:00:00Z",
      "created_at": "2025-09-07T10:00:00Z",
      "created_by": "admin_uuid",
      "created_by_email": "admin@wondernest.com",
      "status": "pending"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "total_pages": 1
  }
}
```

### DELETE /api/admin/invitations/{invitation_id}
Revoke pending invitation.

**Required Role**: Root Administrator or Platform Administrator

**Response (200)**:
```json
{
  "message": "Invitation revoked successfully"
}
```

### POST /api/admin/invitations/{token}/accept
Accept admin invitation (public endpoint).

**Required Role**: None (public endpoint with valid token)

**Request Body**:
```json
{
  "password": "secure_password",
  "confirm_password": "secure_password",
  "first_name": "John",  // Optional if not in invitation
  "last_name": "Doe"     // Optional if not in invitation
}
```

**Response (200)**:
```json
{
  "message": "Invitation accepted successfully",
  "admin": {
    "id": "new_admin_uuid",
    "email": "invite@wondernest.com",
    "role": "support_administrator",
    "status": "active"
  }
}
```

## Audit and Compliance Endpoints

### GET /api/admin/audit-logs
Query audit logs.

**Required Role**: Root Administrator, Platform Administrator

**Query Parameters**:
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 50, max: 200)
- `admin_id` (string): Filter by admin ID
- `action` (string): Filter by action type
- `resource` (string): Filter by resource type
- `start_date` (string): ISO date, filter from date
- `end_date` (string): ISO date, filter to date
- `ip_address` (string): Filter by IP address

**Response (200)**:
```json
{
  "audit_logs": [
    {
      "id": "log_uuid",
      "admin_id": "admin_uuid",
      "admin_email": "admin@wondernest.com",
      "action": "admin_account_created",
      "resource": "admin_account",
      "resource_id": "target_admin_uuid",
      "details": {
        "target_email": "newadmin@wondernest.com",
        "target_role": "support_administrator"
      },
      "ip_address": "192.168.1.100",
      "user_agent": "Mozilla/5.0...",
      "timestamp": "2025-09-07T10:00:00Z",
      "session_id": "session_uuid"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 1247,
    "total_pages": 25
  }
}
```

### GET /api/admin/audit-logs/export
Export audit logs as CSV.

**Required Role**: Root Administrator

**Query Parameters**:
- Same as GET /api/admin/audit-logs
- `format` (string): Export format (csv, json) - default csv

**Response (200)**:
- Content-Type: text/csv or application/json
- Content-Disposition: attachment; filename="audit_logs_2025-09-07.csv"

### GET /api/admin/compliance/coppa-report
Generate COPPA compliance report.

**Required Role**: Root Administrator, Platform Administrator, Content Administrator

**Query Parameters**:
- `start_date` (string): ISO date, report start date
- `end_date` (string): ISO date, report end date
- `format` (string): Report format (json, pdf, csv)

**Response (200)**:
```json
{
  "report": {
    "period": {
      "start_date": "2025-09-01T00:00:00Z",
      "end_date": "2025-09-07T23:59:59Z"
    },
    "metrics": {
      "total_child_accounts": 1247,
      "new_child_accounts": 89,
      "parental_consent_requests": 92,
      "parental_consent_granted": 87,
      "parental_consent_denied": 3,
      "parental_consent_pending": 2,
      "content_moderation_actions": 34,
      "privacy_incidents": 0,
      "data_deletion_requests": 2,
      "data_deletion_completed": 2
    },
    "compliance_status": "compliant",
    "issues": [],
    "generated_at": "2025-09-07T10:00:00Z",
    "generated_by": "admin_uuid"
  }
}
```

## Dashboard and Metrics Endpoints

### GET /api/admin/dashboard
Get admin dashboard metrics.

**Required Role**: Any authenticated admin (data filtered by role)

**Response (200)**:
```json
{
  "dashboard": {
    "summary": {
      "total_users": 15247,
      "total_families": 8934,
      "total_children": 12456,
      "active_sessions": 2341,
      "content_items": 45678,
      "pending_moderation": 23
    },
    "recent_activity": [
      {
        "type": "user_registered",
        "timestamp": "2025-09-07T09:45:00Z",
        "details": "New family registration"
      }
    ],
    "system_health": {
      "api_response_time": 142,
      "database_connections": 12,
      "cache_hit_rate": 0.94,
      "error_rate": 0.001
    },
    "alerts": [
      {
        "level": "warning",
        "message": "High database connection usage",
        "timestamp": "2025-09-07T09:30:00Z"
      }
    ]
  }
}
```

## Permission-Based Endpoint Access

### Root Administrator (Level 5)
- All endpoints
- Full system access

### Platform Administrator (Level 4) 
- All admin management endpoints
- All audit and compliance endpoints
- Dashboard and metrics endpoints
- Cannot modify Root Administrator accounts

### Content Administrator (Level 3)
- Dashboard endpoints (content-focused metrics)
- Compliance endpoints (content-related)
- Future content moderation endpoints

### Analytics Administrator (Level 2)
- Dashboard endpoints (analytics-focused)
- Future analytics and reporting endpoints
- Export capabilities for analytics data

### Support Administrator (Level 1)
- Limited dashboard (support metrics only)
- Future support ticket endpoints
- Limited user lookup capabilities

## Rate Limiting
All admin endpoints are rate limited:
- Authentication endpoints: 5 requests per minute per IP
- Standard endpoints: 100 requests per minute per admin
- Export endpoints: 5 requests per hour per admin
- Dashboard endpoints: 60 requests per minute per admin

## Security Headers
All responses include security headers:
```
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self'
```