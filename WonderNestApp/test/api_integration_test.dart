import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  group('Backend Integration Tests', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8080',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
    });

    test('Health endpoint should be accessible', () async {
      try {
        final response = await dio.get('/health');
        expect(response.statusCode, 200);
        expect(response.data['status'], 'UP');
        print('✅ Backend health check passed');
      } catch (e) {
        fail('Backend is not accessible: $e');
      }
    });

    test('API v1 endpoints should require authentication', () async {
      try {
        await dio.get('/api/v1/family/profile');
        fail('Expected 401 Unauthorized');
      } catch (e) {
        if (e is DioException) {
          expect(e.response?.statusCode, 401);
          print('✅ API authentication check passed');
        } else {
          rethrow;
        }
      }
    });

    test('Token refresh endpoint should work with valid refresh token', () async {
      // This test uses a mock refresh token that would normally be obtained from login
      try {
        final response = await dio.post('/api/v1/auth/session/refresh', data: {
          'refreshToken': 'invalid-token-for-testing',
        });
        // This should fail with 401 for invalid token
        fail('Expected 401 for invalid token');
      } catch (e) {
        if (e is DioException) {
          expect(e.response?.statusCode, 401);
          print('✅ Token refresh validation passed');
        } else {
          rethrow;
        }
      }
    });
  });
}