# Marketplace Library System - API Endpoints

## API Base URL
```
http://localhost:8080/api/v1/marketplace
```

All endpoints require JWT authentication via `Authorization: Bearer <token>` header.

## Creator Management

### Create Creator Profile
```http
POST /creator/profile
```

**Request Body:**
```json
{
  "display_name": "Amazing Educator",
  "bio": "Creating educational content for children",
  "content_specialties": ["reading", "math", "science"],
  "languages_supported": ["en", "es"],
  "website_url": "https://amazingeducator.com",
  "social_links": {
    "twitter": "@amazingeducator",
    "instagram": "amazing_educator"
  }
}
```

**Response:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "display_name": "Amazing Educator",
  "bio": "Creating educational content for children",
  "tier": "hobbyist",
  "account_status": "pending_verification",
  "total_sales": 0,
  "total_revenue": "0.00",
  "average_rating": "0.00",
  "creator_since": "2025-01-06T15:45:00Z",
  "created_at": "2025-01-06T15:45:00Z",
  "updated_at": "2025-01-06T15:45:00Z"
}
```

### Get Creator Profile
```http
GET /creator/profile
```

**Response:** Same as create response, or 404 if no profile exists.

## Content Pack Management

### Create Content Pack
```http
POST /content-packs
```

**Request Body:**
```json
{
  "title": "Educational Story Pack",
  "description": "A collection of interactive stories for early readers",
  "price": "9.99",
  "file_ids": [
    "file-uuid-1",
    "file-uuid-2", 
    "file-uuid-3"
  ],
  "content_type": "story",
  "age_range_min": 36,
  "age_range_max": 72,
  "tags": ["reading", "interactive", "educational"],
  "preview_image_id": "file-uuid-1"
}
```

**Response:**
```json
{
  "marketplace_listing_id": "uuid",
  "manifest": {
    "id": "uuid",
    "title": "Educational Story Pack",
    "description": "A collection of interactive stories for early readers",
    "content_type": "story",
    "age_range": "36-72 months",
    "assets": [
      {
        "id": "file-uuid-1",
        "original_name": "story1.json",
        "content_type": "application/json",
        "size_bytes": 15420,
        "asset_type": "data",
        "signed_url": "http://localhost:8080/api/v1/files/file-uuid-1/signed?payload=...&signature=..."
      }
    ],
    "created_at": "2025-01-06T15:45:00Z"
  },
  "status": "draft"
}
```

## Marketplace Browsing

### Browse Marketplace
```http
GET /browse?page=1&limit=20&content_type=story&age_range_min=36&age_range_max=72
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `content_type` (optional): Filter by content type
- `age_range_min` (optional): Minimum age in months
- `age_range_max` (optional): Maximum age in months

**Response:**
```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Educational Story Pack",
      "price": "9.99",
      "rating": "4.5",
      "review_count": 23,
      "featured_image_url": "https://...",
      "creator_name": "Amazing Educator",
      "creator_tier": "professional",
      "content_type": "story",
      "age_range": "3-6"
    }
  ],
  "total_count": 1,
  "page": 1,
  "total_pages": 1
}
```

### Get Marketplace Item
```http
GET /items/{item_id}
```

**Response:**
```json
{
  "id": "uuid",
  "template_id": "uuid",
  "seller_id": "uuid", 
  "price": "9.99",
  "status": "approved",
  "marketing_title": "Educational Story Pack",
  "marketing_description": "A collection of interactive stories",
  "featured_image_url": "https://...",
  "created_at": "2025-01-06T15:45:00Z",
  "updated_at": "2025-01-06T15:45:00Z"
}
```

## Purchase Flow

### Purchase Item
```http
POST /purchase
```

**Request Body:**
```json
{
  "marketplace_item_id": "uuid",
  "target_children": ["child-uuid-1", "child-uuid-2"],
  "payment_method_id": "stripe-payment-method-id",
  "billing_address": {
    "street": "123 Main St",
    "city": "Boston",
    "state": "MA",
    "zip": "02101"
  }
}
```

**Response:**
```json
{
  "transaction_id": "txn_uuid",
  "status": "completed",
  "total_amount": "9.99",
  "library_items_created": ["lib-item-uuid-1", "lib-item-uuid-2"]
}
```

## Child Library Management

### Get Child Library
```http
GET /library/{child_id}
```

**Response:**
```json
[
  {
    "id": "uuid",
    "child_id": "uuid",
    "marketplace_item_id": "uuid",
    "purchased_by": "uuid",
    "purchase_date": "2025-01-06T15:45:00Z",
    "purchase_price": "9.99",
    "licensing_type": "family",
    "first_accessed": null,
    "last_accessed": "2025-01-06T16:30:00Z", 
    "total_play_time_minutes": 45,
    "completion_percentage": "75.00",
    "favorite": true,
    "downloaded": true,
    "offline_available": true,
    "session_count": 3,
    "created_at": "2025-01-06T15:45:00Z"
  }
]
```

### Get Library Statistics  
```http
GET /library/{child_id}/stats
```

**Response:**
```json
{
  "total_items": 5,
  "favorites_count": 2,
  "total_play_time_hours": 12.5,
  "completion_rate": 0.68,
  "recent_activities": []
}
```

## Collection Management

### Create Collection
```http
POST /collections
```

**Request Body:**
```json
{
  "child_id": "uuid",
  "name": "Favorite Stories",
  "description": "My child's favorite story content",
  "color_theme": "purple",
  "icon_name": "heart"
}
```

**Response:**
```json
{
  "id": "uuid",
  "child_id": "uuid", 
  "name": "Favorite Stories",
  "description": "My child's favorite story content",
  "color_theme": "purple",
  "icon_name": "heart",
  "display_order": 0,
  "is_system_collection": false,
  "parent_created": true,
  "created_at": "2025-01-06T15:45:00Z"
}
```

### Get Child Collections
```http
GET /collections/{child_id}
```

**Response:** Array of collection objects as shown above.

## Review System

### Create Review
```http
POST /reviews
```

**Request Body:**
```json
{
  "marketplace_item_id": "uuid",
  "rating": 5,
  "title": "Amazing content!",
  "review_text": "My child loves this story pack. Great educational value.",
  "educational_value": 5,
  "age_appropriateness": 5, 
  "engagement_level": 4,
  "technical_quality": 5,
  "child_age_when_reviewed": 48,
  "would_recommend": true
}
```

**Response:**
```json
{
  "id": "uuid",
  "marketplace_item_id": "uuid",
  "reviewer_user_id": "uuid",
  "rating": 5,
  "title": "Amazing content!",
  "review_text": "My child loves this story pack. Great educational value.",
  "educational_value": 5,
  "age_appropriateness": 5,
  "engagement_level": 4,
  "technical_quality": 5,
  "child_age_when_reviewed": 48,
  "would_recommend": true,
  "moderation_status": "approved",
  "helpful_votes": 0,
  "total_votes": 0,
  "created_at": "2025-01-06T15:45:00Z"
}
```

### Get Item Reviews
```http
GET /items/{item_id}/reviews
```

**Response:** Array of review objects as shown above.

## Error Responses

All endpoints return consistent error responses:

```json
{
  "error": "Error description",
  "status": 400
}
```

Common HTTP status codes:
- `400`: Bad Request - Invalid input data
- `401`: Unauthorized - Invalid or missing JWT token
- `403`: Forbidden - Insufficient permissions
- `404`: Not Found - Resource not found
- `500`: Internal Server Error - Server error

## Authentication

All endpoints require a valid JWT token in the Authorization header:

```http
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

The JWT token must contain:
- `sub`: User ID (UUID)
- `family_id`: Family ID (UUID) - required for child-related operations
- `exp`: Token expiration timestamp
- `aud`: "wondernest-users"

## Rate Limiting

Currently no rate limiting is implemented, but recommended limits for production:
- Browse/List endpoints: 100 requests per minute
- Purchase endpoints: 10 requests per minute  
- Create/Update endpoints: 20 requests per minute