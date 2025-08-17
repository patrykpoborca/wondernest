import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'mock_api_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Use mock service when backend is not available
  static bool _useMockService = false;
  final MockApiService _mockService = MockApiService();
  
  ApiService() {
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
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          final refreshToken = await _storage.read(key: refreshTokenKey);
          if (refreshToken != null) {
            try {
              final response = await _dio.post('/auth/session/refresh', data: {
                'refreshToken': refreshToken,
              });
              
              // Handle response structure with data wrapper
              final responseData = response.data['data'] ?? response.data;
              final newToken = responseData['accessToken'];
              final newRefreshToken = responseData['refreshToken'];
              
              await _storage.write(key: tokenKey, value: newToken);
              await _storage.write(key: refreshTokenKey, value: newRefreshToken);
              
              // Retry the original request
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
  
  Future<void> _checkBackendAvailability() async {
    try {
      // Check the actual health endpoint (without /api/v1 prefix)
      final healthDio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8080',
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ));
      await healthDio.get('/health');
      _useMockService = false;
      print('✅ Connected to real backend at http://localhost:8080');
    } catch (e) {
      // Backend not available, using mock service
      _useMockService = true;
      print('⚠️ Backend not available, using mock service');
    }
  }
  
  // Health check endpoint
  Future<Response> healthCheck() async {
    if (_useMockService) {
      return _mockService.healthCheck();
    }
    // Health endpoint is at root level, not under /api/v1
    final healthDio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
    ));
    return healthDio.get('/health');
  }
  
  // Auth endpoints
  Future<Response> login(String email, String password) {
    if (_useMockService) {
      return _mockService.login(email, password);
    }
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
  
  // Game endpoints
  Future<Response> saveGameProgress({
    required String gameId,
    required String childId,
    required int score,
    required int level,
    required int playTimeMinutes,
  }) {
    return _dio.post('/games/progress', data: {
      'gameId': gameId,
      'childId': childId,
      'score': score,
      'level': level,
      'playTimeMinutes': playTimeMinutes,
    });
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