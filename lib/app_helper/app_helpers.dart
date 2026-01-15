import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/admin_model.dart';
import 'package:legal_sync/model/appoinment_model.dart';
import 'package:legal_sync/model/review_Model.dart';

/// ==========================
/// Date & Time Helpers
/// ==========================
class DateTimeHelper {
  /// Check if an appointment is upcoming
  static bool isAppointmentUpcoming(AppointmentModel appointment) {
    return appointment.scheduledAt.isAfter(DateTime.now());
  }

  /// Calculate total hours worked by a lawyer for a given list of appointments
  static double totalHoursWorked(List<AppointmentModel> appointments) {
    double totalMinutes = 0;
    for (var appt in appointments) {
      if (appt.status == "completed") {
        totalMinutes += appt.durationMinutes;
      }
    }
    return totalMinutes / 60.0; // return in hours
  }

  /// Calculate remaining time for an appointment
  static Duration remainingTime(AppointmentModel appointment) {
    final endTime = appointment.scheduledAt.add(
      Duration(minutes: appointment.durationMinutes),
    );
    return endTime.difference(DateTime.now());
  }
}

/// ==========================
/// AI Prediction Helpers
/// ==========================
class AIHelper {
  /// Classify review text automatically
  /// For simplicity, basic keyword-based prediction
  static String classifyReview(String reviewText) {
    final text = reviewText.toLowerCase();
    if (text.contains("bad") ||
        text.contains("poor") ||
        text.contains("hate")) {
      return "negative";
    } else if (text.contains("good") ||
        text.contains("excellent") ||
        text.contains("love")) {
      return "positive";
    } else if (text.contains("spam") || text.contains("fake")) {
      return "spam";
    } else {
      return "neutral";
    }
  }

  /// Generate a confidence score (0.0 - 1.0)
  /// Here we use a dummy logic; in real app, connect to AI/ML API
  static double predictConfidence(String reviewText) {
    final prediction = classifyReview(reviewText);
    switch (prediction) {
      case "positive":
      case "negative":
        return 0.8; // high confidence
      case "spam":
        return 0.9;
      default:
        return 0.5; // neutral/low confidence
    }
  }

  /// Update Admin AI prediction history
  static Future<void> updateAdminAIPrediction(
    AdminModel admin,
    ReviewModel review,
    FirebaseFirestore firestore,
  ) async {
    final newEntry = {
      "reviewId": review.reviewId,
      "lawyerId": review.lawyerId,
      "clientId": review.clientId,
      "prediction": review.aiPrediction ?? "neutral",
      "score": review.aiScore ?? 0.0,
      "timestamp": Timestamp.now(),
    };

    final updatedHistory = List<Map<String, dynamic>>.from(
      admin.aiPredictionHistory,
    )..add(newEntry);

    await firestore.collection("admins").doc(admin.adminId).update({
      "aiPredictionHistory": updatedHistory,
      "totalPredictionsReviewed": admin.totalPredictionsReviewed + 1,
      "avgAIPredictionConfidence":
          ((admin.avgAIPredictionConfidence * admin.totalPredictionsReviewed) +
              (review.aiScore ?? 0.0)) /
          (admin.totalPredictionsReviewed + 1),
    });
  }
}

/// ==========================
/// Role-Based Access Control (RBAC)
/// ==========================
enum UserRole { admin, lawyer, client }

class RBAC {
  /// Check if user can access admin panel
  static bool canAccessAdmin(UserRole role) {
    return role == UserRole.admin;
  }

  /// Check if lawyer can access client data
  /// Only allow if lawyer is assigned to this client
  static bool canLawyerAccessClient({
    required String lawyerId,
    required String clientId,
    required Map<String, String> assignments, // {clientId: lawyerId}
  }) {
    return assignments[clientId] == lawyerId;
  }

  /// Check if client can access lawyer data
  /// Only allow if lawyer is assigned to this client
  static bool canClientAccessLawyer({
    required String clientId,
    required String lawyerId,
    required Map<String, String> assignments, // {clientId: lawyerId}
  }) {
    return assignments[clientId] == lawyerId;
  }
}
