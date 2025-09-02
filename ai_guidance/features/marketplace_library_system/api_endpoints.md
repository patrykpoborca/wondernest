# Marketplace & Library System API Endpoints

## Base URL
```
https://api.wondernest.com/api/v2
```

## Authentication
All endpoints require JWT authentication unless specified otherwise.

## 1. Marketplace Endpoints

### 1.1 Browse & Discovery

#### GET /marketplace/browse
Browse marketplace content with filters
```json
Request:
{
  "filters": {
    "content_type": ["story", "game"],
    "age_range": {"min": 36, "max": 72},
    "price_range": {"min": 0, "max": 9.99},
    "categories": ["educational", "adventure"],
    "rating_min": 4.0,
    "creator_tier": ["professional", "verified_educator"]
  },
  "sort_by": "popularity|rating|price|newest",
  "page": 1,
  "limit": 20
}

Response:
{
  "items": [{
    "id": "uuid",
    "title": "string",
    "content_type": "story",
    "creator": {
      "id": "uuid",
      "display_name": "string",
      "tier": "professional",
      "rating": 4.8
    },
    "price": 3.99,
    "rating": 4.5,
    "review_count": 127,
    "preview_url": "string",
    "tags": ["educational", "reading"],
    "age_range": {"min": 36, "max": 72}
  }],
  "pagination": {
    "total": 1250,
    "page": 1,
    "pages": 63,
    "limit": 20
  }
}
```

#### GET /marketplace/item/{id}
Get detailed marketplace listing
```json
Response:
{
  "id": "uuid",
  "title": "string",
  "description": "string",
  "content_type": "story",
  "creator": {
    "id": "uuid",
    "display_name": "string",
    "bio": "string",
    "tier": "professional",
    "verified_educator": true,
    "total_content": 45,
    "average_rating": 4.7,
    "follower_count": 1234
  },
  "pricing": {
    "price": 3.99,
    "original_price": 5.99,
    "licensing_model": "family",
    "subscription_eligible": true,
    "refund_policy": "standard_7_day"
  },
  "content_details": {
    "pages": 24,
    "read_time_minutes": 15,
    "vocabulary_words": ["ecosystem", "biodiversity"],
    "skills": ["reading comprehension", "vocabulary"],
    "educational_objectives": ["Understand ecosystems"],
    "accessibility_features": ["text_to_speech", "dyslexia_font"]
  },
  "ratings": {
    "average": 4.5,
    "count": 127,
    "breakdown": {
      "5": 65,
      "4": 42,
      "3": 15,
      "2": 3,
      "1": 2
    }
  },
  "preview": {
    "demo_available": true,
    "preview_pages": [1, 2, 5, 10],
    "preview_url": "string",
    "video_trailer": "string"
  },
  "purchase_info": {
    "purchased": false,
    "in_library": false,
    "available_for_children": []
  }
}
```

#### GET /marketplace/trending
Get trending content
```json
Request:
{
  "period": "day|week|month",
  "content_type": "all|story|game|activity",
  "age_group": "toddler|preschool|school_age",
  "limit": 10
}

Response:
{
  "trending": [{
    "id": "uuid",
    "title": "string",
    "rank": 1,
    "rank_change": 3,
    "views_period": 5432,
    "purchases_period": 234,
    "creator": {...},
    "price": 3.99
  }]
}
```

#### GET /marketplace/recommendations/{child_id}
Get personalized recommendations for a child
```json
Response:
{
  "recommendations": [{
    "content": {
      "id": "uuid",
      "title": "string",
      "type": "story",
      "price": 3.99
    },
    "reason": "Based on recent reading",
    "score": 0.95,
    "factors": {
      "age_appropriate": 1.0,
      "interest_match": 0.9,
      "skill_development": 0.85,
      "popularity": 0.7
    }
  }]
}
```

### 1.2 Search

#### GET /marketplace/search
Search marketplace content
```json
Request:
{
  "query": "dinosaurs",
  "filters": {
    "content_type": ["story"],
    "max_price": 5.99
  },
  "limit": 20
}

Response:
{
  "results": [{...}],
  "total": 45,
  "suggestions": ["dinosaur adventures", "prehistoric animals"]
}
```

### 1.3 Purchases

#### POST /marketplace/purchase
Purchase content
```json
Request:
{
  "items": [{
    "listing_id": "uuid",
    "purchase_for_children": ["child_uuid_1", "child_uuid_2"]
  }],
  "payment_method_id": "stripe_pm_xxx",
  "promo_code": "SAVE20"
}

Response:
{
  "transaction_id": "uuid",
  "total_amount": 7.98,
  "discount_applied": 2.00,
  "items_purchased": [{
    "listing_id": "uuid",
    "title": "string",
    "price_paid": 3.99,
    "added_to_libraries": ["child_uuid_1", "child_uuid_2"]
  }],
  "receipt_url": "string"
}
```

#### GET /marketplace/purchases
Get purchase history
```json
Response:
{
  "purchases": [{
    "id": "uuid",
    "purchased_at": "2024-01-15T10:30:00Z",
    "items": [{
      "title": "string",
      "price_paid": 3.99,
      "content_type": "story"
    }],
    "total_amount": 3.99,
    "transaction_id": "stripe_xxx"
  }]
}
```

### 1.4 Reviews

#### POST /marketplace/reviews
Submit a review
```json
Request:
{
  "listing_id": "uuid",
  "rating": 5,
  "title": "Excellent story!",
  "review_text": "My kids love this...",
  "child_age_months": 48
}

Response:
{
  "review_id": "uuid",
  "status": "published"
}
```

#### GET /marketplace/reviews/{listing_id}
Get reviews for a listing
```json
Response:
{
  "reviews": [{
    "id": "uuid",
    "rating": 5,
    "title": "string",
    "review_text": "string",
    "reviewer_name": "Parent123",
    "verified_purchase": true,
    "child_age_months": 48,
    "helpful_votes": 23,
    "created_at": "2024-01-10T..."
  }],
  "summary": {
    "average_rating": 4.5,
    "total_reviews": 127,
    "verified_purchases": 120
  }
}
```

## 2. Library Endpoints

### 2.1 Library Management

#### GET /library/{child_id}
Get child's library
```json
Response:
{
  "library": {
    "total_items": 145,
    "categories": {
      "stories": 78,
      "games": 45,
      "activities": 22
    },
    "items": [{
      "id": "uuid",
      "content_id": "uuid",
      "content_type": "story",
      "title": "string",
      "thumbnail_url": "string",
      "acquisition_type": "purchased",
      "acquired_at": "2024-01-10T...",
      "progress": {
        "completion_percentage": 75,
        "last_accessed": "2024-01-15T...",
        "times_completed": 2
      },
      "is_favorite": true,
      "is_downloaded": true,
      "collections": ["uuid1", "uuid2"]
    }]
  }
}
```

#### POST /library/{child_id}/add
Add content to child's library
```json
Request:
{
  "content_id": "uuid",
  "content_type": "story",
  "acquisition_type": "purchased|gifted|free",
  "purchase_id": "uuid"
}

Response:
{
  "library_item_id": "uuid",
  "status": "added"
}
```

#### PUT /library/{child_id}/item/{item_id}
Update library item
```json
Request:
{
  "is_favorite": true,
  "collections": ["uuid1", "uuid2"],
  "parent_notes": "Great for bedtime"
}

Response:
{
  "updated": true
}
```

#### POST /library/{child_id}/item/{item_id}/progress
Update progress
```json
Request:
{
  "completion_percentage": 50,
  "last_position": {
    "page": 12,
    "paragraph": 3
  },
  "time_spent_minutes": 15
}

Response:
{
  "total_time_minutes": 45,
  "completion_percentage": 50
}
```

### 2.2 Collections

#### GET /library/collections/{family_id}
Get family collections
```json
Response:
{
  "collections": [{
    "id": "uuid",
    "name": "Bedtime Stories",
    "description": "Calming stories for bedtime",
    "icon": "moon",
    "color": "#6B46C1",
    "item_count": 23,
    "collection_type": "custom",
    "shared_with_children": ["child_uuid_1"],
    "created_by": "parent_uuid",
    "created_at": "2024-01-01T..."
  }]
}
```

#### POST /library/collections
Create collection
```json
Request:
{
  "family_id": "uuid",
  "name": "Science Adventures",
  "description": "STEM learning content",
  "icon": "microscope",
  "color": "#10B981",
  "collection_type": "custom",
  "shared_with_children": ["child_uuid_1", "child_uuid_2"]
}

Response:
{
  "collection_id": "uuid",
  "status": "created"
}
```

#### POST /library/collections/{id}/items
Add items to collection
```json
Request:
{
  "items": [{
    "content_id": "uuid",
    "content_type": "story"
  }]
}

Response:
{
  "added_count": 3,
  "total_items": 26
}
```

### 2.3 Downloads

#### POST /library/download
Download content for offline
```json
Request:
{
  "child_id": "uuid",
  "content_id": "uuid",
  "quality": "high|medium|low"
}

Response:
{
  "download_url": "string",
  "expires_at": "2024-01-16T...",
  "file_size_mb": 45.2
}
```

#### GET /library/downloads/{child_id}
Get downloaded content
```json
Response:
{
  "downloads": [{
    "content_id": "uuid",
    "title": "string",
    "download_date": "2024-01-10T...",
    "file_size_mb": 45.2,
    "expires_at": "2024-02-10T..."
  }],
  "total_size_mb": 234.5,
  "storage_limit_mb": 1000
}
```

## 3. Creator Endpoints

### 3.1 Creator Profile

#### GET /creators/{id}
Get creator profile
```json
Response:
{
  "creator": {
    "id": "uuid",
    "display_name": "string",
    "bio": "string",
    "avatar_url": "string",
    "tier": "professional",
    "verified_educator": true,
    "specialties": ["early_reading", "stem"],
    "stats": {
      "total_content": 45,
      "total_sales": 1234,
      "average_rating": 4.7,
      "follower_count": 567
    },
    "content": [{
      "id": "uuid",
      "title": "string",
      "type": "story",
      "price": 3.99,
      "rating": 4.5
    }]
  }
}
```

#### POST /creators/follow
Follow a creator
```json
Request:
{
  "creator_id": "uuid",
  "notifications": {
    "new_content": true,
    "sales": false,
    "updates": true
  }
}

Response:
{
  "following": true,
  "total_following": 23
}
```

### 3.2 Creator Dashboard

#### GET /creator/dashboard
Get creator dashboard data
```json
Response:
{
  "overview": {
    "tier": "professional",
    "revenue_share": 75,
    "total_revenue": 12345.67,
    "pending_payout": 456.78,
    "next_payout_date": "2024-02-01"
  },
  "metrics": {
    "period": "last_30_days",
    "sales": 234,
    "revenue": 1234.56,
    "views": 5678,
    "conversion_rate": 4.1,
    "average_rating": 4.7,
    "new_reviews": 45
  },
  "content": [{
    "id": "uuid",
    "title": "string",
    "status": "published",
    "sales_count": 123,
    "revenue": 456.78,
    "rating": 4.5
  }],
  "recent_activity": [{
    "type": "sale|review|follower",
    "description": "string",
    "timestamp": "2024-01-15T..."
  }]
}
```

#### POST /creator/content
Submit new content
```json
Request:
{
  "title": "string",
  "description": "string",
  "content_type": "story",
  "content_data": {...},
  "pricing": {
    "price": 3.99,
    "licensing_model": "family"
  },
  "metadata": {
    "age_range": {"min": 36, "max": 72},
    "skills": ["reading", "vocabulary"],
    "tags": ["adventure", "science"]
  }
}

Response:
{
  "content_id": "uuid",
  "status": "pending_review",
  "estimated_review_time": "24_hours"
}
```

#### GET /creator/analytics/{content_id}
Get detailed analytics for content
```json
Response:
{
  "content_id": "uuid",
  "period": "last_30_days",
  "metrics": {
    "views": 1234,
    "purchases": 56,
    "revenue": 223.44,
    "refunds": 2,
    "completion_rate": 78.5,
    "average_session_minutes": 12.3,
    "repeat_rate": 34.2
  },
  "demographics": {
    "age_distribution": {
      "3-4": 25,
      "5-6": 45,
      "7-8": 30
    },
    "geographic": {
      "US": 78,
      "CA": 12,
      "UK": 10
    }
  },
  "trends": [{
    "date": "2024-01-15",
    "views": 45,
    "purchases": 3,
    "revenue": 11.97
  }]
}
```

## 4. Subscription Endpoints

### 4.1 Subscription Management

#### GET /subscriptions/tiers
Get available subscription tiers
```json
Response:
{
  "tiers": [{
    "id": "uuid",
    "name": "WonderNest Premium",
    "monthly_price": 9.99,
    "annual_price": 99.99,
    "features": {
      "offline_downloads": 20,
      "family_profiles": 4,
      "exclusive_content": true,
      "early_access": true
    },
    "trial_days": 14
  }]
}
```

#### POST /subscriptions/subscribe
Subscribe to a tier
```json
Request:
{
  "tier_id": "uuid",
  "billing_cycle": "monthly|annual",
  "payment_method_id": "stripe_pm_xxx"
}

Response:
{
  "subscription_id": "uuid",
  "status": "active",
  "trial_end": "2024-01-29T...",
  "next_billing_date": "2024-02-15T..."
}
```

#### GET /subscriptions/current
Get current subscription
```json
Response:
{
  "subscription": {
    "id": "uuid",
    "tier": {
      "name": "WonderNest Premium",
      "features": {...}
    },
    "status": "active",
    "billing_cycle": "monthly",
    "current_period_end": "2024-02-15T...",
    "credits_remaining": 5.00,
    "usage": {
      "content_accessed": 45,
      "downloads_used": 12,
      "downloads_limit": 20
    }
  }
}
```

#### PUT /subscriptions/cancel
Cancel subscription
```json
Request:
{
  "cancel_at_period_end": true,
  "reason": "too_expensive",
  "feedback": "Optional feedback text"
}

Response:
{
  "status": "cancelled",
  "active_until": "2024-02-15T..."
}
```

## 5. Bundle Endpoints

### 5.1 Bundle Management

#### GET /bundles
Get available bundles
```json
Response:
{
  "bundles": [{
    "id": "uuid",
    "title": "Reading Adventure Series",
    "description": "5 interconnected stories",
    "creator": {...},
    "items_count": 5,
    "bundle_price": 14.99,
    "individual_price": 24.95,
    "savings": 9.96,
    "bundle_type": "series"
  }]
}
```

#### POST /bundles/purchase
Purchase a bundle
```json
Request:
{
  "bundle_id": "uuid",
  "purchase_for_children": ["child_uuid_1"],
  "payment_method_id": "stripe_pm_xxx"
}

Response:
{
  "transaction_id": "uuid",
  "bundle_price_paid": 14.99,
  "items_added": 5,
  "savings": 9.96
}
```

## Error Responses

All endpoints follow standard error format:
```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Human-readable error message",
    "field": "specific_field_if_applicable",
    "details": {}
  }
}
```

Common error codes:
- `UNAUTHORIZED`: Invalid or missing authentication
- `FORBIDDEN`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `INVALID_REQUEST`: Invalid request parameters
- `PAYMENT_FAILED`: Payment processing error
- `CONTENT_UNAVAILABLE`: Content not available for purchase
- `SUBSCRIPTION_REQUIRED`: Feature requires subscription
- `RATE_LIMITED`: Too many requests