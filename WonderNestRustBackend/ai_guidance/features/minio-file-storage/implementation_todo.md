# Implementation Todo: MinIO File Storage

## Pre-Implementation
- [x] Research existing KTOR file upload implementation
- [x] Review database schema for uploaded_files table
- [x] Plan MinIO integration architecture

## Infrastructure Setup
- [x] Add MinIO to docker-compose.yml
- [x] Configure MinIO environment variables
- [x] Start MinIO container and verify accessibility
- [x] Verify MinIO console at localhost:9001

## Backend Implementation
- [x] Add AWS S3 SDK dependencies to Cargo.toml
- [x] Create storage module structure
- [x] Create StorageProvider trait
- [ ] Implement MinIOStorageProvider
- [ ] Implement LocalStorageProvider
- [ ] Create StorageProviderFactory
- [ ] Implement FileValidationService
- [ ] Implement FileUploadService

## API Implementation
- [ ] Update file upload endpoint with real multipart handling
- [ ] Implement file download with streaming
- [ ] Implement file metadata retrieval
- [ ] Implement file deletion
- [ ] Add file listing with pagination

## Database Integration
- [ ] Create UploadedFile model matching DB schema
- [ ] Add repository methods for CRUD operations
- [ ] Handle file metadata and tags
- [ ] Implement soft delete pattern

## Testing
- [ ] Test file upload with various types
- [ ] Test file size limits
- [ ] Test invalid file rejection
- [ ] Test presigned URL generation
- [ ] Test file deletion
- [ ] Test MinIO persistence across restarts