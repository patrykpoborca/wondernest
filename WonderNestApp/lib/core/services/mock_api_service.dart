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
}