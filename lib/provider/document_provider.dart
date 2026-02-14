import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
      await _service.uploadAndSaveDocument(
        file: file,
        caseId: caseId,
        uploadedBy: uploadedBy,
        fileType: file.path.split('.').last,
        description: description,
      );
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
      await _service.updateDocument(documentId, data);
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
      final existing = await _service.getDocumentById(documentId);
      if (existing == null) {
        throw Exception('Document not found');
      }
      await _service.createNewVersion(
        oldDocument: existing,
        newFile: newFile,
        uploadedBy: existing.uploadedBy,
      );
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load documents for case
  Future<void> loadDocumentsByCase(String caseId) async {
    try {
      state = const AsyncValue.loading();
      final documents = await _service.getDocumentsByCase(caseId).first;
      state = AsyncValue.data(documents);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Download document
  Future<String?> downloadDocument(String fileUrl, String documentId) async {
    try {
      return await _service.getDownloadUrl(documentId);
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
