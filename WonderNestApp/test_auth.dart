import 'dart:convert';
import 'package:http/http.dart' as http;

// Test authentication endpoints
void main() async {
  const baseUrl = 'http://localhost:8080/api/v1';
  
  print('Testing WonderNest Authentication Endpoints...\n');
  
  // Test 1: Register a new parent
  print('1. Testing Parent Registration...');
  try {
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/auth/parent/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'test_parent@example.com',
        'password': 'TestPassword123!',
        'name': 'Test Parent',
        'phoneNumber': '+1234567890',
        'countryCode': 'US',
      }),
    );
    
    print('   Status Code: ${registerResponse.statusCode}');
    if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
      final data = jsonDecode(registerResponse.body);
      print('   Success: ${data['success']}');
      if (data['data'] != null) {
        print('   User ID: ${data['data']['userId']}');
        print('   Access Token: ${data['data']['accessToken']?.substring(0, 20)}...');
      }
    } else {
      print('   Response: ${registerResponse.body}');
    }
  } catch (e) {
    print('   Error: $e');
  }
  
  print('\n2. Testing Parent Login...');
  try {
    final loginResponse = await http.post(
      Uri.parse('$baseUrl/auth/parent/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'test_parent@example.com',
        'password': 'TestPassword123!',
      }),
    );
    
    print('   Status Code: ${loginResponse.statusCode}');
    if (loginResponse.statusCode == 200) {
      final data = jsonDecode(loginResponse.body);
      print('   Success: ${data['success']}');
      if (data['data'] != null) {
        print('   User ID: ${data['data']['userId']}');
        print('   Has PIN: ${data['data']['hasPin']}');
        print('   Children Count: ${data['data']['children']?.length ?? 0}');
      }
    } else {
      print('   Response: ${loginResponse.body}');
    }
  } catch (e) {
    print('   Error: $e');
  }
  
  print('\n3. Testing Invalid Login...');
  try {
    final invalidResponse = await http.post(
      Uri.parse('$baseUrl/auth/parent/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'wrong@example.com',
        'password': 'WrongPassword',
      }),
    );
    
    print('   Status Code: ${invalidResponse.statusCode}');
    print('   Response: ${invalidResponse.body}');
  } catch (e) {
    print('   Error: $e');
  }
  
  print('\nTest completed!');
}