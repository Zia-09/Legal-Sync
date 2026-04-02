import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/document_Model.dart';
import 'package:legal_sync/services/document_service.dart';
import 'package:legal_sync/provider/case_provider.dart';

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

/// Get all documents for a client across all their cases (realtime)
final documentsByClientProvider = 
    StreamProvider.family<List<DocumentModel>, String>((ref, clientId) {
      final casesAsync = ref.watch(casesByClientProvider(clientId));
      final service = ref.watch(documentServiceProvider);
      
      return casesAsync.when(
        data: (cases) {
          if (cases.isEmpty) return Stream.value([]);
          
          // Emit initial empty list, then poll for updates
          return Stream.periodic(const Duration(seconds: 2), (_) async {
            List<DocumentModel> allDocs = [];
            final docSet = <String>{};
            
            for (final caseModel in cases) {
              try {
                final docs = await service.getClientVisibleDocuments(caseModel.caseId).first;
                for (final doc in docs) {
                  if (docSet.add(doc.documentId)) {
                    allDocs.add(doc);
                  }
                }
              } catch (e) {
                // Skip on error
              }
            }
            
            allDocs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
            return allDocs;
          }).asyncMap((future) async => await future);
        },
        loading: () => Stream.value([]),
        error: (err, st) => Stream.error(err),
      );
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

  Future<void> rejectDocument(String documentId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _service.rejectDocument(
        documentId: documentId,
        reason: reason ?? 'Rejected by lawyer',
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
