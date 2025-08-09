package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.json.jsonb
import kotlinx.serialization.Serializable

enum class PlanType { FREE, BASIC, PREMIUM, ENTERPRISE }
enum class BillingCycle { MONTHLY, YEARLY, LIFETIME }
enum class SubscriptionStatus { ACTIVE, TRIALING, PAST_DUE, CANCELED, UNPAID }
enum class PaymentStatus { PENDING, SUCCEEDED, FAILED, REFUNDED }

@Serializable
data class PlanFeatures(
    val maxChildren: Int = 1,
    val maxAudioHoursPerMonth: Int = 10,
    val premiumContent: Boolean = false,
    val advancedAnalytics: Boolean = false,
    val exportData: Boolean = false,
    val prioritySupport: Boolean = false,
    val customReports: Boolean = false
)

@Serializable
data class UsageData(
    val childrenCount: Int = 0,
    val audioHoursUsed: Int = 0,
    val contentViewsCount: Int = 0,
    val lastResetDate: String = ""
)

object Plans : UUIDTable("plans") {
    val name = varchar("name", 100).uniqueIndex()
    val type = enumerationByName<PlanType>("type", 20)
    val displayName = varchar("display_name", 100)
    val description = text("description").nullable()
    
    // Pricing
    val priceCents = integer("price_cents")
    val currency = varchar("currency", 3).default("USD")
    val billingCycle = enumerationByName<BillingCycle>("billing_cycle", 20)
    
    // Features
    val features = jsonb<PlanFeatures>("features", ::PlanFeatures, PlanFeatures::class)
    val maxChildren = integer("max_children").default(1)
    val maxAudioHoursPerMonth = integer("max_audio_hours_per_month").nullable()
    
    // Plan status
    val isActive = bool("is_active").default(true)
    val isVisible = bool("is_visible").default(true)
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp)
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp)
}

object UserSubscriptions : UUIDTable("user_subscriptions") {
    val userId = reference("user_id", Users)
    val planId = reference("plan_id", Plans)
    
    // Subscription details
    val status = enumerationByName<SubscriptionStatus>("status", 20)
    val startedAt = timestamp("started_at")
    val trialEndsAt = timestamp("trial_ends_at").nullable()
    val currentPeriodStartsAt = timestamp("current_period_starts_at")
    val currentPeriodEndsAt = timestamp("current_period_ends_at")
    val canceledAt = timestamp("canceled_at").nullable()
    val endedAt = timestamp("ended_at").nullable()
    
    // Billing integration
    val stripeSubscriptionId = varchar("stripe_subscription_id", 255).nullable().uniqueIndex()
    val stripeCustomerId = varchar("stripe_customer_id", 255).nullable()
    
    // Usage tracking
    val usageData = jsonb<UsageData>("usage_data", ::UsageData, UsageData::class).default(UsageData())
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp)
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp)
}

object Transactions : UUIDTable("transactions") {
    val subscriptionId = reference("subscription_id", UserSubscriptions).nullable()
    val userId = reference("user_id", Users)
    
    // Transaction details
    val amountCents = integer("amount_cents")
    val currency = varchar("currency", 3).default("USD")
    val description = text("description").nullable()
    val status = enumerationByName<PaymentStatus>("status", 20)
    
    // External payment processor
    val stripePaymentIntentId = varchar("stripe_payment_intent_id", 255).nullable()
    val stripeInvoiceId = varchar("stripe_invoice_id", 255).nullable()
    val paymentMethodId = varchar("payment_method_id", 255).nullable()
    
    // Timestamps
    val attemptedAt = timestamp("attempted_at").defaultExpression(CurrentTimestamp)
    val succeededAt = timestamp("succeeded_at").nullable()
    val failedAt = timestamp("failed_at").nullable()
    val refundedAt = timestamp("refunded_at").nullable()
    
    val failureReason = text("failure_reason").nullable()
    val metadata = jsonb<Map<String, String>>("metadata", { it }, Map::class).default(emptyMap())
}