import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String adminId;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;

  final List<String> approvedLawyers;
  final List<String> rejectedLawyers;
  final List<String> suspendedAccounts;
  final String role;
  final bool isActive;
  final Timestamp joinedAt;
  final Timestamp? lastActive;

  // AI Management
  final bool canAccessAIPanel;
  final double aiAccuracyThreshold;
  final int totalPredictionsReviewed;

  // AI Analytics
  final double avgAIPredictionConfidence;
  final int totalCasesPredicted;
  final double aiWinRate;
  final List<Map<String, dynamic>> aiPredictionHistory;

  const AdminModel({
    required this.adminId,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.approvedLawyers = const [],
    this.rejectedLawyers = const [],
    this.suspendedAccounts = const [],
    this.role = "super_admin",
    this.isActive = true,
    required this.joinedAt,
    this.lastActive,
    this.canAccessAIPanel = true,
    this.aiAccuracyThreshold = 0.75,
    this.totalPredictionsReviewed = 0,
    this.avgAIPredictionConfidence = 0.0,
    this.totalCasesPredicted = 0,
    this.aiWinRate = 0.0,
    this.aiPredictionHistory = const [],
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      adminId: json['adminId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      approvedLawyers: (json['approvedLawyers'] as List?)?.cast<String>() ?? [],
      rejectedLawyers: (json['rejectedLawyers'] as List?)?.cast<String>() ?? [],
      suspendedAccounts:
          (json['suspendedAccounts'] as List?)?.cast<String>() ?? [],
      role: json['role']?.toString() ?? 'super_admin',
      isActive: json['isActive'] ?? true,
      joinedAt: json['joinedAt'] is Timestamp
          ? json['joinedAt'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(
              json['joinedAt'] is int
                  ? json['joinedAt'] as int
                  : DateTime.now().millisecondsSinceEpoch,
            ),
      lastActive: json['lastActive'] is Timestamp
          ? json['lastActive'] as Timestamp
          : (json['lastActive'] is int
                ? Timestamp.fromMillisecondsSinceEpoch(
                    json['lastActive'] as int,
                  )
                : null),
      canAccessAIPanel: json['canAccessAIPanel'] ?? true,
      aiAccuracyThreshold: (json['aiAccuracyThreshold'] is num)
          ? (json['aiAccuracyThreshold'] as num).toDouble()
          : 0.75,
      totalPredictionsReviewed: json['totalPredictionsReviewed'] ?? 0,
      avgAIPredictionConfidence: (json['avgAIPredictionConfidence'] is num)
          ? (json['avgAIPredictionConfidence'] as num).toDouble()
          : 0.0,
      totalCasesPredicted: json['totalCasesPredicted'] ?? 0,
      aiWinRate: (json['aiWinRate'] is num)
          ? (json['aiWinRate'] as num).toDouble()
          : 0.0,
      aiPredictionHistory: (json['aiPredictionHistory'] != null)
          ? List<Map<String, dynamic>>.from(json['aiPredictionHistory'])
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adminId': adminId,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'approvedLawyers': approvedLawyers,
      'rejectedLawyers': rejectedLawyers,
      'suspendedAccounts': suspendedAccounts,
      'role': role,
      'isActive': isActive,
      'joinedAt': joinedAt,
      'lastActive': lastActive,
      'canAccessAIPanel': canAccessAIPanel,
      'aiAccuracyThreshold': aiAccuracyThreshold,
      'totalPredictionsReviewed': totalPredictionsReviewed,
      'avgAIPredictionConfidence': avgAIPredictionConfidence,
      'totalCasesPredicted': totalCasesPredicted,
      'aiWinRate': aiWinRate,
      'aiPredictionHistory': aiPredictionHistory,
    };
  }

  AdminModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    List<String>? approvedLawyers,
    List<String>? rejectedLawyers,
    List<String>? suspendedAccounts,
    String? role,
    bool? isActive,
    Timestamp? lastActive,
    bool? canAccessAIPanel,
    double? aiAccuracyThreshold,
    int? totalPredictionsReviewed,
    double? avgAIPredictionConfidence,
    int? totalCasesPredicted,
    double? aiWinRate,
    List<Map<String, dynamic>>? aiPredictionHistory,
  }) {
    return AdminModel(
      adminId: adminId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      approvedLawyers: approvedLawyers ?? this.approvedLawyers,
      rejectedLawyers: rejectedLawyers ?? this.rejectedLawyers,
      suspendedAccounts: suspendedAccounts ?? this.suspendedAccounts,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt,
      lastActive: lastActive ?? this.lastActive,
      canAccessAIPanel: canAccessAIPanel ?? this.canAccessAIPanel,
      aiAccuracyThreshold: aiAccuracyThreshold ?? this.aiAccuracyThreshold,
      totalPredictionsReviewed:
          totalPredictionsReviewed ?? this.totalPredictionsReviewed,
      avgAIPredictionConfidence:
          avgAIPredictionConfidence ?? this.avgAIPredictionConfidence,
      totalCasesPredicted: totalCasesPredicted ?? this.totalCasesPredicted,
      aiWinRate: aiWinRate ?? this.aiWinRate,
      aiPredictionHistory: aiPredictionHistory ?? this.aiPredictionHistory,
    );
  }

  /// Helper: readable dates
  DateTime get joinedAtDate => joinedAt.toDate();
  DateTime? get lastActiveDate => lastActive?.toDate();
}
