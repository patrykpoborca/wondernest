import React, { useState, useCallback } from 'react'
import { useDropzone } from 'react-dropzone'
import { Upload, X, File, Image, FileText, AlertCircle } from 'lucide-react'
import { useUploadFileMutation } from '@/store/api/apiSlice'

interface FileUploadProps {
  onUploadComplete?: (file: any) => void
  accept?: Record<string, string[]>
  maxSize?: number
  category?: 'profile_picture' | 'content' | 'document' | 'game_asset' | 'artwork'
  childId?: string
  isPublic?: boolean
  className?: string
}

export const FileUpload: React.FC<FileUploadProps> = ({
  onUploadComplete,
  accept = {
    'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'],
    'application/pdf': ['.pdf'],
  },
  maxSize = 10 * 1024 * 1024, // 10MB default
  category = 'content',
  childId,
  isPublic = false,
  className = '',
}) => {
  const [uploadedFile, setUploadedFile] = useState<any>(null)
  const [uploadProgress, setUploadProgress] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [uploadFile, { isLoading }] = useUploadFileMutation()

  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    if (acceptedFiles.length === 0) return

    const file = acceptedFiles[0]
    setError(null)
    setUploadProgress(0)

    // Create FormData
    const formData = new FormData()
    formData.append('file', file)
    
    // Add query parameters
    const queryParams = new URLSearchParams()
    queryParams.append('category', category)
    if (childId) queryParams.append('childId', childId)
    queryParams.append('isPublic', isPublic.toString())

    try {
      // Simulate progress for demo
      const progressInterval = setInterval(() => {
        setUploadProgress(prev => {
          if (prev >= 90) {
            clearInterval(progressInterval)
            return prev
          }
          return prev + 10
        })
      }, 200)

      // Upload file
      const result = await uploadFile(formData).unwrap()
      
      clearInterval(progressInterval)
      setUploadProgress(100)
      setUploadedFile(result.data)
      
      if (onUploadComplete) {
        onUploadComplete(result.data)
      }
    } catch (err: any) {
      setError(err.data?.error?.message || 'Upload failed')
      setUploadProgress(0)
    }
  }, [uploadFile, category, childId, isPublic, onUploadComplete])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept,
    maxSize,
    multiple: false,
  })

  const getFileIcon = (mimeType: string) => {
    if (mimeType.startsWith('image/')) return <Image className="w-5 h-5" />
    if (mimeType === 'application/pdf') return <FileText className="w-5 h-5" />
    return <File className="w-5 h-5" />
  }

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  const handleRemove = () => {
    setUploadedFile(null)
    setUploadProgress(0)
    setError(null)
  }

  return (
    <div className={className}>
      {!uploadedFile ? (
        <div
          {...getRootProps()}
          className={`
            relative border-2 border-dashed rounded-lg p-6 text-center cursor-pointer
            transition-colors duration-200
            ${isDragActive ? 'border-blue-500 bg-blue-50' : 'border-gray-300 hover:border-gray-400'}
            ${isLoading ? 'opacity-50 pointer-events-none' : ''}
          `}
        >
          <input {...getInputProps()} />
          
          <Upload className="w-12 h-12 mx-auto mb-4 text-gray-400" />
          
          {isDragActive ? (
            <p className="text-blue-600 font-medium">Drop the file here...</p>
          ) : (
            <>
              <p className="text-gray-700 font-medium mb-1">
                Click to upload or drag and drop
              </p>
              <p className="text-sm text-gray-500">
                Maximum file size: {formatFileSize(maxSize)}
              </p>
            </>
          )}

          {isLoading && (
            <div className="absolute inset-0 flex items-center justify-center bg-white bg-opacity-90 rounded-lg">
              <div className="text-center">
                <div className="mb-2">
                  <div className="w-48 h-2 bg-gray-200 rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-blue-500 transition-all duration-300"
                      style={{ width: `${uploadProgress}%` }}
                    />
                  </div>
                </div>
                <p className="text-sm text-gray-600">Uploading... {uploadProgress}%</p>
              </div>
            </div>
          )}
        </div>
      ) : (
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex items-start justify-between">
            <div className="flex items-start space-x-3">
              <div className="flex-shrink-0 text-gray-500">
                {getFileIcon(uploadedFile.mimeType)}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 truncate">
                  {uploadedFile.originalName}
                </p>
                <p className="text-sm text-gray-500">
                  {formatFileSize(uploadedFile.fileSize)}
                </p>
                {uploadedFile.url && (
                  <a 
                    href={uploadedFile.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm text-blue-600 hover:text-blue-500"
                  >
                    View file
                  </a>
                )}
              </div>
            </div>
            <button
              onClick={handleRemove}
              className="flex-shrink-0 ml-4 text-gray-400 hover:text-gray-500"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>
      )}

      {error && (
        <div className="mt-2 flex items-center text-sm text-red-600">
          <AlertCircle className="w-4 h-4 mr-1" />
          {error}
        </div>
      )}
    </div>
  )
}

export default FileUpload