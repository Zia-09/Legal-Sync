// lib/model/client_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String clientId;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;

  // 🔹 General Client Info
  final List<String> bookedLawyers; // List of lawyer IDs booked by client
  final List<String> caseIds; // List of client’s case IDs
  final double walletBalance; // For prepaid sessions or refunds
  final bool isVerified; // Verified by Admin
  final String status; // active, suspended, deleted, pending
  final String? address;
  final String? gender;
  final Timestamp joinedAt;
  final Timestamp? lastActive;
  final bool isApproved; // Admin approval for client account
  final String? adminNote; // Admin remarks
  final String? deviceToken; // For notifications
  final bool hasPendingPayment; // Track unpaid sessions

  // 🔹 AI Prediction System Fields
  final bool canAccessAIPanel; // Allow admin/client to view AI panel
  final double aiAccuracyThreshold; // Minimum accuracy to accept AI prediction
  final int totalPredictionsReviewed; // Total reviewed predictions
  final int totalCasesPredicted; // Total AI predictions made
  final double avgAIPredictionConfidence; // Average prediction confidence %
  final List<Map<String, dynamic>>
  aiPredictionHistory; // Store AI prediction history

  const ClientModel({
    required this.clientId,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.bookedLawyers = const [],
    this.caseIds = const [],
    this.walletBalance = 0.0,
    this.isVerified = false,
    this.status = "active",
    this.address,
    this.gender,
    required this.joinedAt,
    this.lastActive,
    this.isApproved = false,
    this.adminNote,
    this.deviceToken,
    this.hasPendingPayment = false,

    // 🔹 AI Prediction Defaults
    this.canAccessAIPanel = false,
    this.aiAccuracyThreshold = 0.75,
    this.totalPredictionsReviewed = 0,
    this.totalCasesPredicted = 0,
    this.avgAIPredictionConfidence = 0.0,
    this.aiPredictionHistory = const [],
  });

  /// ✅ Create object from Firestore JSON
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      clientId: json['clientId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      bookedLawyers: List<String>.from(json['bookedLawyers'] ?? []),
      caseIds: List<String>.from(json['caseIds'] ?? []),
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      isVerified: json['isVerified'] ?? false,
      status: json['status'] ?? 'active',
      address: json['address'],
      gender: json['gender'],
      joinedAt: json['joinedAt'] is Timestamp
          ? json['joinedAt']
          : Timestamp.fromMillisecondsSinceEpoch(json['joinedAt'] ?? 0),
      lastActive: json['lastActive'] is Timestamp
          ? json['lastActive']
          : json['lastActive'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['lastActive'])
          : null,
      isApproved: json['isApproved'] ?? false,
      adminNote: json['adminNote'],
      deviceToken: json['deviceToken'],
      hasPendingPayment: json['hasPendingPayment'] ?? false,

      // 🔹 AI Fields
      canAccessAIPanel: json['canAccessAIPanel'] ?? false,
      aiAccuracyThreshold: (json['aiAccuracyThreshold'] ?? 0.75).toDouble(),
      totalPredictionsReviewed: json['totalPredictionsReviewed'] ?? 0,
      totalCasesPredicted: json['totalCasesPredicted'] ?? 0,
      avgAIPredictionConfidence: (json['avgAIPredictionConfidence'] ?? 0.0)
          .toDouble(),
      aiPredictionHistory: (json['aiPredictionHistory'] != null)
          ? List<Map<String, dynamic>>.from(json['aiPredictionHistory'])
          : [],
    );
  }

  /// ✅ Convert object to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'bookedLawyers': bookedLawyers,
      'caseIds': caseIds,
      'walletBalance': walletBalance,
      'isVerified': isVerified,
      'status': status,
      'address': address,
      'gender': gender,
      'joinedAt': joinedAt,
      'lastActive': lastActive,
      'isApproved': isApproved,
      'adminNote': adminNote,
      'deviceToken': deviceToken,
      'hasPendingPayment': hasPendingPayment,

      // 🔹 AI Prediction Fields
      'canAccessAIPanel': canAccessAIPanel,
      'aiAccuracyThreshold': aiAccuracyThreshold,
      'totalPredictionsReviewed': totalPredictionsReviewed,
      'totalCasesPredicted': totalCasesPredicted,
      'avgAIPredictionConfidence': avgAIPredictionConfidence,
      'aiPredictionHistory': aiPredictionHistory,
    };
  }

  /// ✅ Copy with updates
  ClientModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    List<String>? bookedLawyers,
    List<String>? caseIds,
    double? walletBalance,
    bool? isVerified,
    String? status,
    String? address,
    String? gender,
    Timestamp? lastActive,
    bool? isApproved,
    String? adminNote,
    String? deviceToken,
    bool? hasPendingPayment,

    // 🔹 AI Prediction Fields
    bool? canAccessAIPanel,
    double? aiAccuracyThreshold,
    int? totalPredictionsReviewed,
    int? totalCasesPredicted,
    double? avgAIPredictionConfidence,
    List<Map<String, dynamic>>? aiPredictionHistory,
  }) {
    return ClientModel(
      clientId: clientId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bookedLawyers: bookedLawyers ?? this.bookedLawyers,
      caseIds: caseIds ?? this.caseIds,
      walletBalance: walletBalance ?? this.walletBalance,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      joinedAt: joinedAt,
      lastActive: lastActive ?? this.lastActive,
      isApproved: isApproved ?? this.isApproved,
      adminNote: adminNote ?? this.adminNote,
      deviceToken: deviceToken ?? this.deviceToken,
      hasPendingPayment: hasPendingPayment ?? this.hasPendingPayment,

      // 🔹 AI Prediction Fields
      canAccessAIPanel: canAccessAIPanel ?? this.canAccessAIPanel,
      aiAccuracyThreshold: aiAccuracyThreshold ?? this.aiAccuracyThreshold,
      totalPredictionsReviewed:
          totalPredictionsReviewed ?? this.totalPredictionsReviewed,
      totalCasesPredicted: totalCasesPredicted ?? this.totalCasesPredicted,
      avgAIPredictionConfidence:
          avgAIPredictionConfidence ?? this.avgAIPredictionConfidence,
      aiPredictionHistory: aiPredictionHistory ?? this.aiPredictionHistory,
    );
  }
}
