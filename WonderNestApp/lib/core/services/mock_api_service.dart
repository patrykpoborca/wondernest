import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mock API service for development while backend is being implemented
/// This simulates the expected API responses based on API_SPECIFICATIONS.md
class MockApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Simulated database
  static final Map<String, Map<String, dynamic>> _users = {};
  static final Map<String, Map<String, dynamic>> _sessions = {};
  
  Future<Response> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    // Check if user exists
    final user = _users[email];
    if (user == null || user['password'] != password) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/parent/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/parent/login'),
          statusCode: 401,
          data: {
            'success': false,
            'error': {
              'code': 'INVALID_CREDENTIALS',
              'message': 'Invalid email or password',
            }
          },
        ),
      );
    }
    
    // Generate tokens
    final accessToken = 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken = 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
    
    // Store session
    _sessions[accessToken] = {
      'userId': user['userId'],
      'email': email,
      'expiresAt': DateTime.now().add(const Duration(hours: 1)),
    };
    
    return Response(
      requestOptions: RequestOptions(path: '/auth/parent/login'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'userId': user['userId'],
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresIn': 3600,
          'hasPin': user['hasPin'] ?? false,
          'children': user['children'] ?? [],
        }
      },
    );
  }
  
  Future<Response> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    // Check if email already exists
    if (_users.containsKey(email)) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/parent/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/parent/register'),
          statusCode: 400,
          data: {
            'success': false,
            'error': {
              'code': 'EMAIL_EXISTS',
              'message': 'Email already registered',
            }
          },
        ),
      );
    }
    
    // Create user
    final userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final fullName = '$firstName $lastName';
    
    _users[email] = {
      'userId': userId,
      'email': email,
      'password': password,
      'name': fullName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'hasPin': false,
      'children': [],
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Generate tokens
    final accessToken = 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken = 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
    
    // Store session
    _sessions[accessToken] = {
      'userId': userId,
      'email': email,
      'expiresAt': DateTime.now().add(const Duration(hours: 1)),
    };
    
    return Response(
      requestOptions: RequestOptions(path: '/auth/parent/register'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'userId': userId,
          'email': email,
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresIn': 3600,
          'requiresPinSetup': true,
        }
      },
    );
  }
  
  Future<Response> refreshToken(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate new tokens
    final accessToken = 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';
    final newRefreshToken = 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
    
    return Response(
      requestOptions: RequestOptions(path: '/auth/session/refresh'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'accessToken': accessToken,
          'refreshToken': newRefreshToken,
          'expiresIn': 3600,
        }
      },
    );
  }
  
  Future<Response> getProfile(String? accessToken) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (accessToken == null || !_sessions.containsKey(accessToken)) {
      throw DioException(
        requestOptions: RequestOptions(path: '/family/profile'),
        response: Response(
          requestOptions: RequestOptions(path: '/family/profile'),
          statusCode: 401,
          data: {
            'success': false,
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Invalid or expired token',
            }
          },
        ),
      );
    }
    
    final session = _sessions[accessToken]!;
    final user = _users.values.firstWhere(
      (u) => u['userId'] == session['userId'],
      orElse: () => {},
    );
    
    return Response(
      requestOptions: RequestOptions(path: '/family/profile'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'familyId': 'fam_${session['userId']}',
          'parentName': user['name'] ?? 'Parent',
          'children': user['children'] ?? [],
          'subscription': {
            'plan': 'free',
            'validUntil': '2025-12-31',
            'maxChildren': 5,
          }
        }
      },
    );
  }
  
  Future<void> saveTokens(String token, String refreshToken) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }
  
  Future<void> logout() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _sessions.remove(token);
    }
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
  }
  
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && _sessions.containsKey(token);
  }
  
  // COPPA Consent Mock Implementation
  Future<Response> submitCOPPAConsent({
    required String childId,
    required String consentType,
    required Map<String, dynamic> permissions,
    required String verificationMethod,
    Map<String, dynamic>? verificationData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return Response(
      requestOptions: RequestOptions(path: '/coppa/consent'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'consentId': 'consent_${DateTime.now().millisecondsSinceEpoch}',
          'childId': childId,
          'consentType': consentType,
          'permissions': permissions,
          'verificationMethod': verificationMethod,
          'verificationData': verificationData,
          'submittedAt': DateTime.now().toIso8601String(),
          'status': 'approved',
        }
      },
    );
  }
  
  // Health check mock
  Future<Response> healthCheck() async {
    return Response(
      requestOptions: RequestOptions(path: '/health'),
      statusCode: 200,
      data: {
        'status': 'ok',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0-mock'
      },
    );
  }
  
  // Children management mocks
  Future<Response> getChildren() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get children from the first user's data (simplified for mock)
    final children = _users.values.isNotEmpty 
        ? (_users.values.first['children'] ?? [])
        : [];
    
    return Response(
      requestOptions: RequestOptions(path: '/family/children'),
      statusCode: 200,
      data: {
        'success': true,
        'data': children,
      },
    );
  }
  
  Future<Response> createChild({
    required String name,
    required DateTime birthDate,
    String? gender,
    List<String>? interests,
    String? avatar,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final childId = 'child_${DateTime.now().millisecondsSinceEpoch}';
    // Calculate age from birth date
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    
    final child = {
      'id': childId,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'age': age,
      'gender': gender,
      'interests': interests ?? [],
      'avatarUrl': avatar ?? '🐻', // Use avatarUrl to match backend response
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Add to first user's children (simplified for mock)
    if (_users.isNotEmpty) {
      final firstUser = _users.values.first;
      final children = List<Map<String, dynamic>>.from(firstUser['children'] ?? []);
      children.add(child);
      firstUser['children'] = children;
    }
    
    return Response(
      requestOptions: RequestOptions(path: '/family/children'),
      statusCode: 201,
      data: {
        'success': true,
        'data': child,
      },
    );
  }
  
  Future<Response> updateChild({
    required String childId,
    required String name,
    required DateTime birthDate,
    String? gender,
    List<String>? interests,
    String? avatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final updatedChild = {
      'id': childId,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'interests': interests ?? [],
      'avatar': avatar,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    return Response(
      requestOptions: RequestOptions(path: '/family/children/$childId'),
      statusCode: 200,
      data: {
        'success': true,
        'data': updatedChild,
      },
    );
  }
  
  Future<Response> deleteChild(String childId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return Response(
      requestOptions: RequestOptions(path: '/family/children/$childId'),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'Child archived successfully',
      },
    );
  }
  
  // PIN management mocks
  Future<Response> setupPin(String pin) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Store PIN for the current user (simplified)
    if (_users.isNotEmpty) {
      _users.values.first['hasPin'] = true;
      _users.values.first['pin'] = pin; // In real app, this would be hashed
    }
    
    return Response(
      requestOptions: RequestOptions(path: '/auth/parent/setup-pin'),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'PIN setup successfully',
      },
    );
  }
  
  Future<Response> verifyPin(String pin) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check PIN (simplified - any 6 digits work in mock)
    if (pin.length == 6 && RegExp(r'^\d+$').hasMatch(pin)) {
      return Response(
        requestOptions: RequestOptions(path: '/auth/parent/verify-pin'),
        statusCode: 200,
        data: {
          'success': true,
          'valid': true,
        },
      );
    }
    
    throw DioException(
      requestOptions: RequestOptions(path: '/auth/parent/verify-pin'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/parent/verify-pin'),
        statusCode: 401,
        data: {
          'success': false,
          'error': {
            'code': 'INVALID_PIN',
            'message': 'Invalid PIN',
          },
        },
      ),
    );
  }
  
  // Family management mocks
  Future<Response> getFamilyProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get first user as the parent (simplified for mock)
    final user = _users.values.isNotEmpty ? _users.values.first : null;
    final children = user?['children'] ?? [];
    
    return Response(
      requestOptions: RequestOptions(path: '/family/profile'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'family': {
            'id': 'fam_mock_001',
            'name': 'Mock Family',
            'createdAt': DateTime.now().toIso8601String(),
          },
          'members': user != null ? [{
            'userId': user['userId'],
            'firstName': user['firstName'] ?? 'Mock',
            'lastName': user['lastName'] ?? 'Parent',
            'email': user['email'],
            'role': 'parent',
            'joinedAt': user['createdAt'],
          }] : [],
          'children': children,
        },
      },
    );
  }
  
  Future<Response> updateFamilySettings(Map<String, dynamic> settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return Response(
      requestOptions: RequestOptions(path: '/family/settings'),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'Settings updated successfully',
        'data': settings,
      },
    );
  }

  // Game endpoints
  Future<Response> saveGameProgress({
    required String gameId,
    required String childId,
    required int score,
    required int level,
    required int playTimeMinutes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return Response(
      requestOptions: RequestOptions(path: '/games/progress'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'gameId': gameId,
          'childId': childId,
          'score': score,
          'level': level,
          'playTimeMinutes': playTimeMinutes,
          'savedAt': DateTime.now().toIso8601String(),
        },
      },
    );
  }

  Future<Response> saveGameEvent(Map<String, dynamic> eventData) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return Response(
      requestOptions: RequestOptions(path: '/games/events'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'eventId': 'evt_${DateTime.now().millisecondsSinceEpoch}',
          'savedAt': DateTime.now().toIso8601String(),
        },
      },
    );
  }

  Future<Response> getChildGameData(String childId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Create mock saved sticker book project data that matches the expected backend format
    final mockProject = {
      'id': 'mock_project_1',
      'name': 'My First Creation',
      'originalProject': {
        'name': 'My First Creation',
        'lastModified': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'infiniteCanvas': {
          'stickers': [
            {
              'sticker': {'emoji': '🦄', 'category': 'animals'},
              'position': {'dx': 100.0, 'dy': 150.0},
              'scale': 1.0,
              'rotation': 0.0,
            },
            {
              'sticker': {'emoji': '🌟', 'category': 'shapes'},
              'position': {'dx': 200.0, 'dy': 100.0},
              'scale': 1.2,
              'rotation': 0.5,
            },
          ],
          'drawings': [
            {
              'points': [
                {'dx': 50.0, 'dy': 50.0},
                {'dx': 60.0, 'dy': 60.0},
                {'dx': 70.0, 'dy': 55.0},
              ],
              'color': {'value': 4294901760}, // Red color
              'strokeWidth': 3.0,
            },
          ],
        },
        'flipBook': null,
      },
      'savedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'ageMode': 'bigKid',
      'thumbnailPath': null,
      'description': null,
    };
    
    // Format the response to match the real backend structure
    return Response(
      requestOptions: RequestOptions(path: '/analytics/children/$childId/events'),
      statusCode: 200,
      data: {
        'data': {
          'gameData': [
            {
              'dataKey': 'sticker_project_mock_project_1',
              'dataValue': jsonEncode(mockProject),
            },
            // Add a second mock project to test multi-project scenarios
            {
              'dataKey': 'sticker_project_mock_project_2', 
              'dataValue': jsonEncode({
                'id': 'mock_project_2',
                'name': 'Rainbow Drawing',
                'originalProject': {
                  'name': 'Rainbow Drawing',
                  'lastModified': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
                  'infiniteCanvas': {
                    'stickers': [
                      {
                        'sticker': {'emoji': '🌈', 'category': 'nature'},
                        'position': {'dx': 150.0, 'dy': 100.0},
                        'scale': 1.5,
                        'rotation': 0.0,
                      },
                    ],
                    'drawings': [],
                  },
                  'flipBook': null,
                },
                'savedAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
                'ageMode': 'littleKid',
                'thumbnailPath': null,
                'description': null,
              }),
            },
          ],
        },
      },
    );
  }

  Future<Response> unlockAchievement({
    required String gameId,
    required String childId,
    required String achievementId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return Response(
      requestOptions: RequestOptions(path: '/games/achievements/unlock'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'achievementId': achievementId,
          'gameId': gameId,
          'childId': childId,
          'unlockedAt': DateTime.now().toIso8601String(),
        },
      },
    );
  }

  Future<Response> updateVirtualCurrency({
    required String childId,
    required int balance,
    required List<Map<String, dynamic>> transactions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return Response(
      requestOptions: RequestOptions(path: '/games/currency/update'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'childId': childId,
          'balance': balance,
          'transactionCount': transactions.length,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      },
    );
  }

  // =============================================================================
  // FILE UPLOAD ENDPOINTS
  // =============================================================================

  // Simulated file storage
  static final Map<String, Map<String, dynamic>> _uploadedFiles = {};
  static int _fileIdCounter = 1;

  Future<Response> uploadFile({
    required FormData formData,
    Map<String, dynamic>? queryParams,
    Function(double)? onProgress,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate upload time
    
    // Simulate progress callbacks
    if (onProgress != null) {
      for (double progress = 0.0; progress <= 1.0; progress += 0.1) {
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress(progress);
      }
    }
    
    // Generate file ID
    final fileId = 'file_${_fileIdCounter++}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Extract query parameters
    final category = queryParams?['category'] ?? 'content';
    final childId = queryParams?['childId'];
    final isPublic = queryParams?['isPublic'] == 'true';
    
    // Create mock file record
    final uploadedFile = {
      'id': fileId,
      'originalName': 'mock_file.jpg',
      'mimeType': 'image/jpeg',
      'fileSize': 1024 * 100, // 100KB
      'category': category,
      'url': 'https://mock.storage.com/files/$fileId',
      'uploadedAt': DateTime.now().toIso8601String(),
      'metadata': {
        'childId': childId,
        'isPublic': isPublic,
      },
    };
    
    _uploadedFiles[fileId] = uploadedFile;
    
    return Response(
      requestOptions: RequestOptions(path: '/api/v1/files/upload'),
      statusCode: 201,
      data: {
        'success': true,
        'data': uploadedFile,
      },
    );
  }

  Future<Response> getFile(String fileId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final file = _uploadedFiles[fileId];
    if (file == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/files/$fileId'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/files/$fileId'),
          statusCode: 404,
          data: {
            'success': false,
            'error': {
              'code': 'FILE_NOT_FOUND',
              'message': 'File not found',
            },
          },
        ),
      );
    }
    
    return Response(
      requestOptions: RequestOptions(path: '/api/v1/files/$fileId'),
      statusCode: 200,
      data: {
        'success': true,
        'data': file,
      },
    );
  }

  Future<Response> downloadFile({
    required String fileId,
    required String savePath,
    Function(double)? onProgress,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate download time
    
    final file = _uploadedFiles[fileId];
    if (file == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/files/$fileId/download'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/files/$fileId/download'),
          statusCode: 404,
          data: {
            'success': false,
            'error': {
              'code': 'FILE_NOT_FOUND',
              'message': 'File not found',
            },
          },
        ),
      );
    }
    
    // Simulate progress callbacks
    if (onProgress != null) {
      for (double progress = 0.0; progress <= 1.0; progress += 0.1) {
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress(progress);
      }
    }
    
    // In a real scenario, this would save the file to the specified path
    // For mock, we just return success
    return Response(
      requestOptions: RequestOptions(path: '/api/v1/files/$fileId/download'),
      statusCode: 200,
      data: 'Mock file content'.codeUnits, // Simulate file data
    );
  }

  Future<Response> deleteFile(String fileId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final file = _uploadedFiles[fileId];
    if (file == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/files/$fileId'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/files/$fileId'),
          statusCode: 404,
          data: {
            'success': false,
            'error': {
              'code': 'FILE_NOT_FOUND',
              'message': 'File not found',
            },
          },
        ),
      );
    }
    
    // Mark as deleted (soft delete)
    file['deletedAt'] = DateTime.now().toIso8601String();
    
    return Response(
      requestOptions: RequestOptions(path: '/api/v1/files/$fileId'),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'File deleted successfully',
      },
    );
  }

  Future<Response> listUserFiles({
    Map<String, dynamic>? queryParams,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Extract query parameters
    final category = queryParams?['category'];
    final childId = queryParams?['childId'];
    final limit = int.tryParse(queryParams?['limit'] ?? '100') ?? 100;
    final offset = int.tryParse(queryParams?['offset'] ?? '0') ?? 0;
    
    // Filter files
    var files = _uploadedFiles.values.where((file) {
      // Exclude deleted files
      if (file['deletedAt'] != null) return false;
      
      // Filter by category
      if (category != null && file['category'] != category) return false;
      
      // Filter by childId
      if (childId != null && file['metadata']?['childId'] != childId) return false;
      
      return true;
    }).toList();
    
    // Apply pagination
    final totalCount = files.length;
    files = files.skip(offset).take(limit).toList();
    
    return Response(
      requestOptions: RequestOptions(path: '/api/v1/files'),
      statusCode: 200,
      data: {
        'success': true,
        'data': files,
        'metadata': {
          'totalCount': totalCount,
          'limit': limit,
          'offset': offset,
        },
      },
    );
  }

  // =============================================================================
  // GAME DATA PERSISTENCE
  // =============================================================================

  // Simulated game data storage
  static final Map<String, List<Map<String, dynamic>>> _gameData = {};
  
  Future<Response> saveGameData(String childId, Map<String, dynamic> gameData) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Initialize child's game data if not exists
    _gameData[childId] ??= [];
    
    // Enhanced API v2 uses gameKey instead of gameType
    final gameKey = gameData['gameKey'] as String;
    final dataKey = gameData['dataKey'] as String;
    _gameData[childId]!.removeWhere((item) => 
      item['gameKey'] == gameKey && item['dataKey'] == dataKey);
    
    // Add new data
    _gameData[childId]!.add({
      'id': 'mock_id_${DateTime.now().millisecondsSinceEpoch}',
      'instanceId': 'mock_instance_${DateTime.now().millisecondsSinceEpoch}',
      'childId': childId,
      'gameKey': gameKey,
      'dataKey': dataKey,
      'dataValue': gameData['dataValue'],
      'dataVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    return Response(
      requestOptions: RequestOptions(path: '/children/$childId/data'),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'Game data saved successfully',
        'childId': childId,
        'gameKey': gameKey,
        'dataKey': dataKey,
        'data': _gameData[childId]!.last,
      },
    );
  }
  
  Future<Response> getGameData(String childId, {String? gameType, String? dataKey}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final childData = _gameData[childId] ?? [];
    
    // Apply filters - gameType parameter maps to gameKey for v2 compatibility
    var filteredData = childData;
    if (gameType != null) {
      filteredData = filteredData.where((item) => item['gameKey'] == gameType).toList();
    }
    if (dataKey != null) {
      filteredData = filteredData.where((item) => item['dataKey'] == dataKey).toList();
    }
    
    return Response(
      requestOptions: RequestOptions(path: '/children/$childId/data'),
      statusCode: 200,
      data: {
        'success': true,
        'gameData': filteredData,
      },
    );
  }
  
  Future<Response> deleteGameData(String childId, String gameKey, String dataKey) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final childData = _gameData[childId] ?? [];
    final initialLength = childData.length;
    
    // Remove matching data - use gameKey for v2 compatibility
    _gameData[childId] = childData.where((item) => 
      !(item['gameKey'] == gameKey && item['dataKey'] == dataKey)).toList();
    
    final found = _gameData[childId]!.length < initialLength;
    
    return Response(
      requestOptions: RequestOptions(path: '/children/$childId/data/$gameKey/$dataKey'),
      statusCode: found ? 200 : 404,
      data: found ? {
        'success': true,
        'message': 'Game data deleted successfully',
        'childId': childId,
        'gameKey': gameKey,
        'dataKey': dataKey,
        'data': null,
      } : {
        'success': false,
        'message': 'Game data not found',
      },
    );
  }
  
  // ============================================================================
  // AI Story Generation Mock Methods
  // ============================================================================
  
  final List<Map<String, dynamic>> _storyHistory = [];
  int _dailyUsed = 0;
  int _monthlyUsed = 0;
  
  Future<Map<String, dynamic>?> generateAIStory({
    required String prompt,
    String? title,
    List<String>? imageIds,
    String? childId,
    String? targetAge,
    List<String>? educationalGoals,
  }) async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate AI generation time
    
    final storyId = 'story_${DateTime.now().millisecondsSinceEpoch}';
    final generatedTitle = title ?? 'The ${_getRandomAdjective()} ${_getRandomNoun()}';
    
    final story = {
      'id': storyId,
      'title': generatedTitle,
      'content': _generateMockStoryContent(prompt, targetAge ?? '3-5'),
      'chapters': [
        {
          'title': 'Chapter 1: The Beginning',
          'content': 'Once upon a time, in a land filled with wonder and magic, $prompt',
          'orderIndex': 0,
        },
        {
          'title': 'Chapter 2: The Adventure',
          'content': 'Our hero embarked on an amazing journey, discovering new friends and learning valuable lessons along the way.',
          'orderIndex': 1,
        },
        {
          'title': 'Chapter 3: The Happy Ending',
          'content': 'And so, with courage and kindness, everyone lived happily ever after. The end.',
          'orderIndex': 2,
        },
      ],
      'metadata': {
        'ageRange': targetAge ?? '3-5',
        'educationalGoals': educationalGoals ?? [],
        'themes': ['adventure', 'friendship', 'learning'],
        'language': 'en',
        'wordCount': 250,
        'readingLevel': _getReadingLevel(targetAge ?? '3-5'),
        'safetyScore': 0.98,
      },
      'imageUrls': imageIds?.map((id) => 'https://placeholder.com/image/$id').toList() ?? [],
      'createdAt': DateTime.now().toIso8601String(),
      'childId': childId,
      'parentId': 'parent_123',
    };
    
    _storyHistory.insert(0, story);
    _dailyUsed++;
    _monthlyUsed++;
    
    return story;
  }
  
  Future<Map<String, dynamic>?> getAIStoryHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'stories': _storyHistory,
      'totalCount': _storyHistory.length,
    };
  }
  
  Future<Map<String, dynamic>?> getAIQuota() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return {
      'dailyUsed': _dailyUsed,
      'dailyLimit': 5,
      'monthlyUsed': _monthlyUsed,
      'monthlyLimit': 50,
      'dailyResetAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      'monthlyResetAt': DateTime(DateTime.now().year, DateTime.now().month + 1, 1).toIso8601String(),
    };
  }
  
  Future<bool> saveStoryToLibrary(String storyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // In a real app, this would save to the child's library
    return true;
  }
  
  // Helper methods for mock story generation
  String _generateMockStoryContent(String prompt, String ageRange) {
    final baseStory = '''
Once upon a time, there was a magical adventure waiting to unfold. $prompt

In this wonderful story, our characters learned about friendship, kindness, and the importance of being brave. They discovered that with imagination and creativity, anything is possible.

As the sun set on their adventure, everyone gathered together to celebrate what they had learned. They knew that tomorrow would bring new adventures and new opportunities to grow.

The end.
''';
    
    // Adjust complexity based on age range
    if (ageRange == '3-5') {
      return baseStory.replaceAll(RegExp(r'\b\w{10,}\b'), 'fun');
    } else if (ageRange == '6-8') {
      return baseStory;
    } else {
      return '$baseStory\n\nEpilogue: This story teaches us that every challenge is an opportunity for growth.';
    }
  }
  
  String _getRandomAdjective() {
    final adjectives = ['Brave', 'Curious', 'Magical', 'Wonderful', 'Amazing', 'Clever', 'Kind'];
    return adjectives[DateTime.now().millisecond % adjectives.length];
  }
  
  String _getRandomNoun() {
    final nouns = ['Adventure', 'Journey', 'Discovery', 'Friend', 'Explorer', 'Hero', 'Dream'];
    return nouns[DateTime.now().second % nouns.length];
  }
  
  String _getReadingLevel(String ageRange) {
    switch (ageRange) {
      case '3-5':
        return 'Pre-K';
      case '6-8':
        return 'Early Elementary';
      case '9-12':
        return 'Elementary';
      default:
        return 'All Ages';
    }
  }
}