# Remaining TODOs: MinIO File Storage

## ✅ Completed
- Multipart file upload handling
- File size validation (10MB limit)
- MIME type validation  
- Database persistence for file metadata
- Unique key generation (UUID)
- Basic file listing with filters
- Fixed website API endpoint URLs to use `/api/v1/files/`
- Implemented public download endpoint for images
- Separated public and protected routes

## 🚧 In Progress
- Testing file upload/download functionality

## 📝 Not Started
- Implement MinIOStorageProvider using AWS S3 SDK
- Implement LocalStorageProvider for fallback storage
- Create StorageProviderFactory to select provider based on config
- Enhanced FileValidationService with:
  - Magic byte verification
  - COPPA compliance checks
  - Virus scanning integration
- Actual MinIO storage integration
- Presigned URL generation for downloads
- Soft delete implementation
- File usage tracking
- Add integration tests

## ⚠️ Important Notes
- MinIO is running and accessible
- Database table `core.uploaded_files` already exists
- JWT authentication middleware is already in place
- File upload routes exist but are stubbed

## 🔧 Configuration Required
- Create initial bucket in MinIO (wondernest-dev)
- Set up proper CORS rules for MinIO
- Configure file size limits
- Set up allowed MIME types list