import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/services/email_service.dart';

class LawyerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Add or update a lawyer profile
  Future<void> addOrUpdateLawyer(LawyerModel lawyer) async {
    try {
      await _firestore
          .collection('lawyers')
          .doc(lawyer.lawyerId)
          .set(lawyer.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add/update lawyer: $e');
    }
  }

  /// 🔹 Stream: Get all lawyers in real-time
  Stream<List<LawyerModel>> getAllLawyers() {
    return _firestore.collection('lawyers').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => LawyerModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'lawyerId': doc.id,
            }),
          )
          .toList();
    });
  }

  /// 🔹 One-time: Get lawyer by ID
  Future<LawyerModel?> getLawyerById(String lawyerId) async {
    try {
      final doc = await _firestore.collection('lawyers').doc(lawyerId).get();
      if (!doc.exists) return null;
      return LawyerModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'lawyerId': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to get lawyer: $e');
    }
  }

  /// 🔹 Stream: Get lawyer by ID in real-time
  Stream<LawyerModel?> getLawyerStream(String lawyerId) {
    return _firestore.collection('lawyers').doc(lawyerId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return LawyerModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'lawyerId': doc.id,
      });
    });
  }

  /// 🔹 Update specific lawyer fields
  Future<void> updateLawyer({
    required String lawyerId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('lawyers').doc(lawyerId).update(data);

      final bool isApprovedFlag = data['isApproved'] == true;
      final String? approvalStatus = data['approvalStatus'] as String?;
      final String? status = data['status'] as String?;

      final bool shouldSendApprovalEmail =
          isApprovedFlag ||
          approvalStatus == 'approved' ||
          approvalStatus == 'verified' ||
          status == 'active';

      if (shouldSendApprovalEmail) {
        final snapshot = await _firestore
            .collection('lawyers')
            .doc(lawyerId)
            .get();
        final lawyerData = snapshot.data() as Map<String, dynamic>?;
        if (lawyerData != null) {
          final String email = (lawyerData['email'] ?? '').toString();
          if (email.isNotEmpty) {
            final String name = (lawyerData['name'] ?? 'Counselor')
                .toString()
                .trim();
            await emailService.sendProfessionalEmail(
              to: email,
              subject: 'Your LegalSync Lawyer Account is Approved',
              htmlContent:
                  '''
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #131D31; text-align: center;">Congratulations, $name!</h2>
                <p style="font-size: 16px; color: #333;">Your <strong>LegalSync</strong> lawyer profile has been <strong>approved</strong> and is now live for clients.</p>
                <p style="color: #666;">You can start managing cases, scheduling hearings, and chatting with your clients in real-time.</p>
                <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                  <p style="margin: 0; color: #666;"><strong>Account Status:</strong> Approved & Active</p>
                </div>
                <p style="font-size: 14px; color: #777;">If you did not request this approval or believe this is a mistake, please contact LegalSync support immediately.</p>
                <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;" />
                <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. Empowering legal professionals worldwide.</p>
              </div>
              ''',
            );
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update lawyer: $e');
    }
  }

  /// 🔹 Delete lawyer (for admin use)
  Future<void> deleteLawyer(String lawyerId) async {
    try {
      await _firestore.collection('lawyers').doc(lawyerId).delete();
    } catch (e) {
      throw Exception('Failed to delete lawyer: $e');
    }
  }

  /// 🔹 Recommend lawyers by category (specialization)
  Future<List<LawyerModel>> recommendLawyers(String category) async {
    try {
      final snapshot = await _firestore
          .collection('lawyers')
          .where('specialization', isEqualTo: category)
          .get();

      List<LawyerModel> lawyers = snapshot.docs
          .map(
            (doc) => LawyerModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'lawyerId': doc.id,
            }),
          )
          .toList();

      // Sort by rating and experience
      lawyers.sort((a, b) {
        final scoreA = (a.rating * 0.7) + (a.experienceYears * 0.3);
        final scoreB = (b.rating * 0.7) + (b.experienceYears * 0.3);
        return scoreB.compareTo(scoreA);
      });

      return lawyers.take(3).toList();
    } catch (e) {
      throw Exception('Failed to recommend lawyers: $e');
    }
  }

  /// 🧠 Update AI performance metrics for lawyer
  Future<void> updateAIMetrics({
    required String lawyerId,
    double? aiAccuracyThreshold,
    double? avgAIPredictionConfidence,
    int? totalPredictionsReviewed,
    int? totalCasesPredicted,
    double? aiWinRate,
    List<String>? aiPredictionHistory,
  }) async {
    try {
      await _firestore.collection('lawyers').doc(lawyerId).update({
        if (aiAccuracyThreshold != null)
          'aiAccuracyThreshold': aiAccuracyThreshold,
        if (avgAIPredictionConfidence != null)
          'avgAIPredictionConfidence': avgAIPredictionConfidence,
        if (totalPredictionsReviewed != null)
          'totalPredictionsReviewed': totalPredictionsReviewed,
        if (totalCasesPredicted != null)
          'totalCasesPredicted': totalCasesPredicted,
        if (aiWinRate != null) 'aiWinRate': aiWinRate,
        if (aiPredictionHistory != null)
          'aiPredictionHistory': aiPredictionHistory,
      });
    } catch (e) {
      throw Exception('Failed to update AI metrics: $e');
    }
  }

  /// 🧠 Get top-performing AI lawyers
  Future<List<LawyerModel>> getTopAILawyers({int limit = 5}) async {
    try {
      final snapshot = await _firestore.collection('lawyers').get();

      final lawyers = snapshot.docs
          .map(
            (doc) => LawyerModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'lawyerId': doc.id,
            }),
          )
          .toList();

      lawyers.sort((a, b) => b.aiWinRate.compareTo(a.aiWinRate));
      return lawyers.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get top AI lawyers: $e');
    }
  }
}
