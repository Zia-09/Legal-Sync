/// 🔹 Centralized Error Handling & Logging for Legal Sync
///
/// This utility provides:
/// - Structured error logging
/// - Error classification (user, network, server, unknown)
/// - Analytics integration hooks
/// - User-friendly error messages
/// - Stack trace capture for debugging
library;

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

enum ErrorCategory {
  authentication,
  network,
  validation,
  server,
  database,
  storage,
  unknown,
}

class AppException implements Exception {
  final String message;
  final ErrorCategory category;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppException({
    required this.message,
    this.category = ErrorCategory.unknown,
    this.code,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() =>
      'AppException: $message (Category: $category, Code: $code)';

  /// Get user-friendly error message for UI display
  String getUserMessage() {
    switch (category) {
      case ErrorCategory.authentication:
        return 'Authentication failed. Please try logging in again.';
      case ErrorCategory.network:
        return 'Network error. Please check your connection.';
      case ErrorCategory.validation:
        return 'Invalid input. Please check your data.';
      case ErrorCategory.server:
        return 'Server error. Please try again later.';
      case ErrorCategory.database:
        return 'Database error. Please try again.';
      case ErrorCategory.storage:
        return 'Storage error. Failed to upload file.';
      case ErrorCategory.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

/// 🔹 Logger utility with categorized logging
class AppLogger {
  static const String _tag = '📱 LegalSync';

  static void info(String message, {String? tag}) {
    final fullTag = tag != null ? '$_tag::$tag' : _tag;
    developer.log('ℹ️  $message', name: fullTag);
  }

  static void warning(String message, {String? tag}) {
    final fullTag = tag != null ? '$_tag::$tag' : _tag;
    developer.log('⚠️  $message', name: fullTag);
  }

  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final fullTag = tag != null ? '$_tag::$tag' : _tag;
    developer.log(
      '❌ $message\nError: $error',
      name: fullTag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final fullTag = tag != null ? '$_tag::$tag' : _tag;
      developer.log('🐛 $message', name: fullTag);
    }
  }
}

/// 🔹 Error handler with categorization
class ErrorHandler {
  /// Categorize Firebase errors
  static AppException handleFirebaseError(
    dynamic error, {
    String? message,
    StackTrace? stackTrace,
  }) {
    String errorMessage = message ?? 'Unknown Firebase error';
    ErrorCategory category = ErrorCategory.unknown;
    String? code;

    if (error is FirebaseException) {
      code = error.code;
      errorMessage = error.message ?? error.code;

      // Categorize based on error code
      if (code.contains('auth')) {
        category = ErrorCategory.authentication;
      } else if (code.contains('network') || code.contains('unavailable')) {
        category = ErrorCategory.network;
      } else if (code.contains('not-found') || code.contains('permission')) {
        category = ErrorCategory.database;
      }
    } else if (error is SocketException) {
      category = ErrorCategory.network;
      errorMessage = 'Network error: ${error.message}';
    } else {
      errorMessage = error.toString();
    }

    AppLogger.error(
      errorMessage,
      tag: 'Firebase',
      error: error,
      stackTrace: stackTrace,
    );

    return AppException(
      message: errorMessage,
      category: category,
      code: code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Handle validation errors
  static AppException handleValidationError(String message) {
    AppLogger.warning(message, tag: 'Validation');
    return AppException(message: message, category: ErrorCategory.validation);
  }

  /// Handle network errors
  static AppException handleNetworkError(dynamic error) {
    final message = 'Network error: ${error.toString()}';
    AppLogger.error(message, tag: 'Network', error: error);
    return AppException(
      message: message,
      category: ErrorCategory.network,
      originalError: error,
    );
  }

  /// Generic error handler
  static AppException handleError(
    dynamic error, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    if (error is AppException) return error;
    if (error is FirebaseException)
      return handleFirebaseError(error, stackTrace: stackTrace);
    if (error is SocketException) return handleNetworkError(error);

    final message = error.toString();
    AppLogger.error(message, tag: tag, error: error, stackTrace: stackTrace);

    return AppException(
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
