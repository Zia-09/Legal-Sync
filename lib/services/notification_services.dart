import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/notification_model.dart';

class NotificationService {
  final CollectionReference _notifications = FirebaseFirestore.instance
      .collection('notifications');
  final CollectionReference _deviceTokens = FirebaseFirestore.instance
      .collection('user_device_tokens');
  final CollectionReference _notificationQueue = FirebaseFirestore.instance
      .collection('notification_queue');

  String generateNotificationId() {
    return _notifications.doc().id;
  }

  /// 🔹 Add a new notification
  Future<void> addNotification(NotificationModel notification) async {
    await _notifications
        .doc(notification.notificationId)
        .set(notification.toJson());
  }

  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? metadata,
  }) async {
    final id = generateNotificationId();
    await addNotification(
      NotificationModel(
        notificationId: id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        metadata: metadata,
      ),
    );
    return id;
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
    return _notifications.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final docs = snapshot.docs
          .map(
            (doc) =>
                NotificationModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
      return docs;
    });
  }

  Stream<List<NotificationModel>> streamUnreadNotifications(String userId) {
    return streamNotificationsByUser(userId).map((notifications) {
      return notifications.where((n) => n.isRead == false).toList();
    });
  }

  Stream<int> streamUnreadNotificationsCount(String userId) {
    return streamUnreadNotifications(userId).map((items) => items.length);
  }

  /// 🔹 Stream all notifications (for Admin Dashboard)
  Stream<List<NotificationModel>> streamAllNotifications() {
    return _notifications.snapshots().map((snapshot) {
      final docs = snapshot.docs
          .map(
            (doc) =>
                NotificationModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
      return docs;
    });
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

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({
      'isRead': true,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    String? platform,
  }) async {
    final docId = '${userId}_${token.hashCode}';
    await _deviceTokens.doc(docId).set({
      'userId': userId,
      'token': token,
      'platform': platform,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> unregisterDeviceToken({
    required String userId,
    required String token,
  }) async {
    final docId = '${userId}_${token.hashCode}';
    await _deviceTokens.doc(docId).delete();
  }

  /// Queue push payload for backend worker/Cloud Function.
  Future<void> queuePushNotification({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    DateTime? scheduledAt,
    String priority = 'high',
  }) async {
    await _notificationQueue.add({
      'userIds': userIds,
      'title': title,
      'message': message,
      'data': data ?? const {},
      'priority': priority,
      'scheduledAt': scheduledAt != null
          ? Timestamp.fromDate(scheduledAt)
          : FieldValue.serverTimestamp(),
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? metadata,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    for (final userId in userIds) {
      final doc = _notifications.doc();
      batch.set(doc, {
        'notificationId': doc.id,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': Timestamp.fromDate(now),
        'metadata': metadata,
      });
    }

    await batch.commit();
  }
}
