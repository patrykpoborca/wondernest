import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/timber_wrapper.dart';
import '../../../core/services/api_service.dart';
import '../models/sticker_models.dart';

/// Service for managing saved sticker book projects with both local and backend storage
class SavedProjectsService {
  static const String _savedProjectsKey = 'sticker_book_saved_projects';
  static const String _projectCounterKey = 'sticker_book_project_counter';
  static const String _thumbnailsDirName = 'sticker_thumbnails';
  static const String _syncQueueKey = 'sticker_sync_queue';
  static const String _lastSyncKey = 'sticker_last_sync';
  
  /// Age-appropriate naming templates for auto-generated names
  static const List<String> _littleKidNames = [
    'Rainbow Art',
    'Happy Drawing',
    'Star Picture',
    'Sunshine Creation',
    'Magic Picture',
    'Pretty Colors',
    'Fun Art',
    'Sparkly Drawing',
    'Butterfly Art',
    'Flower Picture',
    'Happy Face',
    'Colorful Dream',
    'Sweet Drawing',
    'Bright Picture',
    'Lovely Art'
  ];
  
  static const List<String> _bigKidNames = [
    'Amazing Creation',
    'Cool Design',
    'Awesome Art',
    'Creative Project',
    'Epic Drawing',
    'Fantastic Picture',
    'Incredible Art',
    'Outstanding Work',
    'Brilliant Design',
    'Masterpiece',
    'Creative Vision',
    'Artistic Expression',
    'Unique Creation',
    'Personal Project',
    'Original Artwork'
  ];
  
  SharedPreferences? _prefs;
  Directory? _thumbnailsDir;
  ApiService? _apiService;
  String? _currentChildId;
  
  // Sync state
  bool _isSyncing = false;
  final List<String> _syncQueue = [];
  
  /// Initialize the service with optional child context
  Future<void> initialize({String? childId, ApiService? apiService}) async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _currentChildId = childId;
      _apiService = apiService ?? ApiService();
      
      // Create thumbnails directory
      final appDir = await getApplicationDocumentsDirectory();
      _thumbnailsDir = Directory('${appDir.path}/$_thumbnailsDirName');
      if (!await _thumbnailsDir!.exists()) {
        await _thumbnailsDir!.create(recursive: true);
      }
      
      // Load sync queue
      await _loadSyncQueue();
      
      // Trigger initial sync if we have a child ID
      if (_currentChildId != null) {
        // Don't await to avoid blocking initialization
        _performSync().catchError((error) {
          Timber.w('[SavedProjectsService] Initial sync failed: $error');
        });
      }
      
      Timber.i('[SavedProjectsService] Initialized successfully with child: $_currentChildId');
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to initialize: $e');
      rethrow;
    }
  }
  
  /// Generate an auto-generated name based on age mode
  Future<String> generateAutoName(AgeMode ageMode, {int? counter}) async {
    final isLittleKid = ageMode == AgeMode.littleKid;
    
    if (isLittleKid) {
      // For little kids, use fun descriptive names + number
      final namePool = List<String>.from(_littleKidNames);
      namePool.shuffle();
      final baseName = namePool.first;
      
      if (counter != null && counter > 1) {
        return '$baseName $counter';
      }
      return baseName;
    } else {
      // For big kids, use "My Creation X" pattern or creative names
      int actualCounter = counter ?? await _getNextProjectCounter();
      
      if (actualCounter <= 5) {
        // First few projects get creative names
        final namePool = List<String>.from(_bigKidNames);
        namePool.shuffle();
        return namePool.first;
      } else {
        // After that, use numbered pattern
        return 'My Creation $actualCounter';
      }
    }
  }
  
  /// Get the next project counter
  Future<int> _getNextProjectCounter() async {
    if (_prefs == null) await initialize();
    
    final currentCounter = _prefs!.getInt(_projectCounterKey) ?? 0;
    final nextCounter = currentCounter + 1;
    await _prefs!.setInt(_projectCounterKey, nextCounter);
    return nextCounter;
  }
  
  /// Save a project with optional custom name
  /// If editingProjectId is provided, updates existing project instead of creating new one
  /// Now supports both local and backend sync
  Future<SavedProject> saveProject({
    required StickerBookProject project,
    required AgeMode ageMode,
    String? customName,
    ui.Image? thumbnail,
    String? editingProjectId,
  }) async {
    try {
      if (_prefs == null) await initialize();
      
      // DEBUG: Log detailed project data being saved
      Timber.d('[SavedProjectsService] === SAVING PROJECT START ===');
      Timber.d('[SavedProjectsService] Project name: ${project.name}');
      Timber.d('[SavedProjectsService] Age mode: $ageMode');
      Timber.d('[SavedProjectsService] Custom name provided: ${customName?.isNotEmpty == true ? customName : "none"}');
      Timber.d('[SavedProjectsService] Editing existing project ID: ${editingProjectId ?? "none - creating new"}');
      
      // Log detailed project structure
      Timber.d('[SavedProjectsService] Project structure:');
      Timber.d('[SavedProjectsService]   - Has flipBook: ${project.flipBook != null}');
      Timber.d('[SavedProjectsService]   - Has infiniteCanvas: ${project.infiniteCanvas != null}');
      
      if (project.flipBook != null) {
        Timber.d('[SavedProjectsService]   - FlipBook pages: ${project.flipBook!.pages.length}');
        for (int i = 0; i < project.flipBook!.pages.length; i++) {
          final page = project.flipBook!.pages[i];
          Timber.d('[SavedProjectsService]     Page $i: ${page.stickers.length} stickers, ${page.drawings.length} drawings');
        }
      }
      
      if (project.infiniteCanvas != null) {
        final canvas = project.infiniteCanvas!;
        Timber.d('[SavedProjectsService]   - Canvas stickers: ${canvas.stickers.length}');
        Timber.d('[SavedProjectsService]   - Canvas drawings: ${canvas.drawings.length}');
        
        for (int i = 0; i < canvas.drawings.length; i++) {
          final drawing = canvas.drawings[i];
          Timber.d('[SavedProjectsService]     Drawing $i: ${drawing.points.length} points, color: ${drawing.color}, width: ${drawing.strokeWidth}');
        }
        
        for (int i = 0; i < canvas.stickers.length; i++) {
          final sticker = canvas.stickers[i];
          Timber.d('[SavedProjectsService]     Sticker $i: ${sticker.sticker.emoji}, position: (${sticker.position.dx}, ${sticker.position.dy})');
        }
      }
      
      Timber.d('[SavedProjectsService] === PROJECT DATA LOG END ===');
      
      // Get existing saved projects
      final savedProjects = await _getSavedProjectsLocal();
      
      SavedProject savedProjectResult;
      
      if (editingProjectId != null) {
        // Update existing project
        final existingProjectIndex = savedProjects.indexWhere((p) => p.id == editingProjectId);
        if (existingProjectIndex != -1) {
          final existingProject = savedProjects[existingProjectIndex];
          
          // Use custom name if provided, otherwise keep existing name
          final projectName = customName?.trim().isNotEmpty == true 
              ? customName! 
              : existingProject.name;
          
          // Save thumbnail if provided, otherwise keep existing
          String? thumbnailPath = existingProject.thumbnailPath;
          if (thumbnail != null) {
            thumbnailPath = await _saveThumbnail(editingProjectId, thumbnail);
          }
          
          // Update the existing project
          final updatedProject = SavedProject(
            id: editingProjectId,
            name: projectName,
            originalProject: project.copyWith(name: projectName),
            savedAt: existingProject.savedAt, // Keep original saved date
            ageMode: ageMode,
            thumbnailPath: thumbnailPath,
            description: existingProject.description,
          );
          
          savedProjects[existingProjectIndex] = updatedProject;
          savedProjectResult = updatedProject;
        } else {
          throw Exception('Project with ID $editingProjectId not found for update');
        }
      } else {
        // Create new project
        // Generate name if not provided
        final projectName = customName?.trim().isNotEmpty == true 
            ? customName! 
            : await generateAutoName(ageMode);
        
        // Generate a unique ID for each save (timestamp + random component)
        final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
        
        // Create saved project with unique ID
        final savedProject = SavedProject(
          id: uniqueId,
          name: projectName,
          originalProject: project.copyWith(name: projectName),
          savedAt: DateTime.now(),
          ageMode: ageMode,
        );
        
        // Save thumbnail if provided
        String? thumbnailPath;
        if (thumbnail != null) {
          thumbnailPath = await _saveThumbnail(savedProject.id, thumbnail);
        }
        
        final savedProjectWithThumbnail = savedProject.copyWith(
          thumbnailPath: thumbnailPath,
        );
        
        // Add as new project
        savedProjects.add(savedProjectWithThumbnail);
        savedProjectResult = savedProjectWithThumbnail;
      }
      
      // Sort by save date (most recent first)
      savedProjects.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      
      // Save to local preferences first
      await _saveProjectsLocal(savedProjects);
      
      // Try to save to backend
      await _saveProjectToBackend(savedProjectResult);
      
      Timber.i('[SavedProjectsService] === PROJECT SAVE COMPLETE ===');
      Timber.i('[SavedProjectsService] Saved project: ${savedProjectResult.name}');
      Timber.i('[SavedProjectsService] Project ID: ${savedProjectResult.id}');
      Timber.i('[SavedProjectsService] Saved at: ${savedProjectResult.savedAt}');
      Timber.i('[SavedProjectsService] Thumbnail path: ${savedProjectResult.thumbnailPath ?? "none"}');
      Timber.i('[SavedProjectsService] === END SAVE COMPLETE ===');
      
      return savedProjectResult;
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to save project: $e');
      rethrow;
    }
  }
  
  /// Load all saved projects with backend sync
  Future<List<SavedProject>> getSavedProjects() async {
    try {
      if (_prefs == null) await initialize();
      
      // Get local projects first
      final localProjects = await _getSavedProjectsLocal();
      
      // If we have a child ID, try to sync with backend
      if (_currentChildId != null && _apiService != null) {
        try {
          final backendProjects = await _loadProjectsFromBackend();
          return await _mergeProjects(localProjects, backendProjects);
        } catch (e) {
          Timber.w('[SavedProjectsService] Backend sync failed, using local projects: $e');
        }
      }
      
      return localProjects;
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to load saved projects: $e');
      return [];
    }
  }
  
  /// Delete a saved project from both local and backend
  Future<bool> deleteProject(String projectId) async {
    try {
      if (_prefs == null) await initialize();
      
      final savedProjects = await _getSavedProjectsLocal();
      final projectToDelete = savedProjects.where((p) => p.id == projectId).firstOrNull;
      
      if (projectToDelete == null) {
        return false;
      }
      
      // Delete thumbnail if it exists
      if (projectToDelete.thumbnailPath != null) {
        await _deleteThumbnail(projectToDelete.thumbnailPath!);
      }
      
      // Remove from local list
      savedProjects.removeWhere((p) => p.id == projectId);
      
      // Save updated local list
      await _saveProjectsLocal(savedProjects);
      
      // Try to delete from backend
      await _deleteProjectFromBackend(projectId);
      
      Timber.i('[SavedProjectsService] Project deleted: $projectId');
      return true;
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to delete project: $e');
      return false;
    }
  }
  
  /// Get a specific saved project by ID
  Future<SavedProject?> getProject(String projectId) async {
    final savedProjects = await getSavedProjects();
    return savedProjects.where((p) => p.id == projectId).firstOrNull;
  }

  /// Rename a saved project
  Future<bool> renameProject(String projectId, String newName) async {
    try {
      if (_prefs == null) await initialize();
      
      final savedProjects = await _getSavedProjectsLocal();
      final projectIndex = savedProjects.indexWhere((p) => p.id == projectId);
      
      if (projectIndex == -1) {
        return false;
      }
      
      // Update the project name
      final updatedProject = savedProjects[projectIndex].copyWith(
        name: newName.trim(),
        originalProject: savedProjects[projectIndex].originalProject.copyWith(
          name: newName.trim(),
        ),
      );
      
      savedProjects[projectIndex] = updatedProject;
      
      // Save updated list locally
      await _saveProjectsLocal(savedProjects);
      
      // Save to backend
      await _saveProjectToBackend(updatedProject);
      
      Timber.i('[SavedProjectsService] Project renamed: $projectId -> $newName');
      return true;
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to rename project: $e');
      return false;
    }
  }
  
  /// Save thumbnail image to local storage
  Future<String> _saveThumbnail(String projectId, ui.Image image) async {
    try {
      if (_thumbnailsDir == null) await initialize();
      
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }
      
      final fileName = '${projectId}_thumbnail.png';
      final file = File('${_thumbnailsDir!.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      
      return file.path;
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to save thumbnail: $e');
      rethrow;
    }
  }
  
  /// Delete thumbnail file
  Future<void> _deleteThumbnail(String thumbnailPath) async {
    try {
      final file = File(thumbnailPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Timber.w('[SavedProjectsService] Failed to delete thumbnail: $e');
      // Not critical, continue
    }
  }
  
  /// Capture thumbnail from a widget
  static Future<ui.Image?> captureWidgetAsImage(GlobalKey key) async {
    try {
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        return null;
      }
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      return image;
      
    } catch (e) {
      Timber.w('[SavedProjectsService] Failed to capture thumbnail: $e');
      return null;
    }
  }
  
  /// Get total number of saved projects
  Future<int> getSavedProjectCount() async {
    final projects = await getSavedProjects();
    return projects.length;
  }
  
  /// Get projects grouped by age mode
  Future<Map<AgeMode, List<SavedProject>>> getProjectsByAgeMode() async {
    final projects = await getSavedProjects();
    final grouped = <AgeMode, List<SavedProject>>{};
    
    for (final project in projects) {
      final ageMode = project.ageMode;
      grouped[ageMode] = (grouped[ageMode] ?? [])..add(project);
    }
    
    return grouped;
  }
  
  /// Clear all saved projects (for testing or reset)
  Future<void> clearAllProjects() async {
    try {
      if (_prefs == null) await initialize();
      
      // Delete all thumbnails
      if (_thumbnailsDir != null && await _thumbnailsDir!.exists()) {
        await _thumbnailsDir!.delete(recursive: true);
        await _thumbnailsDir!.create(recursive: true);
      }
      
      // Clear preferences
      await _prefs!.remove(_savedProjectsKey);
      await _prefs!.remove(_projectCounterKey);
      await _prefs!.remove(_syncQueueKey);
      await _prefs!.remove(_lastSyncKey);
      
      // Clear sync queue
      _syncQueue.clear();
      
      Timber.i('[SavedProjectsService] All projects cleared');
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to clear projects: $e');
      rethrow;
    }
  }
  
  // =============================================================================
  // BACKEND SYNC METHODS
  // =============================================================================
  
  /// Load projects from backend using proper game data persistence endpoint
  Future<List<SavedProject>> _loadProjectsFromBackend() async {
    if (_apiService == null || _currentChildId == null) {
      return [];
    }
    
    try {
      Timber.d('[SavedProjectsService] Loading projects from backend for child: $_currentChildId');
      
      // Get sticker book game data from backend using enhanced API v2
      final response = await _apiService!.getGameData(_currentChildId!, gameType: 'sticker_book');
      final data = response.data;
      
      // Enhanced API v2 returns: {success: bool, gameData: [...]}
      final gameDataList = data['gameData'] as List? ?? [];
      final stickerProjects = gameDataList.where((item) {
        final dataKey = item['dataKey'] as String? ?? '';
        return dataKey.startsWith('sticker_project_');
      }).toList();
      
      final backendProjects = <SavedProject>[];
      
      for (final item in stickerProjects) {
        try {
          // The dataValue should be the direct SavedProject JSON
          final projectData = item['dataValue'] as Map<String, dynamic>? ?? {};
          final savedProject = SavedProject.fromJson(projectData);
          backendProjects.add(savedProject);
        } catch (e) {
          Timber.w('[SavedProjectsService] Failed to parse backend project: $e');
        }
      }
      
      Timber.i('[SavedProjectsService] Loaded ${backendProjects.length} projects from backend');
      return backendProjects;
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to load projects from backend: $e');
      return [];
    }
  }
  
  /// Save project to backend using proper game data persistence endpoint
  Future<void> _saveProjectToBackend(SavedProject project) async {
    if (_apiService == null || _currentChildId == null) {
      Timber.w('[SavedProjectsService] Cannot save to backend: apiService=${_apiService != null}, childId=${_currentChildId}');
      // Add to sync queue for later
      await _addToSyncQueue(project.id, 'save');
      return;
    }
    
    try {
      Timber.d('[SavedProjectsService] Starting backend save for project: ${project.name}');
      Timber.d('[SavedProjectsService] Project ID: ${project.id}');
      Timber.d('[SavedProjectsService] Child ID: $_currentChildId');
      Timber.d('[SavedProjectsService] Age Mode: ${project.ageMode}');
      
      // Prepare game data for enhanced API v2 - proper GameRegistry architecture
      final gameDataPayload = {
        'gameKey': 'sticker_book',
        'dataKey': 'sticker_project_${project.id}',
        'dataValue': project.toJson(), // Full project data as JSON
      };
      
      Timber.d('[SavedProjectsService] Game data payload prepared:');
      Timber.d('[SavedProjectsService]   gameKey: ${gameDataPayload['gameKey']}');
      Timber.d('[SavedProjectsService]   dataKey: ${gameDataPayload['dataKey']}');
      Timber.d('[SavedProjectsService]   dataValue size: ${json.encode(gameDataPayload['dataValue']).length} characters');
      
      // Use saveGameData to store project data (NOT analytics endpoint)
      Timber.d('[SavedProjectsService] Calling ApiService.saveGameData...');
      final response = await _apiService!.saveGameData(_currentChildId!, gameDataPayload);
      
      Timber.i('[SavedProjectsService] Project saved to backend successfully: ${project.name}');
      Timber.d('[SavedProjectsService] Backend response status: ${response.statusCode}');
      
    } catch (e, stackTrace) {
      Timber.e('[SavedProjectsService] Failed to save project to backend: $e');
      Timber.e('[SavedProjectsService] Stack trace: $stackTrace');
      
      if (e.toString().contains('500')) {
        Timber.e('[SavedProjectsService] 500 Internal Server Error detected - logging detailed context');
        Timber.e('[SavedProjectsService] Project details - ID: ${project.id}, Name: ${project.name}');
        Timber.e('[SavedProjectsService] Original project last modified: ${project.originalProject.lastModified}');
        if (project.originalProject.infiniteCanvas != null) {
          Timber.e('[SavedProjectsService] Canvas has ${project.originalProject.infiniteCanvas!.drawings.length} drawings');
          Timber.e('[SavedProjectsService] Canvas has ${project.originalProject.infiniteCanvas!.stickers.length} stickers');
        }
      }
      
      await _addToSyncQueue(project.id, 'save');
    }
  }
  
  /// Delete project from backend using proper game data persistence endpoint
  Future<void> _deleteProjectFromBackend(String projectId) async {
    if (_apiService == null || _currentChildId == null) {
      // Add to sync queue for later
      await _addToSyncQueue(projectId, 'delete');
      return;
    }
    
    try {
      Timber.d('[SavedProjectsService] Deleting project from backend: $projectId');
      
      // Use deleteGameData to remove the project (NOT analytics endpoint)
      final dataKey = 'sticker_project_$projectId';
      await _apiService!.deleteGameData(_currentChildId!, 'sticker_book', dataKey);
      
      Timber.i('[SavedProjectsService] Project deleted from backend: $projectId');
      
    } catch (e) {
      Timber.w('[SavedProjectsService] Failed to delete project from backend, adding to sync queue: $e');
      await _addToSyncQueue(projectId, 'delete');
    }
  }
  
  /// Merge local and backend projects, with backend as source of truth for conflicts
  Future<List<SavedProject>> _mergeProjects(List<SavedProject> localProjects, List<SavedProject> backendProjects) async {
    final mergedProjects = <String, SavedProject>{};
    
    // Start with local projects
    for (final project in localProjects) {
      mergedProjects[project.id] = project;
    }
    
    // Override with backend projects (backend wins)
    for (final project in backendProjects) {
      final localProject = mergedProjects[project.id];
      
      if (localProject == null) {
        // New project from backend
        mergedProjects[project.id] = project;
      } else {
        // Compare timestamps to see which is newer
        if (project.originalProject.lastModified.isAfter(localProject.originalProject.lastModified)) {
          // Backend version is newer
          mergedProjects[project.id] = project;
        }
        // If local is newer or same, keep local version
      }
    }
    
    final result = mergedProjects.values.toList();
    result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    
    // Update local storage with merged results
    await _saveProjectsLocal(result);
    
    Timber.i('[SavedProjectsService] Merged ${result.length} projects (${localProjects.length} local + ${backendProjects.length} backend)');
    return result;
  }
  
  /// Perform full synchronization
  Future<void> _performSync() async {
    if (_isSyncing || _apiService == null || _currentChildId == null) {
      return;
    }
    
    _isSyncing = true;
    
    try {
      Timber.i('[SavedProjectsService] Starting sync for child: $_currentChildId');
      
      // Process sync queue first
      await _processSyncQueue();
      
      // Then do a full sync
      final localProjects = await _getSavedProjectsLocal();
      final backendProjects = await _loadProjectsFromBackend();
      await _mergeProjects(localProjects, backendProjects);
      
      // Update last sync timestamp
      await _prefs!.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      Timber.i('[SavedProjectsService] Sync completed successfully');
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Get local projects without backend sync
  Future<List<SavedProject>> _getSavedProjectsLocal() async {
    try {
      if (_prefs == null) await initialize();
      
      final projectsString = _prefs!.getString(_savedProjectsKey);
      if (projectsString == null) {
        Timber.d('[SavedProjectsService] No saved projects found locally');
        return [];
      }
      
      Timber.d('[SavedProjectsService] Loading local projects JSON length: ${projectsString.length}');
      
      final projectsJson = json.decode(projectsString) as List;
      Timber.d('[SavedProjectsService] Found ${projectsJson.length} local saved projects');
      
      final projects = projectsJson.map((projectData) {
        final project = SavedProject.fromJson(projectData);
        
        // DEBUG: Log each project's drawing data
        Timber.d('[SavedProjectsService] Loading local project: ${project.name}');
        if (project.originalProject.infiniteCanvas != null) {
          final drawingsCount = project.originalProject.infiniteCanvas!.drawings.length;
          Timber.d('[SavedProjectsService] Project has $drawingsCount drawings');
          
          for (int i = 0; i < project.originalProject.infiniteCanvas!.drawings.length; i++) {
            final drawing = project.originalProject.infiniteCanvas!.drawings[i];
            Timber.d('[SavedProjectsService] Drawing $i: ${drawing.points.length} points, color: ${drawing.color}');
          }
        }
        
        return project;
      }).toList();
      
      // Sort by save date (most recent first)
      projects.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      
      return projects;
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to load local saved projects: $e');
      return [];
    }
  }
  
  /// Save projects to local storage only
  Future<void> _saveProjectsLocal(List<SavedProject> projects) async {
    try {
      final projectsJson = projects.map((p) => p.toJson()).toList();
      final jsonString = json.encode(projectsJson);
      
      await _prefs!.setString(_savedProjectsKey, jsonString);
      
      Timber.d('[SavedProjectsService] Saved ${projects.length} projects locally');
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to save projects locally: $e');
      rethrow;
    }
  }
  
  // =============================================================================
  // SYNC QUEUE METHODS
  // =============================================================================
  
  /// Add project to sync queue for later processing
  Future<void> _addToSyncQueue(String projectId, String operation) async {
    try {
      final queueItem = {
        'projectId': projectId,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _syncQueue.add(json.encode(queueItem));
      await _saveSyncQueue();
      
      Timber.d('[SavedProjectsService] Added to sync queue: $operation $projectId');
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to add to sync queue: $e');
    }
  }
  
  /// Load sync queue from preferences
  Future<void> _loadSyncQueue() async {
    try {
      final queueString = _prefs!.getString(_syncQueueKey);
      if (queueString != null) {
        final queueJson = json.decode(queueString) as List;
        _syncQueue.clear();
        _syncQueue.addAll(queueJson.cast<String>());
      }
      
      Timber.d('[SavedProjectsService] Loaded sync queue with ${_syncQueue.length} items');
      
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to load sync queue: $e');
      _syncQueue.clear();
    }
  }
  
  /// Save sync queue to preferences
  Future<void> _saveSyncQueue() async {
    try {
      final queueString = json.encode(_syncQueue);
      await _prefs!.setString(_syncQueueKey, queueString);
    } catch (e) {
      Timber.e('[SavedProjectsService] Failed to save sync queue: $e');
    }
  }
  
  /// Process items in sync queue
  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty) return;
    
    Timber.i('[SavedProjectsService] Processing ${_syncQueue.length} items in sync queue');
    
    final failedItems = <String>[];
    
    for (final queueItemJson in List<String>.from(_syncQueue)) {
      try {
        final queueItem = json.decode(queueItemJson) as Map<String, dynamic>;
        final projectId = queueItem['projectId'] as String;
        final operation = queueItem['operation'] as String;
        
        if (operation == 'save') {
          // Find the project in local storage and save to backend
          final localProjects = await _getSavedProjectsLocal();
          final project = localProjects.firstWhere(
            (p) => p.id == projectId,
            orElse: () => throw Exception('Project not found locally'),
          );
          await _saveProjectToBackend(project);
        } else if (operation == 'delete') {
          await _deleteProjectFromBackend(projectId);
        }
        
        // Remove from queue if successful
        _syncQueue.remove(queueItemJson);
        
      } catch (e) {
        Timber.w('[SavedProjectsService] Failed to process sync queue item: $e');
        failedItems.add(queueItemJson);
      }
    }
    
    // Save updated queue
    await _saveSyncQueue();
    
    Timber.i('[SavedProjectsService] Processed sync queue, ${failedItems.length} items failed');
  }
  
  // =============================================================================
  // PUBLIC SYNC METHODS
  // =============================================================================
  
  /// Force a sync with the backend
  Future<void> syncWithBackend() async {
    await _performSync();
  }
  
  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;
  
  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    if (_prefs == null) await initialize();
    
    final syncTimeString = _prefs!.getString(_lastSyncKey);
    if (syncTimeString == null) return null;
    
    try {
      return DateTime.parse(syncTimeString);
    } catch (e) {
      return null;
    }
  }
  
  /// Get number of items waiting to be synced
  int get pendingSyncCount => _syncQueue.length;
  
  /// Update child context for backend operations
  void setChildContext(String? childId) {
    _currentChildId = childId;
    if (childId != null) {
      // Trigger sync for new child
      _performSync().catchError((error) {
        Timber.w('[SavedProjectsService] Sync failed for new child context: $error');
      });
    }
  }
  
}

/// Represents a saved sticker book project
class SavedProject {
  final String id;
  final String name;
  final StickerBookProject originalProject;
  final DateTime savedAt;
  final AgeMode ageMode;
  final String? thumbnailPath;
  final String? description;
  
  const SavedProject({
    required this.id,
    required this.name,
    required this.originalProject,
    required this.savedAt,
    required this.ageMode,
    this.thumbnailPath,
    this.description,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'originalProject': originalProject.toJson(),
      'savedAt': savedAt.toIso8601String(),
      'ageMode': ageMode.name,
      'thumbnailPath': thumbnailPath,
      'description': description,
    };
  }
  
  factory SavedProject.fromJson(Map<String, dynamic> json) {
    return SavedProject(
      id: json['id'],
      name: json['name'],
      originalProject: StickerBookProject.fromJson(json['originalProject']),
      savedAt: DateTime.parse(json['savedAt']),
      ageMode: AgeMode.values.firstWhere(
        (e) => e.name == json['ageMode'],
        orElse: () => AgeMode.bigKid,
      ),
      thumbnailPath: json['thumbnailPath'],
      description: json['description'],
    );
  }
  
  SavedProject copyWith({
    String? id,
    String? name,
    StickerBookProject? originalProject,
    DateTime? savedAt,
    AgeMode? ageMode,
    String? thumbnailPath,
    String? description,
  }) {
    return SavedProject(
      id: id ?? this.id,
      name: name ?? this.name,
      originalProject: originalProject ?? this.originalProject,
      savedAt: savedAt ?? this.savedAt,
      ageMode: ageMode ?? this.ageMode,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      description: description ?? this.description,
    );
  }
}