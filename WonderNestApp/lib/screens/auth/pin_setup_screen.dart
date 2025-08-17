import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../widgets/custom_text_field.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _apiService = ApiService();
  
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.setupPin(_pinController.text);
      
      if (response.statusCode == 200) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PIN setup successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to next screen (e.g., family setup or home)
          context.go('/family-setup');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to setup PIN. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 48),
                  
                  Center(
                    child: Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.9),
                    ).animate().fadeIn().scale(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Setup Your PIN',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Create a 6-digit PIN to secure parent mode access',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3),
                  
                  const SizedBox(height: 48),
                  
                  CustomTextField(
                    controller: _pinController,
                    label: 'Enter 6-digit PIN',
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                      icon: Icon(
                        _obscurePin ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter a PIN';
                      }
                      if (value!.length != 6) {
                        return 'PIN must be exactly 6 digits';
                      }
                      
                      // Check for simple patterns
                      if (RegExp(r'^(\d)\1{5}$').hasMatch(value)) {
                        return 'PIN cannot be all the same digit';
                      }
                      
                      // Check for sequential patterns
                      bool isSequential = true;
                      for (int i = 1; i < value.length; i++) {
                        if (int.parse(value[i]) != int.parse(value[i - 1]) + 1) {
                          isSequential = false;
                          break;
                        }
                      }
                      if (isSequential) {
                        return 'PIN cannot be sequential (e.g., 123456)';
                      }
                      
                      // Check for reverse sequential
                      bool isReverseSequential = true;
                      for (int i = 1; i < value.length; i++) {
                        if (int.parse(value[i]) != int.parse(value[i - 1]) - 1) {
                          isReverseSequential = false;
                          break;
                        }
                      }
                      if (isReverseSequential) {
                        return 'PIN cannot be reverse sequential (e.g., 654321)';
                      }
                      
                      return null;
                    },
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _confirmPinController,
                    label: 'Confirm PIN',
                    obscureText: _obscureConfirmPin,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                      icon: Icon(
                        _obscureConfirmPin ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please confirm your PIN';
                      }
                      if (value != _pinController.text) {
                        return 'PINs do not match';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PIN Requirements',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRequirement('Exactly 6 digits'),
                        _buildRequirement('Not all the same digit (e.g., 111111)'),
                        _buildRequirement('Not sequential (e.g., 123456 or 654321)'),
                        _buildRequirement('Remember it - needed for parent mode'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                  
                  if (_errorMessage != null) ...[
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
                              _errorMessage!,
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
                      onPressed: _isLoading ? null : _setupPin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        elevation: 8,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              'Setup PIN',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 24),
                  
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : () {
                        // Skip PIN setup for now (optional)
                        context.go('/family-setup');
                      },
                      child: Text(
                        'Skip for now',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}