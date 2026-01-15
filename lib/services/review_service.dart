import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/review_Model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  /// 🔹 Create or update a review (Client)
  Future<void> createOrUpdateReview(ReviewModel review) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(review.reviewId)
          .set(review.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create or update review: $e');
    }
  }

  /// 🔹 Get all reviews (Admin)
  Stream<List<ReviewModel>> getAllReviews() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ReviewModel.fromJson({
          ...Map<String, dynamic>.from(data),
          'reviewId': doc.id,
        });
      }).toList();
    });
  }

  /// 🔹 Get reviews for a specific lawyer
  Stream<List<ReviewModel>> getReviewsByLawyer(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return ReviewModel.fromJson({
              ...Map<String, dynamic>.from(data),
              'reviewId': doc.id,
            });
          }).toList(),
        );
  }

  /// 🔹 Get reviews by a specific client
  Stream<List<ReviewModel>> getReviewsByClient(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return ReviewModel.fromJson({
              ...Map<String, dynamic>.from(data),
              'reviewId': doc.id,
            });
          }).toList(),
        );
  }

  /// 🔹 Get a single review by ID
  Future<ReviewModel?> getReviewById(String reviewId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reviewId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return ReviewModel.fromJson({
        ...Map<String, dynamic>.from(data),
        'reviewId': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to get review: $e');
    }
  }

  /// 🔹 Update review (Client edits their review)
  Future<void> updateReview(String reviewId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        ...data,
        'updatedAt': Timestamp.now(),
        'isEdited': true,
      });
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  /// 🔹 Lawyer replies to a review
  Future<void> replyToReview(String reviewId, String reply) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'reply': reply,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to reply to review: $e');
    }
  }

  /// 🔹 Like or unlike a review
  Future<void> toggleLike(String reviewId, String userId, bool isLiked) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'likes': isLiked
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// 🔹 Hide or show a review (Admin)
  Future<void> setReviewVisibility(String reviewId, bool isVisible) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'isVisible': isVisible,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to change visibility: $e');
    }
  }

  /// 🔹 Approve, reject, or flag a review (Admin)
  Future<void> changeReviewStatus({
    required String reviewId,
    required String status,
    String? adminNote,
  }) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'status': status,
        'adminNote': adminNote,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to change review status: $e');
    }
  }

  /// 🔹 Delete a review (Admin only)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).delete();
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  /// 🔹 Get only visible and approved reviews
  Stream<List<ReviewModel>> getVisibleApprovedReviews(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('isVisible', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return ReviewModel.fromJson({
              ...Map<String, dynamic>.from(data),
              'reviewId': doc.id,
            });
          }).toList(),
        );
  }
}
