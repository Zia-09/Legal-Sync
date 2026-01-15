import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../model/document_Model.dart';
import '../services/document_service.dart';

// Service provider
final documentServiceProvider = Provider((ref) {
  return DocumentService();
});

// Stream providers for document data

/// Stream all documents for a specific case
final streamDocumentsByCaseProvider =
    StreamProvider.family<List<DocumentModel>, String>((ref, caseId) {
      final service = ref.watch(documentServiceProvider);
      return service.getDocumentsByCaseId(caseId);
    });

/// Get single document by ID (Future provider)
final getDocumentByIdProvider = FutureProvider.family<DocumentModel?, String>((
  ref,
  documentId,
) async {
  final service = ref.watch(documentServiceProvider);
  return service.getDocumentById(documentId);
});

/// State notifier for managing document state
class DocumentStateNotifier
    extends StateNotifier<AsyncValue<List<DocumentModel>>> {
  final DocumentService _service;

  DocumentStateNotifier(this._service) : super(const AsyncValue.loading());

  /// Upload file
  Future<void> uploadFile({
    required File file,
    required String caseId,
    required String uploadedBy,
    String? description,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _service.uploadFile(file, caseId, uploadedBy, description);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update document (metadata)
  Future<void> updateDocument(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      state = const AsyncValue.loading();
      await _service.saveDocumentMetadata(
        DocumentModel(
          documentId: documentId,
          caseId: data['caseId'],
          uploadedBy: data['uploadedBy'],
          fileUrl: data['fileUrl'],
          fileType: data['fileType'],
          version: data['version'] ?? 1,
          uploadedAt: data['uploadedAt'] ?? DateTime.now(),
          description: data['description'],
          isDeleted: data['isDeleted'] ?? false,
        ),
      );
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      state = const AsyncValue.loading();
      await _service.deleteDocument(documentId);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update document version
  Future<void> updateDocumentVersion(String documentId, File newFile) async {
    try {
      state = const AsyncValue.loading();
      await _service.updateDocumentVersion(documentId, newFile);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load documents for case
  Future<void> loadDocumentsByCase(String caseId) async {
    try {
      state = const AsyncValue.loading();
      final documents = await _service.getDocumentsByCaseId(caseId).first;
      state = AsyncValue.data(documents);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Download document
  Future<File?> downloadDocument(String fileUrl, String documentId) async {
    try {
      return await _service.downloadDocument(fileUrl);
    } catch (e) {
      print('Error downloading document: $e');
      return null;
    }
  }
}

/// State notifier provider for document management
final documentStateNotifierProvider =
    StateNotifierProvider<
      DocumentStateNotifier,
      AsyncValue<List<DocumentModel>>
    >((ref) {
      final service = ref.watch(documentServiceProvider);
      return DocumentStateNotifier(service);
    });
