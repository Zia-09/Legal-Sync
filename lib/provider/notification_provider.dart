import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/notification_model.dart';
import '../services/notification_services.dart';

// ===============================
// Notification Service Provider
// ===============================
final notificationServiceProvider = Provider((ref) => NotificationService());

// ===============================
// All Notifications Provider
// ===============================
final allNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.streamAllNotifications();
});

// ===============================
// User Notifications Provider
// ===============================
final userNotificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
      final service = ref.watch(notificationServiceProvider);
      return service.streamNotificationsByUser(userId);
    });

// ===============================
// Unread Notifications Provider
// ===============================
final unreadNotificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
      final service = ref.watch(notificationServiceProvider);
      return service.streamUnreadNotifications(userId);
    });

// ===============================
// Unread Notifications Count Provider
// ===============================
final unreadNotificationsCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final service = ref.watch(notificationServiceProvider);
  return service.streamUnreadNotificationsCount(userId);
});

// ===============================
// Get Notification by ID Provider
// ===============================
final getNotificationByIdProvider =
    FutureProvider.family<NotificationModel?, String>((
      ref,
      notificationId,
    ) async {
      final service = ref.watch(notificationServiceProvider);
      return service.getNotification(notificationId);
    });

// ===============================
// Notification Notifier
// ===============================
class NotificationNotifier extends StateNotifier<NotificationModel?> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(null);

  Future<String> createNotification(NotificationModel notification) async {
    await _service.addNotification(notification);
    state = notification;
    return notification.notificationId;
  }

  Future<void> updateNotification(NotificationModel notification) async {
    await _service.updateNotification(notification);
    state = notification;
  }

  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(notificationId);
    state = null;
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _service.markAllRead(userId);
  }

  Future<void> loadNotification(String notificationId) async {
    final notification = await _service.getNotification(notificationId);
    state = notification;
  }

  Future<void> sendBulkNotifications(
    List<NotificationModel> notifications,
  ) async {
    for (final notification in notifications) {
      await _service.addNotification(notification);
    }
  }
}

// ===============================
// Notification State Notifier Provider
// ===============================
final notificationStateNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationModel?>((ref) {
      final service = ref.watch(notificationServiceProvider);
      return NotificationNotifier(service);
    });

// ===============================
// Selected Notification Provider
// ===============================
final selectedNotificationProvider = StateProvider<NotificationModel?>(
  (ref) => null,
);
