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