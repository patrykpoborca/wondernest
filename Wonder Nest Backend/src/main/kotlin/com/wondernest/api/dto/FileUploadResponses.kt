package com.wondernest.api.dto

import kotlinx.serialization.Serializable
import com.wondernest.domain.model.UploadedFileDto

@Serializable
data class FileUploadSuccessResponse(
    val success: Boolean = true,
    val data: UploadedFileDto
)

@Serializable
data class FileListSuccessResponse(
    val success: Boolean = true,
    val data: List<UploadedFileDto>
)

@Serializable
data class FileErrorResponse(
    val success: Boolean = false,
    val error: ErrorDetails
)

@Serializable
data class ErrorDetails(
    val code: String,
    val message: String
)

@Serializable
data class FileDeleteSuccessResponse(
    val success: Boolean = true,
    val message: String
)

@Serializable
data class FileUsageResponse(
    val isUsed: Boolean,
    val stories: List<StoryUsageInfo> = emptyList()
)

@Serializable
data class StoryUsageInfo(
    val id: String,
    val title: String,
    val pageCount: Int
)