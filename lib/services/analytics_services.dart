import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/analytics_model.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'analytics';

  /// 🔹 Add or update analytics (merge = true)
  Future<void> setAnalytics(AnalyticsModel analytics) async {
    await _firestore
        .collection(collectionName)
        .doc(analytics.analyticsId)
        .set(analytics.toJson(), SetOptions(merge: true));
  }

  /// 🔹 Fetch analytics once
  Future<AnalyticsModel?> getAnalytics(String analyticsId) async {
    final doc = await _firestore
        .collection(collectionName)
        .doc(analyticsId)
        .get();
    if (doc.exists && doc.data() != null) {
      return AnalyticsModel.fromJson(doc.data()!);
    }
    return null;
  }

  /// 🔹 Real-time stream for analytics updates
  Stream<AnalyticsModel?> streamAnalytics(String analyticsId) {
    return _firestore
        .collection(collectionName)
        .doc(analyticsId)
        .snapshots()
        .map(
          (doc) => doc.exists && doc.data() != null
              ? AnalyticsModel.fromJson(doc.data()!)
              : null,
        );
  }

  /// 🔹 Update partial fields
  Future<void> updateAnalytics(
    String analyticsId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collectionName).doc(analyticsId).update(data);
  }

  /// 🔹 Increment numeric fields safely
  Future<void> incrementField(
    String analyticsId,
    String field,
    int value,
  ) async {
    await _firestore.collection(collectionName).doc(analyticsId).update({
      field: FieldValue.increment(value),
      'lastUpdated': Timestamp.now(),
    });
  }

  /// 🔹 Increment revenue safely
  Future<void> incrementRevenue(String analyticsId, double amount) async {
    await _firestore.collection(collectionName).doc(analyticsId).update({
      'totalRevenue': FieldValue.increment(amount),
      'lastUpdated': Timestamp.now(),
    });
  }
}
