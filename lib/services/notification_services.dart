import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/notification_model.dart';

class NotificationService {
  final CollectionReference _notifications = FirebaseFirestore.instance
      .collection('notifications');

  /// 🔹 Add a new notification
  Future<void> addNotification(NotificationModel notification) async {
    await _notifications
        .doc(notification.notificationId)
        .set(notification.toJson());
  }

  /// 🔹 Update notification (e.g., mark as read)
  Future<void> updateNotification(NotificationModel notification) async {
    await _notifications
        .doc(notification.notificationId)
        .update(notification.toJson());
  }

  /// 🔹 Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  /// 🔹 Get single notification by ID
  Future<NotificationModel?> getNotification(String notificationId) async {
    final doc = await _notifications.doc(notificationId).get();
    if (doc.exists) {
      return NotificationModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// 🔹 Stream notifications for a specific user
  Stream<List<NotificationModel>> streamNotificationsByUser(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => NotificationModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  /// 🔹 Stream all notifications (for Admin Dashboard)
  Stream<List<NotificationModel>> streamAllNotifications() {
    return _notifications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => NotificationModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  /// 🔹 Mark all notifications as read for a user
  Future<void> markAllRead(String userId) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'isRead': true,
        'updatedAt': Timestamp.now(),
      });
    }
  }
}
