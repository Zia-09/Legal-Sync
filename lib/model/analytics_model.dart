import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Analytics / Dashboard Model
class AnalyticsModel {
  final String analyticsId; // Unique document ID
  final int totalClients;
  final int totalLawyers;
  final int totalAppointments;
  final int totalCompletedAppointments;
  final int totalPendingAppointments;
  final double totalRevenue; // Sum of all completed payments
  final int totalCases;
  final int totalReviews;
  final double avgLawyerRating;
  final double avgAIAccuracy; // Across all lawyers
  final Timestamp lastUpdated;

  const AnalyticsModel({
    required this.analyticsId,
    this.totalClients = 0,
    this.totalLawyers = 0,
    this.totalAppointments = 0,
    this.totalCompletedAppointments = 0,
    this.totalPendingAppointments = 0,
    this.totalRevenue = 0.0,
    this.totalCases = 0,
    this.totalReviews = 0,
    this.avgLawyerRating = 0.0,
    this.avgAIAccuracy = 0.0,
    required this.lastUpdated,
  });

  /// 🔹 From Firestore/JSON
  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      analyticsId: json['analyticsId']?.toString() ?? '',
      totalClients: json['totalClients'] ?? 0,
      totalLawyers: json['totalLawyers'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      totalCompletedAppointments: json['totalCompletedAppointments'] ?? 0,
      totalPendingAppointments: json['totalPendingAppointments'] ?? 0,
      totalRevenue: (json['totalRevenue'] is num)
          ? (json['totalRevenue'] as num).toDouble()
          : 0.0,
      totalCases: json['totalCases'] ?? 0,
      totalReviews: json['totalReviews'] ?? 0,
      avgLawyerRating: (json['avgLawyerRating'] is num)
          ? (json['avgLawyerRating'] as num).toDouble()
          : 0.0,
      avgAIAccuracy: (json['avgAIAccuracy'] is num)
          ? (json['avgAIAccuracy'] as num).toDouble()
          : 0.0,
      lastUpdated: json['lastUpdated'] is Timestamp
          ? json['lastUpdated'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch,
            ),
    );
  }

  /// 🔹 To Firestore/JSON
  Map<String, dynamic> toJson() {
    return {
      'analyticsId': analyticsId,
      'totalClients': totalClients,
      'totalLawyers': totalLawyers,
      'totalAppointments': totalAppointments,
      'totalCompletedAppointments': totalCompletedAppointments,
      'totalPendingAppointments': totalPendingAppointments,
      'totalRevenue': totalRevenue,
      'totalCases': totalCases,
      'totalReviews': totalReviews,
      'avgLawyerRating': avgLawyerRating,
      'avgAIAccuracy': avgAIAccuracy,
      'lastUpdated': lastUpdated,
    };
  }

  /// 🔹 CopyWith for updates
  AnalyticsModel copyWith({
    int? totalClients,
    int? totalLawyers,
    int? totalAppointments,
    int? totalCompletedAppointments,
    int? totalPendingAppointments,
    double? totalRevenue,
    int? totalCases,
    int? totalReviews,
    double? avgLawyerRating,
    double? avgAIAccuracy,
    Timestamp? lastUpdated,
  }) {
    return AnalyticsModel(
      analyticsId: analyticsId,
      totalClients: totalClients ?? this.totalClients,
      totalLawyers: totalLawyers ?? this.totalLawyers,
      totalAppointments: totalAppointments ?? this.totalAppointments,
      totalCompletedAppointments:
          totalCompletedAppointments ?? this.totalCompletedAppointments,
      totalPendingAppointments:
          totalPendingAppointments ?? this.totalPendingAppointments,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCases: totalCases ?? this.totalCases,
      totalReviews: totalReviews ?? this.totalReviews,
      avgLawyerRating: avgLawyerRating ?? this.avgLawyerRating,
      avgAIAccuracy: avgAIAccuracy ?? this.avgAIAccuracy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 🔹 Helper: readable last updated date
  DateTime get lastUpdatedDate => lastUpdated.toDate();
}
