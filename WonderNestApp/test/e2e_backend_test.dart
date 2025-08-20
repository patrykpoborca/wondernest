import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import '../lib/core/services/timber_wrapper.dart';

void main() {
  group('End-to-End Backend Integration', () {
    late Dio dio;
    String? accessToken;
    String? refreshToken;
    String? userId;
    String? childId;
    final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final testPassword = 'TestPass123!';

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8080/api/v1',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {'Content-Type': 'application/json'},
      ));
    });

    test('1. Register new parent account', () async {
      try {
        final response = await dio.post('/auth/parent/register', data: {
          'email': testEmail,
          'password': testPassword,
          'name': 'Test Parent',
          'phoneNumber': '+1234567890',
          'countryCode': 'US',
        });

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        
        final data = response.data['data'];
        accessToken = data['accessToken'];
        refreshToken = data['refreshToken'];
        userId = data['userId'];
        
        expect(accessToken, isNotNull);
        expect(refreshToken, isNotNull);
        expect(userId, isNotNull);
        
        // Update dio with auth token
        dio.options.headers['Authorization'] = 'Bearer $accessToken';
        
        Timber.d('✅ Parent registration successful');
        Timber.d('   User ID: $userId');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to register parent: $e');
      }
    });

    test('2. Setup parent PIN', () async {
      try {
        final response = await dio.post('/auth/parent/setup-pin', data: {
          'pin': '123456',
        });

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        
        Timber.d('✅ PIN setup successful');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to setup PIN: $e');
      }
    });

    test('3. Get family profile', () async {
      try {
        final response = await dio.get('/family/profile');

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        
        final family = response.data['data'];
        expect(family, isNotNull);
        
        Timber.d('✅ Family profile retrieved');
        Timber.d('   Family ID: ${family['id']}');
        Timber.d('   Family Name: ${family['name']}');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to get family profile: $e');
      }
    });

    test('4. Create a child profile', () async {
      try {
        final response = await dio.post('/family/children', data: {
          'name': 'Test Child',
          'birthDate': '2020-01-01',
          'gender': 'MALE',
          'interests': ['reading', 'games'],
          'avatar': 'bear',
        });

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        
        final child = response.data['data'];
        childId = child['id'];
        
        expect(childId, isNotNull);
        expect(child['name'], 'Test Child');
        
        Timber.d('✅ Child profile created');
        Timber.d('   Child ID: $childId');
        Timber.d('   Child Name: ${child['name']}');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to create child: $e');
      }
    });

    test('5. Get all children', () async {
      try {
        final response = await dio.get('/family/children');

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        
        final children = response.data['data'] as List;
        expect(children.length, greaterThan(0));
        
        final createdChild = children.firstWhere(
          (c) => c['id'] == childId,
          orElse: () => null,
        );
        
        expect(createdChild, isNotNull);
        expect(createdChild['name'], 'Test Child');
        
        Timber.d('✅ Children list retrieved');
        Timber.d('   Total children: ${children.length}');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to get children: $e');
      }
    });

    test('6. Update child profile', () async {
      if (childId == null) {
        Timber.d('⚠️ Skipping: No child ID available');
        return;
      }

      try {
        final response = await dio.put('/family/children/$childId', data: {
          'name': 'Updated Child Name',
          'birthDate': '2020-01-01',
          'interests': ['reading', 'games', 'music'],
        });

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        
        final child = response.data['data'];
        expect(child['name'], 'Updated Child Name');
        expect(child['interests'], contains('music'));
        
        Timber.d('✅ Child profile updated');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to update child: $e');
      }
    });

    test('7. Submit COPPA consent', () async {
      if (childId == null) {
        Timber.d('⚠️ Skipping: No child ID available');
        return;
      }

      try {
        final response = await dio.post('/coppa/consent', data: {
          'childId': childId,
          'consentType': 'full',
          'permissions': {
            'dataCollection': true,
            'personalizedContent': true,
            'analytics': true,
          },
          'verificationMethod': 'email',
          'verificationData': {
            'email': testEmail,
          },
        });

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        
        Timber.d('✅ COPPA consent submitted');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to submit COPPA consent: $e');
      }
    });

    test('8. Verify data persistence by logging in again', () async {
      try {
        // Login with the same credentials
        final loginResponse = await dio.post('/auth/parent/login', data: {
          'email': testEmail,
          'password': testPassword,
        });

        expect(loginResponse.statusCode, 200);
        expect(loginResponse.data['success'], true);
        
        final data = loginResponse.data['data'];
        final newAccessToken = data['accessToken'];
        
        // Update dio with new auth token
        dio.options.headers['Authorization'] = 'Bearer $newAccessToken';
        
        // Get children to verify persistence
        final childrenResponse = await dio.get('/family/children');
        expect(childrenResponse.statusCode, 200);
        
        final children = childrenResponse.data['data'] as List;
        expect(children.length, greaterThan(0));
        
        final persistedChild = children.firstWhere(
          (c) => c['name'] == 'Updated Child Name',
          orElse: () => null,
        );
        
        expect(persistedChild, isNotNull);
        
        Timber.d('✅ Data persistence verified');
        Timber.d('   Child data persisted correctly in PostgreSQL');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to verify persistence: $e');
      }
    });

    test('9. Delete child profile', () async {
      if (childId == null) {
        Timber.d('⚠️ Skipping: No child ID available');
        return;
      }

      try {
        final response = await dio.delete('/family/children/$childId');

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        
        Timber.d('✅ Child profile deleted');
        
        // Verify deletion
        final childrenResponse = await dio.get('/family/children');
        final children = childrenResponse.data['data'] as List;
        
        final deletedChild = children.firstWhere(
          (c) => c['id'] == childId,
          orElse: () => null,
        );
        
        expect(deletedChild, isNull);
        Timber.d('   Deletion confirmed - child no longer in database');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to delete child: $e');
      }
    });

    test('10. Test token refresh flow', () async {
      try {
        // Use refresh token to get new access token
        final response = await dio.post('/auth/session/refresh', data: {
          'refreshToken': refreshToken,
        });

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        
        final data = response.data['data'];
        expect(data['accessToken'], isNotNull);
        expect(data['refreshToken'], isNotNull);
        
        Timber.d('✅ Token refresh successful');
      } catch (e) {
        if (e is DioException) {
          Timber.d('Response: ${e.response?.data}');
        }
        fail('Failed to refresh token: $e');
      }
    });
  });
}