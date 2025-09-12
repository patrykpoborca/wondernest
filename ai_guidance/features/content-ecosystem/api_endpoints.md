# Content Ecosystem API Endpoints

## Content Discovery & Catalog

### GET /api/v2/content/catalog
Browse available content with filtering and pagination.

**Query Parameters:**
- `child_id` (UUID, required) - Child context for age-appropriate filtering
- `type` (string) - Filter by content type (sticker_pack, character_pack, story, applet)
- `category` (string) - Filter by category
- `age_min` (int) - Minimum age range
- `age_max` (int) - Maximum age range
- `search` (string) - Search query
- `sort` (string) - Sort by: popular, newest, rating, alphabetical
- `page` (int) - Page number (default: 1)
- `limit` (int) - Items per page (default: 20, max: 100)

**Response:**
```json
{
  "content": [
    {
      "id": "uuid",
      "type": "sticker_pack",
      "title": "Animal Friends Sticker Pack",
      "description": "Cute animal stickers for your stories",
      "thumbnail_url": "https://cdn.wondernest.app/...",
      "age_range": {"min": 3, "max": 8},
      "rating": 4.8,
      "price": 299,
      "currency": "USD",
      "is_free": false,
      "is_owned": false,
      "download_size": 15728640,
      "metadata": {
        "sticker_count": 48,
        "themes": ["animals", "nature"],
        "educational_goals": ["creativity", "vocabulary"]
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 145,
    "has_more": true
  }
}
```

### GET /api/v2/content/featured
Get featured and recommended content for a child.

**Query Parameters:**
- `child_id` (UUID, required) - Child to get recommendations for

**Response:**
```json
{
  "featured": {
    "title": "Weekly Picks",
    "content": [...]
  },
  "recommended": {
    "title": "Based on your interests",
    "content": [...]
  },
  "new_releases": {
    "title": "New This Week",
    "content": [...]
  },
  "trending": {
    "title": "Popular with Kids",
    "content": [...]
  }
}
```

## Content Library & Ownership

### GET /api/v2/content/library/{child_id}
Get all content owned by a specific child.

**Response:**
```json
{
  "owned_content": [
    {
      "content_id": "uuid",
      "acquired_at": "2024-01-15T10:30:00Z",
      "last_used": "2024-01-20T15:45:00Z",
      "usage_count": 45,
      "is_favorite": true,
      "download_status": "downloaded",
      "local_path": "/content/stickers/animals",
      "content": {
        // Full content details
      }
    }
  ],
  "statistics": {
    "total_items": 23,
    "total_size": 157286400,
    "favorites": 5,
    "recently_used": 8
  }
}
```

### POST /api/v2/content/library/{child_id}/add
Add content to a child's library (purchase or grant).

**Request Body:**
```json
{
  "content_id": "uuid",
  "acquisition_type": "purchase|grant|subscription",
  "payment_method": "parent_wallet|subscription|free"
}
```

**Response:**
```json
{
  "success": true,
  "library_item": {
    "content_id": "uuid",
    "acquired_at": "2024-01-20T10:30:00Z",
    "download_url": "https://cdn.wondernest.app/..."
  }
}
```

## Content Download & Sync

### GET /api/v2/content/download/{content_id}
Get download URL and metadata for content.

**Headers:**
- `Authorization: Bearer {token}`
- `X-Child-Id: {child_id}`

**Response:**
```json
{
  "download_url": "https://cdn.wondernest.app/signed/...",
  "expires_at": "2024-01-20T12:00:00Z",
  "content_hash": "sha256:...",
  "chunks": [
    {
      "id": 1,
      "url": "https://cdn.wondernest.app/chunks/1",
      "size": 1048576,
      "hash": "sha256:..."
    }
  ],
  "metadata": {
    "version": "1.2.0",
    "dependencies": ["base_pack_v1"],
    "install_size": 15728640
  }
}
```

### POST /api/v2/content/sync
Synchronize content library with server.

**Request Body:**
```json
{
  "child_id": "uuid",
  "device_id": "device_uuid",
  "local_content": [
    {
      "content_id": "uuid",
      "version": "1.1.0",
      "last_modified": "2024-01-15T10:00:00Z"
    }
  ],
  "storage_available": 536870912
}
```

**Response:**
```json
{
  "to_download": [
    {
      "content_id": "uuid",
      "version": "1.2.0",
      "priority": "high",
      "reason": "update_available"
    }
  ],
  "to_delete": [
    {
      "content_id": "uuid",
      "reason": "content_expired"
    }
  ],
  "sync_token": "sync_token_v2"
}
```

## Content Recommendations

### GET /api/v2/content/recommendations
Get AI-powered content recommendations.

**Query Parameters:**
- `child_id` (UUID, required) - Child to get recommendations for
- `count` (int) - Number of recommendations (default: 10)
- `exclude_owned` (bool) - Exclude already owned content

**Response:**
```json
{
  "recommendations": [
    {
      "content": {
        // Full content details
      },
      "reason": "based_on_interest",
      "confidence": 0.92,
      "explanation": "Because you love animal stories"
    }
  ],
  "interests_detected": ["animals", "adventure", "creativity"]
}
```

### POST /api/v2/content/feedback
Submit feedback on content for improving recommendations.

**Request Body:**
```json
{
  "child_id": "uuid",
  "content_id": "uuid",
  "feedback_type": "like|dislike|rating|usage",
  "value": 5,
  "metadata": {
    "session_duration": 300,
    "completion_rate": 0.8
  }
}
```

## Parental Controls

### GET /api/v2/content/parental/settings/{family_id}
Get parental control settings for content.

**Response:**
```json
{
  "approval_mode": "automatic|manual|restricted",
  "age_restrictions": {
    "enforce_age_ratings": true,
    "max_age_rating": 8
  },
  "content_filters": {
    "blocked_types": [],
    "blocked_categories": ["scary"],
    "blocked_creators": []
  },
  "spending_limits": {
    "monthly_limit": 2000,
    "per_item_limit": 500,
    "require_approval_above": 299
  }
}
```

### POST /api/v2/content/parental/approve
Approve or reject content for a child.

**Request Body:**
```json
{
  "approval_id": "uuid",
  "child_id": "uuid",
  "content_id": "uuid",
  "decision": "approve|reject",
  "reason": "string",
  "restrictions": {
    "time_limit": 30,
    "expire_after": "2024-02-01"
  }
}
```

### GET /api/v2/content/parental/pending/{family_id}
Get pending content approvals.

**Response:**
```json
{
  "pending_approvals": [
    {
      "id": "uuid",
      "child": {
        "id": "uuid",
        "name": "Alice"
      },
      "content": {
        // Content details
      },
      "requested_at": "2024-01-20T10:00:00Z",
      "auto_approve_at": "2024-01-21T10:00:00Z"
    }
  ]
}
```

## Content Management (Admin)

### POST /api/admin/content-seeding/content/process
Process uploaded content for distribution.

**Request Body:**
```json
{
  "content_id": "uuid",
  "processing_options": {
    "generate_thumbnails": true,
    "optimize_assets": true,
    "extract_metadata": true,
    "scan_content": true
  }
}
```

### PUT /api/admin/content-seeding/content/{id}/metadata
Update content metadata and categorization.

**Request Body:**
```json
{
  "type": "sticker_pack",
  "metadata": {
    "age_range": {"min": 3, "max": 8},
    "educational_goals": ["creativity", "fine_motor"],
    "themes": ["animals", "nature"],
    "complexity": "beginner",
    "sticker_count": 48,
    "requires_supervision": false
  },
  "categorization": {
    "primary_category": "creative",
    "secondary_categories": ["educational", "fun"],
    "tags": ["animals", "stickers", "art"]
  },
  "distribution": {
    "availability": "marketplace",
    "pricing_tier": "premium",
    "release_date": "2024-02-01"
  }
}
```

### POST /api/admin/content-seeding/content/validate
Validate content for COPPA compliance and safety.

**Request Body:**
```json
{
  "content_id": "uuid",
  "validation_type": "full|quick|coppa_only"
}
```

**Response:**
```json
{
  "valid": true,
  "issues": [],
  "coppa_compliant": true,
  "safety_score": 0.98,
  "recommendations": [
    "Consider adding educational tags"
  ]
}
```

## Creator APIs

### GET /api/v2/creator/dashboard
Get creator dashboard data.

**Response:**
```json
{
  "creator": {
    "id": "uuid",
    "tier": "verified",
    "rating": 4.7
  },
  "content_stats": {
    "total_published": 15,
    "total_downloads": 4523,
    "active_users": 892
  },
  "revenue": {
    "current_month": 45000,
    "last_month": 38500,
    "pending_payout": 12000
  },
  "recent_activity": [...]
}
```

### POST /api/v2/creator/content/submit
Submit new content for review.

**Request Body:**
```json
{
  "title": "Ocean Adventure Stickers",
  "type": "sticker_pack",
  "files": ["file_id_1", "file_id_2"],
  "metadata": {
    // Content metadata
  },
  "pricing": {
    "model": "one_time|subscription",
    "price": 299
  }
}
```

### GET /api/v2/creator/analytics/{content_id}
Get detailed analytics for specific content.

**Response:**
```json
{
  "performance": {
    "downloads": 1234,
    "active_users": 456,
    "completion_rate": 0.78,
    "average_session": 420
  },
  "demographics": {
    "age_distribution": {
      "3-5": 0.3,
      "6-8": 0.5,
      "9-12": 0.2
    }
  },
  "feedback": {
    "rating": 4.6,
    "reviews": 89,
    "sentiment": "positive"
  }
}
```