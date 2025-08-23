import 'package:dio/dio.dart';
import 'dart:io' show Platform;
import '../../core/services/timber_wrapper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'mock_api_service.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator/physical devices
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    } else {
      return 'http://localhost:8080/api/v1';
    }
  }
  
  static String get healthUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    } else {
      return 'http://localhost:8080';
    }
  }
  
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Use mock service when backend is not available
  static bool _useMockService = false;
  final MockApiService _mockService = MockApiService();
  
  ApiService._internal() {
    Timber.i('[API] Initializing ApiService');
    Timber.i('[API] Platform: ${Platform.operatingSystem}');
    Timber.i('[API] Base URL: $baseUrl');
    Timber.i('[API] Health URL: $healthUrl');
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Check if backend is available
    _checkBackendAvailability();
    
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Log detailed request info for debugging
        if (options.path.contains('/analytics/events')) {
          Timber.d('[API] === HTTP REQUEST DEBUG ===');
          Timber.d('[API] Method: ${options.method}');
          Timber.d('[API] Path: ${options.path}');
          Timber.d('[API] Full URL: ${options.baseUrl}${options.path}');
          Timber.d('[API] Headers:');
          options.headers.forEach((key, value) => 
            Timber.d('[API]   $key: ${key.toLowerCase().contains('auth') ? '[REDACTED]' : value}'));
          Timber.d('[API] Request data type: ${options.data?.runtimeType}');
          if (options.data != null) {
            Timber.d('[API] Request data: ${options.data}');
          }
          Timber.d('[API] === END HTTP REQUEST DEBUG ===');
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) async {
        if (response.requestOptions.path.contains('/analytics/events')) {
          Timber.d('[API] === HTTP RESPONSE DEBUG ===');
          Timber.d('[API] Status Code: ${response.statusCode}');
          Timber.d('[API] Status Message: ${response.statusMessage}');
          Timber.d('[API] Response Headers:');
          response.headers.forEach((key, values) => 
            Timber.d('[API]   $key: $values'));
          Timber.d('[API] Response Data: ${response.data}');
          Timber.d('[API] === END HTTP RESPONSE DEBUG ===');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        // Log detailed error info for debugging
        if (error.requestOptions.path.contains('/analytics/events')) {
          Timber.e('[API] === HTTP ERROR DEBUG ===');
          Timber.e('[API] Error Type: ${error.type}');
          Timber.e('[API] Error Message: ${error.message}');
          Timber.e('[API] Request Path: ${error.requestOptions.path}');
          if (error.response != null) {
            Timber.e('[API] Response Status: ${error.response!.statusCode}');
            Timber.e('[API] Response Status Message: ${error.response!.statusMessage}');
            Timber.e('[API] Response Data: ${error.response!.data}');
            Timber.e('[API] Response Headers:');
            error.response!.headers.forEach((key, values) => 
              Timber.e('[API]   $key: $values'));
          }
          Timber.e('[API] === END HTTP ERROR DEBUG ===');
        }
        
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          final refreshToken = await _storage.read(key: refreshTokenKey);
          if (refreshToken != null) {
            try {
              // Create a new Dio instance for refresh to avoid interceptor loops
              final refreshDio = Dio(BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                },
              ));
              
              final response = await refreshDio.post('/auth/session/refresh', data: {
                'refreshToken': refreshToken,
              });
              
              // Handle response structure with data wrapper
              final responseData = response.data['data'] ?? response.data;
              final newToken = responseData['accessToken'];
              final newRefreshToken = responseData['refreshToken'];
              
              await _storage.write(key: tokenKey, value: newToken);
              await _storage.write(key: refreshTokenKey, value: newRefreshToken);
              
              // Retry the original request with new token
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final cloneReq = await _dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              
              return handler.resolve(cloneReq);
            } catch (e) {
              // Refresh failed, logout user
              await logout();
            }
          }
        }
        handler.next(error);
      },
    ));
  }
  
  Future<void> saveTokens(String token, String refreshToken) async {
    await _storage.write(key: tokenKey, value: token);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
  }
  
  Future<void> logout() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: refreshTokenKey);
  }
  
  Future<bool> isLoggedIn() async {
    if (_useMockService) {
      return _mockService.isLoggedIn();
    }
    final token = await _storage.read(key: tokenKey);
    return token != null;
  }
  
  // Helper method to check if we're using mock service
  bool get isUsingMockService => _useMockService;
  
  Future<void> _checkBackendAvailability() async {
    try {
      // Check the actual health endpoint (without /api/v1 prefix)
      final healthDio = Dio(BaseOptions(
        baseUrl: healthUrl,
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ));
      await healthDio.get('/health');
      _useMockService = false;
      Timber.i('[API] Connected to real backend at $healthUrl');
    } catch (e) {
      // Backend not available, using mock service
      _useMockService = true;
      Timber.w('[API] Backend not available at $healthUrl, using mock service. Error: ${e.toString()}');
    }
  }
  
  // Health check endpoint
  Future<Response> healthCheck() async {
    if (_useMockService) {
      return _mockService.healthCheck();
    }
    // Health endpoint is at root level, not under /api/v1
    final healthDio = Dio(BaseOptions(
      baseUrl: healthUrl,
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
    ));
    return healthDio.get('/health');
  }
  
  // Auth endpoints
  Future<Response> login(String email, String password) {
    if (_useMockService) {
      Timber.i('[API] Using mock service for login');
      return _mockService.login(email, password);
    }
    
    Timber.i('[API] Making login request to $baseUrl/auth/parent/login');
    Timber.i('[API] Platform: ${Platform.operatingSystem}');
    Timber.i('[API] Base URL: $baseUrl');
    
    return _dio.post('/auth/parent/login', data: {
      'email': email,
      'password': password,
    });
  }
  
  Future<Response> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) {
    if (_useMockService) {
      return _mockService.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
    }
    
    // Combine first and last name for the API
    final fullName = '$firstName $lastName'.trim();
    
    return _dio.post('/auth/parent/register', data: {
      'email': email,
      'password': password,
      'name': fullName,
      'phoneNumber': phoneNumber ?? '',
      'countryCode': 'US', // Default to US for now
    });
  }
  
  Future<Response> getProfile() async {
    if (_useMockService) {
      final token = await _storage.read(key: tokenKey);
      return _mockService.getProfile(token);
    }
    return _dio.get('/family/profile');
  }
  
  // PIN management endpoints
  Future<Response> setupPin(String pin) {
    if (_useMockService) {
      return _mockService.setupPin(pin);
    }
    return _dio.post('/auth/parent/setup-pin', data: {
      'pin': pin,
    });
  }
  
  Future<Response> verifyPin(String pin) {
    if (_useMockService) {
      return _mockService.verifyPin(pin);
    }
    return _dio.post('/auth/parent/verify-pin', data: {
      'pin': pin,
    });
  }
  
  // Family endpoints
  Future<Response> getFamilyProfile() {
    if (_useMockService) {
      return _mockService.getFamilyProfile();
    }
    return _dio.get('/family/profile');
  }
  
  Future<Response> updateFamilySettings(Map<String, dynamic> settings) {
    if (_useMockService) {
      return _mockService.updateFamilySettings(settings);
    }
    return _dio.put('/family/settings', data: settings);
  }
  
  // Children endpoints
  Future<Response> getChildren() {
    if (_useMockService) {
      return _mockService.getChildren();
    }
    return _dio.get('/family/children');
  }
  
  Future<Response> createChild({
    required String name,
    required DateTime birthDate,
    String? gender,
    List<String>? interests,
    String? avatar,
  }) {
    if (_useMockService) {
      return _mockService.createChild(
        name: name,
        birthDate: birthDate,
        gender: gender,
        interests: interests,
        avatar: avatar,
      );
    }
    
    // Format birthDate as YYYY-MM-DD for backend
    final formattedDate = '${birthDate.year.toString().padLeft(4, '0')}-'
        '${birthDate.month.toString().padLeft(2, '0')}-'
        '${birthDate.day.toString().padLeft(2, '0')}';
    
    return _dio.post('/family/children', data: {
      'name': name,
      'birthDate': formattedDate,
      if (gender != null) 'gender': gender,
      if (interests != null && interests.isNotEmpty) 'interests': interests,
      if (avatar != null) 'avatar': avatar,
    });
  }
  
  Future<Response> updateChild({
    required String childId,
    required String name,
    required DateTime birthDate,
    String? gender,
    List<String>? interests,
    String? avatar,
  }) {
    if (_useMockService) {
      return _mockService.updateChild(
        childId: childId,
        name: name,
        birthDate: birthDate,
        gender: gender,
        interests: interests,
        avatar: avatar,
      );
    }
    
    // Format birthDate as YYYY-MM-DD for backend
    final formattedDate = '${birthDate.year.toString().padLeft(4, '0')}-'
        '${birthDate.month.toString().padLeft(2, '0')}-'
        '${birthDate.day.toString().padLeft(2, '0')}';
    
    return _dio.put('/family/children/$childId', data: {
      'name': name,
      'birthDate': formattedDate,
      if (gender != null) 'gender': gender,
      if (interests != null) 'interests': interests,
      if (avatar != null) 'avatar': avatar,
    });
  }
  
  Future<Response> deleteChild(String childId) {
    if (_useMockService) {
      return _mockService.deleteChild(childId);
    }
    return _dio.delete('/family/children/$childId');
  }
  
  // Content endpoints
  Future<Response> getContent({String? category, int? ageGroup}) {
    return _dio.get('/content', queryParameters: {
      if (category != null) 'category': category,
      if (ageGroup != null) 'ageGroup': ageGroup,
    });
  }
  
  // Analytics endpoints
  Future<Response> getDailyAnalytics(String childId) {
    return _dio.get('/analytics/daily', queryParameters: {
      'childId': childId,
    });
  }
  
  // Game endpoints - redirected to analytics endpoints since game routes are disabled
  Future<Response> saveGameProgress({
    required String gameId,
    required String childId,
    required int score,
    required int level,
    required int playTimeMinutes,
  }) {
    if (_useMockService) {
      return _mockService.saveGameProgress(
        gameId: gameId,
        childId: childId,
        score: score,
        level: level,
        playTimeMinutes: playTimeMinutes,
      );
    }
    
    // Game routes are disabled, redirect to analytics endpoint
    final analyticsEvent = {
      'eventType': 'game_progress',
      'childId': childId,
      'contentId': gameId,
      'duration': playTimeMinutes,
      'eventData': {
        'gameId': gameId,
        'score': score,
        'level': level,
        'playTimeMinutes': playTimeMinutes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    };
    
    return _dio.post('/analytics/events', data: analyticsEvent);
  }

  Future<Response> saveGameEvent(Map<String, dynamic> eventData) {
    Timber.d('[API] === SAVE GAME EVENT START ===');
    Timber.d('[API] Received eventData keys: ${eventData.keys.toList()}');
    Timber.d('[API] Raw eventData received:');
    eventData.forEach((key, value) => Timber.d('[API]   $key: $value (${value?.runtimeType})'));
    
    if (_useMockService) {
      Timber.i('[API] Using mock service for saveGameEvent');
      return _mockService.saveGameEvent(eventData);
    }
    
    try {
      Timber.d('[API] Converting to analytics event format...');
      
      // Game routes are disabled, redirect to analytics endpoint
      // Convert game event data to analytics event format
      final analyticsEvent = {
        'eventType': eventData['eventType'] ?? 'game_event',
        'childId': eventData['childId'] ?? '',
        'contentId': eventData['gameId'] ?? eventData['contentId'] ?? eventData['gameType'] ?? 'unknown',
        'duration': _parseDuration(eventData['duration'] ?? eventData['playTimeMinutes'] ?? 0),
        'eventData': _prepareEventData(eventData),
        'sessionId': eventData['sessionId'],
      };
      
      Timber.d('[API] Analytics event created:');
      Timber.d('[API]   eventType: ${analyticsEvent['eventType']}');
      Timber.d('[API]   childId: ${analyticsEvent['childId']}');
      Timber.d('[API]   contentId: ${analyticsEvent['contentId']}');
      Timber.d('[API]   duration: ${analyticsEvent['duration']} (${analyticsEvent['duration'].runtimeType})');
      Timber.d('[API]   sessionId: ${analyticsEvent['sessionId']}');
      
      final preparedEventData = analyticsEvent['eventData'] as Map<String, dynamic>;
      Timber.d('[API]   eventData contents (${preparedEventData.length} fields):');
      preparedEventData.forEach((key, value) => 
        Timber.d('[API]     $key: $value (${value?.runtimeType})'));
      
      Timber.d('[API] Making POST request to /analytics/events...');
      Timber.d('[API] Full request payload: $analyticsEvent');
      
      return _dio.post('/analytics/events', data: analyticsEvent);
      
    } catch (e, stackTrace) {
      Timber.e('[API] Error in saveGameEvent: $e');
      Timber.e('[API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Helper method to prepare event data preserving proper data types
  Map<String, dynamic> _prepareEventData(Map<String, dynamic> eventData) {
    Timber.d('[API] === PREPARING EVENT DATA ===');
    Timber.d('[API] Input eventData has ${eventData.length} fields');
    
    final cleanedEventData = <String, dynamic>{};
    final skippedFields = <String>[];
    const topLevelFields = ['eventType', 'childId', 'gameId', 'contentId', 'duration', 'playTimeMinutes', 'sessionId'];
    
    for (final entry in eventData.entries) {
      final key = entry.key;
      final value = entry.value;
      
      Timber.d('[API] Processing field: $key = $value (${value?.runtimeType})');
      
      // Skip fields that are already handled at the top level
      if (topLevelFields.contains(key)) {
        skippedFields.add(key);
        Timber.d('[API]   → Skipped (top-level field)');
        continue;
      }
      
      if (value == null) {
        Timber.d('[API]   → Skipped (null value)');
        continue;
      } else if (value is DateTime) {
        final timestamp = value.millisecondsSinceEpoch;
        cleanedEventData[key] = timestamp;
        Timber.d('[API]   → Converted DateTime to timestamp: $timestamp');
      } else if (value is bool || value is num || value is String) {
        cleanedEventData[key] = value;
        Timber.d('[API]   → Kept primitive type as-is');
      } else if (value is List || value is Map) {
        cleanedEventData[key] = value;
        Timber.d('[API]   → Kept structured data as-is (${value is List ? "List[${value.length}]" : "Map[${(value as Map).length}]"})');
      } else {
        final stringValue = value.toString();
        cleanedEventData[key] = stringValue;
        Timber.d('[API]   → Converted to string: $stringValue');
      }
    }
    
    Timber.d('[API] Event data preparation complete:');
    Timber.d('[API]   - Processed ${eventData.length} input fields');
    Timber.d('[API]   - Skipped ${skippedFields.length} top-level fields: $skippedFields');
    Timber.d('[API]   - Included ${cleanedEventData.length} fields in eventData');
    
    return cleanedEventData;
  }

  /// Parse duration value to int, handling both string and numeric inputs
  int _parseDuration(dynamic durationValue) {
    Timber.d('[API] Parsing duration: $durationValue (${durationValue?.runtimeType})');
    
    if (durationValue == null) {
      Timber.d('[API] Duration is null, returning 0');
      return 0;
    }
    
    int result;
    if (durationValue is int) {
      result = durationValue;
      Timber.d('[API] Duration is already int: $result');
    } else if (durationValue is double) {
      result = durationValue.round();
      Timber.d('[API] Converted double to int: $durationValue → $result');
    } else if (durationValue is String) {
      result = int.tryParse(durationValue) ?? 0;
      Timber.d('[API] Parsed string to int: "$durationValue" → $result');
    } else {
      result = 0;
      Timber.d('[API] Unknown duration type ${durationValue.runtimeType}, returning 0');
    }
    
    return result;
  }

  Future<Response> getChildGameData(String childId) {
    if (_useMockService) {
      return _mockService.getChildGameData(childId);
    }
    
    // Game routes are disabled, return a mock response structure for now
    // In production, this would query analytics data to reconstruct game state
    return Future.value(Response(
      requestOptions: RequestOptions(path: '/games/child/$childId'),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'gameProgress': [],
          'achievements': [],
          'virtualCurrency': {'balance': 0, 'transactions': []},
        },
      },
    ));
  }

  Future<Response> unlockAchievement({
    required String gameId,
    required String childId,
    required String achievementId,
  }) {
    if (_useMockService) {
      return _mockService.unlockAchievement(
        gameId: gameId,
        childId: childId,
        achievementId: achievementId,
      );
    }
    
    // Game routes are disabled, redirect to analytics endpoint
    final analyticsEvent = {
      'eventType': 'achievement_unlocked',
      'childId': childId,
      'contentId': gameId,
      'duration': 0,
      'eventData': {
        'gameId': gameId,
        'achievementId': achievementId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    };
    
    return _dio.post('/analytics/events', data: analyticsEvent);
  }

  Future<Response> updateVirtualCurrency({
    required String childId,
    required int balance,
    required List<Map<String, dynamic>> transactions,
  }) {
    if (_useMockService) {
      return _mockService.updateVirtualCurrency(
        childId: childId,
        balance: balance,
        transactions: transactions,
      );
    }
    
    // Game routes are disabled, redirect to analytics endpoint
    final analyticsEvent = {
      'eventType': 'virtual_currency_updated',
      'childId': childId,
      'contentId': 'virtual_currency',
      'duration': 0,
      'eventData': {
        'balance': balance,
        'transactionCount': transactions.length,
        'transactions': transactions,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    };
    
    return _dio.post('/analytics/events', data: analyticsEvent);
  }
  
  // COPPA endpoints
  Future<Response> submitCOPPAConsent({
    required String childId,
    required String consentType,
    required Map<String, dynamic> permissions,
    required String verificationMethod,
    Map<String, dynamic>? verificationData,
  }) {
    if (_useMockService) {
      return _mockService.submitCOPPAConsent(
        childId: childId,
        consentType: consentType,
        permissions: permissions,
        verificationMethod: verificationMethod,
        verificationData: verificationData,
      );
    }
    return _dio.post('/coppa/consent', data: {
      'childId': childId,
      'consentType': consentType,
      'permissions': permissions,
      'verificationMethod': verificationMethod,
      if (verificationData != null) 'verificationData': verificationData,
    });
  }
}

