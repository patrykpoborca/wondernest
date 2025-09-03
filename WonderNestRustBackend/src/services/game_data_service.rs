use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::{
    SaveGameDataRequest, GameDataResponse, GameDataItem, LoadGameDataResponse, SimpleGameData,
};

pub struct GameDataService {
    db: PgPool,
}

impl GameDataService {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    // Save or update game data for a child (matching Kotlin upsert behavior exactly)
    pub async fn save_game_data(
        &self,
        child_id: Uuid,
        request: SaveGameDataRequest,
    ) -> anyhow::Result<GameDataResponse> {
        let now = Utc::now();
        
        // First check if child exists
        let child_exists = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM family.child_profiles WHERE id = $1 AND is_active = true AND archived_at IS NULL)"
        )
        .bind(child_id)
        .fetch_one(&self.db)
        .await?;

        if !child_exists {
            return Ok(GameDataResponse {
                success: false,
                message: "Child not found".to_string(),
                child_id: child_id.to_string(),
                game_type: request.game_type,
                data_key: Some(request.data_key),
            });
        }

        // Use PostgreSQL UPSERT (ON CONFLICT) to match Kotlin behavior exactly
        sqlx::query(
            r#"
            INSERT INTO games.simple_game_data (id, child_id, game_type, data_key, data_value, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (child_id, game_type, data_key)
            DO UPDATE SET 
                data_value = EXCLUDED.data_value,
                updated_at = EXCLUDED.updated_at
            "#
        )
        .bind(Uuid::new_v4())
        .bind(child_id)
        .bind(&request.game_type)
        .bind(&request.data_key)
        .bind(&request.data_value)
        .bind(now)
        .bind(now)
        .execute(&self.db)
        .await?;

        Ok(GameDataResponse {
            success: true,
            message: "Game data saved successfully".to_string(),
            child_id: child_id.to_string(),
            game_type: request.game_type,
            data_key: Some(request.data_key),
        })
    }

    // Get all game data for a child with optional filters (matching Kotlin exactly)
    pub async fn load_game_data(
        &self,
        child_id: Uuid,
        game_type_filter: Option<&str>,
        data_key_filter: Option<&str>,
    ) -> anyhow::Result<LoadGameDataResponse> {
        let mut query = "SELECT id, child_id, game_type, data_key, data_value, created_at, updated_at FROM games.simple_game_data WHERE child_id = $1".to_string();
        let mut param_count = 1;
        let mut params: Vec<Box<dyn sqlx::Encode<'_, sqlx::Postgres> + Send>> = vec![Box::new(child_id)];

        // Add optional filters
        if let Some(game_type) = game_type_filter {
            if !game_type.is_empty() {
                param_count += 1;
                query.push_str(&format!(" AND game_type = ${}", param_count));
                params.push(Box::new(game_type.to_string()));
            }
        }

        if let Some(data_key) = data_key_filter {
            if !data_key.is_empty() {
                param_count += 1;
                query.push_str(&format!(" AND data_key = ${}", param_count));
                params.push(Box::new(data_key.to_string()));
            }
        }

        query.push_str(" ORDER BY updated_at DESC");

        // Use a simpler approach with manual parameter binding
        let mut sql_query = sqlx::query_as::<_, SimpleGameData>(&query);
        
        // Bind parameters based on what filters were applied
        sql_query = sql_query.bind(child_id);
        
        if game_type_filter.is_some() && !game_type_filter.unwrap().is_empty() {
            sql_query = sql_query.bind(game_type_filter.unwrap());
        }
        
        if data_key_filter.is_some() && !data_key_filter.unwrap().is_empty() {
            sql_query = sql_query.bind(data_key_filter.unwrap());
        }

        let game_data_rows = sql_query.fetch_all(&self.db).await?;

        // Convert to response format (matching Kotlin exactly)
        let game_data_items: Vec<GameDataItem> = game_data_rows
            .into_iter()
            .map(|row| GameDataItem {
                id: row.id.to_string(),
                child_id: row.child_id.to_string(),
                game_type: row.game_type,
                data_key: row.data_key,
                data_value: row.data_value,
                created_at: row.created_at.to_rfc3339(),
                updated_at: row.updated_at.to_rfc3339(),
            })
            .collect();

        Ok(LoadGameDataResponse {
            success: true,
            game_data: game_data_items,
        })
    }

    // Get specific game data item (matching Kotlin exactly)
    pub async fn get_game_data_item(
        &self,
        child_id: Uuid,
        game_type: &str,
        data_key: &str,
    ) -> anyhow::Result<Option<GameDataItem>> {
        let row = sqlx::query_as::<_, SimpleGameData>(
            "SELECT id, child_id, game_type, data_key, data_value, created_at, updated_at FROM games.simple_game_data WHERE child_id = $1 AND game_type = $2 AND data_key = $3"
        )
        .bind(child_id)
        .bind(game_type)
        .bind(data_key)
        .fetch_optional(&self.db)
        .await?;

        Ok(row.map(|r| GameDataItem {
            id: r.id.to_string(),
            child_id: r.child_id.to_string(),
            game_type: r.game_type,
            data_key: r.data_key,
            data_value: r.data_value,
            created_at: r.created_at.to_rfc3339(),
            updated_at: r.updated_at.to_rfc3339(),
        }))
    }

    // Delete specific game data (matching Kotlin exactly)
    pub async fn delete_game_data_item(
        &self,
        child_id: Uuid,
        game_type: &str,
        data_key: &str,
    ) -> anyhow::Result<GameDataResponse> {
        let result = sqlx::query(
            "DELETE FROM games.simple_game_data WHERE child_id = $1 AND game_type = $2 AND data_key = $3"
        )
        .bind(child_id)
        .bind(game_type)
        .bind(data_key)
        .execute(&self.db)
        .await?;

        if result.rows_affected() > 0 {
            Ok(GameDataResponse {
                success: true,
                message: "Game data deleted successfully".to_string(),
                child_id: child_id.to_string(),
                game_type: game_type.to_string(),
                data_key: Some(data_key.to_string()),
            })
        } else {
            Ok(GameDataResponse {
                success: false,
                message: "Game data not found".to_string(),
                child_id: child_id.to_string(),
                game_type: game_type.to_string(),
                data_key: Some(data_key.to_string()),
            })
        }
    }

    // Delete all game data for a child and game type (matching Kotlin exactly)
    pub async fn delete_game_data_for_type(
        &self,
        child_id: Uuid,
        game_type: &str,
    ) -> anyhow::Result<GameDataResponse> {
        let result = sqlx::query(
            "DELETE FROM games.simple_game_data WHERE child_id = $1 AND game_type = $2"
        )
        .bind(child_id)
        .bind(game_type)
        .execute(&self.db)
        .await?;

        Ok(GameDataResponse {
            success: true,
            message: format!("Deleted {} game data items", result.rows_affected()),
            child_id: child_id.to_string(),
            game_type: game_type.to_string(),
            data_key: None,
        })
    }
}