# Changelog: Sticker Book Game

## [2025-08-25 00:00] - Type: BUGFIX

### Summary
Fixed critical issues preventing sticker book saves from working properly with backend

### Context
- Task: Fix 500 errors when saving sticker projects
- Issue: Multiple layers of problems including type mismatches, schema issues, and update logic

### Changes Made
- ✅ Fixed type mismatch: Backend now accepts JsonElement instead of Map<String, JsonElement>
- ✅ Fixed schema qualification: All game tables now use qualified names (games.table_name)
- ✅ Fixed serialization: Changed all JSONB columns from Map<String, Any> to Map<String, String>
- ✅ Implemented UPSERT logic: saveGameData now handles both inserts and updates
- ✅ Added versioning: Each save increments version number for audit trail
- ⚠️ Removed SET search_path workaround after fixing table definitions

### Technical Implementation
```kotlin
// Changed from INSERT-only to UPSERT pattern
val existingData = ChildGameData
    .select { 
        (ChildGameData.childGameInstanceId eq instanceId) and 
        (ChildGameData.dataKey eq dataKey) 
    }
    .singleOrNull()

if (existingData != null) {
    // UPDATE with version increment
    ChildGameData.update { /*...*/ }
} else {
    // INSERT as new
    ChildGameData.insertAndGetId { /*...*/ }
}
```

### Files Modified
| File | Change Type | Description |
|------|------------|-------------|
| `/Wonder Nest Backend/src/main/kotlin/com/wondernest/services/games/GameDataService.kt` | MODIFY | Added UPSERT logic, fixed type handling |
| `/Wonder Nest Backend/src/main/kotlin/com/wondernest/data/database/table/Games.kt` | MODIFY | Fixed table definitions with schema qualifiers |
| `/Wonder Nest Backend/src/main/kotlin/com/wondernest/api/games/EnhancedGameRoutes.kt` | MODIFY | Changed from updateGameData to saveGameData |
| `/Wonder Nest Backend/src/main/kotlin/com/wondernest/services/games/ChildGameInstanceService.kt` | MODIFY | Fixed Map types for settings/preferences |

### Testing
- Tested: Multiple sequential saves of same project
- Method: CURL commands to test endpoint directly
- Result: Successfully saved with versions 1, 2, 3 incrementing properly

### Known Issues
- 🐛 Authentication still requires valid JWT token (mock mode works)
- 📝 Need to test with actual Flutter app integration

### Next Steps
- Test full integration with Flutter app
- Verify sync across multiple devices
- Add comprehensive error handling for edge cases

### Dependencies
- None added or modified

---

## [2025-08-24 18:00] - Type: FEATURE

### Summary
Initial implementation of enhanced game data architecture

### Context
- Task: Implement proper GameRegistry → ChildGameInstances → ChildGameData pattern
- Issue: Moving away from SimpleGameData to proper architecture

### Changes Made
- ✅ Created GameRegistry service
- ✅ Created ChildGameInstanceService
- ✅ Created GameDataService with save/update/delete operations
- ✅ Added V3 and V4 migrations for games schema
- ✅ Set up enhanced API v2 routes

### Files Modified
| File | Change Type | Description |
|------|------------|-------------|
| `/Wonder Nest Backend/src/main/resources/db/migration/V3__Add_Games_Schema.sql` | CREATE | Added games schema with all tables |
| `/Wonder Nest Backend/src/main/resources/db/migration/V4__Add_Game_Asset_Registry.sql` | CREATE | Added game asset registry |
| `/Wonder Nest Backend/src/main/kotlin/com/wondernest/services/games/*.kt` | CREATE | All game services |

### Testing
- Tested: Database migrations
- Result: All tables created successfully

---