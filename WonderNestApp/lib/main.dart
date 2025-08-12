import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/child/child_home.dart';

void main() {
  runApp(const WonderNestApp());
}

class WonderNestApp extends StatelessWidget {
  const WonderNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'WonderNest',
            theme: AppTheme.lightTheme,
            routerConfig: _createRouter(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: authProvider.isLoggedIn ? '/dashboard' : '/welcome',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isLoading = authProvider.isLoading;

        if (isLoading) return null;

        final isAuthRoute = ['/welcome', '/login', '/signup', '/onboarding'].contains(state.matchedLocation);

        if (!isLoggedIn && !isAuthRoute) {
          return '/welcome';
        }

        if (isLoggedIn && isAuthRoute) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
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
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const ParentDashboard(),
        ),
        GoRoute(
          path: '/child-home',
          builder: (context, state) => const ChildHome(),
        ),
      ],
    );
  }
}
