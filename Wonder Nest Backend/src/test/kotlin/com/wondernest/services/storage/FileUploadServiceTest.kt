package com.wondernest.services.storage

import com.wondernest.data.database.table.UserRole
import com.wondernest.domain.model.FileCategory
import com.wondernest.domain.model.User
import kotlinx.coroutines.runBlocking
import kotlinx.datetime.Clock
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.io.ByteArrayInputStream
import java.nio.file.Path
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.test.assertFailsWith

class FileUploadServiceTest {
    
    @TempDir
    lateinit var tempDir: Path
    
    private lateinit var storageProvider: StorageProvider
    private lateinit var validationService: FileValidationService
    private lateinit var fileUploadService: FileUploadService
    
    private val testUser = User(
        id = UUID.randomUUID(),
        email = "test@example.com",
        firstName = "Test",
        lastName = "User",
        role = UserRole.PARENT,
        createdAt = Clock.System.now(),
        updatedAt = Clock.System.now()
    )
    
    @BeforeEach
    fun setUp() {
        storageProvider = LocalStorageProvider(
            basePath = tempDir.toString(),
            baseUrl = "http://localhost:8080"
        )
        validationService = FileValidationService()
        fileUploadService = FileUploadService(storageProvider, validationService)
    }
    
    @Test
    fun `test upload valid image file`() = runBlocking {
        // Create a simple PNG header (8 bytes PNG signature)
        val pngHeader = byteArrayOf(
            0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
        )
        val inputStream = ByteArrayInputStream(pngHeader)
        
        val result = fileUploadService.uploadFile(
            user = testUser,
            fileName = "test.png",
            contentType = "image/png",
            inputStream = inputStream,
            category = FileCategory.CONTENT
        )
        
        assertNotNull(result)
        assertEquals("test.png", result.originalName)
        assertEquals("image/png", result.mimeType)
        assertEquals(FileCategory.CONTENT, result.category)
        assertEquals(testUser.id, result.userId)
    }
    
    @Test
    fun `test upload file with invalid MIME type`() = runBlocking {
        val content = "test content".toByteArray()
        val inputStream = ByteArrayInputStream(content)
        
        assertFailsWith<IllegalArgumentException> {
            fileUploadService.uploadFile(
                user = testUser,
                fileName = "test.exe",
                contentType = "application/x-msdownload",
                inputStream = inputStream,
                category = FileCategory.CONTENT
            )
        }
    }
    
    @Test
    fun `test upload file exceeding size limit`() = runBlocking {
        // Create a large byte array (11 MB)
        val largeContent = ByteArray(11 * 1024 * 1024)
        val inputStream = ByteArrayInputStream(largeContent)
        
        assertFailsWith<IllegalArgumentException> {
            fileUploadService.uploadFile(
                user = testUser,
                fileName = "large.jpg",
                contentType = "image/jpeg",
                inputStream = inputStream,
                category = FileCategory.CONTENT
            )
        }
    }
    
    @Test
    fun `test file validation service`() {
        val validationService = FileValidationService()
        
        // Test valid file
        val validResult = validationService.validateFile(
            fileName = "test.jpg",
            contentType = "image/jpeg",
            fileSize = 1024 * 1024 // 1 MB
        )
        assertTrue(validResult.isValid)
        
        // Test invalid extension
        val invalidExtResult = validationService.validateFile(
            fileName = "test.exe",
            contentType = "application/x-msdownload",
            fileSize = 1024
        )
        assertTrue(!invalidExtResult.isValid)
        assertEquals("File type not allowed", invalidExtResult.error)
        
        // Test file too large
        val tooLargeResult = validationService.validateFile(
            fileName = "test.jpg",
            contentType = "image/jpeg",
            fileSize = 11 * 1024 * 1024 // 11 MB
        )
        assertTrue(!tooLargeResult.isValid)
        assertEquals("File size exceeds maximum allowed size of 10MB", tooLargeResult.error)
    }
    
    @Test
    fun `test local storage provider upload and download`() = runBlocking {
        val content = "Test file content"
        val inputStream = ByteArrayInputStream(content.toByteArray())
        
        val uploadResult = storageProvider.upload(
            fileName = "test.txt",
            contentType = "text/plain",
            inputStream = inputStream,
            metadata = mapOf("userId" to testUser.id.toString())
        )
        
        assertNotNull(uploadResult)
        assertTrue(uploadResult.key.isNotEmpty())
        assertEquals(content.length.toLong(), uploadResult.size)
        
        // Test download
        val downloadedContent = storageProvider.download(uploadResult.key)
        assertNotNull(downloadedContent)
        assertEquals(content, String(downloadedContent))
        
        // Test delete
        val deleted = storageProvider.delete(uploadResult.key)
        assertTrue(deleted)
        
        // Verify file is deleted
        val afterDelete = storageProvider.download(uploadResult.key)
        assertEquals(null, afterDelete)
    }
    
    @Test
    fun `test file content validation with magic bytes`() {
        val validationService = FileValidationService()
        
        // Test valid JPEG
        val jpegHeader = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte())
        val jpegStream = ByteArrayInputStream(jpegHeader)
        jpegStream.mark(16)
        assertTrue(validationService.validateFileContent(jpegStream, "image/jpeg"))
        
        // Test valid PNG
        val pngHeader = byteArrayOf(
            0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
        )
        val pngStream = ByteArrayInputStream(pngHeader)
        pngStream.mark(16)
        assertTrue(validationService.validateFileContent(pngStream, "image/png"))
        
        // Test invalid content for declared type
        val textContent = "Not an image".toByteArray()
        val textStream = ByteArrayInputStream(textContent)
        textStream.mark(16)
        assertTrue(!validationService.validateFileContent(textStream, "image/jpeg"))
    }
    
    @Test
    fun `test upload with metadata and category`() = runBlocking {
        val pngHeader = byteArrayOf(
            0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
        )
        val inputStream = ByteArrayInputStream(pngHeader)
        
        val childId = UUID.randomUUID()
        val metadata = mapOf(
            "description" to "Child artwork",
            "tags" to "drawing,creative"
        )
        
        val result = fileUploadService.uploadFile(
            user = testUser,
            fileName = "artwork.png",
            contentType = "image/png",
            inputStream = inputStream,
            category = FileCategory.ARTWORK,
            childId = childId,
            isPublic = false,
            metadata = metadata
        )
        
        assertNotNull(result)
        assertEquals(FileCategory.ARTWORK, result.category)
        assertEquals(childId, result.childId)
        assertEquals(false, result.isPublic)
        assertEquals("Child artwork", result.metadata["description"])
        assertEquals("drawing,creative", result.metadata["tags"])
    }
}