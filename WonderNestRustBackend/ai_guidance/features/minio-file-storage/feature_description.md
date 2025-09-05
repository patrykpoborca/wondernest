# MinIO File Storage Integration

## Overview
Implement a complete file upload and storage system for the Rust backend using MinIO as an S3-compatible storage provider, matching the architecture from the KTOR backend but with improved cloud-ready storage.

## User Stories
- As a parent, I want to upload profile pictures for my children so that they have personalized avatars
- As a parent, I want to upload artwork and content so that it can be used in stories
- As a system, I want to store files persistently so that they survive server restarts
- As a developer, I want S3-compatible storage so that we can easily migrate to AWS in production

## Acceptance Criteria
- [x] MinIO runs in Docker with persistent storage
- [x] Files can be uploaded through the API
- [ ] Files are validated for type and size before storage
- [ ] File metadata is saved to PostgreSQL
- [ ] Files can be downloaded via presigned URLs
- [ ] Files can be deleted when no longer needed
- [ ] System works with both MinIO and local storage fallback

## Technical Constraints
- Must be S3-compatible for easy cloud migration
- Must validate files for COPPA compliance
- Must support multiple file types (images, documents)
- Must generate unique keys to prevent collisions
- Must handle large files efficiently with streaming

## Security Considerations
- File type validation to prevent malicious uploads
- Size limits to prevent abuse
- Access control via presigned URLs
- COPPA compliance for child-related content
- Virus scanning capability (future enhancement)