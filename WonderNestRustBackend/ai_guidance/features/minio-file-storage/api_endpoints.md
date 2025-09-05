# API Endpoints: File Upload System

## Base URL
`/api/v1/files`

## Endpoints

### Upload File
**POST** `/api/v1/files/upload`

**Request:**
- Method: `multipart/form-data`
- Headers:
  - `Authorization: Bearer {token}`
- Form Data:
  - `file`: File data
  - `category`: (optional) File category [profile_picture, content, document, game_asset, artwork]
  - `childId`: (optional) Associated child ID
  - `isPublic`: (optional) Whether file is publicly accessible

**Response:**
```json
{
  "data": {
    "id": "uuid",
    "originalName": "image.jpg",
    "mimeType": "image/jpeg",
    "fileSize": 1024000,
    "category": "content",
    "url": "/api/v1/files/{id}/download",
    "uploadedAt": "2024-01-01T00:00:00Z",
    "metadata": {}
  }
}
```

### Get File Metadata
**GET** `/api/v1/files/{file_id}`

**Response:**
```json
{
  "id": "uuid",
  "originalName": "image.jpg",
  "mimeType": "image/jpeg",
  "fileSize": 1024000,
  "category": "content",
  "url": "/api/v1/files/{id}/download",
  "uploadedAt": "2024-01-01T00:00:00Z",
  "metadata": {}
}
```

### Download File
**GET** `/api/v1/files/{file_id}/download`

**Response:**
- Binary file data
- Or redirect to presigned URL

### Check File Usage
**GET** `/api/v1/files/{file_id}/usage`

**Response:**
```json
{
  "isUsed": false,
  "stories": []
}
```

### Delete File
**DELETE** `/api/v1/files/{file_id}`

**Response:**
```json
{
  "message": "File deleted successfully"
}
```

### List Files
**GET** `/api/v1/files`

**Query Parameters:**
- `category`: Filter by category
- `childId`: Filter by child
- `limit`: Max results (default: 100)
- `offset`: Pagination offset
- `isPublic`: Filter public/private

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "originalName": "image.jpg",
      "mimeType": "image/jpeg",
      "fileSize": 1024000,
      "category": "content",
      "url": "/api/v1/files/{id}/download",
      "uploadedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Status Codes
- `200 OK`: Success
- `201 Created`: File uploaded successfully
- `400 Bad Request`: Invalid request
- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: File not found
- `413 Payload Too Large`: File exceeds size limit
- `415 Unsupported Media Type`: File type not allowed
- `500 Internal Server Error`: Server error