import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color primaryPurple = Color(0xFF7B68EE);
  static const Color primaryGreen = Color(0xFF4CAF50);
  
  // Secondary Colors
  static const Color secondaryOrange = Color(0xFFFF9800);
  static const Color secondaryPink = Color(0xFFE91E63);
  static const Color secondaryYellow = Color(0xFFFFEB3B);
  
  // Neutral Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Child-Safe Palette
  static const Color kidSafeBlue = Color(0xFF64B5F6);
  static const Color kidSafeGreen = Color(0xFF81C784);
  static const Color kidSafePurple = Color(0xFFBA68C8);
  static const Color kidSafeOrange = Color(0xFFFFB74D);
  static const Color kidSafeYellow = Color(0xFFFFF176);
  static const Color kidSafePink = Color(0xFFF06292);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Additional Colors needed by components
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color accentPurple = Color(0xFFBA68C8);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color kidBackgroundLight = Color(0xFFF0F8FF);
  
  // Aliases for compatibility
  static const Color primary = primaryBlue;
  static const Color kidModeBackground = kidBackgroundLight;
  static const Color kidModeAccent = kidSafeBlue;
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient kidGradient = LinearGradient(
    colors: [kidSafeBlue, kidSafePurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFFF7043)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient welcomeGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}