import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/review_Model.dart';
import '../services/review_service.dart';

/// 🔹 Step 1: Provide the ReviewService instance
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

/// 🔹 Step 2: Stream provider for all reviews (Admin view)
final allReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  final service = ref.watch(reviewServiceProvider);
  return service.getAllReviews();
});

/// 🔹 Step 3: Stream provider for lawyer’s visible + approved reviews
final lawyerReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((
  ref,
  lawyerId,
) {
  final service = ref.watch(reviewServiceProvider);
  return service.getVisibleApprovedReviews(lawyerId);
});

/// 🔹 Step 4: Stream provider for client’s own reviews
final clientReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((
  ref,
  clientId,
) {
  final service = ref.watch(reviewServiceProvider);
  return service.getReviewsByClient(clientId);
});

/// 🔹 Step 5: StateNotifier for actions (add, update, delete)
class ReviewController extends StateNotifier<AsyncValue<void>> {
  final ReviewService _service;
  ReviewController(this._service) : super(const AsyncValue.data(null));

  /// ➕ Create or update a review
  Future<void> createOrUpdateReview(ReviewModel review) async {
    state = const AsyncValue.loading();
    try {
      await _service.createOrUpdateReview(review);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ✏️ Update review (edit)
  Future<void> updateReview(String reviewId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateReview(reviewId, data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 💬 Lawyer reply
  Future<void> replyToReview(String reviewId, String reply) async {
    state = const AsyncValue.loading();
    try {
      await _service.replyToReview(reviewId, reply);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ❤️ Toggle like
  Future<void> toggleLike(String reviewId, String userId, bool isLiked) async {
    try {
      await _service.toggleLike(reviewId, userId, isLiked);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 👁️ Hide or show (Admin)
  Future<void> setVisibility(String reviewId, bool visible) async {
    try {
      await _service.setReviewVisibility(reviewId, visible);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ✅ Approve / ❌ Reject / 🚩 Flag review (Admin)
  Future<void> changeStatus(
    String reviewId,
    String status,
    String? note,
  ) async {
    try {
      await _service.changeReviewStatus(
        reviewId: reviewId,
        status: status,
        adminNote: note,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 🗑️ Delete review (Admin)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _service.deleteReview(reviewId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 🔹 Step 6: Provider for the controller
final reviewControllerProvider =
    StateNotifierProvider<ReviewController, AsyncValue<void>>((ref) {
      final service = ref.watch(reviewServiceProvider);
      return ReviewController(service);
    });
