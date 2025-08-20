import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Theme
import 'core/theme/app_theme.dart';

// Providers
import 'providers/app_mode_provider.dart';
import 'providers/auth_provider.dart';

// Game System
import 'core/games/game_initialization.dart';

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
import 'screens/games/game_plugin_framework.dart';
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

class WonderNestApp extends ConsumerStatefulWidget {
  const WonderNestApp({super.key});

  @override
  ConsumerState<WonderNestApp> createState() => _WonderNestAppState();
}

class _WonderNestAppState extends ConsumerState<WonderNestApp> {
  late final GoRouter _router;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
    // Initialize auth state and game system on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Initialize auth state
        await ref.read(authProvider.notifier).checkLoginStatus();
        
        // Initialize game system using the provider
        await ref.read(gameInitializationProvider.future);
        
        setState(() {
          _isInitialized = true;
        });
      } catch (e) {
        print('[ERROR] Failed to initialize app: $e');
        // Still mark as initialized to show the app, even if game system failed
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing auth
    if (!_isInitialized) {
      return MaterialApp(
        title: 'WonderNest',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return MaterialApp.router(
      title: 'WonderNest',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      // Start with welcome screen by default
      initialLocation: '/welcome',
      
      redirect: (context, state) {
        // Read the auth and app mode states
        final authState = ref.read(authProvider);
        final appModeState = ref.read(appModeProvider);
        final currentPath = state.matchedLocation;
        
        print('[REDIRECT] Router check for: $currentPath at ${DateTime.now()}');
        print('[REDIRECT] Auth status: ${authState.isLoggedIn}');
        print('[REDIRECT] App mode: ${appModeState.currentMode}');
        
        // Auth routes that don't require login
        final publicRoutes = ['/welcome', '/login', '/signup'];
        final isPublicRoute = publicRoutes.any((route) => currentPath == route);
        
        // Check if user is logged in
        if (!authState.isLoggedIn) {
          // If not logged in and not on a public route, redirect to welcome
          if (!isPublicRoute) {
            print('[REDIRECT] Not logged in, redirecting to /welcome');
            return '/welcome';
          }
          print('[REDIRECT] Not logged in but on public route: $currentPath');
          return null; // Allow access to public routes
        }
        
        // User is logged in
        if (isPublicRoute) {
          // If logged in and on auth route, redirect to child selection
          print('[REDIRECT] Already logged in, redirecting to /child-selection');
          return '/child-selection';
        }
        
        // Kid mode routes - allow access if logged in
        final kidRoutes = ['/child-selection', '/child-home', '/game'];
        final isKidRoute = kidRoutes.any((route) => currentPath.startsWith(route));
        
        if (isKidRoute) {
          print('[REDIRECT] Kid route detected - allowing access to: $currentPath');
          return null; // Allow kid routes for logged in users
        }
        
        // All other routes allowed for logged in users
        print('[REDIRECT] Allowing access to: $currentPath');
        return null;
      },
      
      routes: [
        // Child Selection Screen - Entry point for kids
        GoRoute(
          path: '/child-selection',
          builder: (context, state) {
            print('[ROUTE] Building ChildSelectionScreen at ${DateTime.now()}');
            return const ChildSelectionScreen();
          },
        ),
        
        // Child Home - The main toy box experience
        GoRoute(
          path: '/child-home',
          builder: (context, state) {
            print('[ROUTE] Building ChildHome route at ${DateTime.now()}');
            print('[ROUTE] state.matchedLocation: ${state.matchedLocation}');
            print('[ROUTE] Current context: $context');
            
            // Return the ChildHome widget directly
            return const ChildHome();
          },
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
        
        // Mini-Game Framework (Legacy web games)
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

        // Game Plugin Framework (New plugin-based games)
        GoRoute(
          path: '/game/:gameId',
          builder: (context, state) {
            final gameId = state.pathParameters['gameId'] ?? '';
            final gameData = state.extra as Map<String, dynamic>?;
            
            if (gameData == null || gameId.isEmpty) {
              // Return to child home if no game data
              print('[ROUTE] No game data provided for gameId: $gameId');
              return const ChildHome();
            }
            
            return GamePluginFramework(
              gameId: gameId,
              childId: gameData['childId'] ?? '',
              childName: gameData['childName'] ?? '',
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

