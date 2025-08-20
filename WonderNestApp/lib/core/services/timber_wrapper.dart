import 'package:flutter/foundation.dart';
import 'package:timber/timber.dart' as timber_pkg;
import 'package:logging/logging.dart';

/// Wrapper for Timber to provide a simple logging API
/// 
/// This wraps the actual Timber package which uses Dart's logging package
/// underneath, providing a simpler API similar to Android's Timber.
class Timber {
  static bool _initialized = false;
  static final _logger = Logger('WonderNest');

  /// Initialize Timber logging
  static Future<void> init() async {
    if (_initialized) return;
    
    // Initialize Timber forest
    await timber_pkg.Timber.instance.init();
    
    // Plant appropriate trees based on build mode
    if (kDebugMode) {
      // In debug mode, use developer tree for console output
      timber_pkg.Timber.instance.plant(timber_pkg.DeveloperTree());
    }
    
    // Set root logger level
    Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
    
    _initialized = true;
  }

  /// Log debug message
  static void d(String message, {Object? ex, StackTrace? stackTrace}) {
    _logger.fine(message, ex, stackTrace);
  }

  /// Log info message
  static void i(String message, {Object? ex, StackTrace? stackTrace}) {
    _logger.info(message, ex, stackTrace);
  }

  /// Log warning message
  static void w(String message, {Object? ex, StackTrace? stackTrace}) {
    _logger.warning(message, ex, stackTrace);
  }

  /// Log error message
  static void e(String message, {Object? ex, StackTrace? stackTrace}) {
    _logger.severe(message, ex, stackTrace);
  }

  /// Log fatal/wtf message
  static void f(String message, {Object? ex, StackTrace? stackTrace}) {
    _logger.shout(message, ex, stackTrace);
  }
}