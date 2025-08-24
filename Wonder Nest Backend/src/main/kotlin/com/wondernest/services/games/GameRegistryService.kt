package com.wondernest.services.games

import com.wondernest.data.database.table.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID

/**
 * Service for managing game registry operations
 * Handles game registration, retrieval, and validation according to proper architecture
 */
class GameRegistryService {
    
    /**
     * Get all active games
     */
    fun getAllActiveGames(): List<GameInfo> = transaction {
        GameRegistry.join(GameTypes, JoinType.INNER) { GameRegistry.gameTypeId eq GameTypes.id }
            .join(GameCategories, JoinType.INNER) { GameRegistry.categoryId eq GameCategories.id }
            .select { GameRegistry.isActive eq true }
            .orderBy(GameRegistry.displayName)
            .map { row ->
                GameInfo(
                    id = row[GameRegistry.id].toString(),
                    gameKey = row[GameRegistry.gameKey],
                    displayName = row[GameRegistry.displayName],
                    description = row[GameRegistry.description],
                    gameType = row[GameTypes.name],
                    category = row[GameCategories.name],
                    minAgeMonths = row[GameRegistry.minAgeMonths],
                    maxAgeMonths = row[GameRegistry.maxAgeMonths],
                    isActive = row[GameRegistry.isActive]
                )
            }
    }
    
    /**
     * Get game by game key (e.g., "sticker_book")
     */
    fun getGameByKey(gameKey: String): GameInfo? = transaction {
        GameRegistry.join(GameTypes, JoinType.INNER) { GameRegistry.gameTypeId eq GameTypes.id }
            .join(GameCategories, JoinType.INNER) { GameRegistry.categoryId eq GameCategories.id }
            .select { (GameRegistry.gameKey eq gameKey) and (GameRegistry.isActive eq true) }
            .singleOrNull()?.let { row ->
                GameInfo(
                    id = row[GameRegistry.id].toString(),
                    gameKey = row[GameRegistry.gameKey],
                    displayName = row[GameRegistry.displayName],
                    description = row[GameRegistry.description],
                    gameType = row[GameTypes.name],
                    category = row[GameCategories.name],
                    minAgeMonths = row[GameRegistry.minAgeMonths],
                    maxAgeMonths = row[GameRegistry.maxAgeMonths],
                    isActive = row[GameRegistry.isActive]
                )
            }
    }
    
    /**
     * Get game by UUID
     */
    fun getGameById(gameId: UUID): GameInfo? = transaction {
        GameRegistry.join(GameTypes, JoinType.INNER) { GameRegistry.gameTypeId eq GameTypes.id }
            .join(GameCategories, JoinType.INNER) { GameRegistry.categoryId eq GameCategories.id }
            .select { (GameRegistry.id eq gameId) and (GameRegistry.isActive eq true) }
            .singleOrNull()?.let { row ->
                GameInfo(
                    id = row[GameRegistry.id].toString(),
                    gameKey = row[GameRegistry.gameKey],
                    displayName = row[GameRegistry.displayName],
                    description = row[GameRegistry.description],
                    gameType = row[GameTypes.name],
                    category = row[GameCategories.name],
                    minAgeMonths = row[GameRegistry.minAgeMonths],
                    maxAgeMonths = row[GameRegistry.maxAgeMonths],
                    isActive = row[GameRegistry.isActive]
                )
            }
    }
    
    /**
     * Validate if a game is appropriate for a child's age
     */
    fun isGameAgeAppropriate(gameId: UUID, childAgeMonths: Int): Boolean = transaction {
        GameRegistry.select { GameRegistry.id eq gameId }
            .singleOrNull()?.let { row ->
                val minAge = row[GameRegistry.minAgeMonths]
                val maxAge = row[GameRegistry.maxAgeMonths]
                childAgeMonths in minAge..maxAge
            } ?: false
    }
    
    /**
     * Get games by category
     */
    fun getGamesByCategory(categoryName: String): List<GameInfo> = transaction {
        GameRegistry.join(GameTypes, JoinType.INNER) { GameRegistry.gameTypeId eq GameTypes.id }
            .join(GameCategories, JoinType.INNER) { GameRegistry.categoryId eq GameCategories.id }
            .select { (GameCategories.name eq categoryName) and (GameRegistry.isActive eq true) }
            .orderBy(GameRegistry.displayName)
            .map { row ->
                GameInfo(
                    id = row[GameRegistry.id].toString(),
                    gameKey = row[GameRegistry.gameKey],
                    displayName = row[GameRegistry.displayName],
                    description = row[GameRegistry.description],
                    gameType = row[GameTypes.name],
                    category = row[GameCategories.name],
                    minAgeMonths = row[GameRegistry.minAgeMonths],
                    maxAgeMonths = row[GameRegistry.maxAgeMonths],
                    isActive = row[GameRegistry.isActive]
                )
            }
    }
    
    /**
     * Get all game types
     */
    fun getAllGameTypes(): List<GameTypeInfo> = transaction {
        GameTypes.selectAll().orderBy(GameTypes.name).map { row ->
            GameTypeInfo(
                id = row[GameTypes.id].toString(),
                name = row[GameTypes.name],
                description = row[GameTypes.description]
            )
        }
    }
    
    /**
     * Get all game categories
     */
    fun getAllGameCategories(): List<GameCategoryInfo> = transaction {
        GameCategories.selectAll().orderBy(GameCategories.name).map { row ->
            GameCategoryInfo(
                id = row[GameCategories.id].toString(),
                name = row[GameCategories.name],
                parentCategoryId = row[GameCategories.parentCategoryId]?.toString()
            )
        }
    }
}

// Data models for GameRegistryService responses
@Serializable
data class GameInfo(
    val id: String,
    val gameKey: String,
    val displayName: String,
    val description: String,
    val gameType: String,
    val category: String,
    val minAgeMonths: Int,
    val maxAgeMonths: Int,
    val isActive: Boolean
)

@Serializable
data class GameTypeInfo(
    val id: String,
    val name: String,
    val description: String
)

@Serializable
data class GameCategoryInfo(
    val id: String,
    val name: String,
    val parentCategoryId: String?
)