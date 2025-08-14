// Simple test to verify navigation logic
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  print('\n=== Testing GoRouter Configuration ===\n');
  
  // Create a simple router to test the route configuration
  final router = GoRouter(
    initialLocation: '/child-selection',
    routes: [
      GoRoute(
        path: '/child-selection',
        builder: (context, state) {
          print('[TEST] Building child-selection route');
          return const Text('Child Selection');
        },
      ),
      GoRoute(
        path: '/child-home',
        pageBuilder: (context, state) {
          print('[TEST] Building child-home route via pageBuilder');
          return MaterialPage(
            key: ValueKey('child-home-page'),
            child: const Text('Child Home'),
            name: '/child-home',
          );
        },
      ),
    ],
  );
  
  // Test route matching
  print('Testing route configuration:');
  
  final childSelectionConfig = router.configuration.findMatch('/child-selection');
  if (childSelectionConfig != null) {
    print('✓ /child-selection route is configured');
  } else {
    print('✗ /child-selection route NOT found');
  }
  
  final childHomeConfig = router.configuration.findMatch('/child-home');
  if (childHomeConfig != null) {
    print('✓ /child-home route is configured');
  } else {
    print('✗ /child-home route NOT found');
  }
  
  print('\n=== Test Complete ===\n');
  
  // Run a simple Flutter app to test navigation
  runApp(MaterialApp.router(
    routerConfig: router,
  ));
}