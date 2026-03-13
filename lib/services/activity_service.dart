import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/activity_model.dart';

/// 🔹 ActivityService handles all Firestore operations for case activity logging
class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Log a new activity for a case
  Future<void> logActivity({
    required String caseId,
    required String userId,
    required String userName,
    required String userRole,
    required String actionType,
    required String actionDescription,
  }) async {
    try {
      final String id = _firestore.collection('case_activities').doc().id;

      final ActivityModel activity = ActivityModel(
        id: id,
        caseId: caseId,
        userId: userId,
        userName: userName,
        userRole: userRole,
        actionType: actionType,
        actionDescription: actionDescription,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('case_activities')
          .doc(id)
          .set(activity.toJson());
    } catch (e) {
      print('🔥 Error logging activity: $e');
    }
  }

  Stream<List<ActivityModel>> streamCaseActivities(String caseId) {
    return _firestore
        .collection('case_activities')
        .where('caseId', isEqualTo: caseId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ActivityModel.fromJson(doc.data()))
              .toList();
          // Sort client-side to avoid index requirements in development
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }
}
