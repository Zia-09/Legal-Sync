import 'package:intl/intl.dart';

/// 🔹 DateTime Helper - Format dates, calculate durations, compare deadlines
class DateTimeHelper {
  /// Format date to readable string
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    try {
      return DateFormat(format).format(date);
    } catch (_) {
      return date.toString();
    }
  }

  /// Format time to readable string
  static String formatTime(DateTime time, {String format = 'hh:mm a'}) {
    try {
      return DateFormat(format).format(time);
    } catch (_) {
      return time.toString();
    }
  }

  /// Format date and time together
  static String formatDateTime(
    DateTime dateTime, {
    String format = 'MMM dd, yyyy hh:mm a',
  }) {
    try {
      return DateFormat(format).format(dateTime);
    } catch (_) {
      return dateTime.toString();
    }
  }

  /// Calculate duration between two dates
  static String getDurationString(DateTime startTime, DateTime endTime) {
    final duration = endTime.difference(startTime);

    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Calculate hours between two times
  static double getHoursBetween(DateTime startTime, DateTime endTime) {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  /// Calculate minutes between two times
  static int getMinutesBetween(DateTime startTime, DateTime endTime) {
    return endTime.difference(startTime).inMinutes;
  }

  /// Compare deadline
  static String getDeadlineStatus(DateTime deadline) {
    final now = DateTime.now();
    final duration = deadline.difference(now);

    if (duration.isNegative) {
      return 'Overdue';
    } else if (duration.inDays > 7) {
      return '${duration.inDays} days remaining';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} days remaining';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h remaining';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m remaining';
    } else {
      return 'Due now';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.day == tomorrow.day &&
        date.month == tomorrow.month &&
        date.year == tomorrow.year;
  }

  /// Check if date is upcoming (within 7 days)
  static bool isUpcoming(DateTime date) {
    final now = DateTime.now();
    final duration = date.difference(now);
    return duration.isNegative == false && duration.inDays <= 7;
  }

  /// Get days until date
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    return date.difference(now).inDays;
  }

  /// Parse different date formats
  static DateTime? parseDate(String dateString) {
    try {
      // Try ISO format first
      return DateTime.parse(dateString);
    } catch (_) {
      try {
        // Try common formats
        return DateFormat('MMM dd, yyyy').parse(dateString);
      } catch (_) {
        return null;
      }
    }
  }

  /// Get relative time (e.g., "2 hours ago", "in 3 days")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final duration = now.difference(date);

    if (duration.isNegative) {
      // Future date
      final futureDuration = date.difference(now);
      if (futureDuration.inSeconds < 60) {
        return 'in a moment';
      } else if (futureDuration.inMinutes < 60) {
        return 'in ${futureDuration.inMinutes} minutes';
      } else if (futureDuration.inHours < 24) {
        return 'in ${futureDuration.inHours} hours';
      } else {
        return 'in ${futureDuration.inDays} days';
      }
    } else {
      // Past date
      if (duration.inSeconds < 60) {
        return 'just now';
      } else if (duration.inMinutes < 60) {
        return '${duration.inMinutes} minutes ago';
      } else if (duration.inHours < 24) {
        return '${duration.inHours} hours ago';
      } else {
        return '${duration.inDays} days ago';
      }
    }
  }
}
