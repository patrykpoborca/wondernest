# API Endpoints: Sticker Book Game

## Base Path
`/api/v2/games`

## Endpoints

### PUT /children/{childId}/data
**Description**: Save or update sticker book project data (UPSERT operation)
**Authentication**: Required (JWT Bearer token)
**Request**:
```json
{
  "gameKey": "sticker_book",
  "dataKey": "sticker_project_{projectId}",
  "dataValue": {
    "id": "string",
    "name": "string",
    "drawings": [
      {
        "id": "string",
        "strokes": ["array of stroke data"]
      }
    ],
    "stickers": [
      {
        "id": "string",
        "type": "string",
        "x": "number",
        "y": "number",
        "rotation": "number",
        "scale": "number"
      }
    ],
    "lastModified": "ISO-8601 timestamp",
    "backgroundColor": "string (hex color)",
    "canvasSize": {
      "width": "number",
      "height": "number"
    }
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "Game data saved successfully",
  "data": {
    "id": "UUID",
    "instanceId": "UUID",
    "childId": "UUID",
    "gameKey": "sticker_book",
    "dataKey": "sticker_project_123",
    "dataValue": {/* same as request */},
    "dataVersion": 1,
    "createdAt": "ISO-8601",
    "updatedAt": "ISO-8601"
  }
}
```

**Error Codes**:
- 400: Invalid child ID format or invalid request body
- 401: Authentication required or invalid token
- 404: Game not found in registry
- 500: Server error during save operation

**Validation**:
- childId: Must be valid UUID
- gameKey: Must exist in game_registry
- dataKey: Required, unique per child/game combination
- dataValue: Must be valid JSON

---

### GET /children/{childId}/data
**Description**: Retrieve all sticker book projects for a child
**Authentication**: Required
**Query Parameters**:
- `gameKey` (required): "sticker_book"
- `dataKey` (optional): Specific project ID to retrieve

**Response**:
```json
{
  "success": true,
  "gameData": [
    {
      "id": "UUID",
      "instanceId": "UUID",
      "childId": "UUID",
      "gameKey": "sticker_book",
      "dataKey": "sticker_project_123",
      "dataValue": {/* project data */},
      "dataVersion": 1,
      "createdAt": "ISO-8601",
      "updatedAt": "ISO-8601"
    }
  ]
}
```

**Error Codes**:
- 400: Missing gameKey parameter
- 401: Authentication required
- 404: No data found

---

### GET /children/{childId}/data/{gameKey}/{dataKey}
**Description**: Retrieve specific sticker book project
**Authentication**: Required

**Response**:
```json
{
  "id": "UUID",
  "instanceId": "UUID",
  "childId": "UUID",
  "gameKey": "sticker_book",
  "dataKey": "sticker_project_123",
  "dataValue": {/* project data */},
  "dataVersion": 1,
  "createdAt": "ISO-8601",
  "updatedAt": "ISO-8601"
}
```

**Error Codes**:
- 400: Invalid parameters
- 401: Authentication required
- 404: Project not found

---

### DELETE /children/{childId}/data/{gameKey}/{dataKey}
**Description**: Delete specific sticker book project
**Authentication**: Required

**Response**:
```json
{
  "success": true,
  "message": "Game data deleted successfully",
  "childId": "UUID",
  "gameKey": "sticker_book",
  "dataKey": "sticker_project_123",
  "data": null
}
```

**Error Codes**:
- 400: Invalid parameters
- 401: Authentication required
- 404: Project not found

---

### GET /children/{childId}/active
**Description**: Get list of games with saved data for a child
**Authentication**: Required

**Response**:
```json
{
  "success": true,
  "activeGames": [
    {
      "gameKey": "sticker_book",
      "displayName": "Sticker Book",
      "totalPlayTimeMinutes": 45,
      "lastPlayedAt": "ISO-8601",
      "lastDataUpdate": "ISO-8601"
    }
  ]
}
```

---

## Implementation Notes

### Versioning
- Each update to a project increments the `dataVersion` field
- Useful for conflict resolution in multi-device scenarios
- Can be used for undo/redo functionality

### Storage
- Projects stored in `games.child_game_data` table
- Uses JSONB column type for flexible schema
- Indexed on (child_game_instance_id, data_key) for fast lookups

### Sync Strategy
- Flutter app maintains local SQLite cache
- Syncs with backend when network available
- Conflict resolution: Latest timestamp wins
- Offline changes queued for sync

### Size Limits
- Maximum dataValue size: 10MB
- Enforced at API level to prevent database bloat
- Large drawings should be optimized client-side

### Performance
- Use pagination for large project lists
- Consider adding `limit` and `offset` query parameters
- Thumbnails generated and cached client-side