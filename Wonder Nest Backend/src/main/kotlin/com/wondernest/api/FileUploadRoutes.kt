package com.wondernest.api

import com.wondernest.data.database.table.UserRole
import com.wondernest.domain.model.FileCategory
import com.wondernest.domain.model.UploadedFileDto
import com.wondernest.domain.model.User
import com.wondernest.services.storage.FileUploadService
import io.ktor.http.*
import io.ktor.http.content.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.datetime.Clock
import mu.KotlinLogging
import org.koin.ktor.ext.inject
import java.util.*

private val logger = KotlinLogging.logger {}

/**
 * Extension function to extract authenticated user from JWT
 */
fun ApplicationCall.extractUser(): User {
    val principal = principal<JWTPrincipal>()
        ?: throw IllegalStateException("No JWT principal found")
    
    val userId = principal.payload.getClaim("userId").asString()
        ?: throw IllegalStateException("No userId in JWT")
    
    val email = principal.payload.getClaim("email").asString()
        ?: throw IllegalStateException("No email in JWT")
    
    val roleStr = principal.payload.getClaim("role").asString() ?: "parent"
    val role = when (roleStr.lowercase()) {
        "parent" -> UserRole.PARENT
        "admin" -> UserRole.ADMIN
        else -> UserRole.PARENT
    }
    
    return User(
        id = UUID.fromString(userId),
        email = email,
        firstName = principal.payload.getClaim("firstName").asString(),
        lastName = principal.payload.getClaim("lastName").asString(),
        role = role,
        createdAt = Clock.System.now(),
        updatedAt = Clock.System.now()
    )
}

/**
 * File upload routes
 */
fun Route.fileUploadRoutes() {
    val fileUploadService by inject<FileUploadService>()
    
    authenticate("auth-jwt") {
        route("/files") {
            
            // Upload file
            post("/upload") {
                try {
                    val user = call.extractUser()
                    val multipart = call.receiveMultipart()
                    
                    // Get query parameters
                    val category = call.request.queryParameters["category"]?.let { 
                        FileCategory.fromString(it) 
                    } ?: FileCategory.CONTENT
                    
                    val childId = call.request.queryParameters["childId"]?.let { 
                        UUID.fromString(it) 
                    }
                    
                    val isPublic = call.request.queryParameters["isPublic"]?.toBoolean() ?: false
                    
                    var uploadedFile: UploadedFileDto? = null
                    
                    multipart.forEachPart { part ->
                        when (part) {
                            is PartData.FileItem -> {
                                val fileName = part.originalFileName ?: "unknown"
                                val contentType = part.contentType?.toString() ?: "application/octet-stream"
                                
                                // Upload file
                                val file = fileUploadService.uploadFile(
                                    user = user,
                                    fileName = fileName,
                                    contentType = contentType,
                                    inputStream = part.streamProvider(),
                                    category = category,
                                    childId = childId,
                                    isPublic = isPublic
                                )
                                
                                uploadedFile = UploadedFileDto(
                                    id = file.id.toString(),
                                    originalName = file.originalName,
                                    mimeType = file.mimeType,
                                    fileSize = file.fileSize,
                                    category = file.category.toDbValue(),
                                    url = file.url,
                                    uploadedAt = file.uploadedAt.toString(),
                                    metadata = file.metadata
                                )
                            }
                            else -> {}
                        }
                        part.dispose()
                    }
                    
                    if (uploadedFile != null) {
                        call.respond(HttpStatusCode.Created, mapOf(
                            "success" to true,
                            "data" to uploadedFile
                        ))
                    } else {
                        call.respond(HttpStatusCode.BadRequest, mapOf(
                            "success" to false,
                            "error" to mapOf(
                                "code" to "NO_FILE",
                                "message" to "No file provided in the request"
                            )
                        ))
                    }
                } catch (e: IllegalArgumentException) {
                    logger.error(e) { "File validation failed" }
                    call.respond(HttpStatusCode.BadRequest, mapOf(
                        "success" to false,
                        "error" to mapOf(
                            "code" to "VALIDATION_ERROR",
                            "message" to e.message
                        )
                    ))
                } catch (e: Exception) {
                    logger.error(e) { "File upload failed" }
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "success" to false,
                        "error" to mapOf(
                            "code" to "UPLOAD_FAILED",
                            "message" to "Failed to upload file"
                        )
                    ))
                }
            }
            
            // Get file metadata
            get("/{fileId}") {
                try {
                    val user = call.extractUser()
                    val fileId = UUID.fromString(call.parameters["fileId"])
                    
                    val file = fileUploadService.getFile(fileId, user.id)
                    
                    if (file != null) {
                        val dto = UploadedFileDto(
                            id = file.id.toString(),
                            originalName = file.originalName,
                            mimeType = file.mimeType,
                            fileSize = file.fileSize,
                            category = file.category.toDbValue(),
                            url = file.url,
                            uploadedAt = file.uploadedAt.toString(),
                            metadata = file.metadata
                        )
                        
                        call.respond(HttpStatusCode.OK, mapOf(
                            "success" to true,
                            "data" to dto
                        ))
                    } else {
                        call.respond(HttpStatusCode.NotFound, mapOf(
                            "success" to false,
                            "error" to mapOf(
                                "code" to "FILE_NOT_FOUND",
                                "message" to "File not found"
                            )
                        ))
                    }
                } catch (e: Exception) {
                    logger.error(e) { "Failed to get file" }
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "success" to false,
                        "error" to mapOf(
                            "code" to "GET_FAILED",
                            "message" to "Failed to get file"
                        )
                    ))
                }
            }
            
            // Download file
            get("/{fileId}/download") {
                try {
                    val user = call.extractUser()
                    val fileId = UUID.fromString(call.parameters["fileId"])
                    
                    val file = fileUploadService.getFile(fileId, user.id)
                    val data = file?.let { fileUploadService.downloadFile(fileId, user.id) }
                    
                    if (file != null && data != null) {
                        call.response.header(
                            HttpHeaders.ContentDisposition, 
                            ContentDisposition.Attachment
                                .withParameter(ContentDisposition.Parameters.FileName, file.originalName)
                                .toString()
                        )
                        call.respondBytes(
                            data,
                            ContentType.parse(file.mimeType),
                            HttpStatusCode.OK
                        )
                    } else {
                        call.respond(HttpStatusCode.NotFound, mapOf(
                            "success" to false,
                            "error" to mapOf(
                                "code" to "FILE_NOT_FOUND",
                                "message" to "File not found"
                            )
                        ))
                    }
                } catch (e: Exception) {
                    logger.error(e) { "Failed to download file" }
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "success" to false,
                        "error" to mapOf(
                            "code" to "DOWNLOAD_FAILED",
                            "message" to "Failed to download file"
                        )
                    ))
                }
            }
            
            // Delete file
            delete("/{fileId}") {
                try {
                    val user = call.extractUser()
                    val fileId = UUID.fromString(call.parameters["fileId"])
                    
                    val deleted = fileUploadService.deleteFile(fileId, user.id)
                    
                    if (deleted) {
                        call.respond(HttpStatusCode.OK, mapOf(
                            "success" to true,
                            "message" to "File deleted successfully"
                        ))
                    } else {
                        call.respond(HttpStatusCode.NotFound, mapOf(
                            "success" to false,
                            "error" to mapOf(
                                "code" to "FILE_NOT_FOUND",
                                "message" to "File not found"
                            )
                        ))
                    }
                } catch (e: Exception) {
                    logger.error(e) { "Failed to delete file" }
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "success" to false,
                        "error" to mapOf(
                            "code" to "DELETE_FAILED",
                            "message" to "Failed to delete file"
                        )
                    ))
                }
            }
            
            // List user's files
            get {
                try {
                    val user = call.extractUser()
                    
                    val category = call.request.queryParameters["category"]?.let { 
                        FileCategory.fromString(it) 
                    }
                    
                    val childId = call.request.queryParameters["childId"]?.let { 
                        UUID.fromString(it) 
                    }
                    
                    val limit = call.request.queryParameters["limit"]?.toIntOrNull() ?: 100
                    val offset = call.request.queryParameters["offset"]?.toIntOrNull() ?: 0
                    
                    val files = fileUploadService.listUserFiles(
                        userId = user.id,
                        category = category,
                        childId = childId,
                        limit = limit,
                        offset = offset
                    )
                    
                    val dtos = files.map { file ->
                        UploadedFileDto(
                            id = file.id.toString(),
                            originalName = file.originalName,
                            mimeType = file.mimeType,
                            fileSize = file.fileSize,
                            category = file.category.toDbValue(),
                            url = file.url,
                            uploadedAt = file.uploadedAt.toString(),
                            metadata = file.metadata
                        )
                    }
                    
                    call.respond(HttpStatusCode.OK, mapOf(
                        "success" to true,
                        "data" to dtos
                    ))
                } catch (e: Exception) {
                    logger.error(e) { "Failed to list files" }
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "success" to false,
                        "error" to mapOf(
                            "code" to "LIST_FAILED",
                            "message" to "Failed to list files"
                        )
                    ))
                }
            }
        }
    }
}