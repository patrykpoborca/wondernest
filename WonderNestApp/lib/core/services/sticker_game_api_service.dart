import 'package:flutter/material.dart';
import 'api_service.dart';
import '../../games/sticker_book/models/sticker_models.dart';
import '../services/timber_wrapper.dart';

/// API service specifically for sticker game functionality
class StickerGameApiService {
  final ApiService _apiService = ApiService();
  
  // =============================================================================
  // GAME INITIALIZATION
  // =============================================================================
  
  /// Initialize sticker game for a child
  Future<StickerGameInitResponse> initializeStickerGame(String childId, {int? ageMonths}) async {
    try {
      Timber.i('[StickerGameAPI] Initializing sticker game for child: $childId');
      
      final response = await _apiService.saveGameEvent({
        'gameType': 'sticker_book',
        'eventType': 'initialize',
        'childId': childId,
        if (ageMonths != null) 'ageMonths': ageMonths.toString(),
      });
      
      return StickerGameInitResponse.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to initialize sticker game: $e');
      // Return mock data for development
      return _getMockInitResponse(childId);
    }
  }
  
  // =============================================================================
  // STICKER SETS AND COLLECTIONS
  // =============================================================================
  
  /// Get available sticker sets for child's age
  Future<List<StickerPack>> getAvailableStickerSets(String childId, {String? theme}) async {
    try {
      Timber.i('[StickerGameAPI] Getting available sticker sets for child: $childId');
      
      final queryParams = <String, dynamic>{};
      if (theme != null) queryParams['theme'] = theme;
      
      final response = await _apiService.getChildGameData(childId);
      
      final data = response.data['data'] ?? response.data;
      final stickerSets = (data['stickerSets'] as List)
          .map((set) => _convertToStickerPack(set))
          .toList();
      
      return stickerSets;
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to get sticker sets: $e');
      // Return mock data
      return _getMockStickerPacks();
    }
  }
  
  /// Get child's unlocked sticker collections
  Future<List<StickerPack>> getChildStickerCollections(String childId) async {
    try {
      Timber.i('[StickerGameAPI] Getting sticker collections for child: $childId');
      
      final response = await _apiService.getChildGameData(childId);
      
      final data = response.data['data'] ?? response.data;
      final collections = (data['collections'] as List)
          .map((collection) => _convertToStickerPack(collection['stickerSet']))
          .toList();
      
      return collections;
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to get sticker collections: $e');
      // Return mock data
      return _getMockStickerPacks().where((pack) => pack.isUnlocked).toList();
    }
  }
  
  /// Unlock a sticker set for child
  Future<bool> unlockStickerSet(String childId, String stickerSetId) async {
    try {
      Timber.i('[StickerGameAPI] Unlocking sticker set $stickerSetId for child: $childId');
      
      final response = await _apiService.saveGameEvent({
        'gameType': 'sticker_book',
        'eventType': 'unlock_sticker_set',
        'childId': childId,
        'stickerSetId': stickerSetId,
      });
      
      return response.statusCode == 200;
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to unlock sticker set: $e');
      return false;
    }
  }
  
  // =============================================================================
  // STICKER BOOK PROJECTS
  // =============================================================================
  
  /// Get child's sticker book projects
  Future<List<StickerBookProject>> getChildProjects(String childId) async {
    try {
      Timber.i('[StickerGameAPI] Getting projects for child: $childId');
      
      final response = await _apiService.getChildGameData(childId);
      
      final data = response.data['data'] ?? response.data;
      final projects = (data['projects'] as List)
          .map((project) => _convertToStickerBookProject(project))
          .toList();
      
      return projects;
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to get projects: $e');
      // Return mock data
      return _getMockProjects();
    }
  }
  
  /// Create new sticker book project
  Future<StickerBookProject> createProject({
    required String childId,
    required String name,
    required CreationMode mode,
    String? templateId,
    String? description,
  }) async {
    try {
      Timber.i('[StickerGameAPI] Creating project "$name" for child: $childId');
      
      final response = await _apiService.saveGameEvent({
        'gameType': 'sticker_book',
        'eventType': 'create_project',
        'childId': childId,
        'projectData': {
          'name': name,
          'mode': mode.name,
          if (templateId != null) 'templateId': templateId,
          if (description != null) 'description': description,
        },
      });
      
      final data = response.data['data'] ?? response.data;
      return _convertToStickerBookProject(data);
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to create project: $e');
      // Return mock project
      return _createMockProject(name, mode);
    }
  }
  
  /// Get specific project
  Future<StickerBookProject?> getProject(String childId, String projectId) async {
    try {
      Timber.i('[StickerGameAPI] Getting project $projectId for child: $childId');
      
      final response = await _apiService.getChildGameData(childId);
      
      final data = response.data['data'] ?? response.data;
      return _convertToStickerBookProject(data);
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to get project: $e');
      return null;
    }
  }
  
  /// Update project data
  Future<StickerBookProject?> updateProject({
    required String childId,
    required String projectId,
    required Map<String, dynamic> projectData,
    String? sessionId,
  }) async {
    try {
      Timber.i('[StickerGameAPI] Updating project $projectId for child: $childId');
      
      final response = await _apiService.saveGameEvent({
        'gameType': 'sticker_book',
        'eventType': 'update_project',
        'childId': childId,
        'projectId': projectId,
        'projectData': projectData,
        if (sessionId != null) 'sessionId': sessionId,
      });
      
      final data = response.data['data'] ?? response.data;
      return _convertToStickerBookProject(data);
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to update project: $e');
      return null;
    }
  }
  
  /// Delete project
  Future<bool> deleteProject(String childId, String projectId) async {
    try {
      Timber.i('[StickerGameAPI] Deleting project $projectId for child: $childId');
      
      final response = await _apiService.saveGameEvent({
        'gameType': 'sticker_book',
        'eventType': 'delete_project',
        'childId': childId,
        'projectId': projectId,
      });
      
      return response.statusCode == 200;
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to delete project: $e');
      return false;
    }
  }
  
  // =============================================================================
  // GAME SESSIONS
  // =============================================================================
  
  /// Start a new game session
  Future<GameSession?> startGameSession({
    required String childId,
    String? deviceType,
    String? appVersion,
  }) async {
    try {
      Timber.i('[StickerGameAPI] Starting game session for child: $childId');
      
      final response = await _apiService.saveGameEvent({
        'gameType': 'sticker_book',
        'eventType': 'start_session',
        'childId': childId,
        'deviceInfo': {
          if (deviceType != null) 'deviceType': deviceType,
          if (appVersion != null) 'appVersion': appVersion,
        },
      });
      
      final data = response.data['data'] ?? response.data;
      return GameSession.fromJson(data);
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to start game session: $e');
      return null;
    }
  }
  
  /// End game session
  Future<bool> endGameSession(String sessionId, Map<String, dynamic> finalMetrics) async {
    try {
      Timber.i('[StickerGameAPI] Ending game session: $sessionId');
      
      final response = await _apiService.saveGameEvent({
        'gameType': 'sticker_book',
        'eventType': 'end_session',
        'sessionId': sessionId,
        'finalMetrics': finalMetrics,
      });
      
      return response.statusCode == 200;
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to end game session: $e');
      return false;
    }
  }
  
  // =============================================================================
  // ANALYTICS AND PROGRESS
  // =============================================================================
  
  /// Record sticker interaction
  Future<bool> recordInteraction({
    required String childId,
    required String projectId,
    required String sessionId,
    required String interactionType,
    required Map<String, dynamic> interactionData,
  }) async {
    try {
      Timber.d('[StickerGameAPI] Recording interaction: $interactionType');
      
      final response = await _apiService.saveGameEvent({
        'gameType': 'sticker_book',
        'eventType': 'interaction',
        'childId': childId,
        'projectId': projectId,
        'sessionId': sessionId,
        'interactionType': interactionType,
        'interactionData': interactionData,
      });
      
      return response.statusCode == 200;
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to record interaction: $e');
      return false;
    }
  }
  
  /// Get child's sticker game progress
  Future<StickerGameProgress> getChildProgress(String childId) async {
    try {
      Timber.i('[StickerGameAPI] Getting progress for child: $childId');
      
      final response = await _apiService.getChildGameData(childId);
      
      final data = response.data['data'] ?? response.data;
      return StickerGameProgress.fromJson(data);
    } catch (e) {
      Timber.e('[StickerGameAPI] Failed to get progress: $e');
      // Return mock progress
      return _getMockProgress();
    }
  }
  
  // =============================================================================
  // HELPER METHODS AND CONVERTERS
  // =============================================================================
  
  StickerPack _convertToStickerPack(Map<String, dynamic> data) {
    final stickerData = (data['stickerData'] as List)
        .map((sticker) => Sticker.fromJson(sticker))
        .toList();
    
    return StickerPack(
      id: data['id'] ?? 'unknown',
      name: data['name'] ?? 'Unknown Pack',
      description: data['description'] ?? '',
      category: StickerCategory.values.firstWhere(
        (cat) => cat.name == data['theme'],
        orElse: () => StickerCategory.custom,
      ),
      stickers: stickerData,
      isUnlocked: data['isUnlocked'] ?? false,
      isPremium: data['isPremium'] ?? false,
    );
  }
  
  StickerBookProject _convertToStickerBookProject(Map<String, dynamic> data) {
    final creationMode = CreationMode.values.firstWhere(
      (mode) => mode.name == data['creationMode'],
      orElse: () => CreationMode.infiniteCanvas,
    );
    
    final projectData = data['projectData'] as Map<String, dynamic>? ?? {};
    
    // Convert project data to appropriate canvas/flipbook structure
    CreativeCanvas? canvas;
    FlipBook? flipBook;
    
    if (creationMode == CreationMode.infiniteCanvas && projectData.containsKey('canvas')) {
      canvas = CreativeCanvas.fromJson(projectData['canvas']);
    } else if (creationMode == CreationMode.flipBook && projectData.containsKey('flipBook')) {
      flipBook = FlipBook.fromJson(projectData['flipBook']);
    }
    
    return StickerBookProject(
      id: data['id'] ?? 'unknown',
      name: data['projectName'] ?? 'Untitled Project',
      description: data['description'] ?? '',
      mode: creationMode,
      infiniteCanvas: canvas,
      flipBook: flipBook,
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      lastModified: DateTime.tryParse(data['lastModified'] ?? '') ?? DateTime.now(),
      thumbnailPath: data['thumbnailUrl'],
    );
  }
  
  // =============================================================================
  // MOCK DATA FOR OFFLINE DEVELOPMENT
  // =============================================================================
  
  StickerGameInitResponse _getMockInitResponse(String childId) {
    return StickerGameInitResponse(
      success: true,
      message: 'Sticker game initialized (mock)',
      data: {
        'childId': childId,
        'gameInstanceId': 'mock-instance-id',
        'availableStickerSets': _getMockStickerPacks().map((pack) => pack.toJson()).toList(),
      },
    );
  }
  
  List<StickerPack> _getMockStickerPacks() {
    return [
      StickerPack(
        id: 'animals_basic',
        name: 'Farm Animals',
        description: 'Cute farm animals for your creations',
        category: StickerCategory.animals,
        stickers: [
          const Sticker(id: 'cow_1', name: 'Happy Cow', emoji: '🐄', category: StickerCategory.animals),
          const Sticker(id: 'pig_1', name: 'Little Pig', emoji: '🐷', category: StickerCategory.animals),
          const Sticker(id: 'chicken_1', name: 'Chicken', emoji: '🐔', category: StickerCategory.animals),
        ],
        isUnlocked: true,
      ),
      StickerPack(
        id: 'shapes_basic',
        name: 'Basic Shapes',
        description: 'Fundamental shapes in bright colors',
        category: StickerCategory.shapes,
        stickers: [
          const Sticker(id: 'circle_red', name: 'Red Circle', emoji: '🔴', category: StickerCategory.shapes),
          const Sticker(id: 'square_blue', name: 'Blue Square', emoji: '🟦', category: StickerCategory.shapes),
          const Sticker(id: 'triangle_green', name: 'Green Triangle', emoji: '🔺', category: StickerCategory.shapes),
        ],
        isUnlocked: true,
      ),
      StickerPack(
        id: 'vehicles_basic',
        name: 'Vehicles',
        description: 'Cars, trucks, and transportation',
        category: StickerCategory.vehicles,
        stickers: [
          const Sticker(id: 'car_red', name: 'Red Car', emoji: '🚗', category: StickerCategory.vehicles),
          const Sticker(id: 'truck_blue', name: 'Blue Truck', emoji: '🚚', category: StickerCategory.vehicles),
          const Sticker(id: 'plane_white', name: 'Airplane', emoji: '✈️', category: StickerCategory.vehicles),
        ],
        isUnlocked: false,
        isPremium: true,
      ),
    ];
  }
  
  List<StickerBookProject> _getMockProjects() {
    final now = DateTime.now();
    return [
      StickerBookProject(
        id: 'project_1',
        name: 'My Farm Scene',
        description: 'A beautiful farm with animals',
        mode: CreationMode.infiniteCanvas,
        infiniteCanvas: CreativeCanvas.infinite(
          id: 'canvas_1',
          name: 'Farm Canvas',
          background: const CanvasBackground(
            id: 'farm_bg',
            name: 'Farm Background',
            backgroundColor: Colors.lightGreen,
          ),
          createdAt: now.subtract(const Duration(days: 2)),
          lastModified: now.subtract(const Duration(hours: 3)),
          viewport: const CanvasViewport(screenSize: Size(800, 600)),
        ),
        createdAt: now.subtract(const Duration(days: 2)),
        lastModified: now.subtract(const Duration(hours: 3)),
      ),
      StickerBookProject(
        id: 'project_2',
        name: 'My Story Book',
        description: 'A flip book story about adventure',
        mode: CreationMode.flipBook,
        flipBook: FlipBook(
          id: 'flipbook_1',
          name: 'Adventure Story',
          createdAt: now.subtract(const Duration(days: 1)),
          lastModified: now.subtract(const Duration(minutes: 30)),
          pages: [],
        ),
        createdAt: now.subtract(const Duration(days: 1)),
        lastModified: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }
  
  StickerBookProject _createMockProject(String name, CreationMode mode) {
    final now = DateTime.now();
    final projectId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    
    if (mode == CreationMode.infiniteCanvas) {
      return StickerBookProject(
        id: projectId,
        name: name,
        mode: mode,
        infiniteCanvas: CreativeCanvas.infinite(
          id: '${projectId}_canvas',
          name: name,
          background: const CanvasBackground(
            id: 'default',
            name: 'White Background',
            backgroundColor: Colors.white,
          ),
          createdAt: now,
          lastModified: now,
          viewport: const CanvasViewport(screenSize: Size(800, 600)),
        ),
        createdAt: now,
        lastModified: now,
      );
    } else {
      return StickerBookProject(
        id: projectId,
        name: name,
        mode: mode,
        flipBook: FlipBook(
          id: '${projectId}_flipbook',
          name: name,
          createdAt: now,
          lastModified: now,
          pages: [],
        ),
        createdAt: now,
        lastModified: now,
      );
    }
  }
  
  StickerGameProgress _getMockProgress() {
    return const StickerGameProgress(
      totalProjects: 2,
      completedProjects: 1,
      totalPlayTimeMinutes: 45,
      unlockedStickerSets: 2,
      totalStickersUsed: 15,
      achievementsUnlocked: 3,
      favoriteTheme: 'animals',
      skillMetrics: {
        'creativity': 85.0,
        'fine_motor_skills': 78.0,
        'problem_solving': 82.0,
      },
    );
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

class StickerGameInitResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> data;
  
  StickerGameInitResponse({
    required this.success,
    required this.message,
    required this.data,
  });
  
  factory StickerGameInitResponse.fromJson(Map<String, dynamic> json) {
    return StickerGameInitResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: json['data'] ?? json,
    );
  }
}

class GameSession {
  final String id;
  final String childGameInstanceId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? deviceType;
  final String? appVersion;
  final Map<String, dynamic> sessionData;
  
  GameSession({
    required this.id,
    required this.childGameInstanceId,
    required this.startedAt,
    this.endedAt,
    this.deviceType,
    this.appVersion,
    this.sessionData = const {},
  });
  
  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['sessionId'] ?? json['id'],
      childGameInstanceId: json['childGameInstanceId'] ?? '',
      startedAt: DateTime.tryParse(json['startedAt'] ?? '') ?? DateTime.now(),
      endedAt: json['endedAt'] != null ? DateTime.tryParse(json['endedAt']) : null,
      deviceType: json['deviceType'],
      appVersion: json['appVersion'],
      sessionData: json['sessionData'] ?? {},
    );
  }
}

class StickerGameProgress {
  final int totalProjects;
  final int completedProjects;
  final int totalPlayTimeMinutes;
  final int unlockedStickerSets;
  final int totalStickersUsed;
  final int achievementsUnlocked;
  final String? favoriteTheme;
  final Map<String, double> skillMetrics;
  
  const StickerGameProgress({
    required this.totalProjects,
    required this.completedProjects,
    required this.totalPlayTimeMinutes,
    required this.unlockedStickerSets,
    required this.totalStickersUsed,
    required this.achievementsUnlocked,
    this.favoriteTheme,
    this.skillMetrics = const {},
  });
  
  factory StickerGameProgress.fromJson(Map<String, dynamic> json) {
    return StickerGameProgress(
      totalProjects: json['totalProjects'] ?? 0,
      completedProjects: json['completedProjects'] ?? 0,
      totalPlayTimeMinutes: json['totalPlayTimeMinutes'] ?? 0,
      unlockedStickerSets: json['unlockedStickerSets'] ?? 0,
      totalStickersUsed: json['totalStickersUsed'] ?? 0,
      achievementsUnlocked: json['achievementsUnlocked'] ?? 0,
      favoriteTheme: json['favoriteTheme'],
      skillMetrics: Map<String, double>.from(json['skillMetrics'] ?? {}),
    );
  }
}