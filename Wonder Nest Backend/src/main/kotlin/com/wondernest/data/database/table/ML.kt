package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.json.jsonb
import kotlinx.serialization.Serializable
import java.math.BigDecimal

@Serializable
data class ModelParameters(
    val learningRate: Double = 0.01,
    val regularization: Double = 0.001,
    val maxFeatures: Int = 1000,
    val minSamples: Int = 10
)

@Serializable
data class FeatureImportance(
    val ageWeight: Double = 0.3,
    val categoryWeight: Double = 0.25,
    val engagementWeight: Double = 0.2,
    val timeWeight: Double = 0.15,
    val similarityWeight: Double = 0.1
)

@Serializable
data class PerformanceMetrics(
    val accuracy: Double = 0.0,
    val precision: Double = 0.0,
    val recall: Double = 0.0,
    val f1Score: Double = 0.0,
    val auc: Double = 0.0
)

@Serializable
data class RecommendationReasoning(
    val primaryReason: String = "age_appropriate",
    val secondaryFactors: List<String> = emptyList(),
    val confidenceScore: Double = 0.0,
    val similarContent: List<String> = emptyList()
)

// Content recommendation models
object RecommendationModels : UUIDTable("recommendation_models") {
    val name = varchar("name", 100).uniqueIndex()
    val modelType = varchar("model_type", 50) // collaborative_filtering, content_based, hybrid
    val version = varchar("version", 20)
    
    // Model configuration
    val parameters = jsonb<ModelParameters>("parameters", ::ModelParameters, ModelParameters::class).default(ModelParameters())
    val featureImportance = jsonb<FeatureImportance>("feature_importance", ::FeatureImportance, FeatureImportance::class).default(FeatureImportance())
    val performanceMetrics = jsonb<PerformanceMetrics>("performance_metrics", ::PerformanceMetrics, PerformanceMetrics::class).default(PerformanceMetrics())
    
    // Model lifecycle
    val trainedAt = timestamp("trained_at")
    val deployedAt = timestamp("deployed_at").nullable()
    val isActive = bool("is_active").default(false)
    
    // Training data info
    val trainingDataFrom = timestamp("training_data_from")
    val trainingDataTo = timestamp("training_data_to")
    val trainingSamplesCount = integer("training_samples_count")
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp)
}

// Content recommendations for children
object ContentRecommendations : UUIDTable("content_recommendations") {
    val childId = reference("child_id", ChildProfiles)
    val contentId = reference("content_id", ContentItems)
    val modelId = reference("model_id", RecommendationModels).nullable()
    
    // Recommendation score and reasoning
    val score = decimal("score", 4, 3) // 0-1 recommendation score
    val reasoning = jsonb<RecommendationReasoning>("reasoning", ::RecommendationReasoning, RecommendationReasoning::class).default(RecommendationReasoning())
    val recommendationType = varchar("recommendation_type", 50) // trending, similar_to_liked, age_appropriate
    
    // Recommendation lifecycle
    val generatedAt = timestamp("generated_at").defaultExpression(CurrentTimestamp)
    val expiresAt = timestamp("expires_at")
    val shownToUser = bool("shown_to_user").default(false)
    val shownAt = timestamp("shown_at").nullable()
    
    // User feedback
    val userAction = varchar("user_action", 50).nullable() // viewed, liked, disliked, skipped, shared
    val userActionAt = timestamp("user_action_at").nullable()
    
    init {
        uniqueIndex(childId, contentId, modelId, generatedAt)
    }
}