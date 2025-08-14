// Simple script to verify route configuration
import 'dart:io';

void main() {
  print('\n=== Verifying Route Configuration ===\n');
  
  // Read the main.dart file
  final mainFile = File('lib/main.dart');
  if (!mainFile.existsSync()) {
    print('✗ Could not find lib/main.dart');
    return;
  }
  
  final content = mainFile.readAsStringSync();
  
  // Check for child-home route definition
  if (content.contains("path: '/child-home'")) {
    print('✓ /child-home route path is defined');
  } else {
    print('✗ /child-home route path NOT found');
  }
  
  // Check for pageBuilder (our new implementation)
  if (content.contains('pageBuilder: (context, state)') && content.contains('child-home')) {
    print('✓ /child-home uses pageBuilder (new implementation)');
  } else if (content.contains("builder: (context, state)") && content.contains('child-home')) {
    print('⚠ /child-home uses builder (old implementation)');
  } else {
    print('✗ /child-home builder not properly configured');
  }
  
  // Check for wrapper widget
  if (content.contains('_ChildHomeWrapper')) {
    print('✓ _ChildHomeWrapper is defined');
  } else {
    print('✗ _ChildHomeWrapper NOT found');
  }
  
  // Check ChildHome widget file
  final childHomeFile = File('lib/screens/child/child_home.dart');
  if (childHomeFile.existsSync()) {
    final childHomeContent = childHomeFile.readAsStringSync();
    
    if (childHomeContent.contains('createState()')) {
      print('✓ ChildHome has createState method');
    }
    
    if (childHomeContent.contains('[WIDGET] ChildHome.initState()')) {
      print('✓ ChildHome has debug logging in initState');
    }
    
    if (childHomeContent.contains('[WIDGET] ChildHome.build()')) {
      print('✓ ChildHome has debug logging in build');
    }
  }
  
  // Check navigation in child selection
  final childSelectionFile = File('lib/screens/child/child_selection_screen.dart');
  if (childSelectionFile.existsSync()) {
    final selectionContent = childSelectionFile.readAsStringSync();
    
    if (selectionContent.contains("context.go('/child-home')")) {
      print('✓ Child selection navigates to /child-home');
    }
    
    if (selectionContent.contains('selectChildAndSwitchMode')) {
      print('✓ Child selection uses selectChildAndSwitchMode');
    }
  }
  
  print('\n=== Verification Complete ===\n');
}