import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/sticker_game_api_service.dart';
import '../core/services/api_service.dart';
import '../games/sticker_book/models/sticker_models.dart';
import '../games/sticker_book/services/saved_projects_service.dart';
import '../core/services/timber_wrapper.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Provider for the Sticker Game API Service
final stickerGameApiServiceProvider = Provider<StickerGameApiService>((ref) {
  return StickerGameApiService();
});

/// Provider for the Saved Projects Service with child context
final savedProjectsServiceProvider = Provider.family<SavedProjectsService, String?>((ref, childId) {
  final service = SavedProjectsService();
  final apiService = ApiService();
  
  // Initialize with child context when available
  if (childId != null) {
    service.initialize(childId: childId, apiService: apiService);
  }
  
  return service;
});

/// Provider for sticker game state management
final stickerGameStateProvider = StateNotifierProvider.family<StickerGameStateNotifier, StickerBookGameState, String>(
  (ref, childId) {
    final apiService = ref.watch(stickerGameApiServiceProvider);
    return StickerGameStateNotifier(childId, apiService);
  },
);

/// Provider for available sticker packs
final availableStickerPacksProvider = FutureProvider.family<List<StickerPack>, String>((ref, childId) async {
  final apiService = ref.watch(stickerGameApiServiceProvider);
  return await apiService.getAvailableStickerSets(childId);
});

/// Provider for child's unlocked sticker collections
final childStickerCollectionsProvider = FutureProvider.family<List<StickerPack>, String>((ref, childId) async {
  final apiService = ref.watch(stickerGameApiServiceProvider);
  return await apiService.getChildStickerCollections(childId);
});

/// Provider for child's sticker book projects
final childProjectsProvider = FutureProvider.family<List<StickerBookProject>, String>((ref, childId) async {
  final apiService = ref.watch(stickerGameApiServiceProvider);
  return await apiService.getChildProjects(childId);
});

/// Provider for child's game progress
final stickerGameProgressProvider = FutureProvider.family<StickerGameProgress, String>((ref, childId) async {
  final apiService = ref.watch(stickerGameApiServiceProvider);
  return await apiService.getChildProgress(childId);
});

/// Provider for saved projects with child context and age mode filtering
final savedProjectsProvider = FutureProvider.family<List<SavedProject>, ({String? childId, AgeMode ageMode})>((ref, params) async {
  final savedProjectsService = ref.watch(savedProjectsServiceProvider(params.childId));
  
  // Ensure service is initialized
  if (params.childId != null) {
    final apiService = ApiService();
    await savedProjectsService.initialize(childId: params.childId, apiService: apiService);
  } else {
    await savedProjectsService.initialize();
  }
  
  final allProjects = await savedProjectsService.getSavedProjects();
  
  // Filter by age mode
  return allProjects.where((project) => project.ageMode == params.ageMode).toList();
});

/// Provider for saved project count with child context
final savedProjectCountProvider = FutureProvider.family<int, String?>((ref, childId) async {
  final savedProjectsService = ref.watch(savedProjectsServiceProvider(childId));
  
  // Ensure service is initialized
  if (childId != null) {
    final apiService = ApiService();
    await savedProjectsService.initialize(childId: childId, apiService: apiService);
  } else {
    await savedProjectsService.initialize();
  }
  
  return await savedProjectsService.getSavedProjectCount();
});

// =============================================================================
// STATE NOTIFIER
// =============================================================================

class StickerGameStateNotifier extends StateNotifier<StickerBookGameState> {
  final String childId;
  final StickerGameApiService _apiService;
  
  GameSession? _currentSession;
  bool _isInitialized = false;
  
  StickerGameStateNotifier(this.childId, this._apiService) : super(const StickerBookGameState()) {
    _initializeGame();
  }
  
  /// Set up SavedProjectsService with child context
  SavedProjectsService? _savedProjectsService;
  
  void _initializeSavedProjects() {
    _savedProjectsService = SavedProjectsService();
    _savedProjectsService!.initialize(
      childId: childId, 
      apiService: ApiService(),
    ).catchError((error) {
      Timber.w('[StickerGameProvider] Failed to initialize SavedProjectsService: $error');
    });
  }
  
  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  
  Future<void> _initializeGame() async {
    if (_isInitialized) return;
    
    try {
      Timber.i('[StickerGameProvider] Initializing sticker game for child: $childId');
      
      // Initialize SavedProjectsService first
      _initializeSavedProjects();
      
      // Initialize the game with the backend
      await _apiService.initializeStickerGame(childId);
      
      // Load child's projects and collections
      final projects = await _apiService.getChildProjects(childId);
      final collections = await _apiService.getChildStickerCollections(childId);
      final availablePacks = await _apiService.getAvailableStickerSets(childId);
      
      // Create initial state
      StickerBookProject? currentProject;
      if (projects.isNotEmpty) {
        currentProject = projects.first;
      } else {
        // Create a default project if none exist
        currentProject = await _createDefaultProject();
        projects.insert(0, currentProject);
      }
      
      // Determine age mode based on child's age (simplified for now)
      final childAge = _getChildAge(); // Would get from child profile
      final ageMode = childAge < 7 ? AgeMode.littleKid : AgeMode.bigKid;
      
      state = StickerBookGameState(
        projects: projects,
        stickerPacks: collections.isNotEmpty ? collections : availablePacks.where((pack) => pack.isUnlocked).toList(),
        unlockedStickers: _buildUnlockedStickersSet(collections),
        currentProjectId: currentProject.id,
        ageMode: ageMode,
        childAge: childAge,
        lastPlayDate: DateTime.now(),
      );
      
      _isInitialized = true;
      Timber.i('[StickerGameProvider] Game initialized successfully');
      
    } catch (e) {
      Timber.e('[StickerGameProvider] Failed to initialize game: $e');
      // Fall back to creating a basic offline state
      await _createOfflineState();
    }
  }
  
  Future<StickerBookProject> _createDefaultProject() async {
    final project = await _apiService.createProject(
      childId: childId,
      name: 'My First Creation',
      mode: CreationMode.infiniteCanvas,
    );
    return project;
  }
  
  Set<String> _buildUnlockedStickersSet(List<StickerPack> collections) {
    final unlockedStickers = <String>{};
    for (final pack in collections) {
      for (final sticker in pack.stickers) {
        unlockedStickers.add(sticker.id);
      }
    }
    return unlockedStickers;
  }
  
  int _getChildAge() {
    // This would typically come from the child profile
    // For now, default to 8 years old
    return 8;
  }
  
  Future<void> _createOfflineState() async {
    Timber.w('[StickerGameProvider] Creating offline state');
    
    // Initialize SavedProjectsService even in offline mode
    _initializeSavedProjects();
    
    // Create a basic offline state with mock data
    final defaultCanvas = CreativeCanvas.infinite(
      id: 'default',
      name: 'My Creation',
      background: const CanvasBackground(
        id: 'default',
        name: 'White Background',
        backgroundColor: Colors.white,
      ),
      viewport: const CanvasViewport(screenSize: Size(800, 600)),
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
    
    final defaultProject = StickerBookProject(
      id: 'offline_default',
      name: 'My First Creation',
      mode: CreationMode.infiniteCanvas,
      infiniteCanvas: defaultCanvas,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
    
    state = StickerBookGameState(
      projects: [defaultProject],
      currentProjectId: defaultProject.id,
      stickerPacks: _getMockStickerPacks(),
      unlockedStickers: {'cow_1', 'pig_1', 'chicken_1', 'circle_red', 'square_blue'},
      ageMode: AgeMode.bigKid,
      childAge: 8,
      lastPlayDate: DateTime.now(),
    );
    
    _isInitialized = true;
  }
  
  List<StickerPack> _getMockStickerPacks() {
    return [
      StickerPack(
        id: 'animals_basic',
        name: 'Farm Animals',
        description: 'Cute farm animals',
        category: StickerCategory.animals,
        stickers: const [
          Sticker(id: 'cow_1', name: 'Happy Cow', emoji: '🐄', category: StickerCategory.animals),
          Sticker(id: 'pig_1', name: 'Little Pig', emoji: '🐷', category: StickerCategory.animals),
          Sticker(id: 'chicken_1', name: 'Chicken', emoji: '🐔', category: StickerCategory.animals),
        ],
        isUnlocked: true,
      ),
      StickerPack(
        id: 'shapes_basic',
        name: 'Basic Shapes',
        description: 'Fundamental shapes in bright colors',
        category: StickerCategory.shapes,
        stickers: const [
          Sticker(id: 'circle_red', name: 'Red Circle', emoji: '🔴', category: StickerCategory.shapes),
          Sticker(id: 'square_blue', name: 'Blue Square', emoji: '🟦', category: StickerCategory.shapes),
        ],
        isUnlocked: true,
      ),
    ];
  }
  
  // =============================================================================
  // PROJECT MANAGEMENT
  // =============================================================================
  
  Future<void> createProject(String name, CreationMode mode) async {
    try {
      Timber.i('[StickerGameProvider] Creating project: $name');
      
      final project = await _apiService.createProject(
        childId: childId,
        name: name,
        mode: mode,
      );
      
      final updatedProjects = [...state.projects, project];
      state = state.copyWith(
        projects: updatedProjects,
        currentProjectId: project.id,
        totalCreations: state.totalCreations + 1,
        lastPlayDate: DateTime.now(),
      );
      
      Timber.i('[StickerGameProvider] Project created successfully');
    } catch (e) {
      Timber.e('[StickerGameProvider] Failed to create project: $e');
    }
  }
  
  Future<void> updateProject(String projectId, Map<String, dynamic> projectData) async {
    try {
      Timber.d('[StickerGameProvider] Updating project: $projectId');
      
      final updatedProject = await _apiService.updateProject(
        childId: childId,
        projectId: projectId,
        projectData: projectData,
        sessionId: _currentSession?.id,
      );
      
      if (updatedProject != null) {
        final updatedProjects = state.projects.map((project) {
          return project.id == projectId ? updatedProject : project;
        }).toList();
        
        state = state.copyWith(
          projects: updatedProjects,
          lastPlayDate: DateTime.now(),
        );
      }
    } catch (e) {
      Timber.e('[StickerGameProvider] Failed to update project: $e');
    }
  }
  
  Future<void> deleteProject(String projectId) async {
    try {
      Timber.i('[StickerGameProvider] Deleting project: $projectId');
      
      final success = await _apiService.deleteProject(childId, projectId);
      
      if (success) {
        final updatedProjects = state.projects.where((project) => project.id != projectId).toList();
        
        // If we deleted the current project, switch to another one
        String? newCurrentProjectId = state.currentProjectId;
        if (state.currentProjectId == projectId) {
          newCurrentProjectId = updatedProjects.isNotEmpty ? updatedProjects.first.id : null;
        }
        
        state = state.copyWith(
          projects: updatedProjects,
          currentProjectId: newCurrentProjectId,
        );
      }
    } catch (e) {
      Timber.e('[StickerGameProvider] Failed to delete project: $e');
    }
  }
  
  void setCurrentProject(String projectId) {
    state = state.copyWith(currentProjectId: projectId);
  }
  
  // =============================================================================
  // STICKER PACK MANAGEMENT
  // =============================================================================
  
  Future<void> unlockStickerSet(String stickerSetId) async {
    try {
      Timber.i('[StickerGameProvider] Unlocking sticker set: $stickerSetId');
      
      final success = await _apiService.unlockStickerSet(childId, stickerSetId);
      
      if (success) {
        // Refresh the collections
        final collections = await _apiService.getChildStickerCollections(childId);
        final unlockedStickers = _buildUnlockedStickersSet(collections);
        
        state = state.copyWith(
          stickerPacks: collections,
          unlockedStickers: unlockedStickers,
        );
      }
    } catch (e) {
      Timber.e('[StickerGameProvider] Failed to unlock sticker set: $e');
    }
  }
  
  // =============================================================================
  // GAME SESSION MANAGEMENT
  // =============================================================================
  
  Future<void> startGameSession() async {
    try {
      Timber.i('[StickerGameProvider] Starting game session');
      
      _currentSession = await _apiService.startGameSession(
        childId: childId,
        deviceType: 'mobile',
        appVersion: '1.0.0',
      );
      
      if (_currentSession != null) {
        Timber.i('[StickerGameProvider] Game session started: ${_currentSession!.id}');
      }
    } catch (e) {
      Timber.e('[StickerGameProvider] Failed to start game session: $e');
    }
  }
  
  Future<void> endGameSession() async {
    if (_currentSession == null) return;
    
    try {
      Timber.i('[StickerGameProvider] Ending game session: ${_currentSession!.id}');
      
      final finalMetrics = {
        'totalPlayTimeMinutes': state.totalCreations * 5, // Simple estimation
        'projectsCreated': state.totalCreations,
        'stickersUsed': state.totalStickersCollected,
      };
      
      await _apiService.endGameSession(_currentSession!.id, finalMetrics);
      _currentSession = null;
      
      Timber.i('[StickerGameProvider] Game session ended successfully');
    } catch (e) {
      Timber.e('[StickerGameProvider] Failed to end game session: $e');
    }
  }
  
  // =============================================================================
  // ANALYTICS
  // =============================================================================
  
  Future<void> recordInteraction({
    required String projectId,
    required String interactionType,
    required Map<String, dynamic> interactionData,
  }) async {
    if (_currentSession == null) return;
    
    try {
      await _apiService.recordInteraction(
        childId: childId,
        projectId: projectId,
        sessionId: _currentSession!.id,
        interactionType: interactionType,
        interactionData: interactionData,
      );
    } catch (e) {
      Timber.d('[StickerGameProvider] Failed to record interaction: $e');
      // Don't throw - analytics failures shouldn't break gameplay
    }
  }
  
  // =============================================================================
  // UI STATE MANAGEMENT
  // =============================================================================
  
  void setSelectedTool(CanvasTool tool) {
    state = state.copyWith(selectedTool: tool);
  }
  
  void setSelectedColor(Color color) {
    state = state.copyWith(selectedColor: color);
  }
  
  void setSelectedBrushSize(double size) {
    state = state.copyWith(selectedBrushSize: size);
  }
  
  void setSelectedBrushType(BrushType type) {
    state = state.copyWith(selectedBrushType: type);
  }
  
  void setDefaultMode(CreationMode mode) {
    state = state.copyWith(defaultMode: mode);
  }
  
  @override
  void dispose() {
    endGameSession();
    super.dispose();
  }
}