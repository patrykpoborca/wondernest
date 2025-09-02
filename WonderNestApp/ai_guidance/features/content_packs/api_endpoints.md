# Content Packs API Documentation

## Base URL
`/api/v1/content-packs`

## Endpoints

### Get Categories
**GET** `/categories`
- Returns list of content pack categories
- Response: `{ categories: ContentPackCategory[] }`

### Get Featured Packs
**GET** `/featured`
- Returns featured content packs
- Response: `{ packs: ContentPack[] }`

### Search Packs
**POST** `/search`
- Search and filter content packs
- Request: `ContentPackSearchRequest`
- Response: `ContentPackSearchResponse`

### Get Pack Details
**GET** `/{packId}`
- Get detailed information about a specific pack
- Response: `{ pack: ContentPack }`

### Get Owned Packs
**GET** `/owned`
- Query params: `childId` (optional)
- Returns packs owned by user/child
- Response: `{ packs: ContentPack[] }`

### Purchase Pack
**POST** `/purchase`
- Request: `{ packId: string, childId?: string }`
- Response: `{ success: boolean, ownership: UserPackOwnership }`
- Requires parental approval

### Get Pack Assets
**GET** `/{packId}/assets`
- Returns all assets in a pack (requires ownership)
- Response: `{ assets: ContentPackAsset[] }`

### Update Download Status
**PUT** `/{packId}/download`
- Request: `{ status: string, progress: number, childId?: string }`
- Updates download progress for offline usage

### Record Pack Usage
**POST** `/{packId}/usage`
- Request: `{ usedInFeature: string, childId?: string, assetId?: string, sessionId?: string, usageDurationSeconds?: number, metadata?: object }`
- Records when and how a pack is used

## Data Models

### ContentPack
```typescript
{
  id: string
  name: string
  packType: string // 'characterBundle' | 'backdropCollection' | etc
  priceCents: number
  isFree: boolean
  categoryId?: string
  thumbnailUrl?: string
  previewUrls: string[]
  totalAssets: number
  fileSizeBytes: number
  userOwnership?: UserPackOwnership
}
```

### ContentPackSearchRequest
```typescript
{
  query?: string
  category?: string
  packType?: string
  ageMin?: number
  ageMax?: number
  priceMin?: number
  priceMax?: number
  isFree?: boolean
  educationalGoals?: string[]
  sortBy: string // 'popularity' | 'price' | 'newest' | 'rating'
  sortOrder: string // 'asc' | 'desc'
  page: number
  size: number
}
```