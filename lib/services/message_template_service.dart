import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/message_template_Model.dart';

/// 🔹 Message Template Service - Manage message templates for quick responses
class MessageTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'message_templates';

  /// Create new template
  Future<void> createTemplate(MessageTemplateModel template) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(template.templateId)
          .set(template.toJson());
    } catch (e) {
      print('Error creating template: $e');
      rethrow;
    }
  }

  /// Get template by ID
  Future<MessageTemplateModel?> getTemplateById(String templateId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(templateId)
          .get();
      if (doc.exists) {
        return MessageTemplateModel.fromJson(doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error getting template: $e');
      return null;
    }
  }

  /// Get all templates for a lawyer
  Future<List<MessageTemplateModel>> getTemplatesByLawyer(
    String lawyerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('isActive', isEqualTo: true)
          .orderBy('usageCount', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageTemplateModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting lawyer templates: $e');
      return [];
    }
  }

  /// Stream templates for a lawyer
  Stream<List<MessageTemplateModel>> streamTemplatesByLawyer(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('isActive', isEqualTo: true)
        .orderBy('usageCount', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageTemplateModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get templates by category
  Future<List<MessageTemplateModel>> getTemplatesByCategory(
    String lawyerId,
    String category,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('usageCount', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageTemplateModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting templates by category: $e');
      return [];
    }
  }

  /// Search templates by tag
  Future<List<MessageTemplateModel>> searchTemplatesByTag(
    String lawyerId,
    String tag,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('tags', arrayContains: tag)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageTemplateModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error searching templates: $e');
      return [];
    }
  }

  /// Search templates by keyword (title or content)
  Future<List<MessageTemplateModel>> searchTemplates(
    String lawyerId,
    String keyword,
  ) async {
    try {
      final allTemplates = await getTemplatesByLawyer(lawyerId);

      return allTemplates
          .where(
            (template) =>
                template.title.toLowerCase().contains(keyword.toLowerCase()) ||
                template.content.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();
    } catch (e) {
      print('Error searching templates: $e');
      return [];
    }
  }

  /// Update template
  Future<void> updateTemplate(
    String templateId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update(data);
    } catch (e) {
      print('Error updating template: $e');
      rethrow;
    }
  }

  /// Increment usage count
  Future<void> incrementUsageCount(String templateId) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update({
        'usageCount': FieldValue.increment(1),
        'lastUsedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error incrementing usage count: $e');
      rethrow;
    }
  }

  /// Delete template (soft delete)
  Future<void> deactivateTemplate(String templateId) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update({
        'isActive': false,
      });
    } catch (e) {
      print('Error deactivating template: $e');
      rethrow;
    }
  }

  /// Permanently delete template
  Future<void> deleteTemplate(String templateId) async {
    try {
      await _firestore.collection(_collection).doc(templateId).delete();
    } catch (e) {
      print('Error deleting template: $e');
      rethrow;
    }
  }

  /// Add tag to template
  Future<void> addTagToTemplate(String templateId, String tag) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update({
        'tags': FieldValue.arrayUnion([tag]),
      });
    } catch (e) {
      print('Error adding tag: $e');
      rethrow;
    }
  }

  /// Remove tag from template
  Future<void> removeTagFromTemplate(String templateId, String tag) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update({
        'tags': FieldValue.arrayRemove([tag]),
      });
    } catch (e) {
      print('Error removing tag: $e');
      rethrow;
    }
  }

  /// Get most used templates
  Future<List<MessageTemplateModel>> getMostUsedTemplates(
    String lawyerId,
    int limit,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('isActive', isEqualTo: true)
          .orderBy('usageCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MessageTemplateModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting most used templates: $e');
      return [];
    }
  }

  /// Get recently used templates
  Future<List<MessageTemplateModel>> getRecentlyUsedTemplates(
    String lawyerId,
    int limit,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('isActive', isEqualTo: true)
          .orderBy('lastUsedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MessageTemplateModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting recently used templates: $e');
      return [];
    }
  }

  /// Get public templates (shared by other lawyers)
  Future<List<MessageTemplateModel>> getPublicTemplates(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('usageCount', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => MessageTemplateModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting public templates: $e');
      return [];
    }
  }

  /// Share template with other lawyers (make public)
  Future<void> shareTemplate(String templateId) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update({
        'isPublic': true,
      });
    } catch (e) {
      print('Error sharing template: $e');
      rethrow;
    }
  }

  /// Unshare template
  Future<void> unshareTemplate(String templateId) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update({
        'isPublic': false,
      });
    } catch (e) {
      print('Error unsharing template: $e');
      rethrow;
    }
  }
}
