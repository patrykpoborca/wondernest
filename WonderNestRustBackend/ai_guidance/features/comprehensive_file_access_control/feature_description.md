# Comprehensive File Access Control System

## Overview
A robust file access control system that handles public and private file sharing with granular permissions for viewing, editing, and deleting files based on user relationships and ownership.

## Business Rules

### Multi-Account Family Architecture
WonderNest supports **multiple user accounts per family** through the `family.families` and `family.family_members` tables:
- Each family can have multiple adult user accounts (parents, guardians, caregivers)
- Each user account can belong to one family
- Family members have roles (admin, member) with different permissions
- All family members share access to private family content

### Access Levels
1. **Public Files**: Anyone can view, only owner can edit/delete
2. **Private Files**: Only family members (all accounts in same family) can view, only owner can edit/delete
3. **System Files**: Cannot be deleted, special handling

### Multi-Account Permission Matrix
| Action | Public File | Private File | Owner Required | Family Member Access |
|--------|-------------|--------------|----------------|---------------------|
| View   | Anyone      | Family only  | No             | All family accounts |
| Edit   | Owner only  | Owner only   | Yes            | No (owner only)     |
| Delete | Owner only  | Owner only   | Yes            | No (owner only)     |

### Family Account Scenarios
- **Parent A uploads private photo**: Parent B (same family) can view but not edit/delete
- **Parent B uploads public content**: Anyone can view, only Parent B can edit/delete  
- **Family child profile**: Multiple parent accounts can manage child's files
- **Cross-account visibility**: Private files are visible to all family member accounts

## User Stories

### As a user uploading files
- I want to choose if my file is public or private during upload
- I want public files to be accessible by anyone via shareable links
- I want private files to be accessible only by my family members
- I want to always retain edit/delete permissions regardless of file visibility

### As a family member (multi-account)
- I want to access private files uploaded by other family member accounts
- I want to view family files from my spouse/partner's account without being able to edit or delete them
- I want to see which family member uploaded each file
- I want clear error messages when I lack permissions
- I want to manage files for shared family children from my account

### As a public user (no account)
- I want to access public files via direct links
- I want to get clear "not found" errors for private files (no information leakage)

## Technical Requirements

### Database Schema
- `is_public` flag already exists
- `user_id` (owner) already exists  
- `detached_at` for soft deletion already exists
- **Multi-account family support** via existing tables:
  - `family.families` - family entities with admin user
  - `family.family_members` - multiple users per family with roles
  - Indexed queries for family membership verification

### API Endpoints Required
1. **GET `/api/v1/files/{id}/public`** - Public access (no auth required)
2. **GET `/api/v1/files/{id}/family`** - Family access (auth required)
3. **PUT `/api/v1/files/{id}`** - Edit metadata (owner only)
4. **DELETE `/api/v1/files/{id}`** - Delete file (owner only)
5. **PATCH `/api/v1/files/{id}/visibility`** - Change public/private (owner only)

### Security Considerations
- No information leakage: private files return 404, not 403 to public users
- JWT validation required for all authenticated endpoints
- Family membership verification for private file access
- Owner verification for all modification operations
- Rate limiting on public endpoints to prevent abuse

## Acceptance Criteria

### Public File Access
- [ ] Anyone can access public files without authentication
- [ ] Public files accessible via shareable URLs
- [ ] Private files return 404 to unauthenticated users
- [ ] No information leakage about file existence for private files

### Family File Access  
- [ ] Family members can access private files of other family members
- [ ] Non-family members cannot access private files (404 response)
- [ ] Authentication required for family endpoint
- [ ] Family membership verified via database query

### Owner Permissions
- [ ] Only file owner can edit file metadata
- [ ] Only file owner can delete files
- [ ] Only file owner can change file visibility (public ↔ private)
- [ ] Owner permissions work regardless of file visibility
- [ ] Clear 403 Forbidden responses for non-owners attempting modifications

### Error Handling
- [ ] 404 for non-existent files
- [ ] 404 for private files accessed by public users (no info leakage)
- [ ] 403 for authenticated users lacking permissions
- [ ] 401 for missing/invalid authentication where required
- [ ] Meaningful error messages that don't reveal sensitive information

### Frontend Integration
- [ ] FileManager component uses appropriate endpoint based on file visibility
- [ ] Upload component allows setting public/private flag
- [ ] Edit operations properly validate ownership
- [ ] Delete operations properly validate ownership
- [ ] Visibility toggle available for file owners

## Implementation Complexity: HIGH

### Reasons for Complexity:
1. **Multiple Access Patterns**: Public, family, and owner-only access
2. **Security Critical**: Must prevent information leakage
3. **Database Relationships**: Family membership queries
4. **State Management**: Frontend must handle different URL patterns
5. **Error Handling**: Different error responses based on user context

## Security Constraints

### COPPA Compliance
- File access logs may be required for audit
- Family relationship verification must be secure
- No data leakage about children's files to unauthorized users

### Information Leakage Prevention
- Private files must return 404 (not 403) to prevent existence confirmation
- Error messages must not reveal information about family relationships
- Failed authentication should not indicate whether file exists

## Performance Considerations
- Family membership queries should be optimized with indexes
- Public file access should be cacheable (no dynamic auth checks)
- Consider CDN integration for public files
- Rate limiting on public endpoints to prevent enumeration attacks