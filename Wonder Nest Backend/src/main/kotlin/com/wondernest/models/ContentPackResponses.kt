package com.wondernest.models

import kotlinx.serialization.Serializable

@Serializable
data class ContentPackResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: String? = null
)

@Serializable
data class CategoriesData(
    val categories: List<ContentPackCategory>
)

@Serializable
data class PacksData(
    val packs: List<ContentPack>
)

@Serializable
data class PackData(
    val pack: ContentPack
)

@Serializable
data class AssetsData(
    val assets: List<ContentPackAsset>
)

@Serializable
data class MessageData(
    val message: String
)