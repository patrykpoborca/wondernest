import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      // Check if user has completed onboarding
      final secureStorage = const FlutterSecureStorage();
      final hasCompletedOnboarding = await secureStorage.read(key: 'onboarding_completed') == 'true';
      
      if (mounted) {
        if (hasCompletedOnboarding) {
          context.go('/parent-dashboard');
        } else {
          context.go('/onboarding');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.welcomeGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.go('/welcome'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ).animate().fadeIn().slideX(begin: -1),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Sign in to continue your family\'s learning journey',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3),
                  
                  const SizedBox(height: 48),
                  
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
                  
                  if (authState.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[300]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: GoogleFonts.poppins(
                                color: Colors.red[300],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().shake(),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        elevation: 8,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: authState.isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              'Sign In',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}