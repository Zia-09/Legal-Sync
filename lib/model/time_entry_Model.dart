import 'package:cloud_firestore/cloud_firestore.dart';

class TimeEntryModel {
  final String timeEntryId;
  final String caseId;
  final String lawyerId;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in minutes
  final String? description;
  final String? taskType; // "research", "drafting", "meeting", "court", etc.
  final bool isBillable;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // "active", "paused", "completed"

  const TimeEntryModel({
    required this.timeEntryId,
    required this.caseId,
    required this.lawyerId,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.description,
    this.taskType,
    this.isBillable = true,
    required this.createdAt,
    this.updatedAt,
    this.status = "completed",
  });

  factory TimeEntryModel.fromJson(Map<String, dynamic> json) {
    return TimeEntryModel(
      timeEntryId: json['timeEntryId']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      lawyerId: json['lawyerId']?.toString() ?? '',
      startTime: json['startTime'] is Timestamp
          ? (json['startTime'] as Timestamp).toDate()
          : DateTime.tryParse(json['startTime']?.toString() ?? '') ??
                DateTime.now(),
      endTime: json['endTime'] is Timestamp
          ? (json['endTime'] as Timestamp).toDate()
          : (json['endTime'] != null
                ? DateTime.tryParse(json['endTime']?.toString() ?? '')
                : null),
      duration: json['duration'] ?? 0,
      description: json['description']?.toString(),
      taskType: json['taskType']?.toString(),
      isBillable: json['isBillable'] ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] != null
                ? DateTime.tryParse(json['updatedAt']?.toString() ?? '')
                : null),
      status: json['status']?.toString() ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeEntryId': timeEntryId,
      'caseId': caseId,
      'lawyerId': lawyerId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration,
      'description': description,
      'taskType': taskType,
      'isBillable': isBillable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
    };
  }

  TimeEntryModel copyWith({
    DateTime? endTime,
    int? duration,
    String? description,
    String? taskType,
    bool? isBillable,
    DateTime? updatedAt,
    String? status,
  }) {
    return TimeEntryModel(
      timeEntryId: timeEntryId,
      caseId: caseId,
      lawyerId: lawyerId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      isBillable: isBillable ?? this.isBillable,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  double get durationInHours => duration / 60.0;
  bool get isActive => status == 'active';
}
