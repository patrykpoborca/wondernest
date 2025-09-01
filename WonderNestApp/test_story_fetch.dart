import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing story fetch from backend...\n');
  
  // Test child ID used in both web and Flutter
  const testChildId = '50cb1b31-bd85-4604-8cd1-efc1a73c9359';
  const gameType = 'story_adventure';
  
  try {
    // Try to fetch without auth first (will fail but shows connection)
    final response = await http.get(
      Uri.parse('http://localhost:8080/api/v2/games/children/$testChildId/data?gameType=$gameType'),
      headers: {'Content-Type': 'application/json'},
    );
    
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}\n');
    
    if (response.statusCode == 401) {
      print('Backend is running but requires authentication.');
      print('This is expected. The Flutter app will handle authentication.\n');
    }
    
    // Check if backend is healthy
    final healthResponse = await http.get(
      Uri.parse('http://localhost:8080/health'),
    );
    
    print('Health check status: ${healthResponse.statusCode}');
    if (healthResponse.statusCode == 200) {
      print('Backend is running and responsive.');
    }
    
  } catch (e) {
    print('Error connecting to backend: $e');
    print('Make sure the backend is running with: docker-compose up -d');
  }
  
  print('\n---');
  print('Next steps:');
  print('1. Run the Flutter app');
  print('2. Log in with parent account poborcapatryk+1@gmail.com');
  print('3. Navigate to Story Adventure game');
  print('4. Look for story "testyt" in the list');
}