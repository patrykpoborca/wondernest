import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'lib/main.dart';
import 'lib/providers/app_mode_provider.dart';
import 'lib/models/child_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('\n=== Testing Direct Navigation to /child-home ===\n');
  
  // Create the app
  runApp(
    ProviderScope(
      child: MaterialApp.router(
        title: 'Test Navigation',
        routerConfig: GoRouter(
          initialLocation: '/child-home',  // Start directly at child-home
          routes: [
            GoRoute(
              path: '/child-home',
              builder: (context, state) {
                print('[TEST] Building /child-home route');
                print('[TEST] Route matched successfully');
                
                // Create a test widget that simulates ChildHome
                return Consumer(
                  builder: (context, ref, child) {
                    final activeChild = ref.watch(activeChildProvider);
                    print('[TEST] activeChild in route: ${activeChild?.name ?? 'null'}');
                    
                    // Set a test child if none exists
                    if (activeChild == null) {
                      print('[TEST] Setting test child...');
                      Future.microtask(() {
                        ref.read(appModeProvider.notifier).selectChildAndSwitchMode(
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
                      });
                    }
                    
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Test Child Home'),
                            Text('Active Child: ${activeChild?.name ?? 'None'}'),
                            ElevatedButton(
                              onPressed: () {
                                print('[TEST] Button pressed - would navigate to real ChildHome');
                              },
                              child: Text('Test Button'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}