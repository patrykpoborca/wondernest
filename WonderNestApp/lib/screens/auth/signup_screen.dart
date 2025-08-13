import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate() || !_agreeToTerms) return;

    final success = await ref.read(authProvider.notifier).signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (success && mounted) {
      context.go('/onboarding');
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
                    'Join WonderNest',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Create your family\'s learning adventure',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3),
                  
                  const SizedBox(height: 48),
                  
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your email';
                      }
                      
                      // More strict email validation
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(value!)) {
                        return 'Please enter a valid email address';
                      }
                      
                      // Check for invalid characters
                      if (value.contains(' ')) {
                        return 'Email cannot contain spaces';
                      }
                      
                      return null;
                    },
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
                  
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
                        return 'Please enter a password';
                      }
                      if (value!.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      
                      // Check for uppercase letter
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Password must contain at least one uppercase letter';
                      }
                      
                      // Check for special character
                      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                        return 'Password must contain at least one special character';
                      }
                      
                      // Check for common passwords
                      final commonPasswords = [
                        'password', 'password123', '123456', '123456789', 
                        'qwerty', 'abc123', 'password1', 'admin', 'letmein'
                      ];
                      final lowerValue = value.toLowerCase();
                      for (final commonPass in commonPasswords) {
                        if (lowerValue.contains(commonPass)) {
                          return 'Password is too common. Please choose a more secure password';
                        }
                      }
                      
                      return null;
                    },
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                        fillColor: WidgetStateProperty.all(Colors.white),
                        checkColor: AppColors.primaryBlue,
                      ),
                      Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1000.ms),
                  
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
                      onPressed: (authState.isLoading || !_agreeToTerms) ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _agreeToTerms ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        foregroundColor: AppColors.primaryBlue,
                        elevation: _agreeToTerms ? 8 : 0,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: authState.isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              'Create Account',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
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