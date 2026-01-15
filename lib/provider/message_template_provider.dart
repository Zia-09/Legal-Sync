import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/message_template_Model.dart';
import '../services/message_template_service.dart';

// ===============================
// Message Template Service Provider
// ===============================
final messageTemplateServiceProvider = Provider(
  (ref) => MessageTemplateService(),
);

// ===============================
// Message Templates for Lawyer Provider
// ===============================
final messageTemplatesForLawyerProvider =
    StreamProvider.family<List<MessageTemplateModel>, String>((ref, lawyerId) {
      final service = ref.watch(messageTemplateServiceProvider);
      return service.streamTemplatesByLawyer(lawyerId);
    });

// ===============================
// Message Templates by Category Provider
// ===============================
final messageTemplatesByCategoryProvider =
    FutureProvider.family<List<MessageTemplateModel>, String>((
      ref,
      category,
    ) async {
      final service = ref.watch(messageTemplateServiceProvider);
      return service.getTemplatesByCategory('', category);
    });

// ===============================
// Get Message Template by ID Provider
// ===============================
final getMessageTemplateByIdProvider =
    FutureProvider.family<MessageTemplateModel?, String>((
      ref,
      templateId,
    ) async {
      final service = ref.watch(messageTemplateServiceProvider);
      return service.getTemplateById(templateId);
    });

// ===============================
// Most Used Templates Provider
// ===============================
final mostUsedTemplatesProvider =
    FutureProvider.family<List<MessageTemplateModel>, String>((
      ref,
      lawyerId,
    ) async {
      final service = ref.watch(messageTemplateServiceProvider);
      return service.getMostUsedTemplates(lawyerId, limit: 10);
    });

// ===============================
// Recently Used Templates Provider
// ===============================
final recentlyUsedTemplatesProvider =
    FutureProvider.family<List<MessageTemplateModel>, String>((
      ref,
      lawyerId,
    ) async {
      final service = ref.watch(messageTemplateServiceProvider);
      return service.getRecentlyUsedTemplates(lawyerId, limit: 10);
    });

// ===============================
// Message Template Notifier
// ===============================
class MessageTemplateNotifier extends StateNotifier<MessageTemplateModel?> {
  final MessageTemplateService _service;

  MessageTemplateNotifier(this._service) : super(null);

  Future<void> createTemplate(MessageTemplateModel template) async {
    await _service.createTemplate(template);
    state = template;
  }

  Future<void> updateTemplate(
    String templateId,
    Map<String, dynamic> data,
  ) async {
    await _service.updateTemplate(templateId, data);
  }

  Future<void> deleteTemplate(String templateId) async {
    await _service.deleteTemplate(templateId);
    state = null;
  }

  Future<void> loadTemplate(String templateId) async {
    final template = await _service.getTemplateById(templateId);
    state = template;
  }

  Future<void> incrementUsageCount(String templateId) async {
    await _service.incrementUsageCount(templateId);
  }

  Future<void> deactivateTemplate(String templateId) async {
    await _service.deactivateTemplate(templateId);
  }

  Future<void> addTag(String templateId, String tag) async {
    await _service.addTagToTemplate(templateId, tag);
  }

  Future<void> removeTag(String templateId, String tag) async {
    await _service.removeTagFromTemplate(templateId, tag);
  }

  Future<void> shareTemplate(String templateId) async {
    await _service.shareTemplate(templateId);
  }

  Future<void> unshareTemplate(String templateId) async {
    await _service.unshareTemplate(templateId);
  }
}

// ===============================
// Message Template State Notifier Provider
// ===============================
final messageTemplateStateNotifierProvider =
    StateNotifierProvider<MessageTemplateNotifier, MessageTemplateModel?>((
      ref,
    ) {
      final service = ref.watch(messageTemplateServiceProvider);
      return MessageTemplateNotifier(service);
    });

// ===============================
// Selected Message Template Provider
// ===============================
final selectedMessageTemplateProvider = StateProvider<MessageTemplateModel?>(
  (ref) => null,
);
