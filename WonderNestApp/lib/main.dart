import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Theme
import 'core/theme/app_theme.dart';

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

class WonderNestApp extends ConsumerStatefulWidget {
  const WonderNestApp({super.key});

  @override
  ConsumerState<WonderNestApp> createState() => _WonderNestAppState();
}

class _WonderNestAppState extends ConsumerState<WonderNestApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WonderNest',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      // Start with child selection for kid-first approach
      initialLocation: '/child-selection',
      
      
      redirect: (context, state) {
        // Read the app mode state directly inside the redirect callback
        final appModeState = ref.read(appModeProvider);
        final currentPath = state.matchedLocation;
        
        print('[REDIRECT] Router check for: $currentPath at ${DateTime.now()}');
        print('[REDIRECT] App mode: ${appModeState.currentMode}');
        print('[REDIRECT] Full state info:');
        print('[REDIRECT]   - path: ${state.path}');
        print('[REDIRECT]   - fullPath: ${state.fullPath}');
        print('[REDIRECT]   - uri: ${state.uri}');
        print('[REDIRECT]   - matchedLocation: ${state.matchedLocation}');
        
        // Kid mode routes - ALWAYS allow access (kid-first approach)
        final kidRoutes = ['/child-selection', '/child-home', '/game'];
        final isKidRoute = kidRoutes.any((route) => currentPath.startsWith(route));
        
        if (isKidRoute) {
          print('[REDIRECT] Kid route detected - allowing immediate access to: $currentPath');
          print('[REDIRECT] Returning null to allow navigation');
          return null; // Always allow kid routes
        }
        
        // For non-kid routes, we'll need to check auth status
        // But for now, just allow everything else too to focus on fixing the child-home issue
        print('[REDIRECT] Non-kid route, allowing for now: $currentPath');
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

