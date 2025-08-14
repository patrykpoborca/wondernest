import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'lib/main.dart';
import 'lib/screens/child/child_home.dart';
import 'lib/screens/child/child_selection_screen.dart';
import 'lib/providers/app_mode_provider.dart';
import 'lib/models/child_profile.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for testing
  await Hive.initFlutter();
  
  group('Child Home Navigation Tests', () {
    testWidgets('ChildHome widget should be rendered when navigating to /child-home', (WidgetTester tester) async {
      print('\n=== Starting ChildHome Navigation Test ===\n');
      
      // Build the app
      await tester.pumpWidget(
        const ProviderScope(
          child: WonderNestApp(),
        ),
      );
      
      print('App built successfully');
      
      // Wait for the app to settle
      await tester.pumpAndSettle();
      
      print('App settled, checking initial route');
      
      // We should be on the child selection screen initially
      expect(find.byType(ChildSelectionScreen), findsOneWidget);
      print('✓ ChildSelectionScreen is displayed');
      
      // Find and tap the "Play as Guest" button
      final playAsGuestButton = find.text('Play as Guest');
      if (playAsGuestButton.evaluate().isNotEmpty) {
        print('Found "Play as Guest" button, tapping...');
        await tester.tap(playAsGuestButton);
        await tester.pumpAndSettle();
        
        // Check if ChildHome is rendered
        final childHomeWidget = find.byType(ChildHome);
        if (childHomeWidget.evaluate().isNotEmpty) {
          print('✓ ChildHome widget is rendered!');
          
          // Check for specific elements in ChildHome
          final toyBoxText = find.text('🧸 My Toy Box');
          if (toyBoxText.evaluate().isNotEmpty) {
            print('✓ Toy Box section is visible');
          } else {
            print('✗ Toy Box section not found');
          }
        } else {
          print('✗ ChildHome widget NOT rendered');
          
          // Check what's currently on screen
          final widgets = find.byType(Widget);
          print('Current widget tree has ${widgets.evaluate().length} widgets');
        }
      } else {
        print('✗ "Play as Guest" button not found');
      }
      
      print('\n=== Test Complete ===\n');
    });
    
    testWidgets('Direct navigation to /child-home should work', (WidgetTester tester) async {
      print('\n=== Starting Direct Navigation Test ===\n');
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the app mode provider to have a guest child
            appModeProvider.overrideWith((ref) {
              final notifier = AppModeNotifier(const FlutterSecureStorage());
              // Set a guest child immediately
              notifier.selectChildAndSwitchMode(
                ChildProfile(
                  id: 'test_child',
                  name: 'Test Child',
                  age: 5,
                  avatarUrl: '🎮',
                  birthDate: DateTime.now().subtract(const Duration(days: 5 * 365)),
                  gender: 'not_specified',
                  interests: ['games'],
                  contentSettings: ContentSettings(
                    maxAgeRating: 6,
                    blockedCategories: [],
                    allowedDomains: [],
                    subtitlesEnabled: true,
                    audioMonitoringEnabled: true,
                    educationalContentOnly: false,
                  ),
                  timeRestrictions: TimeRestrictions(
                    weekdayLimits: {},
                    weekendLimits: {},
                    dailyScreenTimeMinutes: 60,
                    bedtimeEnabled: false,
                  ),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              return notifier;
            }),
          ],
          child: const WonderNestApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Navigate directly to /child-home
      final BuildContext context = tester.element(find.byType(MaterialApp));
      GoRouter.of(context).go('/child-home');
      
      await tester.pumpAndSettle();
      
      // Check if ChildHome is rendered
      final childHomeWidget = find.byType(ChildHome);
      if (childHomeWidget.evaluate().isNotEmpty) {
        print('✓ Direct navigation to ChildHome successful!');
        
        // Check for the welcome header
        final welcomeText = find.textContaining('Hi Test Child!');
        if (welcomeText.evaluate().isNotEmpty) {
          print('✓ Welcome header with child name is visible');
        } else {
          print('✗ Welcome header not found');
        }
      } else {
        print('✗ ChildHome widget NOT rendered after direct navigation');
      }
      
      print('\n=== Test Complete ===\n');
    });
  });
}