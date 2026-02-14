import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String documentId;
  final String caseId;
  final String uploadedBy; // lawyerId or clientId
  final String fileUrl; // Cloud Storage URL
  final String fileType; // pdf, image, doc, etc.
  final String? fileName;
  final double? fileSize; // in bytes
  final int version; // for version control
  final DateTime uploadedAt;
  final DateTime? updatedAt;
  final String? description;
  final List<String> tags; // for organization
  final bool isConfidential;
  final String? visibleTo; // "lawyer_only", "client_only", "both"
  final bool isApprovedForClient;
  final DateTime? approvedAt;
  final String? approvedBy;

  const DocumentModel({
    required this.documentId,
    required this.caseId,
    required this.uploadedBy,
    required this.fileUrl,
    required this.fileType,
    this.fileName,
    this.fileSize,
    this.version = 1,
    required this.uploadedAt,
    this.updatedAt,
    this.description,
    this.tags = const [],
    this.isConfidential = false,
    this.visibleTo = "both",
    this.isApprovedForClient = true,
    this.approvedAt,
    this.approvedBy,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      documentId: json['documentId']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      uploadedBy: json['uploadedBy']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      fileName: json['fileName']?.toString(),
      fileSize: (json['fileSize'] is num)
          ? (json['fileSize'] as num).toDouble()
          : null,
      version: json['version'] ?? 1,
      uploadedAt: json['uploadedAt'] is Timestamp
          ? (json['uploadedAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ??
                DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] != null
                ? DateTime.tryParse(json['updatedAt']?.toString() ?? '')
                : null),
      description: json['description']?.toString(),
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      isConfidential: json['isConfidential'] ?? false,
      visibleTo: json['visibleTo']?.toString() ?? 'both',
      isApprovedForClient: json['isApprovedForClient'] ?? true,
      approvedAt: json['approvedAt'] is Timestamp
          ? (json['approvedAt'] as Timestamp).toDate()
          : (json['approvedAt'] != null
                ? DateTime.tryParse(json['approvedAt']?.toString() ?? '')
                : null),
      approvedBy: json['approvedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'caseId': caseId,
      'uploadedBy': uploadedBy,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileName': fileName,
      'fileSize': fileSize,
      'version': version,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'description': description,
      'tags': tags,
      'isConfidential': isConfidential,
      'visibleTo': visibleTo,
      'isApprovedForClient': isApprovedForClient,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
    };
  }

  DocumentModel copyWith({
    String? fileUrl,
    DateTime? uploadedAt,
    String? description,
    List<String>? tags,
    bool? isConfidential,
    String? visibleTo,
    bool? isApprovedForClient,
    DateTime? approvedAt,
    String? approvedBy,
    int? version,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      documentId: documentId,
      caseId: caseId,
      uploadedBy: uploadedBy,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType,
      fileName: fileName,
      fileSize: fileSize,
      version: version ?? this.version,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isConfidential: isConfidential ?? this.isConfidential,
      visibleTo: visibleTo ?? this.visibleTo,
      isApprovedForClient: isApprovedForClient ?? this.isApprovedForClient,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }

  bool get isPDF => fileType.toLowerCase() == 'pdf';
  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'gif'].contains(fileType.toLowerCase());
}
