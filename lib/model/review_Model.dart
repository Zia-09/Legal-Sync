import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String lawyerId;
  final String clientId;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final List<String> likes; // For "like" feature
  final String? reply; // Lawyer reply
  final bool isVisible; // Admin can hide instead of delete
  final String? adminNote; // Admin’s reason or note
  final String status; // "approved", "pending", "hidden", "flagged"

  // 🧠 AI Prediction Fields
  final double? aiScore; // Confidence score (0.0 - 1.0)
  final String? aiPrediction; // "positive", "negative", "spam", etc.

  ReviewModel({
    required this.reviewId,
    required this.lawyerId,
    required this.clientId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.likes = const [],
    this.reply,
    this.isVisible = true,
    this.adminNote,
    this.status = "approved",
    this.aiScore,
    this.aiPrediction,
  });

  /// ✅ From Firestore / JSON
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] ?? '',
      lawyerId: json['lawyerId'] ?? '',
      clientId: json['clientId'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] != null
                ? DateTime.tryParse(json['updatedAt'])
                : null),
      isEdited: json['isEdited'] ?? false,
      likes: (json['likes'] != null)
          ? List<String>.from(json['likes'])
          : <String>[],
      reply: json['reply'],
      isVisible: json['isVisible'] ?? true,
      adminNote: json['adminNote'],
      status: json['status'] ?? "approved",
      aiScore: (json['aiScore'] != null)
          ? (json['aiScore'] as num).toDouble()
          : null,
      aiPrediction: json['aiPrediction'],
    );
  }

  /// ✅ To Firestore / JSON
  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'lawyerId': lawyerId,
      'clientId': clientId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isEdited': isEdited,
      'likes': likes,
      'reply': reply,
      'isVisible': isVisible,
      'adminNote': adminNote,
      'status': status,
      'aiScore': aiScore,
      'aiPrediction': aiPrediction,
    };
  }

  /// 🔹 Alias for toJson
  Map<String, dynamic> toMap() => toJson();

  /// 🔹 Alias for fromJson
  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel.fromJson({...map, 'reviewId': id});
  }

  /// ✅ CopyWith for easy updates
  ReviewModel copyWith({
    double? rating,
    String? comment,
    DateTime? updatedAt,
    bool? isEdited,
    List<String>? likes,
    String? reply,
    bool? isVisible,
    String? adminNote,
    String? status,
    double? aiScore,
    String? aiPrediction,
  }) {
    return ReviewModel(
      reviewId: reviewId,
      lawyerId: lawyerId,
      clientId: clientId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      likes: likes ?? this.likes,
      reply: reply ?? this.reply,
      isVisible: isVisible ?? this.isVisible,
      adminNote: adminNote ?? this.adminNote,
      status: status ?? this.status,
      aiScore: aiScore ?? this.aiScore,
      aiPrediction: aiPrediction ?? this.aiPrediction,
    );
  }
}
