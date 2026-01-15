import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 🔹 Notification Helper - Schedule reminders and manage notifications
class NotificationHelper {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize notification plugin
  static Future<void> initializeNotifications() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidInitializationSettings,
            iOS: iosInitializationSettings,
          );

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Request permissions
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Schedule notification at specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'legal_sync_channel',
            'Legal Sync Notifications',
            channelDescription: 'Notifications for Legal Sync App',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  /// Schedule hearing reminder (1 day before)
  static Future<void> scheduleHearingReminder({
    required String hearingId,
    required String courtName,
    required DateTime hearingDate,
  }) async {
    try {
      final reminderTime = hearingDate.subtract(Duration(days: 1));

      if (reminderTime.isBefore(DateTime.now())) {
        print('Hearing date has already passed');
        return;
      }

      await scheduleNotification(
        id: hearingId.hashCode,
        title: 'Upcoming Hearing Reminder',
        body:
            'Court hearing at $courtName tomorrow at ${hearingDate.hour}:${hearingDate.minute.toString().padLeft(2, '0')}',
        scheduledTime: reminderTime,
        payload: 'hearing_$hearingId',
      );
    } catch (e) {
      print('Error scheduling hearing reminder: $e');
    }
  }

  /// Schedule appointment reminder
  static Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String clientName,
    required DateTime appointmentTime,
    int minutesBefore = 30,
  }) async {
    try {
      final reminderTime = appointmentTime.subtract(
        Duration(minutes: minutesBefore),
      );

      if (reminderTime.isBefore(DateTime.now())) {
        print('Appointment time has already passed');
        return;
      }

      await scheduleNotification(
        id: appointmentId.hashCode,
        title: 'Appointment Reminder',
        body:
            'You have an appointment with $clientName in $minutesBefore minutes',
        scheduledTime: reminderTime,
        payload: 'appointment_$appointmentId',
      );
    } catch (e) {
      print('Error scheduling appointment reminder: $e');
    }
  }

  /// Schedule deadline reminder
  static Future<void> scheduleDeadlineReminder({
    required String caseId,
    required String title,
    required DateTime deadline,
    int daysBeforeCount = 3,
  }) async {
    try {
      final reminderTime = deadline.subtract(Duration(days: daysBeforeCount));

      if (reminderTime.isBefore(DateTime.now())) {
        print('Deadline has already passed');
        return;
      }

      await scheduleNotification(
        id: caseId.hashCode,
        title: 'Deadline Reminder',
        body: '$title due in $daysBeforeCount days',
        scheduledTime: reminderTime,
        payload: 'deadline_$caseId',
      );
    } catch (e) {
      print('Error scheduling deadline reminder: $e');
    }
  }

  /// Schedule time entry reminder (hourly)
  static Future<void> scheduleTimeEntryReminder({
    required String lawyerId,
    required DateTime nextReminderTime,
  }) async {
    try {
      if (nextReminderTime.isBefore(DateTime.now())) {
        print('Reminder time has already passed');
        return;
      }

      await scheduleNotification(
        id: 'timeentry_${lawyerId}_${DateTime.now().millisecondsSinceEpoch}'
            .hashCode,
        title: 'Time Entry Reminder',
        body: 'Have you logged your time today?',
        scheduledTime: nextReminderTime,
        payload: 'timeentry_$lawyerId',
      );
    } catch (e) {
      print('Error scheduling time entry reminder: $e');
    }
  }

  /// Send immediate notification
  static Future<void> sendImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const int id = 999;
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'legal_sync_channel',
            'Legal Sync Notifications',
            channelDescription: 'Notifications for Legal Sync App',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      print('Error sending immediate notification: $e');
    }
  }

  /// Cancel scheduled notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Notification callback handler
  static void handleNotificationTap(String? payload) {
    if (payload == null) return;

    // Route based on payload
    if (payload.startsWith('hearing_')) {
      print('Navigating to hearing details');
      // Navigate to hearing screen
    } else if (payload.startsWith('appointment_')) {
      print('Navigating to appointment details');
      // Navigate to appointment screen
    } else if (payload.startsWith('deadline_')) {
      print('Navigating to case details');
      // Navigate to case screen
    } else if (payload.startsWith('timeentry_')) {
      print('Navigating to time tracking');
      // Navigate to time tracking screen
    }
  }
}
