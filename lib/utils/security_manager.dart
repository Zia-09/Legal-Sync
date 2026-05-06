/// 🔹 Security Utilities for Legal Sync
///
/// Best practices:
/// - Never hardcode API keys (use environment variables or secure storage)
/// - Use HTTPS for all API calls
/// - Implement certificate pinning
/// - Encrypt sensitive data before caching
/// - Validate SSL certificates
/// - Use secure token storage
library;

import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legal_sync/utils/error_handler.dart';

class SecurityManager {
  static const String _secureKeyPrefix = 'secure_';
  static late SharedPreferences _secureStorage;

  /// Initialize security manager
  static Future<void> initialize() async {
    try {
      _secureStorage = await SharedPreferences.getInstance();
      AppLogger.info('SecurityManager initialized', tag: 'Security');
    } catch (e) {
      AppLogger.error(
        'Failed to initialize SecurityManager',
        tag: 'Security',
        error: e,
      );
    }
  }

  /// ========================
  /// SECURE TOKEN STORAGE
  /// ========================

  /// Store sensitive token securely
  /// Note: SharedPreferences is not fully encrypted on all platforms
  /// For production, use flutter_secure_storage package
  static Future<void> storeSecureToken(String key, String token) async {
    try {
      final secureKey = _secureKeyPrefix + key;
      await _secureStorage.setString(secureKey, token);
      AppLogger.info('Secure token stored: $key', tag: 'Security');
    } catch (e) {
      AppLogger.error(
        'Failed to store secure token: $key',
        tag: 'Security',
        error: e,
      );
    }
  }

  /// Retrieve secure token
  static Future<String?> getSecureToken(String key) async {
    try {
      final secureKey = _secureKeyPrefix + key;
      return _secureStorage.getString(secureKey);
    } catch (e) {
      AppLogger.error(
        'Failed to retrieve secure token: $key',
        tag: 'Security',
        error: e,
      );
      return null;
    }
  }

  /// Clear secure token
  static Future<void> clearSecureToken(String key) async {
    try {
      final secureKey = _secureKeyPrefix + key;
      await _secureStorage.remove(secureKey);
      AppLogger.info('Secure token cleared: $key', tag: 'Security');
    } catch (e) {
      AppLogger.error(
        'Failed to clear secure token: $key',
        tag: 'Security',
        error: e,
      );
    }
  }

  /// ========================
  /// ENCRYPTION UTILITIES
  /// ========================

  /// Hash sensitive data (SHA-256)
  static String hashData(String data) {
    try {
      return crypto.sha256.convert(utf8.encode(data)).toString();
    } catch (e) {
      AppLogger.error('Failed to hash data', tag: 'Security', error: e);
      return '';
    }
  }

  /// Simple base64 encoding for non-critical data
  /// WARNING: Not suitable for highly sensitive data
  static String encodeData(String data) {
    try {
      return base64.encode(utf8.encode(data));
    } catch (e) {
      AppLogger.error('Failed to encode data', tag: 'Security', error: e);
      return data;
    }
  }

  /// Decode base64 data
  static String decodeData(String encoded) {
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (e) {
      AppLogger.error('Failed to decode data', tag: 'Security', error: e);
      return encoded;
    }
  }

  /// ========================
  /// INPUT VALIDATION
  /// ========================

  /// Validate email format
  static bool isValidEmail(String email) {
    try {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      return emailRegex.hasMatch(email);
    } catch (e) {
      AppLogger.warning('Email validation error: $e', tag: 'Security');
      return false;
    }
  }

  /// Validate password strength
  static Map<String, bool> validatePasswordStrength(String password) {
    return {
      'isLongEnough': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumbers': password.contains(RegExp(r'[0-9]')),
      'hasSpecialChars': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  /// Check if password is strong
  static bool isStrongPassword(String password) {
    final checks = validatePasswordStrength(password);
    return checks.values.every((v) => v == true);
  }

  /// Sanitize user input
  static String sanitizeInput(String input) {
    try {
      // Remove potentially harmful characters
      String sanitized = input;
      sanitized = sanitized.replaceAll('<', '');
      sanitized = sanitized.replaceAll('>', '');
      sanitized = sanitized.replaceAll('"', '');
      sanitized = sanitized.replaceAll("'", '');
      sanitized = sanitized.replaceAll('%', '');
      sanitized = sanitized.replaceAll(';', '');
      sanitized = sanitized.replaceAll('(', '');
      sanitized = sanitized.replaceAll(')', '');
      sanitized = sanitized.replaceAll('&', '');
      return sanitized.trim();
    } catch (e) {
      AppLogger.warning('Input sanitization error: $e', tag: 'Security');
      return input.trim();
    }
  }

  /// ========================
  /// AUTHENTICATION HELPERS
  /// ========================

  /// Verify JWT token format (basic validation)
  static bool isValidJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // Decode payload
      final payload = parts[1];
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = utf8.decode(base64.decode(normalized));
      final json = jsonDecode(decoded);

      // Check expiration if present
      if (json['exp'] != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(
          (json['exp'] as int) * 1000,
        );
        return expiryTime.isAfter(DateTime.now());
      }
      return true;
    } catch (e) {
      AppLogger.warning('JWT validation error: $e', tag: 'Security');
      return false;
    }
  }

  /// ========================
  /// AUDIT LOGGING
  /// ========================

  /// Log security-related events
  static Future<void> logSecurityEvent({
    required String event,
    required String userId,
    Map<String, dynamic>? details,
  }) async {
    try {
      AppLogger.info('Security Event: $event by $userId', tag: 'AuditLog');
      // TODO: Send to backend audit log service
      // await auditLogService.logEvent(event, userId, details);
    } catch (e) {
      AppLogger.error(
        'Failed to log security event',
        tag: 'AuditLog',
        error: e,
      );
    }
  }
}
