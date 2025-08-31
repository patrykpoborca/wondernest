// Mock file service for development until backend is fixed
interface MockFile {
  id: string
  originalName: string
  mimeType: string
  fileSize: number
  category: string
  url: string
  uploadedAt: string
  metadata?: Record<string, any>
}

class MockFileService {
  private files: MockFile[] = []
  
  async uploadFile(
    file: File,
    category: string = 'game_asset',
    childId?: string,
    isPublic: boolean = false
  ): Promise<{ success: boolean; data: MockFile }> {
    // Simulate upload delay
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // Create a mock URL using blob
    const url = URL.createObjectURL(file)
    
    const mockFile: MockFile = {
      id: `file_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      originalName: file.name,
      mimeType: file.type,
      fileSize: file.size,
      category,
      url,
      uploadedAt: new Date().toISOString(),
      metadata: {
        childId,
        isPublic,
      }
    }
    
    // Store in local array (in real app, this would be in backend)
    this.files.push(mockFile)
    
    // Also store in localStorage for persistence across page reloads
    const storedFiles = JSON.parse(localStorage.getItem('mockUploadedFiles') || '[]')
    storedFiles.push(mockFile)
    localStorage.setItem('mockUploadedFiles', JSON.stringify(storedFiles))
    
    return {
      success: true,
      data: mockFile
    }
  }
  
  async getUserFiles(category?: string): Promise<{ success: boolean; data: MockFile[] }> {
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // Get files from localStorage
    const storedFiles = JSON.parse(localStorage.getItem('mockUploadedFiles') || '[]')
    
    // Also add some default mock images for testing
    const defaultImages: MockFile[] = [
      {
        id: 'mock_1',
        originalName: 'forest.jpg',
        mimeType: 'image/jpeg',
        fileSize: 245000,
        category: 'game_asset',
        url: 'https://picsum.photos/400/300?random=101',
        uploadedAt: new Date().toISOString(),
        metadata: {}
      },
      {
        id: 'mock_2',
        originalName: 'mountain.jpg',
        mimeType: 'image/jpeg',
        fileSize: 312000,
        category: 'game_asset',
        url: 'https://picsum.photos/400/300?random=102',
        uploadedAt: new Date().toISOString(),
        metadata: {}
      },
      {
        id: 'mock_3',
        originalName: 'ocean.jpg',
        mimeType: 'image/jpeg',
        fileSize: 198000,
        category: 'game_asset',
        url: 'https://picsum.photos/400/300?random=103',
        uploadedAt: new Date().toISOString(),
        metadata: {}
      }
    ]
    
    const allFiles = [...defaultImages, ...storedFiles, ...this.files]
    
    // Filter by category if provided
    const filteredFiles = category 
      ? allFiles.filter(f => f.category === category)
      : allFiles
    
    // Remove duplicates by ID
    const uniqueFiles = Array.from(
      new Map(filteredFiles.map(f => [f.id, f])).values()
    )
    
    return {
      success: true,
      data: uniqueFiles
    }
  }
  
  async deleteFile(fileId: string): Promise<{ success: boolean }> {
    // Remove from local array
    this.files = this.files.filter(f => f.id !== fileId)
    
    // Remove from localStorage
    const storedFiles = JSON.parse(localStorage.getItem('mockUploadedFiles') || '[]')
    const updatedFiles = storedFiles.filter((f: MockFile) => f.id !== fileId)
    localStorage.setItem('mockUploadedFiles', JSON.stringify(updatedFiles))
    
    return { success: true }
  }
  
  clearAllMockFiles(): void {
    this.files = []
    localStorage.removeItem('mockUploadedFiles')
  }
}

export const mockFileService = new MockFileService()
export type { MockFile }