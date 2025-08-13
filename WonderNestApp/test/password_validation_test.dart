import 'package:flutter_test/flutter_test.dart';

String? validatePassword(String? value) {
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
}

void main() {
  group('Password Validation Tests', () {
    test('should reject empty password', () {
      expect(validatePassword(''), 'Please enter a password');
      expect(validatePassword(null), 'Please enter a password');
    });

    test('should reject short password', () {
      expect(validatePassword('Test1!'), 'Password must be at least 8 characters');
    });

    test('should reject password without uppercase', () {
      expect(validatePassword('test123!'), 'Password must contain at least one uppercase letter');
    });

    test('should reject password without special character', () {
      expect(validatePassword('Test1234'), 'Password must contain at least one special character');
    });

    test('should reject common passwords', () {
      expect(validatePassword('Password123!'), 'Password is too common. Please choose a more secure password');
      expect(validatePassword('Qwerty123!'), 'Password is too common. Please choose a more secure password');
    });

    test('should accept valid password', () {
      expect(validatePassword('MySecure@123!'), null);
      expect(validatePassword('StrongCode1!'), null);
      expect(validatePassword('Complex#Safe2024'), null);
    });
  });
}