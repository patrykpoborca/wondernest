import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Centralized logging service for WonderNest
/// 
/// This service provides a consistent logging interface across the application,
/// following child safety and privacy requirements. All logs are properly
/// anonymized and contain no personally identifiable information.
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  late final Logger _logger;

  /// Initialize the logging service
  /// Should be called during app startup
  void initialize() {
    _logger = Logger(
      filter: _getLogFilter(),
      printer: _getLogPrinter(),
      output: _getLogOutput(),
    );
  }

  /// Get the appropriate log filter based on build mode
  LogFilter _getLogFilter() {
    if (kDebugMode) {
      // In debug mode, log everything
      return DevelopmentFilter();
    } else {
      // In production, be more restrictive
      return ProductionFilter();
    }
  }

  /// Get the appropriate log printer
  LogPrinter _getLogPrinter() {
    if (kDebugMode) {
      // Pretty printing for development
      return PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: false, // Keep it professional for child safety app
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        excludeBox: {
          Level.trace: true,
          Level.debug: false,
          Level.info: false,
          Level.warning: false,
          Level.error: false,
          Level.fatal: false,
        },
      );
    } else {
      // Simple printing for production
      return SimplePrinter();
    }
  }

  /// Get the appropriate log output
  LogOutput _getLogOutput() {
    if (kDebugMode) {
      return ConsoleOutput();
    } else {
      // In production, we might want to add additional outputs
      // like file logging or crash reporting (without PII)
      return ConsoleOutput();
    }
  }

  // Convenience methods for different log levels

  /// Log trace messages (most verbose)
  void trace(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log debug messages (development info)
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info messages (general app flow)
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages (potential issues)
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages (actual errors)
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal messages (critical errors)
  void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // Specialized logging methods for child safety app

  /// Log child interaction events (anonymized)
  void logChildInteraction(String action, {Map<String, dynamic>? metadata}) {
    final sanitizedMetadata = _sanitizeMetadata(metadata);
    info('Child interaction: $action', sanitizedMetadata);
  }

  /// Log parent action events
  void logParentAction(String action, {Map<String, dynamic>? metadata}) {
    final sanitizedMetadata = _sanitizeMetadata(metadata);
    info('Parent action: $action', sanitizedMetadata);
  }

  /// Log security events
  void logSecurityEvent(String event, {Map<String, dynamic>? metadata}) {
    final sanitizedMetadata = _sanitizeMetadata(metadata);
    warning('Security event: $event', sanitizedMetadata);
  }

  /// Log COPPA compliance events
  void logComplianceEvent(String event, {Map<String, dynamic>? metadata}) {
    final sanitizedMetadata = _sanitizeMetadata(metadata);
    info('COPPA compliance: $event', sanitizedMetadata);
  }

  /// Log API requests (without sensitive data)
  void logApiRequest(String endpoint, String method, {int? statusCode}) {
    debug('API $method $endpoint${statusCode != null ? ' -> $statusCode' : ''}');
  }

  /// Log game events
  void logGameEvent(String gameName, String event, {Map<String, dynamic>? metadata}) {
    final sanitizedMetadata = _sanitizeMetadata(metadata);
    info('Game event [$gameName]: $event', sanitizedMetadata);
  }

  /// Sanitize metadata to remove any potentially sensitive information
  Map<String, dynamic>? _sanitizeMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;

    final sanitized = <String, dynamic>{};
    for (final entry in metadata.entries) {
      // Skip keys that might contain sensitive data
      if (_isSensitiveKey(entry.key)) {
        continue;
      }
      
      // Sanitize string values
      if (entry.value is String) {
        sanitized[entry.key] = _sanitizeString(entry.value as String);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized.isEmpty ? null : sanitized;
  }

  /// Check if a key might contain sensitive information
  bool _isSensitiveKey(String key) {
    final sensitiveKeys = {
      'email', 'password', 'pin', 'token', 'secret', 'key',
      'name', 'phone', 'address', 'location', 'id', 'uuid',
      'birth', 'age', 'personal'
    };
    
    final lowerKey = key.toLowerCase();
    return sensitiveKeys.any((sensitive) => lowerKey.contains(sensitive));
  }

  /// Sanitize string values to prevent PII leakage
  String _sanitizeString(String value) {
    // If string looks like an email, mask it
    if (value.contains('@')) {
      return '[email]';
    }
    
    // If string looks like a phone number, mask it
    if (RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(value)) {
      return '[phone]';
    }
    
    // If string is very long, truncate it
    if (value.length > 100) {
      return '${value.substring(0, 97)}...';
    }
    
    return value;
  }
}

/// Global logger instance
final logger = LoggingService();

/// Production log filter - more restrictive
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In production, only log warnings and above
    return event.level.index >= Level.warning.index;
  }
}

/// Development log filter - allows all logs
class DevelopmentFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In development, log everything except trace by default
    return event.level.index >= Level.debug.index;
  }
}