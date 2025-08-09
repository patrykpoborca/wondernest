package com.wondernest.services.storage

class StorageService {
    suspend fun uploadFile(fileName: String, content: ByteArray): String {
        // TODO: Implement S3 upload
        return "https://example.com/uploads/$fileName"
    }
    
    suspend fun deleteFile(fileUrl: String): Boolean {
        // TODO: Implement S3 delete
        return true
    }
}