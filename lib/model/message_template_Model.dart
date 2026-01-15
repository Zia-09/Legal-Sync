import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Message Template Model - Canned/template responses for quick messaging
class MessageTemplateModel {
  final String templateId;
  final String lawyerId;
  final String title;
  final String content;
  final String
  category; // greeting, closing, status_update, legal_advice, client_update
  final List<String> tags; // For organizing and searching
  final int usageCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isPublic; // Can other lawyers use this template?

  MessageTemplateModel({
    required this.templateId,
    required this.lawyerId,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    this.usageCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.lastUsedAt,
    this.isPublic = false,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'templateId': templateId,
      'lawyerId': lawyerId,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'usageCount': usageCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
      'isPublic': isPublic,
    };
  }

  /// Create from JSON
  factory MessageTemplateModel.fromJson(Map<String, dynamic> json) {
    return MessageTemplateModel(
      templateId: json['templateId'] ?? '',
      lawyerId: json['lawyerId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'status_update',
      tags: List<String>.from(json['tags'] ?? []),
      usageCount: json['usageCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      lastUsedAt: json['lastUsedAt'] is Timestamp
          ? (json['lastUsedAt'] as Timestamp).toDate()
          : null,
      isPublic: json['isPublic'] ?? false,
    );
  }

  /// Copy with method
  MessageTemplateModel copyWith({
    String? templateId,
    String? lawyerId,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    int? usageCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isPublic,
  }) {
    return MessageTemplateModel(
      templateId: templateId ?? this.templateId,
      lawyerId: lawyerId ?? this.lawyerId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  /// Increment usage count
  MessageTemplateModel incrementUsage() {
    return copyWith(usageCount: usageCount + 1, lastUsedAt: DateTime.now());
  }

  /// Check if template is active
  bool get active {
    return isActive;
  }

  /// Get category display name
  String get categoryDisplay {
    return switch (category) {
      'greeting' => 'Greeting',
      'closing' => 'Closing',
      'status_update' => 'Status Update',
      'legal_advice' => 'Legal Advice',
      'client_update' => 'Client Update',
      _ => 'General',
    };
  }

  /// Get preview of template content (truncated)
  String get preview {
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }

  /// Check if template has specific tag
  bool hasTag(String tag) {
    return tags.contains(tag);
  }

  /// Add tag to template
  MessageTemplateModel addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  /// Remove tag from template
  MessageTemplateModel removeTag(String tag) {
    final updatedTags = tags.where((t) => t != tag).toList();
    return copyWith(tags: updatedTags);
  }

  @override
  String toString() {
    return 'MessageTemplateModel(templateId: $templateId, title: $title, category: $category)';
  }
}
