import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerModel {
  final String lawyerId;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String? profileImage;
  final String? bio;
  final double rating;
  final int totalReviews;
  final List<String> caseIds;
  final List<String> clientIds;
  final bool isVerified;
  final String status;
  final double consultationFee;
  final String? location;
  final String? experience; // e.g. "5 years", "3+ years"
  final String role;
  final bool isApproved;
  final String approvalStatus;
  final String? approvedBy;
  final String? rejectionReason;
  final String? degreeDocument;
  final String? licenseDocument;
  final String? idCardDocument;
  final Timestamp joinedAt;
  final Timestamp? lastActive;

  // 🔹 AI Prediction & Performance Tracking
  final bool canAccessAIPanel;
  final double aiAccuracyThreshold;
  final int totalPredictionsReviewed;
  final double avgAIPredictionConfidence;
  final int totalCasesPredicted;
  final double aiWinRate;
  final List<Map<String, dynamic>> aiPredictionHistory;

  final double aiScore;

  const LawyerModel({
    required this.lawyerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    this.profileImage,
    this.bio,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.caseIds = const [],
    this.clientIds = const [],
    this.isVerified = false,
    this.status = "active",
    this.consultationFee = 0.0,
    this.location,
    this.experience,
    this.role = "lawyer",
    this.isApproved = false,
    this.approvalStatus = "pending",
    this.approvedBy,
    this.rejectionReason,
    this.degreeDocument,
    this.licenseDocument,
    this.idCardDocument,
    required this.joinedAt,
    this.lastActive,
    this.canAccessAIPanel = false,
    this.aiAccuracyThreshold = 0.75,
    this.totalPredictionsReviewed = 0,
    this.avgAIPredictionConfidence = 0.0,
    this.totalCasesPredicted = 0,
    this.aiWinRate = 0.0,
    this.aiPredictionHistory = const [],
    this.aiScore = 0.0,
  });

  /// ✅ Convert from Firestore
  factory LawyerModel.fromJson(Map<String, dynamic> json) {
    return LawyerModel(
      lawyerId: json['lawyerId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      profileImage: json['profileImage'],
      bio: json['bio'],
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      caseIds: (json['caseIds'] as List?)?.cast<String>() ?? const [],
      clientIds: (json['clientIds'] as List?)?.cast<String>() ?? const [],
      isVerified: json['isVerified'] ?? false,
      status: json['status']?.toString() ?? 'active',
      consultationFee: (json['consultationFee'] is num)
          ? (json['consultationFee'] as num).toDouble()
          : 0.0,
      location: json['location'],
      experience: json['experience']?.toString(),
      role: json['role']?.toString() ?? 'lawyer',
      isApproved: json['isApproved'] ?? false,
      approvalStatus: json['approvalStatus']?.toString() ?? 'pending',
      approvedBy: json['approvedBy'],
      rejectionReason: json['rejectionReason'],
      degreeDocument: json['degreeDocument'],
      licenseDocument: json['licenseDocument'],
      idCardDocument: json['idCardDocument'],
      joinedAt: json['joinedAt'] is Timestamp
          ? json['joinedAt'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(
              (json['joinedAt'] is int)
                  ? json['joinedAt'] as int
                  : DateTime.now().millisecondsSinceEpoch,
            ),
      lastActive: json['lastActive'] is Timestamp
          ? json['lastActive'] as Timestamp
          : (json['lastActive'] != null && json['lastActive'] is int)
          ? Timestamp.fromMillisecondsSinceEpoch(json['lastActive'] as int)
          : null,
      canAccessAIPanel: json['canAccessAIPanel'] ?? false,
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
      aiScore: (json['aiScore'] is num)
          ? (json['aiScore'] as num).toDouble()
          : 0.0,
    );
  }

  /// ✅ Convert to Firestore
  Map<String, dynamic> toJson() {
    return {
      'lawyerId': lawyerId,
      'name': name,
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'profileImage': profileImage,
      'bio': bio,
      'rating': rating,
      'totalReviews': totalReviews,
      'caseIds': caseIds,
      'clientIds': clientIds,
      'isVerified': isVerified,
      'status': status,
      'consultationFee': consultationFee,
      'location': location,
      'experience': experience,
      'role': role,
      'isApproved': isApproved,
      'approvalStatus': approvalStatus,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'degreeDocument': degreeDocument,
      'licenseDocument': licenseDocument,
      'idCardDocument': idCardDocument,
      'joinedAt': joinedAt,
      'lastActive': lastActive,
      'canAccessAIPanel': canAccessAIPanel,
      'aiAccuracyThreshold': aiAccuracyThreshold,
      'totalPredictionsReviewed': totalPredictionsReviewed,
      'avgAIPredictionConfidence': avgAIPredictionConfidence,
      'totalCasesPredicted': totalCasesPredicted,
      'aiWinRate': aiWinRate,
      'aiPredictionHistory': aiPredictionHistory,
      'aiScore': aiScore,
    };
  }

  /// 🔹 Alias for toJson
  Map<String, dynamic> toMap() => toJson();

  /// ✅ Copy with updates
  LawyerModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? specialization,
    String? profileImage,
    String? bio,
    double? rating,
    int? totalReviews,
    List<String>? caseIds,
    List<String>? clientIds,
    bool? isVerified,
    String? status,
    double? consultationFee,
    String? location,
    String? experience,
    String? role,
    bool? isApproved,
    String? approvalStatus,
    String? approvedBy,
    String? rejectionReason,
    String? degreeDocument,
    String? licenseDocument,
    String? idCardDocument,
    Timestamp? lastActive,
    bool? canAccessAIPanel,
    double? aiAccuracyThreshold,
    int? totalPredictionsReviewed,
    double? avgAIPredictionConfidence,
    int? totalCasesPredicted,
    double? aiWinRate,
    List<Map<String, dynamic>>? aiPredictionHistory,
    double? aiScore,
  }) {
    return LawyerModel(
      lawyerId: lawyerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      caseIds: caseIds ?? this.caseIds,
      clientIds: clientIds ?? this.clientIds,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      consultationFee: consultationFee ?? this.consultationFee,
      location: location ?? this.location,
      experience: experience ?? this.experience,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      degreeDocument: degreeDocument ?? this.degreeDocument,
      licenseDocument: licenseDocument ?? this.licenseDocument,
      idCardDocument: idCardDocument ?? this.idCardDocument,
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
      aiScore: aiScore ?? this.aiScore,
    );
  }

  /// ✅ Compute numeric experience (years)
  double get experienceYears {
    if (experience == null || experience!.trim().isEmpty) return 0.0;
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(experience!.trim());
    return double.tryParse(match?.group(1) ?? '0') ?? 0.0;
  }
}
