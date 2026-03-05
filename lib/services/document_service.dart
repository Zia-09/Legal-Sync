import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/document_Model.dart';
import 'package:legal_sync/services/supabase_service.dart';

class DocumentService {
  DocumentService({FirebaseFirestore? firestore, SupabaseService? supabase})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _supabase = supabase ?? supabaseService;

  final FirebaseFirestore _firestore;
  final SupabaseService _supabase;
  static const String _collection = 'documents';
  static const String _storagePath = 'case_documents';

  /// 🔹 Upload file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String caseId,
    required String fileName,
  }) async {
    try {
      final path = '$_storagePath/$caseId';
      return await _supabase.uploadFile(file: file, path: path);
    } catch (e) {
      throw Exception('Failed to upload file to Supabase: $e');
    }
  }

  /// 🔹 Save document metadata
  Future<void> saveDocumentMetadata(DocumentModel document) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(document.documentId)
          .set(document.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save document metadata: $e');
    }
  }

  /// 🔹 Upload file and save metadata
  Future<DocumentModel> uploadAndSaveDocument({
    required File file,
    required String caseId,
    required String uploadedBy,
    required String fileType,
    String? description,
    List<String> tags = const [],
    bool isConfidential = false,
  }) async {
    try {
      final fileUrl = await uploadFile(
        file: file,
        caseId: caseId,
        fileName: file.path.split('/').last,
      );

      final documentId = _firestore.collection(_collection).doc().id;
      final document = DocumentModel(
        documentId: documentId,
        caseId: caseId,
        uploadedBy: uploadedBy,
        fileUrl: fileUrl,
        fileType: fileType,
        fileName: file.path.split('/').last,
        fileSize: file.lengthSync().toDouble(),
        uploadedAt: DateTime.now(),
        description: description,
        tags: tags,
        isConfidential: isConfidential,
        isApprovedForClient: !isConfidential,
      );

      await saveDocumentMetadata(document);
      return document;
    } catch (e) {
      throw Exception('Failed to upload and save document: $e');
    }
  }

  /// 🔹 Get documents for case
  Stream<List<DocumentModel>> getDocumentsByCase(String caseId) {
    return _firestore
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map(
                (doc) => DocumentModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'documentId': doc.id,
                }),
              )
              .toList();
          docs.sort(
            (a, b) => b.uploadedAt.compareTo(a.uploadedAt),
          ); // Newest first
          return docs;
        });
  }

  /// Documents visible to client (approved + visibility policy).
  Stream<List<DocumentModel>> getClientVisibleDocuments(String caseId) {
    return getDocumentsByCase(caseId).map((documents) {
      return documents
          .where(
            (doc) =>
                doc.isApprovedForClient == true &&
                (doc.visibleTo == null ||
                    doc.visibleTo == 'both' ||
                    doc.visibleTo == 'client_only'),
          )
          .toList();
    });
  }

  /// Backward-compatible alias for older provider naming.
  Stream<List<DocumentModel>> getDocumentsByCaseId(String caseId) {
    return getDocumentsByCase(caseId);
  }

  /// 🔹 Get document by ID
  Future<DocumentModel?> getDocumentById(String documentId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(documentId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return DocumentModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'documentId': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to fetch document: $e');
    }
  }

  /// 🔹 Update document metadata
  Future<void> updateDocument(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection(_collection).doc(documentId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  Future<void> approveDocumentForClient({
    required String documentId,
    required String approvedBy,
  }) async {
    await updateDocument(documentId, {
      'isApprovedForClient': true,
      'approvedAt': Timestamp.now(),
      'approvedBy': approvedBy,
    });
  }

  Future<void> revokeClientAccessToDocument({
    required String documentId,
    String? reason,
  }) async {
    await updateDocument(documentId, {
      'isApprovedForClient': false,
      'revokeReason': reason,
    });
  }

  /// 🔹 Version control - create new version
  Future<DocumentModel> createNewVersion({
    required DocumentModel oldDocument,
    required File newFile,
    required String uploadedBy,
  }) async {
    try {
      final newFileUrl = await uploadFile(
        file: newFile,
        caseId: oldDocument.caseId,
        fileName: newFile.path.split('/').last,
      );

      final newVersion = oldDocument.copyWith(
        version: oldDocument.version + 1,
        fileUrl: newFileUrl,
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        uploadedBy: uploadedBy,
      );

      await updateDocument(oldDocument.documentId, newVersion.toJson());
      return newVersion;
    } catch (e) {
      throw Exception('Failed to create new version: $e');
    }
  }

  /// 🔹 Download document (get URL)
  Future<String> getDownloadUrl(String documentId) async {
    try {
      final doc = await getDocumentById(documentId);
      if (doc == null) throw Exception('Document not found');
      return doc.fileUrl;
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  /// 🔹 Delete document and file
  Future<void> deleteDocument(String documentId) async {
    try {
      final doc = await getDocumentById(documentId);
      if (doc != null) {
        // Delete from storage
        try {
          await _supabase.deleteFile(doc.fileUrl);
        } catch (_) {
          // File may already be deleted
        }
      }

      // Delete metadata
      await _firestore.collection(_collection).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  /// 🔹 Search documents
  Stream<List<DocumentModel>> searchDocuments(String caseId, String query) {
    return _firestore
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map(
                (doc) => DocumentModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'documentId': doc.id,
                }),
              )
              .toList();
          docs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return docs
              .where(
                (doc) =>
                    ((doc.fileName?.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ??
                        false) ||
                    (doc.description?.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ??
                        false) ||
                    doc.tags.any(
                      (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                    )),
              )
              .toList();
        });
  }

  /// 🔹 Get all documents for a lawyer (all cases)
  Stream<List<DocumentModel>> getDocumentsByLawyer(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('uploadedBy', isEqualTo: lawyerId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map(
                (doc) => DocumentModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'documentId': doc.id,
                }),
              )
              .toList();
          docs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return docs;
        });
  }
}
