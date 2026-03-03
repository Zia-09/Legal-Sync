import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/document_Model.dart';
import 'package:legal_sync/services/document_service.dart';

final documentServiceProvider = Provider((ref) => DocumentService());

final documentsByLawyerProvider =
    StreamProvider.family<List<DocumentModel>, String>((ref, lawyerId) {
      final service = ref.watch(documentServiceProvider);
      return service.getDocumentsByLawyer(lawyerId);
    });

final documentsByCaseProvider =
    StreamProvider.family<List<DocumentModel>, String>((ref, caseId) {
      final service = ref.watch(documentServiceProvider);
      return service.getDocumentsByCase(caseId);
    });

final documentStateProvider =
    StateNotifierProvider<DocumentNotifier, AsyncValue<void>>((ref) {
      final service = ref.watch(documentServiceProvider);
      return DocumentNotifier(service);
    });

class DocumentNotifier extends StateNotifier<AsyncValue<void>> {
  final DocumentService _service;

  DocumentNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> approveDocument(String documentId, String lawyerId) async {
    state = const AsyncValue.loading();
    try {
      await _service.approveDocumentForClient(
        documentId: documentId,
        approvedBy: lawyerId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> revokeAccess(String documentId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _service.revokeClientAccessToDocument(
        documentId: documentId,
        reason: reason,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteDocument(documentId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
