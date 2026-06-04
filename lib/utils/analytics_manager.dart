/// 🔹 Analytics & Monitoring Utilities
///
/// This provides:
/// - Event tracking
/// - Performance monitoring
/// - Crash reporting integration points
/// - User behavior analytics
library;

import 'package:legal_sync/utils/error_handler.dart';

enum AnalyticsEvent {
  appLaunched,
  userLoggedIn,
  userLoggedOut,
  caseCreated,
  caseUpdated,
  documentUploaded,
  paymentProcessed,
  errorOccurred,
  screenViewed,
  buttonClicked,
  featureUsed,
}

class AnalyticsManager {
  static const String _eventPrefix = 'legal_sync_';
  static final List<Map<String, dynamic>> _eventQueue = [];
  static const int _maxQueueSize = 100;

  /// Log analytics event
  static void logEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? parameters,
    String? customEventName,
  }) {
    try {
      final eventName = customEventName ?? _getEventName(event);
      final eventData = {
        'event': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        'parameters': parameters ?? {},
      };

      _eventQueue.add(eventData);

      // Keep queue size manageable
      if (_eventQueue.length > _maxQueueSize) {
        _eventQueue.removeAt(0);
      }

      AppLogger.debug('Event logged: $eventName', tag: 'Analytics');

      // Future: Send to Firebase Analytics or backend
      // FirebaseAnalytics.instance.logEvent(
      //   name: eventName,
      //   parameters: parameters,
      // );
    } catch (e) {
      AppLogger.error(
        'Failed to log analytics event',
        tag: 'Analytics',
        error: e,
      );
    }
  }

  /// Log screen view
  static void logScreenView(String screenName) {
    logEvent(
      AnalyticsEvent.screenViewed,
      parameters: {'screen_name': screenName},
    );
  }

  /// Log button click
  static void logButtonClick(String buttonName, {String? screenName}) {
    logEvent(
      AnalyticsEvent.buttonClicked,
      parameters: {
        'button_name': buttonName,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }

  /// Log feature usage
  static void logFeatureUsage(
    String featureName, {
    Map<String, dynamic>? details,
  }) {
    logEvent(
      AnalyticsEvent.featureUsed,
      parameters: {'feature_name': featureName, ...?details},
    );
  }

  /// Log error event
  static void logError(
    String errorType, {
    String? errorMessage,
    String? stack,
  }) {
    logEvent(
      AnalyticsEvent.errorOccurred,
      parameters: {
        'error_type': errorType,
        if (errorMessage != null) 'error_message': errorMessage,
        if (stack != null) 'stack_trace': stack,
      },
    );
  }

  /// Get event name from enum
  static String _getEventName(AnalyticsEvent event) {
    return _eventPrefix + event.toString().split('.').last;
  }

  /// Flush queued events
  static Future<void> flushEvents() async {
    try {
      if (_eventQueue.isEmpty) return;

      AppLogger.info(
        'Flushing ${_eventQueue.length} analytics events',
        tag: 'Analytics',
      );

      // Future: Send queued events to backend
      // await analyticsService.sendEvents(_eventQueue);

      _eventQueue.clear();
    } catch (e) {
      AppLogger.error(
        'Failed to flush analytics events',
        tag: 'Analytics',
        error: e,
      );
    }
  }
}

/// 🔹 Performance Monitoring
class PerformanceMonitor {
  static final Map<String, Stopwatch> _stopwatches = {};

  /// Start timing a performance metric
  static void startTimer(String label) {
    _stopwatches[label] = Stopwatch()..start();
    AppLogger.debug('Performance timer started: $label', tag: 'Performance');
  }

  /// Stop timer and log duration
  static int? stopTimer(String label) {
    final stopwatch = _stopwatches[label];
    if (stopwatch == null) {
      AppLogger.warning('Timer not found: $label', tag: 'Performance');
      return null;
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    AppLogger.info(
      'Performance metric [$label]: ${elapsedMs}ms',
      tag: 'Performance',
    );

    // Log slow operations (> 2 seconds)
    if (elapsedMs > 2000) {
      AnalyticsManager.logEvent(
        AnalyticsEvent.featureUsed,
        parameters: {
          'metric_type': 'slow_operation',
          'operation': label,
          'duration_ms': elapsedMs,
        },
      );
    }

    _stopwatches.remove(label);
    return elapsedMs;
  }

  /// Get elapsed time without stopping
  static int? getElapsed(String label) {
    return _stopwatches[label]?.elapsedMilliseconds;
  }

  /// Clear all timers
  static void clearAll() {
    _stopwatches.clear();
  }
}

/// 🔹 Crash Reporter Integration Point
class CrashReporter {
  /// Report crash with context
  static Future<void> reportCrash({
    required String error,
    required StackTrace stackTrace,
    Map<String, dynamic>? context,
  }) async {
    try {
      AppLogger.error(
        'Crash reported: $error',
        tag: 'CrashReporter',
        stackTrace: stackTrace,
      );

      // Future: Integrate with Firebase Crashlytics or similar
      // await FirebaseCrashlytics.instance.recordError(
      //   error,
      //   stackTrace,
      //   reason: 'Uncaught exception',
      //   information: [context],
      // );

      AnalyticsManager.logError(
        'uncaught_exception',
        errorMessage: error,
        stack: stackTrace.toString(),
      );
    } catch (e) {
      AppLogger.error('Failed to report crash', tag: 'CrashReporter', error: e);
    }
  }
}
