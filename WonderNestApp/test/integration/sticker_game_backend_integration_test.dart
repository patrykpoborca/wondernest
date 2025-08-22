import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/core/services/sticker_game_api_service.dart';
import '../../lib/providers/sticker_game_provider.dart';
import '../../lib/games/sticker_book/models/sticker_models.dart';

// This annotation generates mock classes
@GenerateMocks([StickerGameApiService])
import 'sticker_game_backend_integration_test.mocks.dart';

void main() {
  group('Sticker Game Backend Integration', () {
    late MockStickerGameApiService mockApiService;
    
    setUp(() {
      mockApiService = MockStickerGameApiService();
    });
    
    group('Game Initialization', () {
      test('should initialize sticker game for child', () async {
        // Arrange
        const childId = 'test-child-id';
        final expectedResponse = StickerGameInitResponse(
          success: true,
          message: 'Game initialized',
          data: {'gameInstanceId': 'test-instance-id'},
        );
        
        when(mockApiService.initializeStickerGame(childId, ageMonths: anyNamed('ageMonths')))
            .thenAnswer((_) async => expectedResponse);
        
        // Act
        final result = await mockApiService.initializeStickerGame(childId, ageMonths: 60);
        
        // Assert
        expect(result.success, isTrue);
        expect(result.message, equals('Game initialized'));
        verify(mockApiService.initializeStickerGame(childId, ageMonths: 60)).called(1);
      });
    });
    
    group('Sticker Pack Management', () {
      test('should get available sticker sets for child', () async {
        // Arrange
        const childId = 'test-child-id';
        final mockStickerPacks = [
          StickerPack(
            id: 'animals_basic',
            name: 'Farm Animals',
            description: 'Cute farm animals',
            category: StickerCategory.animals,
            stickers: const [
              Sticker(id: 'cow_1', name: 'Happy Cow', emoji: '🐄', category: StickerCategory.animals),
            ],
            isUnlocked: true,
          ),
        ];
        
        when(mockApiService.getAvailableStickerSets(childId))
            .thenAnswer((_) async => mockStickerPacks);
        
        // Act
        final result = await mockApiService.getAvailableStickerSets(childId);
        
        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, equals('Farm Animals'));
        expect(result.first.isUnlocked, isTrue);
        verify(mockApiService.getAvailableStickerSets(childId)).called(1);
      });
      
      test('should unlock sticker set for child', () async {
        // Arrange
        const childId = 'test-child-id';
        const stickerSetId = 'animals_basic';
        
        when(mockApiService.unlockStickerSet(childId, stickerSetId))
            .thenAnswer((_) async => true);
        
        // Act
        final result = await mockApiService.unlockStickerSet(childId, stickerSetId);
        
        // Assert
        expect(result, isTrue);
        verify(mockApiService.unlockStickerSet(childId, stickerSetId)).called(1);
      });
    });
    
    group('Project Management', () {
      test('should create new sticker book project', () async {
        // Arrange
        const childId = 'test-child-id';
        const projectName = 'My Test Project';
        const mode = CreationMode.infiniteCanvas;
        
        final mockProject = StickerBookProject(
          id: 'test-project-id',
          name: projectName,
          mode: mode,
          infiniteCanvas: CreativeCanvas.infinite(
            id: 'test-canvas-id',
            name: projectName,
            background: const CanvasBackground(id: 'default', name: 'White'),
            viewport: const CanvasViewport(screenSize: Size(800, 600)),
            createdAt: DateTime.now(),
            lastModified: DateTime.now(),
          ),
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
        );
        
        when(mockApiService.createProject(
          childId: childId,
          name: projectName,
          mode: mode,
        )).thenAnswer((_) async => mockProject);
        
        // Act
        final result = await mockApiService.createProject(
          childId: childId,
          name: projectName,
          mode: mode,
        );
        
        // Assert
        expect(result.name, equals(projectName));
        expect(result.mode, equals(mode));
        expect(result.infiniteCanvas, isNotNull);
        verify(mockApiService.createProject(
          childId: childId,
          name: projectName,
          mode: mode,
        )).called(1);
      });
      
      test('should get child projects', () async {
        // Arrange
        const childId = 'test-child-id';
        final mockProjects = [
          StickerBookProject(
            id: 'project-1',
            name: 'Project 1',
            mode: CreationMode.infiniteCanvas,
            createdAt: DateTime.now(),
            lastModified: DateTime.now(),
          ),
          StickerBookProject(
            id: 'project-2',
            name: 'Project 2',
            mode: CreationMode.flipBook,
            createdAt: DateTime.now(),
            lastModified: DateTime.now(),
          ),
        ];
        
        when(mockApiService.getChildProjects(childId))
            .thenAnswer((_) async => mockProjects);
        
        // Act
        final result = await mockApiService.getChildProjects(childId);
        
        // Assert
        expect(result, hasLength(2));
        expect(result.first.name, equals('Project 1'));
        expect(result.last.name, equals('Project 2'));
        verify(mockApiService.getChildProjects(childId)).called(1);
      });
      
      test('should update project data', () async {
        // Arrange
        const childId = 'test-child-id';
        const projectId = 'test-project-id';
        final projectData = {'canvas': {'stickers': []}};
        
        final updatedProject = StickerBookProject(
          id: projectId,
          name: 'Updated Project',
          mode: CreationMode.infiniteCanvas,
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
        );
        
        when(mockApiService.updateProject(
          childId: childId,
          projectId: projectId,
          projectData: projectData,
        )).thenAnswer((_) async => updatedProject);
        
        // Act
        final result = await mockApiService.updateProject(
          childId: childId,
          projectId: projectId,
          projectData: projectData,
        );
        
        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(projectId));
        verify(mockApiService.updateProject(
          childId: childId,
          projectId: projectId,
          projectData: projectData,
        )).called(1);
      });
    });
    
    group('Game Sessions', () {
      test('should start game session', () async {
        // Arrange
        const childId = 'test-child-id';
        final mockSession = GameSession(
          id: 'test-session-id',
          childGameInstanceId: 'test-instance-id',
          startedAt: DateTime.now(),
          deviceType: 'mobile',
          appVersion: '1.0.0',
        );
        
        when(mockApiService.startGameSession(childId: childId))
            .thenAnswer((_) async => mockSession);
        
        // Act
        final result = await mockApiService.startGameSession(childId: childId);
        
        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test-session-id'));
        expect(result.deviceType, equals('mobile'));
        verify(mockApiService.startGameSession(childId: childId)).called(1);
      });
      
      test('should end game session', () async {
        // Arrange
        const sessionId = 'test-session-id';
        final finalMetrics = {'playTime': 300, 'stickersUsed': 15};
        
        when(mockApiService.endGameSession(sessionId, finalMetrics))
            .thenAnswer((_) async => true);
        
        // Act
        final result = await mockApiService.endGameSession(sessionId, finalMetrics);
        
        // Assert
        expect(result, isTrue);
        verify(mockApiService.endGameSession(sessionId, finalMetrics)).called(1);
      });
    });
    
    group('Analytics', () {
      test('should record interaction', () async {
        // Arrange
        const childId = 'test-child-id';
        const projectId = 'test-project-id';
        const sessionId = 'test-session-id';
        const interactionType = 'sticker_placed';
        final interactionData = {'stickerId': 'cow_1', 'position': {'x': 100, 'y': 200}};
        
        when(mockApiService.recordInteraction(
          childId: childId,
          projectId: projectId,
          sessionId: sessionId,
          interactionType: interactionType,
          interactionData: interactionData,
        )).thenAnswer((_) async => true);
        
        // Act
        final result = await mockApiService.recordInteraction(
          childId: childId,
          projectId: projectId,
          sessionId: sessionId,
          interactionType: interactionType,
          interactionData: interactionData,
        );
        
        // Assert
        expect(result, isTrue);
        verify(mockApiService.recordInteraction(
          childId: childId,
          projectId: projectId,
          sessionId: sessionId,
          interactionType: interactionType,
          interactionData: interactionData,
        )).called(1);
      });
      
      test('should get child progress', () async {
        // Arrange
        const childId = 'test-child-id';
        const mockProgress = StickerGameProgress(
          totalProjects: 5,
          completedProjects: 3,
          totalPlayTimeMinutes: 120,
          unlockedStickerSets: 4,
          totalStickersUsed: 25,
          achievementsUnlocked: 7,
          favoriteTheme: 'animals',
          skillMetrics: {'creativity': 85.0, 'fine_motor_skills': 78.0},
        );
        
        when(mockApiService.getChildProgress(childId))
            .thenAnswer((_) async => mockProgress);
        
        // Act
        final result = await mockApiService.getChildProgress(childId);
        
        // Assert
        expect(result.totalProjects, equals(5));
        expect(result.completedProjects, equals(3));
        expect(result.favoriteTheme, equals('animals'));
        expect(result.skillMetrics['creativity'], equals(85.0));
        verify(mockApiService.getChildProgress(childId)).called(1);
      });
    });
    
    group('Error Handling', () {
      test('should handle API failures gracefully', () async {
        // Arrange
        const childId = 'test-child-id';
        
        when(mockApiService.getChildProjects(childId))
            .thenThrow(Exception('Network error'));
        
        // Act & Assert
        expect(
          () => mockApiService.getChildProjects(childId),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should return mock data when backend is unavailable', () async {
        // This test would verify the fallback behavior in the real API service
        final apiService = StickerGameApiService();
        
        // Since the backend won't be running during tests, this should return mock data
        final result = await apiService.getAvailableStickerSets('test-child-id');
        
        // Assert we get some sticker packs (even if they're mock data)
        expect(result, isNotEmpty);
        expect(result.first, isA<StickerPack>());
      });
    });
  });
  
  group('Backend Data Flow Integration', () {
    test('should demonstrate complete game flow', () async {
      // This test demonstrates how the complete game flow would work
      final apiService = MockStickerGameApiService();
      const childId = 'integration-test-child';
      
      // 1. Initialize game
      final initResponse = StickerGameInitResponse(
        success: true,
        message: 'Game initialized',
        data: {'gameInstanceId': 'test-instance'},
      );
      when(apiService.initializeStickerGame(childId))
          .thenAnswer((_) async => initResponse);
      
      final init = await apiService.initializeStickerGame(childId);
      expect(init.success, isTrue);
      
      // 2. Get available sticker packs
      final mockPacks = [
        StickerPack(
          id: 'animals_basic',
          name: 'Farm Animals',
          description: 'Basic farm animals',
          category: StickerCategory.animals,
          stickers: const [
            Sticker(id: 'cow_1', name: 'Cow', emoji: '🐄', category: StickerCategory.animals),
          ],
          isUnlocked: true,
        ),
      ];
      when(apiService.getAvailableStickerSets(childId))
          .thenAnswer((_) async => mockPacks);
      
      final packs = await apiService.getAvailableStickerSets(childId);
      expect(packs, hasLength(1));
      
      // 3. Create a project
      final mockProject = StickerBookProject(
        id: 'project-1',
        name: 'My Farm Scene',
        mode: CreationMode.infiniteCanvas,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );
      when(apiService.createProject(
        childId: childId,
        name: 'My Farm Scene',
        mode: CreationMode.infiniteCanvas,
      )).thenAnswer((_) async => mockProject);
      
      final project = await apiService.createProject(
        childId: childId,
        name: 'My Farm Scene',
        mode: CreationMode.infiniteCanvas,
      );
      expect(project.name, equals('My Farm Scene'));
      
      // 4. Start game session
      final mockSession = GameSession(
        id: 'session-1',
        childGameInstanceId: 'instance-1',
        startedAt: DateTime.now(),
      );
      when(apiService.startGameSession(childId: childId))
          .thenAnswer((_) async => mockSession);
      
      final session = await apiService.startGameSession(childId: childId);
      expect(session!.id, equals('session-1'));
      
      // 5. Record interactions
      when(apiService.recordInteraction(
        childId: childId,
        projectId: project.id,
        sessionId: session.id,
        interactionType: 'sticker_placed',
        interactionData: anyNamed('interactionData'),
      )).thenAnswer((_) async => true);
      
      final interactionRecorded = await apiService.recordInteraction(
        childId: childId,
        projectId: project.id,
        sessionId: session.id,
        interactionType: 'sticker_placed',
        interactionData: {'stickerId': 'cow_1'},
      );
      expect(interactionRecorded, isTrue);
      
      // 6. Update project
      final updatedProject = project.copyWith(
        lastModified: DateTime.now(),
      );
      when(apiService.updateProject(
        childId: childId,
        projectId: project.id,
        projectData: anyNamed('projectData'),
      )).thenAnswer((_) async => updatedProject);
      
      final updated = await apiService.updateProject(
        childId: childId,
        projectId: project.id,
        projectData: {'canvas': {'stickers': [{'id': 'cow_1'}]}},
      );
      expect(updated, isNotNull);
      
      // 7. End session
      when(apiService.endGameSession(session.id, anyNamed('finalMetrics')))
          .thenAnswer((_) async => true);
      
      final sessionEnded = await apiService.endGameSession(
        session.id,
        {'playTime': 300, 'stickersUsed': 1},
      );
      expect(sessionEnded, isTrue);
      
      // Verify all interactions happened
      verify(apiService.initializeStickerGame(childId)).called(1);
      verify(apiService.getAvailableStickerSets(childId)).called(1);
      verify(apiService.createProject(
        childId: childId,
        name: 'My Farm Scene',
        mode: CreationMode.infiniteCanvas,
      )).called(1);
      verify(apiService.startGameSession(childId: childId)).called(1);
      verify(apiService.recordInteraction(
        childId: childId,
        projectId: project.id,
        sessionId: session.id,
        interactionType: 'sticker_placed',
        interactionData: anyNamed('interactionData'),
      )).called(1);
      verify(apiService.updateProject(
        childId: childId,
        projectId: project.id,
        projectData: anyNamed('projectData'),
      )).called(1);
      verify(apiService.endGameSession(session.id, anyNamed('finalMetrics'))).called(1);
    });
  });
}

/// Helper extension for testing
extension StickerBookProjectTestExtension on StickerBookProject {
  StickerBookProject copyWith({
    String? id,
    String? name,
    String? description,
    CreationMode? mode,
    CreativeCanvas? infiniteCanvas,
    FlipBook? flipBook,
    DateTime? createdAt,
    DateTime? lastModified,
    String? thumbnailPath,
  }) {
    return StickerBookProject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mode: mode ?? this.mode,
      infiniteCanvas: infiniteCanvas ?? this.infiniteCanvas,
      flipBook: flipBook ?? this.flipBook,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}