import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Theme
import 'core/theme/app_theme.dart';

// Models
import 'models/app_mode.dart';

// Providers
import 'providers/app_mode_provider.dart';

// Screens
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/parent/parent_control_dashboard.dart';
import 'screens/child/child_home.dart';
import 'screens/child/child_selection_screen.dart';
import 'screens/security/pin_entry_screen.dart';
import 'screens/coppa/coppa_consent_screen.dart';
import 'screens/games/mini_game_framework.dart';
import 'screens/family/family_overview_screen.dart';
import 'screens/family/child_profile_screen.dart';
import 'screens/content/content_library_screen.dart';
import 'screens/content/content_filter_settings_screen.dart';
import 'models/game_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: WonderNestApp(),
    ),
  );
}

class WonderNestApp extends ConsumerWidget {
  const WonderNestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appModeState = ref.watch(appModeProvider);
    
    return MaterialApp.router(
      title: 'WonderNest',
      theme: AppTheme.lightTheme,
      routerConfig: _createRouter(ref, appModeState),
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _createRouter(WidgetRef ref, AppModeState appModeState) {
    return GoRouter(
      // Start with child selection for kid-first approach
      initialLocation: '/child-selection',
      
      redirect: (context, state) async {
        // Check authentication and onboarding status
        final secureStorage = const FlutterSecureStorage();
        final accessToken = await secureStorage.read(key: 'auth_token');
        final hasCompletedOnboarding = await secureStorage.read(key: 'onboarding_completed') == 'true';
        
        final currentPath = state.matchedLocation;
        final isLoggedIn = accessToken != null;
        
        // Allow auth routes to work without redirection during auth flow
        final authRoutes = ['/welcome', '/signup', '/login', '/onboarding'];
        final isAuthRoute = authRoutes.contains(currentPath);
        
        // Kid mode routes (accessible without authentication)
        final kidRoutes = ['/child-selection', '/child-home', '/game'];
        final isKidRoute = kidRoutes.any((route) => currentPath.startsWith(route));
        
        // If on kid route, allow access regardless of authentication
        if (isKidRoute) {
          return null;
        }
        
        // If not logged in and trying to access parent features, redirect to welcome
        if (!isLoggedIn && !isAuthRoute && !isKidRoute) {
          return '/welcome';
        }
        
        // If logged in and trying to access auth routes, redirect based on onboarding
        if (isLoggedIn && isAuthRoute && currentPath != '/onboarding') {
          if (hasCompletedOnboarding) {
            // After auth completion, check if we should stay in parent mode or return to kid mode
            if (appModeState.currentMode == AppMode.parent) {
              return '/parent-dashboard';
            } else {
              return '/child-selection';
            }
          } else {
            return '/onboarding';
          }
        }
        
        // Allow onboarding to proceed if logged in
        if (currentPath == '/onboarding' && isLoggedIn) {
          return null;
        }
        
        // If logged in but hasn't completed onboarding, redirect to onboarding
        if (isLoggedIn && !hasCompletedOnboarding && !isAuthRoute && !isKidRoute) {
          return '/onboarding';
        }
        
        // Parent mode routes protection
        final parentRoutes = [
          '/parent-dashboard',
          '/parent-controls',
          '/settings',
          '/coppa-consent',
          '/family',
          '/child-profile',
          '/content-library',
          '/content-filters',
        ];
        
        final isParentRoute = parentRoutes.any((route) => currentPath.startsWith(route));
        
        // If trying to access parent route but not in parent mode
        if (isParentRoute && appModeState.currentMode != AppMode.parent) {
          // Redirect to PIN entry with return path
          return '/pin-entry?redirect=$currentPath';
        }
        
        return null;
      },
      
      routes: [
        // Kid Mode (Default)
        GoRoute(
          path: '/child-home',
          builder: (context, state) => const ChildHome(),
        ),
        
        // Child Selection for Kid Mode Entry (accessible without authentication)
        GoRoute(
          path: '/child-selection',
          builder: (context, state) => const ChildSelectionScreen(),
        ),
        
        // Authentication & Onboarding
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        
        // PIN Entry for Parent Mode
        GoRoute(
          path: '/pin-entry',
          builder: (context, state) {
            final redirect = state.uri.queryParameters['redirect'];
            final isSetup = state.uri.queryParameters['setup'] == 'true';
            
            return PinEntryScreen(
              isSetup: isSetup,
              onSuccess: redirect != null 
                ? () => context.go(redirect)
                : null,
            );
          },
        ),
        
        // Parent Mode Routes
        GoRoute(
          path: '/parent-dashboard',
          builder: (context, state) => const ParentDashboard(),
        ),
        // Fallback for old dashboard route
        GoRoute(
          path: '/dashboard',
          redirect: (context, state) => '/parent-dashboard',
        ),
        GoRoute(
          path: '/parent-controls',
          builder: (context, state) => const ParentControlDashboard(),
        ),
        
        // COPPA Consent
        GoRoute(
          path: '/coppa-consent',
          builder: (context, state) {
            final childId = state.uri.queryParameters['childId'] ?? '';
            final childName = state.uri.queryParameters['childName'] ?? '';
            final childAge = int.tryParse(state.uri.queryParameters['childAge'] ?? '0') ?? 0;
            
            return CoppaConsentScreen(
              childId: childId,
              childName: childName,
              childAge: childAge,
            );
          },
        ),
        
        // Family Management Routes
        GoRoute(
          path: '/family',
          builder: (context, state) => const FamilyOverviewScreen(),
        ),
        GoRoute(
          path: '/child-profile/create',
          builder: (context, state) => const ChildProfileScreen(),
        ),
        GoRoute(
          path: '/child-profile/:childId',
          builder: (context, state) {
            final childId = state.pathParameters['childId'];
            return ChildProfileScreen(
              childId: childId,
              isEditing: false,
            );
          },
        ),
        GoRoute(
          path: '/child-profile/:childId/edit',
          builder: (context, state) {
            final childId = state.pathParameters['childId'];
            return ChildProfileScreen(
              childId: childId,
              isEditing: true,
            );
          },
        ),
        
        // Content Management Routes
        GoRoute(
          path: '/content-library',
          builder: (context, state) => const ContentLibraryScreen(),
        ),
        GoRoute(
          path: '/content-filters',
          builder: (context, state) => const ContentFilterSettingsScreen(),
        ),
        
        // Mini-Game Framework
        GoRoute(
          path: '/game',
          builder: (context, state) {
            final gameData = state.extra as Map<String, dynamic>?;
            
            if (gameData == null) {
              // Return to child home if no game data
              return const ChildHome();
            }
            
            final game = GameModel(
              id: gameData['id'] ?? '',
              name: gameData['name'] ?? 'Game',
              description: gameData['description'] ?? '',
              thumbnailUrl: gameData['thumbnailUrl'] ?? '',
              gameUrl: gameData['gameUrl'] ?? '',
              type: GameType.web,
              minAge: gameData['minAge'] ?? 3,
              maxAge: gameData['maxAge'] ?? 13,
              categories: List<String>.from(gameData['categories'] ?? []),
              educationalTopics: List<String>.from(gameData['educationalTopics'] ?? []),
              isWhitelisted: true,
            );
            
            return MiniGameFramework(
              game: game,
              childId: gameData['childId'] ?? '',
            );
          },
        ),
      ],
      
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'Unknown error',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/child-selection'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
