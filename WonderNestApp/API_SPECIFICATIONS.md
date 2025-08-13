# WonderNest API Endpoint Specifications

## Base URL
```
Production: https://api.wondernest.com/api/v1
Development: http://localhost:8080/api/v1
```

## Authentication Headers
```
Authorization: Bearer {access_token}
X-Device-Id: {device_uuid}
X-App-Version: {app_version}
X-Platform: {ios|android}
```

## 1. Authentication & Session Management

### POST /auth/parent/register
Register a new parent account.
```json
Request:
{
  "email": "parent@example.com",
  "password": "SecurePassword123!",
  "name": "John Doe",
  "phoneNumber": "+1234567890",
  "countryCode": "US"
}

Response (200):
{
  "success": true,
  "data": {
    "userId": "usr_abc123",
    "email": "parent@example.com",
    "accessToken": "eyJ...",
    "refreshToken": "ref_xyz789",
    "expiresIn": 3600,
    "requiresPinSetup": true
  }
}

Error (400):
{
  "success": false,
  "error": {
    "code": "EMAIL_EXISTS",
    "message": "Email already registered"
  }
}
```

### POST /auth/parent/login
Parent login with email and password.
```json
Request:
{
  "email": "parent@example.com",
  "password": "SecurePassword123!"
}

Response (200):
{
  "success": true,
  "data": {
    "userId": "usr_abc123",
    "accessToken": "eyJ...",
    "refreshToken": "ref_xyz789",
    "expiresIn": 3600,
    "hasPin": true,
    "children": [
      {
        "id": "chld_123",
        "name": "Timmy",
        "age": 7,
        "avatarUrl": "https://..."
      }
    ]
  }
}
```

### POST /auth/parent/verify-pin
Verify parent PIN for mode switching.
```json
Request:
{
  "pin": "123456",
  "deviceId": "device_uuid"
}

Response (200):
{
  "success": true,
  "data": {
    "verified": true,
    "parentModeToken": "pmt_abc123",
    "expiresIn": 900
  }
}

Error (401):
{
  "success": false,
  "error": {
    "code": "INVALID_PIN",
    "message": "Invalid PIN",
    "attemptsRemaining": 3
  }
}
```

### POST /auth/session/refresh
Refresh access token.
```json
Request:
{
  "refreshToken": "ref_xyz789"
}

Response (200):
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "ref_new123",
    "expiresIn": 3600
  }
}
```

## 2. Family Management

### GET /family/profile
Get family profile with all children.
```json
Response (200):
{
  "success": true,
  "data": {
    "familyId": "fam_123",
    "parentName": "John Doe",
    "children": [
      {
        "id": "chld_123",
        "name": "Timmy",
        "age": 7,
        "birthDate": "2017-03-15",
        "gender": "male",
        "avatarUrl": "https://...",
        "interests": ["dinosaurs", "space", "lego"],
        "contentSettings": {
          "maxAgeRating": 7,
          "subtitlesEnabled": true,
          "audioMonitoringEnabled": true
        }
      }
    ],
    "subscription": {
      "plan": "premium",
      "validUntil": "2025-01-01",
      "maxChildren": 5
    }
  }
}
```

### POST /family/children
Add a new child profile.
```json
Request:
{
  "name": "Sally",
  "birthDate": "2018-06-20",
  "gender": "female",
  "interests": ["art", "music", "animals"],
  "avatarId": "avatar_princess"
}

Response (201):
{
  "success": true,
  "data": {
    "childId": "chld_456",
    "name": "Sally",
    "profileCreated": true
  }
}
```

### PUT /family/children/{childId}
Update child profile.
```json
Request:
{
  "name": "Sally",
  "interests": ["art", "music", "animals", "science"],
  "contentSettings": {
    "maxAgeRating": 8,
    "subtitlesEnabled": true
  }
}

Response (200):
{
  "success": true,
  "data": {
    "childId": "chld_456",
    "updated": true
  }
}
```

## 3. Content Control

### GET /content/filters
Get content filter settings.
```json
Response (200):
{
  "success": true,
  "data": {
    "globalFilters": {
      "violence": "none",
      "language": "mild",
      "sexualContent": "none",
      "substances": "none"
    },
    "blockedKeywords": ["violent", "inappropriate"],
    "allowedCategories": ["education", "entertainment", "games"],
    "ageRatings": {
      "maxMovieRating": "PG",
      "maxGameRating": "E10+",
      "maxAppRating": "9+"
    }
  }
}
```

### PUT /content/filters
Update content filter settings.
```json
Request:
{
  "childId": "chld_123",
  "filters": {
    "violence": "none",
    "language": "none",
    "maxAgeRating": 7
  },
  "blockedKeywords": ["scary", "monster"]
}

Response (200):
{
  "success": true,
  "data": {
    "updated": true,
    "appliedTo": ["chld_123"]
  }
}
```

### GET /content/whitelist
Get whitelisted content.
```json
Response (200):
{
  "success": true,
  "data": {
    "websites": [
      {
        "id": "site_1",
        "url": "pbskids.org",
        "name": "PBS Kids",
        "category": "educational"
      }
    ],
    "youtubeChannels": [
      {
        "id": "yt_1",
        "channelId": "UC...",
        "name": "Sesame Street",
        "verified": true
      }
    ],
    "games": [
      {
        "id": "game_1",
        "name": "Math Adventures",
        "url": "https://...",
        "ageRange": "5-8"
      }
    ]
  }
}
```

## 4. Activity Tracking

### POST /activity/track
Track child activity.
```json
Request:
{
  "childId": "chld_123",
  "type": "video",
  "title": "Learning ABCs",
  "platform": "youtube",
  "contentId": "video_123",
  "duration": 300,
  "timestamp": "2025-01-12T10:30:00Z",
  "metadata": {
    "channelName": "Educational Channel",
    "category": "education"
  }
}

Response (201):
{
  "success": true,
  "data": {
    "activityId": "act_789",
    "recorded": true
  }
}
```

### GET /activity/child/{childId}/summary
Get activity summary for a child.
```json
Response (200):
{
  "success": true,
  "data": {
    "childId": "chld_123",
    "period": "week",
    "totalScreenTime": 840,
    "dailyAverage": 120,
    "topCategories": [
      {
        "category": "education",
        "minutes": 420,
        "percentage": 50
      },
      {
        "category": "entertainment",
        "minutes": 300,
        "percentage": 35.7
      }
    ],
    "topContent": [
      {
        "title": "Math Games",
        "type": "game",
        "totalMinutes": 180
      }
    ],
    "vocabularyExposure": {
      "uniqueWords": 324,
      "newWords": 45,
      "readingLevel": 2.3
    }
  }
}
```

### POST /activity/subtitle-exposure
Track subtitle/caption exposure.
```json
Request:
{
  "childId": "chld_123",
  "contentId": "video_456",
  "subtitles": [
    {
      "text": "Once upon a time",
      "timestamp": "00:00:05",
      "duration": 3
    }
  ],
  "wordsExposed": ["once", "upon", "time"],
  "readingLevel": 1.5
}

Response (201):
{
  "success": true,
  "data": {
    "recorded": true,
    "totalWordsTracked": 1250
  }
}
```

## 5. Parental Controls

### GET /controls/settings
Get parental control settings.
```json
Response (200):
{
  "success": true,
  "data": {
    "childId": "chld_123",
    "screenTimeLimit": {
      "daily": 120,
      "weekday": 90,
      "weekend": 150
    },
    "bedtime": {
      "enabled": true,
      "start": "20:00",
      "end": "07:00"
    },
    "appRestrictions": {
      "youtube": {
        "allowed": true,
        "maxDailyMinutes": 30
      }
    },
    "educationalRequirement": {
      "enabled": true,
      "minimumMinutes": 30
    }
  }
}
```

### PUT /controls/time-limits
Update time limit settings.
```json
Request:
{
  "childId": "chld_123",
  "limits": {
    "daily": 120,
    "weekday": 90,
    "weekend": 150,
    "educationalBonus": 30
  }
}

Response (200):
{
  "success": true,
  "data": {
    "updated": true,
    "effectiveFrom": "2025-01-13T00:00:00Z"
  }
}
```

## 6. Mini-Games Management

### GET /games/whitelist
Get whitelisted games.
```json
Response (200):
{
  "success": true,
  "data": {
    "games": [
      {
        "id": "game_123",
        "name": "Math Adventure",
        "description": "Fun math learning game",
        "url": "https://...",
        "thumbnailUrl": "https://...",
        "ageRange": "5-8",
        "categories": ["education", "math"],
        "rating": 4.5
      }
    ]
  }
}
```

### POST /games/progress
Save game progress.
```json
Request:
{
  "gameId": "game_123",
  "childId": "chld_123",
  "score": 1500,
  "level": 5,
  "achievements": ["first_win", "speed_bonus"],
  "playTimeMinutes": 15
}

Response (201):
{
  "success": true,
  "data": {
    "saved": true,
    "totalScore": 5500,
    "rank": "gold"
  }
}
```

## 7. COPPA Compliance

### POST /coppa/consent
Submit parental consent.
```json
Request:
{
  "childId": "chld_123",
  "consentType": "full",
  "permissions": {
    "dataCollection": true,
    "thirdPartySharing": false,
    "marketing": false,
    "analytics": true
  },
  "parentSignature": "John Doe",
  "verificationMethod": "credit_card",
  "verificationToken": "tok_123"
}

Response (201):
{
  "success": true,
  "data": {
    "consentId": "consent_456",
    "status": "granted",
    "validUntil": "2026-01-12",
    "certificateUrl": "https://..."
  }
}
```

### GET /coppa/consent/status
Check consent status.
```json
Response (200):
{
  "success": true,
  "data": {
    "childId": "chld_123",
    "hasConsent": true,
    "consentDate": "2025-01-12",
    "expiresOn": "2026-01-12",
    "permissions": {
      "dataCollection": true,
      "thirdPartySharing": false,
      "marketing": false
    }
  }
}
```

### POST /coppa/data-deletion
Request data deletion (COPPA right).
```json
Request:
{
  "childId": "chld_123",
  "reason": "parent_request",
  "deleteAll": true,
  "confirmation": "DELETE-CHILD-DATA"
}

Response (200):
{
  "success": true,
  "data": {
    "deletionId": "del_789",
    "status": "scheduled",
    "completionDate": "2025-01-15",
    "dataCategories": ["activity", "preferences", "analytics"]
  }
}
```

## Error Codes

| Code | Description |
|------|-------------|
| AUTH_FAILED | Authentication failed |
| INVALID_PIN | Invalid PIN entered |
| SESSION_EXPIRED | Session has expired |
| CHILD_NOT_FOUND | Child profile not found |
| PERMISSION_DENIED | Operation not permitted |
| CONTENT_BLOCKED | Content is blocked by filters |
| LIMIT_EXCEEDED | Time or usage limit exceeded |
| COPPA_REQUIRED | COPPA consent required |
| SUBSCRIPTION_REQUIRED | Premium subscription required |

## Rate Limiting

- Authentication endpoints: 5 requests per minute
- Activity tracking: 100 requests per minute
- Content queries: 30 requests per minute
- Settings updates: 10 requests per minute

## Webhook Events

The backend can send webhooks for:
- Screen time limit reached
- Inappropriate content detected
- Emergency keyword detected in audio
- New achievement unlocked
- Subscription expiring