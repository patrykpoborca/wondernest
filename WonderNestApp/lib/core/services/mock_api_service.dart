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
}