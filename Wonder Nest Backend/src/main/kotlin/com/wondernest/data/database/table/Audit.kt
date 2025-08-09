package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.json.jsonb
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString

@Serializable
data class AuditMetadata(
    val endpoint: String? = null,
    val userAgent: String? = null,
    val requestId: String? = null,
    val executionTimeMs: Long? = null
)

@Serializable
data class RetentionCriteria(
    val retainForLegal: Boolean = false,
    val dataType: String = "general",
    val retainUntilChildAge: Int? = null,
    val complianceRequirement: String? = null
)

// Comprehensive audit log for compliance and security
object ActivityLog : UUIDTable("activity_log") {
    // Who performed the action
    val userId = reference("user_id", Users).nullable()
    val childId = reference("child_id", ChildProfiles).nullable() // If action relates to child
    
    // What action was performed
    val action = enumerationByName<ActionType>("action", 20)
    val affectedTableName = varchar("table_name", 100)
    val recordId = uuid("record_id").nullable()
    
    // Action details
    val oldValues = jsonb<Map<String, Any>>("old_values", 
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).nullable() // Previous state
    val newValues = jsonb<Map<String, Any>>("new_values",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).nullable() // New state
    
    // Context
    val timestamp = timestamp("timestamp").defaultExpression(CurrentTimestamp())
    val ipAddress = varchar("ip_address", 45).nullable()
    val userAgent = text("user_agent").nullable()
    val sessionId = uuid("session_id").nullable()
    
    // Additional metadata
    val metadata = jsonb<AuditMetadata>("metadata",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(AuditMetadata())
    
    // Compliance fields
    val retentionUntil = timestamp("retention_until").nullable() // When this can be deleted
    val legalHold = bool("legal_hold").default(false) // Legal hold prevents deletion
}

// Data retention policies
object DataRetentionPolicies : UUIDTable("data_retention_policies") {
    val policyTableName = varchar("table_name", 100).uniqueIndex()
    val retentionPeriodDays = integer("retention_period_days")
    val retentionCriteria = jsonb<RetentionCriteria>("retention_criteria",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(RetentionCriteria())
    
    // Policy details
    val description = text("description")
    val legalBasis = text("legal_basis").nullable() // COPPA, GDPR, business requirement
    
    // Policy status
    val isActive = bool("is_active").default(true)
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
}