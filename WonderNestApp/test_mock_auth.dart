import 'package:dio/dio.dart';
import 'lib/core/services/mock_api_service.dart';

void main() async {
  print('Testing Mock Authentication Service...\n');
  
  final mockService = MockApiService();
  
  // Test 1: Register a new user
  print('1. Testing Registration...');
  try {
    final response = await mockService.signup(
      email: 'test@example.com',
      password: 'Password123!',
      firstName: 'John',
      lastName: 'Doe',
    );
    
    print('   Status: ${response.statusCode}');
    print('   Success: ${response.data['success']}');
    print('   User ID: ${response.data['data']['userId']}');
    print('   Token: ${response.data['data']['accessToken']?.substring(0, 20)}...\n');
  } catch (e) {
    print('   Error: $e\n');
  }
  
  // Test 2: Login with registered user
  print('2. Testing Login...');
  try {
    final response = await mockService.login('test@example.com', 'Password123!');
    
    print('   Status: ${response.statusCode}');
    print('   Success: ${response.data['success']}');
    print('   User ID: ${response.data['data']['userId']}');
    print('   Has PIN: ${response.data['data']['hasPin']}\n');
  } catch (e) {
    print('   Error: $e\n');
  }
  
  // Test 3: Try to register with same email
  print('3. Testing Duplicate Registration...');
  try {
    await mockService.signup(
      email: 'test@example.com',
      password: 'AnotherPass123!',
      firstName: 'Jane',
      lastName: 'Smith',
    );
    print('   Should not reach here!\n');
  } catch (e) {
    if (e is DioException) {
      print('   Expected error: ${e.response?.data['error']['message']}\n');
    }
  }
  
  // Test 4: Login with wrong password
  print('4. Testing Invalid Login...');
  try {
    await mockService.login('test@example.com', 'WrongPassword');
    print('   Should not reach here!\n');
  } catch (e) {
    if (e is DioException) {
      print('   Expected error: ${e.response?.data['error']['message']}\n');
    }
  }
  
  print('Mock authentication tests completed!');
}