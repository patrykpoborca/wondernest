import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_mode_provider.dart';
import '../../services/security_service.dart';
import '../../core/theme/app_colors.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  final bool isSetup;
  final VoidCallback? onSuccess;

  const PinEntryScreen({
    super.key,
    this.isSetup = false,
    this.onSuccess,
  });

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  final SecurityService _securityService = SecurityService();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    // Focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    if (!widget.isSetup) {
      final isAvailable = await _securityService.isBiometricAvailable();
      final isEnabled = await _securityService.isBiometricEnabled();
      setState(() {
        _showBiometric = isAvailable && isEnabled;
      });
    }
  }

  String _getPin() {
    return _controllers.map((c) => c.text).join();
  }

  void _clearPin() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _handlePinSubmit() async {
    final pin = _getPin();
    
    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isSetup) {
        if (!_isConfirming) {
          // First entry
          setState(() {
            _confirmPin = pin;
            _isConfirming = true;
            _isLoading = false;
          });
          _clearPin();
        } else {
          // Confirming PIN
          if (pin == _confirmPin) {
            final success = await _securityService.setupPin(pin);
            if (success) {
              _handleSuccess();
            } else {
              setState(() {
                _errorMessage = 'Failed to set PIN';
              });
            }
          } else {
            setState(() {
              _errorMessage = 'PINs do not match';
              _isConfirming = false;
              _confirmPin = '';
            });
            _clearPin();
          }
        }
      } else {
        // Verify existing PIN
        final appMode = ref.read(appModeProvider.notifier);
        final success = await appMode.switchToParentMode(pin);
        
        if (success) {
          _handleSuccess();
        } else {
          setState(() {
            _errorMessage = 'Incorrect PIN';
          });
          _clearPin();
          
          // Vibrate on error
          HapticFeedback.mediumImpact();
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSuccess() {
    HapticFeedback.lightImpact();
    
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      context.go('/parent-dashboard');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authenticated = await _securityService.authenticateWithBiometrics();
    
    if (authenticated) {
      final appMode = ref.read(appModeProvider.notifier);
      // For biometric, we still need to verify the stored PIN internally
      // This is a simplified version - in production, handle this more securely
      _handleSuccess();
    } else {
      setState(() {
        _errorMessage = 'Biometric authentication failed';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              Text(
                widget.isSetup
                    ? (_isConfirming ? 'Confirm PIN' : 'Set Parent PIN')
                    : 'Enter Parent PIN',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isSetup
                    ? 'This PIN will be used to access parent controls'
                    : 'Enter your PIN to switch to Parent Mode',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // PIN Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: 45,
                    height: 55,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      obscureText: true,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _controllers[index].text.isNotEmpty
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _controllers[index].text.isNotEmpty
                                ? AppColors.primary
                                : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        
                        // Check if all fields are filled
                        if (_controllers.every((c) => c.text.isNotEmpty)) {
                          _handlePinSubmit();
                        }
                      },
                    ),
                  );
                }),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 14,
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handlePinSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.isSetup
                          ? (_isConfirming ? 'Confirm PIN' : 'Set PIN')
                          : 'Verify',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                if (_showBiometric && !widget.isSetup) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _authenticateWithBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use Biometric'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ],
              
              const Spacer(),
              
              if (!widget.isSetup)
                TextButton(
                  onPressed: () {
                    // Handle forgotten PIN
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Forgot PIN?'),
                        content: const Text(
                          'Please contact support to reset your PIN. '
                          'You will need to verify your account ownership.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Forgot PIN?'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}