# Creator Platform API Endpoints

## Authentication & Authorization

### POST /api/v1/creators/auth/register
Register new creator account
```json
Request:
{
  "email": "creator@example.com",
  "password": "SecurePassword123!",
  "first_name": "Jane",
  "last_name": "Doe",
  "country": "US",
  "accept_terms": true
}

Response: 201 Created
{
  "creator_id": "uuid",
  "email": "creator@example.com",
  "verification_required": true,
  "next_steps": ["verify_email", "complete_application"]
}
```

### POST /api/v1/creators/auth/login
Creator login with 2FA support
```json
Request:
{
  "email": "creator@example.com",
  "password": "SecurePassword123!",
  "otp_code": "123456"  // Optional, required if 2FA enabled
}

Response: 200 OK
{
  "access_token": "jwt_token",
  "refresh_token": "refresh_token",
  "creator_id": "uuid",
  "tier": "verified_educator",
  "requires_2fa": false
}
```

### POST /api/v1/creators/auth/refresh
Refresh access token
```json
Request:
{
  "refresh_token": "refresh_token"
}

Response: 200 OK
{
  "access_token": "new_jwt_token",
  "refresh_token": "new_refresh_token"
}
```

### POST /api/v1/creators/auth/logout
Logout creator session
```json
Request:
{
  "refresh_token": "refresh_token"
}

Response: 204 No Content
```

### POST /api/v1/creators/auth/2fa/enable
Enable two-factor authentication
```json
Request:
{
  "password": "current_password"
}

Response: 200 OK
{
  "secret": "JBSWY3DPEHPK3PXP",
  "qr_code": "data:image/png;base64,...",
  "backup_codes": ["code1", "code2", "..."]
}
```

## Creator Onboarding

### POST /api/v1/creators/apply
Submit creator application
```json
Request:
{
  "creator_type": "educator",
  "display_name": "Ms. Jane's Learning Corner",
  "bio": "20 years teaching experience...",
  "content_specialties": ["early_reading", "mathematics", "science"],
  "languages_supported": ["en", "es"],
  "website_url": "https://example.com",
  "social_links": {
    "linkedin": "https://linkedin.com/in/jane",
    "twitter": "@janelearning"
  },
  "educator_credentials": {
    "degree": "Masters in Education",
    "institution": "State University",
    "teaching_certificate": "K-8 Mathematics",
    "years_experience": 20
  },
  "sample_work_urls": [
    "https://example.com/sample1",
    "https://example.com/sample2"
  ],
  "target_age_groups": ["3-5", "6-8"],
  "content_types_interested": ["stories", "educational_activities"]
}

Response: 201 Created
{
  "application_id": "uuid",
  "status": "pending_review",
  "estimated_review_time": "48 hours",
  "next_steps": ["identity_verification", "credential_verification"]
}
```

### POST /api/v1/creators/verify/identity
Submit identity verification
```json
Request:
{
  "verification_method": "document",
  "document_type": "drivers_license",
  "document_front": "base64_encoded_image",
  "document_back": "base64_encoded_image",
  "selfie": "base64_encoded_image"
}

Response: 200 OK
{
  "verification_id": "uuid",
  "status": "processing",
  "estimated_completion": "2024-01-15T10:00:00Z"
}
```

### POST /api/v1/creators/verify/credentials
Submit educator credentials for verification
```json
Request:
{
  "credential_type": "teaching_license",
  "document": "base64_encoded_pdf",
  "issuing_authority": "State Board of Education",
  "license_number": "TCH123456",
  "expiry_date": "2025-12-31"
}

Response: 200 OK
{
  "verification_id": "uuid",
  "status": "pending_verification",
  "manual_review_required": true
}
```

### POST /api/v1/creators/tax-documents
Upload tax documentation
```json
Request:
{
  "document_type": "W9",  // or W8-BEN for international
  "tax_id": "encrypted_tax_id",
  "document": "base64_encoded_pdf",
  "signature": "base64_encoded_signature",
  "signed_date": "2024-01-15"
}

Response: 200 OK
{
  "document_id": "uuid",
  "status": "received",
  "valid_until": "2025-01-15"
}
```

### GET /api/v1/creators/onboarding/status
Check onboarding progress
```json
Response: 200 OK
{
  "overall_status": "in_progress",
  "completion_percentage": 75,
  "steps": [
    {
      "step": "account_creation",
      "status": "completed",
      "completed_at": "2024-01-14T09:00:00Z"
    },
    {
      "step": "application_submission",
      "status": "completed",
      "completed_at": "2024-01-14T09:30:00Z"
    },
    {
      "step": "identity_verification",
      "status": "completed",
      "completed_at": "2024-01-14T10:00:00Z"
    },
    {
      "step": "credential_verification",
      "status": "in_progress",
      "started_at": "2024-01-14T10:30:00Z"
    },
    {
      "step": "tax_documentation",
      "status": "pending"
    },
    {
      "step": "banking_setup",
      "status": "pending"
    }
  ],
  "blocked_reasons": [],
  "next_action_required": "Wait for credential verification"
}
```

## Creator Profile Management

### GET /api/v1/creators/profile
Get creator profile
```json
Response: 200 OK
{
  "creator_id": "uuid",
  "display_name": "Ms. Jane's Learning Corner",
  "bio": "20 years teaching experience...",
  "avatar_url": "https://cdn.wondernest.com/creators/avatar.jpg",
  "cover_image_url": "https://cdn.wondernest.com/creators/cover.jpg",
  "tier": "verified_educator",
  "tier_benefits": {
    "revenue_share": 60,
    "max_listings": 25,
    "payout_frequency": "bi-weekly",
    "support_level": "priority"
  },
  "verified_educator": true,
  "content_specialties": ["early_reading", "mathematics"],
  "languages_supported": ["en", "es"],
  "stats": {
    "total_content": 45,
    "approved_content": 42,
    "total_sales": 1250,
    "average_rating": 4.7,
    "total_reviews": 234,
    "follower_count": 892
  },
  "creator_since": "2024-01-01",
  "featured_creator": false
}
```

### PUT /api/v1/creators/profile
Update creator profile
```json
Request:
{
  "display_name": "Updated Learning Corner",
  "bio": "Updated bio...",
  "content_specialties": ["early_reading", "mathematics", "science"],
  "languages_supported": ["en", "es", "fr"],
  "social_links": {
    "linkedin": "https://linkedin.com/in/jane",
    "website": "https://janelearning.com"
  }
}

Response: 200 OK
{
  "message": "Profile updated successfully",
  "profile": { /* updated profile object */ }
}
```

### POST /api/v1/creators/profile/avatar
Upload avatar image
```json
Request: multipart/form-data
{
  "avatar": File (max 5MB, jpg/png)
}

Response: 200 OK
{
  "avatar_url": "https://cdn.wondernest.com/creators/new-avatar.jpg"
}
```

## Content Management

### GET /api/v1/creators/templates
Get available content templates
```json
Response: 200 OK
{
  "templates": [
    {
      "id": "uuid",
      "name": "Interactive Story Template",
      "category": "story",
      "description": "Create engaging stories with choices",
      "age_range": "3-8",
      "difficulty_level": "beginner",
      "estimated_creation_time": 60,
      "usage_count": 234,
      "average_rating": 4.5,
      "preview_url": "https://wondernest.com/templates/preview/uuid"
    }
  ],
  "featured_templates": [],
  "categories": [
    {
      "category": "story",
      "display_name": "Stories",
      "template_count": 15
    }
  ]
}
```

### POST /api/v1/creators/content
Create new content submission
```json
Request:
{
  "title": "The Adventures of Luna the Learning Cat",
  "description": "An interactive story about curiosity and learning",
  "content_type": "interactive_story",
  "template_id": "uuid",
  "age_range_min": 4,
  "age_range_max": 7,
  "difficulty_level": "beginner",
  "educational_goals": [
    "Develop reading comprehension",
    "Learn about animals",
    "Practice decision making"
  ],
  "vocabulary_words": ["curiosity", "adventure", "discovery"],
  "estimated_duration_minutes": 15,
  "content_data": {
    "pages": [
      {
        "text": "Luna was a curious cat...",
        "image_url": "https://cdn.wondernest.com/temp/image1.jpg",
        "choices": []
      }
    ]
  }
}

Response: 201 Created
{
  "submission_id": "uuid",
  "status": "draft",
  "created_at": "2024-01-15T10:00:00Z",
  "auto_save_enabled": true,
  "validation_status": {
    "is_valid": false,
    "missing_fields": ["marketing_description", "preview_image"]
  }
}
```

### PUT /api/v1/creators/content/{submission_id}
Update content submission
```json
Request:
{
  "title": "Updated Title",
  "content_data": { /* updated content */ },
  "marketing_description": "Perfect for early readers...",
  "proposed_price": 4.99,
  "search_keywords": ["reading", "animals", "interactive"]
}

Response: 200 OK
{
  "submission_id": "uuid",
  "status": "draft",
  "last_saved": "2024-01-15T10:30:00Z",
  "validation_status": {
    "is_valid": true,
    "ready_for_submission": true
  }
}
```

### POST /api/v1/creators/content/{submission_id}/submit
Submit content for review
```json
Request:
{
  "final_check_completed": true,
  "creator_notes": "Ready for review. Updated based on previous feedback.",
  "licensing_model": "per_child",
  "proposed_price": 4.99
}

Response: 200 OK
{
  "submission_id": "uuid",
  "status": "pending_review",
  "estimated_review_time": "24-48 hours",
  "moderation_queue_position": 42,
  "automatic_checks": {
    "safety_scan": "passed",
    "plagiarism_check": "passed",
    "quality_score": 85,
    "flags": []
  }
}
```

### GET /api/v1/creators/content/{submission_id}/preview
Get content preview
```json
Request:
?mode=child_view  // or parent_view, full_content

Response: 200 OK
{
  "submission_id": "uuid",
  "preview_url": "https://preview.wondernest.com/content/uuid",
  "preview_expires": "2024-01-15T12:00:00Z",
  "preview_data": { /* content structured for preview */ }
}
```

### DELETE /api/v1/creators/content/{submission_id}
Delete draft content
```json
Response: 204 No Content
```

### GET /api/v1/creators/content
List creator's content
```json
Request:
?status=draft,pending_review,approved,rejected
&page=1
&limit=20
&sort=created_at:desc

Response: 200 OK
{
  "content": [
    {
      "id": "uuid",
      "title": "The Adventures of Luna",
      "content_type": "interactive_story",
      "status": "approved",
      "created_at": "2024-01-10T09:00:00Z",
      "last_updated": "2024-01-14T15:00:00Z",
      "marketplace_status": "published",
      "stats": {
        "views": 1234,
        "purchases": 89,
        "rating": 4.7,
        "revenue": 445.11
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "has_more": true
  },
  "summary": {
    "total_drafts": 3,
    "pending_review": 2,
    "approved": 40,
    "rejected": 0
  }
}
```

### POST /api/v1/creators/assets/upload
Upload content assets
```json
Request: multipart/form-data
{
  "file": File (max 100MB),
  "asset_type": "image",  // image, audio, video
  "submission_id": "uuid",
  "description": "Main character illustration"
}

Response: 200 OK
{
  "asset_id": "uuid",
  "url": "https://cdn.wondernest.com/assets/uuid.jpg",
  "thumbnail_url": "https://cdn.wondernest.com/assets/uuid_thumb.jpg",
  "file_size": 2048576,
  "mime_type": "image/jpeg",
  "dimensions": {
    "width": 1920,
    "height": 1080
  }
}
```

## Analytics & Reporting

### GET /api/v1/creators/dashboard
Get creator dashboard data
```json
Response: 200 OK
{
  "overview": {
    "total_revenue": 12345.67,
    "monthly_revenue": 2345.67,
    "total_sales": 892,
    "monthly_sales": 156,
    "average_rating": 4.7,
    "content_count": 45,
    "follower_count": 892
  },
  "recent_sales": [
    {
      "date": "2024-01-15T09:30:00Z",
      "content_title": "Luna's Adventure",
      "buyer_region": "US-CA",
      "amount": 4.99,
      "creator_earnings": 2.99
    }
  ],
  "trending_content": [
    {
      "content_id": "uuid",
      "title": "Top Performer",
      "trend": "up",
      "change_percentage": 23.5
    }
  ],
  "notifications": [
    {
      "type": "content_approved",
      "message": "Your content 'New Story' has been approved",
      "timestamp": "2024-01-15T08:00:00Z"
    }
  ]
}
```

### GET /api/v1/creators/analytics
Get detailed analytics
```json
Request:
?period=30d  // 7d, 30d, 90d, 1y, all
&metrics=revenue,sales,views,engagement

Response: 200 OK
{
  "period": {
    "start": "2023-12-16",
    "end": "2024-01-15"
  },
  "revenue": {
    "total": 2345.67,
    "by_day": [
      {"date": "2024-01-15", "amount": 89.45}
    ],
    "by_content": [
      {"content_id": "uuid", "title": "Luna", "amount": 445.11}
    ],
    "growth_rate": 15.3
  },
  "sales": {
    "total": 156,
    "conversion_rate": 3.2,
    "average_order_value": 15.04
  },
  "engagement": {
    "total_views": 4892,
    "unique_viewers": 3234,
    "average_rating": 4.7,
    "review_count": 45,
    "completion_rate": 78.5
  },
  "demographics": {
    "age_distribution": {
      "3-5": 35,
      "6-8": 45,
      "9-12": 20
    },
    "geographic_distribution": {
      "US": 70,
      "CA": 15,
      "UK": 10,
      "other": 5
    }
  }
}
```

### GET /api/v1/creators/analytics/content/{content_id}
Get analytics for specific content
```json
Response: 200 OK
{
  "content_id": "uuid",
  "title": "Luna's Adventure",
  "performance": {
    "total_revenue": 445.11,
    "total_sales": 89,
    "views": 2341,
    "conversion_rate": 3.8,
    "average_rating": 4.7,
    "review_count": 23
  },
  "engagement": {
    "average_completion": 85.3,
    "replay_rate": 23.4,
    "favorite_rate": 45.2,
    "average_session_minutes": 12.5
  },
  "trends": {
    "daily_sales": [/* array of daily data */],
    "cumulative_revenue": [/* array of cumulative data */]
  },
  "feedback": {
    "positive_keywords": ["engaging", "educational", "fun"],
    "improvement_areas": ["too short", "more variety"]
  }
}
```

## Financial Management

### GET /api/v1/creators/payouts
Get payout history and pending payouts
```json
Response: 200 OK
{
  "pending_payout": {
    "amount": 234.56,
    "currency": "USD",
    "estimated_date": "2024-01-20",
    "transactions_included": 45
  },
  "payout_history": [
    {
      "payout_id": "uuid",
      "amount": 456.78,
      "currency": "USD",
      "status": "completed",
      "method": "ACH",
      "paid_date": "2024-01-05",
      "transaction_count": 89,
      "receipt_url": "https://wondernest.com/receipts/uuid"
    }
  ],
  "lifetime_earnings": 12345.67,
  "available_balance": 234.56,
  "minimum_payout": 50.00,
  "next_payout_eligible": true
}
```

### POST /api/v1/creators/payouts/request
Request manual payout
```json
Request:
{
  "amount": 234.56,
  "method": "ACH"  // or "PayPal", "Wire"
}

Response: 200 OK
{
  "payout_id": "uuid",
  "status": "processing",
  "amount": 234.56,
  "estimated_arrival": "2024-01-18",
  "transaction_fee": 0.00
}
```

### PUT /api/v1/creators/banking
Update banking information
```json
Request:
{
  "method": "ACH",
  "account_holder_name": "Jane Doe",
  "account_type": "checking",
  "routing_number": "encrypted_routing",
  "account_number": "encrypted_account",
  "bank_name": "Chase Bank"
}

Response: 200 OK
{
  "status": "verified",
  "last_four": "1234",
  "bank_name": "Chase Bank"
}
```

### GET /api/v1/creators/tax-documents/{year}
Get tax documents for specific year
```json
Response: 200 OK
{
  "year": 2023,
  "documents": [
    {
      "type": "1099-MISC",
      "generated_date": "2024-01-31",
      "amount_reported": 12345.67,
      "download_url": "https://secure.wondernest.com/tax/uuid.pdf"
    }
  ]
}
```

## Support & Communication

### GET /api/v1/creators/support/tickets
List support tickets
```json
Response: 200 OK
{
  "tickets": [
    {
      "ticket_id": "uuid",
      "subject": "Content review taking too long",
      "status": "open",
      "priority": "medium",
      "created_at": "2024-01-14T10:00:00Z",
      "last_updated": "2024-01-14T14:00:00Z",
      "last_response_from": "support"
    }
  ]
}
```

### POST /api/v1/creators/support/tickets
Create support ticket
```json
Request:
{
  "subject": "Payment not received",
  "category": "payments",
  "priority": "high",
  "message": "I haven't received my payout...",
  "attachments": ["uuid1", "uuid2"]
}

Response: 201 Created
{
  "ticket_id": "uuid",
  "ticket_number": "CRT-2024-0142",
  "status": "open",
  "estimated_response_time": "4 hours"
}
```

### GET /api/v1/creators/notifications
Get creator notifications
```json
Response: 200 OK
{
  "notifications": [
    {
      "id": "uuid",
      "type": "content_approved",
      "title": "Content Approved",
      "message": "Your content 'Luna's Adventure' has been approved",
      "timestamp": "2024-01-15T09:00:00Z",
      "read": false,
      "action_url": "/content/uuid"
    }
  ],
  "unread_count": 3
}
```

## Moderation Feedback

### GET /api/v1/creators/content/{submission_id}/feedback
Get moderation feedback
```json
Response: 200 OK
{
  "submission_id": "uuid",
  "moderation_status": "request_changes",
  "feedback": {
    "overall_rating": 3.5,
    "content_quality": 4.0,
    "educational_value": 4.5,
    "safety_rating": 2.5,
    "age_appropriateness": 4.0
  },
  "public_feedback": "Good educational content but needs safety improvements",
  "suggested_changes": [
    "Remove reference to unsafe behavior on page 3",
    "Add parent guidance note for complex topics"
  ],
  "flagged_issues": ["safety_concern"],
  "can_resubmit": true
}
```

### POST /api/v1/creators/content/{submission_id}/appeal
Appeal moderation decision
```json
Request:
{
  "reason": "misunderstanding",
  "explanation": "The flagged content was taken out of context...",
  "supporting_documents": ["uuid1", "uuid2"]
}

Response: 200 OK
{
  "appeal_id": "uuid",
  "status": "under_review",
  "estimated_review_time": "48 hours"
}
```