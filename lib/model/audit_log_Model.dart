import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Audit Log Model - Track all user activities for compliance and debugging
class AuditLogModel {
  final String logId;
  final String userId;
  final String userRole;
  final String action; // create, read, update, delete, login, logout, etc
  final String resourceType; // case, document, invoice, etc
  final String resourceId;
  final Map<String, dynamic>? changeDetails; // What changed
  final String? description;
  final String ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final String status; // success, failure
  final String? errorMessage;

  AuditLogModel({
    required this.logId,
    required this.userId,
    required this.userRole,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    this.changeDetails,
    this.description,
    required this.ipAddress,
    this.userAgent,
    required this.timestamp,
    required this.status,
    this.errorMessage,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'userId': userId,
      'userRole': userRole,
      'action': action,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'changeDetails': changeDetails,
      'description': description,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      logId: json['logId'] ?? '',
      userId: json['userId'] ?? '',
      userRole: json['userRole'] ?? '',
      action: json['action'] ?? '',
      resourceType: json['resourceType'] ?? '',
      resourceId: json['resourceId'] ?? '',
      changeDetails: json['changeDetails'] as Map<String, dynamic>?,
      description: json['description'],
      ipAddress: json['ipAddress'] ?? '',
      userAgent: json['userAgent'],
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
      status: json['status'] ?? 'success',
      errorMessage: json['errorMessage'],
    );
  }

  /// Copy with method
  AuditLogModel copyWith({
    String? logId,
    String? userId,
    String? userRole,
    String? action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? changeDetails,
    String? description,
    String? ipAddress,
    String? userAgent,
    DateTime? timestamp,
    String? status,
    String? errorMessage,
  }) {
    return AuditLogModel(
      logId: logId ?? this.logId,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      changeDetails: changeDetails ?? this.changeDetails,
      description: description ?? this.description,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if operation was successful
  bool get isSuccess {
    return status.toLowerCase() == 'success';
  }

  /// Check if operation failed
  bool get isFailure {
    return status.toLowerCase() == 'failure';
  }

  /// Get action display name
  String get actionDisplay {
    return switch (action.toLowerCase()) {
      'create' => 'Created',
      'read' => 'Viewed',
      'update' => 'Modified',
      'delete' => 'Deleted',
      'login' => 'Logged In',
      'logout' => 'Logged Out',
      'export' => 'Exported',
      'download' => 'Downloaded',
      'upload' => 'Uploaded',
      'approve' => 'Approved',
      'reject' => 'Rejected',
      _ => action,
    };
  }

  /// Get resource type display name
  String get resourceTypeDisplay {
    return switch (resourceType.toLowerCase()) {
      'case' => 'Case',
      'document' => 'Document',
      'invoice' => 'Invoice',
      'hearing' => 'Hearing',
      'time_entry' => 'Time Entry',
      'user' => 'User',
      'appointment' => 'Appointment',
      _ => resourceType,
    };
  }

  /// Create summary string
  String get summary {
    return '$actionDisplay $resourceTypeDisplay by $userRole';
  }

  /// Create detailed log entry
  String get detailedLog {
    return '''
Audit Log Entry:
- LogID: $logId
- User: $userId ($userRole)
- Action: $actionDisplay
- Resource: $resourceTypeDisplay ($resourceId)
- Timestamp: $timestamp
- Status: $status
- IP Address: $ipAddress
${description != null ? '- Description: $description' : ''}
${errorMessage != null ? '- Error: $errorMessage' : ''}
${changeDetails != null ? '- Changes: $changeDetails' : ''}
''';
  }

  @override
  String toString() {
    return 'AuditLogModel(logId: $logId, userId: $userId, action: $action, resourceType: $resourceType)';
  }
}
