// lib/services/lawyer_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/model/review_Model.dart';

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

  /// 🔹 Update specific lawyer fields
  Future<void> updateLawyer({
    required String lawyerId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('lawyers').doc(lawyerId).update(data);
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

  /// 🔹 Add review and update lawyer rating
  Future<void> addReview(ReviewModel review) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(review.reviewId);
      await reviewRef.set(review.toJson());

      await _updateLawyerRating(review.lawyerId);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  /// 🔹 Stream: Get all reviews for a specific lawyer
  Stream<List<ReviewModel>> getReviewsForLawyer(String lawyerId) {
    return _firestore
        .collection('reviews')
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => ReviewModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'reviewId': doc.id,
                }),
              )
              .toList();
        });
  }

  /// 🔹 Helper: Recalculate average rating
  Future<void> _updateLawyerRating(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      if (snapshot.docs.isEmpty) {
        await _firestore.collection('lawyers').doc(lawyerId).update({
          'rating': 0.0,
          'totalReviews': 0,
        });
        return;
      }

      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += (doc['rating'] ?? 0).toDouble();
      }

      final avgRating = total / snapshot.docs.length;

      await _firestore.collection('lawyers').doc(lawyerId).update({
        'rating': avgRating,
        'totalReviews': snapshot.docs.length,
      });
    } catch (e) {
      throw Exception('Failed to update lawyer rating: $e');
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
      final snapshot = await _firestore
          .collection('lawyers')
          .orderBy('aiWinRate', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => LawyerModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'lawyerId': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get top AI lawyers: $e');
    }
  }
}
