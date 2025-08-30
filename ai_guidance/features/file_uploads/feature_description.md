# File Upload System Feature Plan

## Overview
Implement a comprehensive file upload system for WonderNest that supports multiple storage providers (local filesystem for development, S3 for production) with proper abstraction, validation, and security.

## User Stories
- As a parent, I want to upload profile pictures for my children so that their profiles are personalized
- As a parent, I want to upload custom content (images, PDFs) so that my children can access family-approved materials
- As a parent, I want to see thumbnails of uploaded content so that I can manage it easily
- As a system admin, I want file uploads to be secure and validated so that malicious content cannot be uploaded

## Acceptance Criteria
- [ ] Files can be uploaded through the mobile app
- [ ] Files can be uploaded through the website
- [ ] Uploaded files are validated for type and size
- [ ] Files are stored locally in development mode
- [ ] Files are stored in S3 in production mode
- [ ] File metadata is stored in the database
- [ ] Users can retrieve their uploaded files
- [ ] Users can delete their uploaded files
- [ ] Proper error handling for upload failures
- [ ] COPPA-compliant data handling

## Technical Architecture

### Storage Abstraction Layer
```kotlin
interface StorageProvider {
    suspend fun upload(file: FileUpload): FileMetadata
    suspend fun download(key: String): ByteArray
    suspend fun delete(key: String): Boolean
    suspend fun getUrl(key: String): String
    suspend fun exists(key: String): Boolean
}
```

### Providers
1. **LocalStorageProvider**: Stores files in local filesystem
2. **S3StorageProvider**: Stores files in AWS S3
3. **StorageProviderFactory**: Creates appropriate provider based on environment

### Database Schema
```sql
CREATE TABLE uploaded_files (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    child_id UUID REFERENCES children(id) NULL,
    file_key VARCHAR(255) UNIQUE NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    storage_provider VARCHAR(50) NOT NULL,
    file_category VARCHAR(50) NOT NULL, -- profile_picture, content, document
    metadata JSONB,
    is_public BOOLEAN DEFAULT FALSE,
    uploaded_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
```

### API Endpoints
- `POST /api/v1/files/upload` - Upload a file
- `GET /api/v1/files/{fileId}` - Get file metadata
- `GET /api/v1/files/{fileId}/download` - Download file
- `DELETE /api/v1/files/{fileId}` - Delete file
- `GET /api/v1/files/user/{userId}` - List user's files
- `POST /api/v1/files/{fileId}/share` - Share file with family

## Security Considerations
- File type validation (whitelist allowed types)
- File size limits (configurable per file type)
- Virus scanning for uploaded files
- Access control (users can only access their own files)
- Secure file names (prevent path traversal)
- Content-Type validation
- Image processing for profile pictures (resize, format conversion)

## Implementation Steps

### Phase 1: Backend Infrastructure
1. Create storage abstraction interface
2. Implement LocalStorageProvider
3. Implement S3StorageProvider
4. Create database migration for uploaded_files table
5. Implement file validation service
6. Create file upload API endpoints
7. Add authentication and authorization

### Phase 2: Mobile App Integration
1. Add file picker dependency
2. Create file upload service
3. Add upload UI components
4. Implement progress tracking
5. Add file management screen

### Phase 3: Website Integration
1. Create file upload component
2. Add drag-and-drop support
3. Implement progress indicators
4. Add file management interface

### Phase 4: Testing & Polish
1. Unit tests for storage providers
2. Integration tests for API endpoints
3. E2E tests for file upload flow
4. Performance testing with large files
5. Error handling improvements

## Configuration

### Development (application.yaml)
```yaml
storage:
  provider: local
  local:
    base-path: ./uploads
    serve-url: http://localhost:8080/files
  limits:
    max-file-size: 10485760  # 10MB
    allowed-types: 
      - image/jpeg
      - image/png
      - image/gif
      - application/pdf
```

### Production (application.yaml)
```yaml
storage:
  provider: s3
  s3:
    bucket: wondernest-uploads
    region: us-east-1
    access-key: ${AWS_ACCESS_KEY}
    secret-key: ${AWS_SECRET_KEY}
  limits:
    max-file-size: 52428800  # 50MB
    allowed-types:
      - image/jpeg
      - image/png
      - image/gif
      - application/pdf
```

## Success Metrics
- Upload success rate > 99%
- Average upload time < 5 seconds for 5MB file
- Zero security vulnerabilities
- User satisfaction with file management features