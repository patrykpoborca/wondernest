import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  
  static const String _pinKey = 'parent_pin_hash';
  static const String _saltKey = 'pin_salt';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 30);

  SecurityService()
      : _secureStorage = const FlutterSecureStorage(),
        _localAuth = LocalAuthentication();

  // Hash PIN with salt for secure storage
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate random salt
  String _generateSalt() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bytes = utf8.encode('salt_$timestamp');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // Set up initial PIN
  Future<bool> setupPin(String pin) async {
    try {
      if (pin.length < 4 || pin.length > 8) {
        throw Exception('PIN must be between 4 and 8 digits');
      }
      
      if (!RegExp(r'^\d+$').hasMatch(pin)) {
        throw Exception('PIN must contain only numbers');
      }
      
      final salt = _generateSalt();
      final hashedPin = _hashPin(pin, salt);
      
      await _secureStorage.write(key: _pinKey, value: hashedPin);
      await _secureStorage.write(key: _saltKey, value: salt);
      await _resetFailedAttempts();
      
      return true;
    } catch (e) {
      print('Error setting up PIN: $e');
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      // Check if locked out
      if (await _isLockedOut()) {
        throw Exception('Too many failed attempts. Please try again later.');
      }
      
      final storedHash = await _secureStorage.read(key: _pinKey);
      final salt = await _secureStorage.read(key: _saltKey);
      
      if (storedHash == null || salt == null) {
        return false;
      }
      
      final inputHash = _hashPin(pin, salt);
      
      if (inputHash == storedHash) {
        await _resetFailedAttempts();
        return true;
      } else {
        await _incrementFailedAttempts();
        return false;
      }
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      if (await verifyPin(oldPin)) {
        return await setupPin(newPin);
      }
      return false;
    } catch (e) {
      print('Error changing PIN: $e');
      return false;
    }
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isBiometricEnabled = await _secureStorage.read(key: _biometricEnabledKey);
      
      if (isBiometricEnabled != 'true') {
        return false;
      }
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Parent Mode',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (authenticated) {
        await _resetFailedAttempts();
      }
      
      return authenticated;
    } catch (e) {
      print('Error with biometric authentication: $e');
      return false;
    }
  }

  // Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // Failed attempts management
  Future<void> _incrementFailedAttempts() async {
    final currentAttempts = await _getFailedAttempts();
    final newAttempts = currentAttempts + 1;
    
    await _secureStorage.write(
      key: _failedAttemptsKey,
      value: newAttempts.toString(),
    );
    
    if (newAttempts >= maxFailedAttempts) {
      await _setLockout();
    }
  }

  Future<int> _getFailedAttempts() async {
    final value = await _secureStorage.read(key: _failedAttemptsKey);
    return value != null ? int.tryParse(value) ?? 0 : 0;
  }

  Future<void> _resetFailedAttempts() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockoutTimeKey);
  }

  Future<void> _setLockout() async {
    final lockoutTime = DateTime.now().add(lockoutDuration);
    await _secureStorage.write(
      key: _lockoutTimeKey,
      value: lockoutTime.toIso8601String(),
    );
  }

  Future<bool> _isLockedOut() async {
    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    
    if (lockoutTimeStr == null) {
      return false;
    }
    
    final lockoutTime = DateTime.parse(lockoutTimeStr);
    
    if (DateTime.now().isAfter(lockoutTime)) {
      await _resetFailedAttempts();
      return false;
    }
    
    return true;
  }

  Future<Duration?> getRemainingLockoutTime() async {
    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    
    if (lockoutTimeStr == null) {
      return null;
    }
    
    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final now = DateTime.now();
    
    if (now.isAfter(lockoutTime)) {
      await _resetFailedAttempts();
      return null;
    }
    
    return lockoutTime.difference(now);
  }

  // Clear all security data (use with caution)
  Future<void> clearAllSecurityData() async {
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _saltKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _resetFailedAttempts();
  }
}