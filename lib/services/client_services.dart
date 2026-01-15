// lib/services/client_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/model/client_Model.dart';

class ClientService {
  ClientService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'clients';

  // =========================
  // CLIENT PROFILE
  // =========================

  /// Add or update client profile
  Future<String> addOrUpdateClient(ClientModel client) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(client.clientId)
          .set(client.toJson(), SetOptions(merge: true));
      return "success";
    } catch (e) {
      print("Error in addOrUpdateClient: $e");
      return "Failed to add/update client: $e";
    }
  }

  /// Get client by ID
  Future<ClientModel?> getClientById(String clientId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(clientId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ClientModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'clientId': doc.id,
      });
    } catch (e) {
      print("Error in getClientById: $e");
      return null;
    }
  }

  /// Get all clients (Admin)
  Stream<List<ClientModel>> getAllClients() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => ClientModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'clientId': doc.id,
            }),
          )
          .toList();
    });
  }

  /// Update client profile
  Future<String> updateClient({
    required String clientId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(_collection).doc(clientId).update(data);
      return "success";
    } catch (e) {
      print("Error in updateClient: $e");
      return "Failed to update client: $e";
    }
  }

  /// Delete client (Admin use)
  Future<String> deleteClient(String clientId) async {
    try {
      // Delete all related cases
      final caseSnapshot = await _firestore
          .collection('cases')
          .where('clientId', isEqualTo: clientId)
          .get();

      for (var doc in caseSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete client document
      await _firestore.collection(_collection).doc(clientId).delete();
      return "success";
    } catch (e) {
      print("Error in deleteClient: $e");
      return "Failed to delete client: $e";
    }
  }

  // =========================
  // LAWYER BOOKING
  // =========================

  /// Book a lawyer for client
  Future<String> bookLawyer({
    required String clientId,
    required String lawyerId,
  }) async {
    try {
      final clientDoc = _firestore.collection(_collection).doc(clientId);
      final docSnapshot = await clientDoc.get();

      if (!docSnapshot.exists) return "Client not found";

      await clientDoc.update({
        'bookedLawyers': FieldValue.arrayUnion([lawyerId]),
      });

      return "success";
    } catch (e) {
      print("Error in bookLawyer: $e");
      return "Failed to book lawyer: $e";
    }
  }

  /// Unbook a lawyer
  Future<String> unbookLawyer({
    required String clientId,
    required String lawyerId,
  }) async {
    try {
      await _firestore.collection(_collection).doc(clientId).update({
        'bookedLawyers': FieldValue.arrayRemove([lawyerId]),
      });
      return "success";
    } catch (e) {
      print("Error in unbookLawyer: $e");
      return "Failed to unbook lawyer: $e";
    }
  }

  // =========================
  // CASE MANAGEMENT
  // =========================

  /// Create a new case for client
  Future<String> createCase(CaseModel caseModel) async {
    try {
      await _firestore
          .collection('cases')
          .doc(caseModel.caseId)
          .set(caseModel.toJson());

      // Link case to client
      await _firestore.collection(_collection).doc(caseModel.clientId).update({
        'caseIds': FieldValue.arrayUnion([caseModel.caseId]),
      });

      return "success";
    } catch (e) {
      print("Error in createCase: $e");
      return "Failed to create case: $e";
    }
  }

  /// Get all cases for a client (real-time)
  Stream<List<CaseModel>> getClientCases(String clientId) {
    return _firestore
        .collection('cases')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => CaseModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'caseId': doc.id,
                }),
              )
              .toList();
        });
  }

  /// Get single case by ID
  Future<CaseModel?> getCaseById(String caseId) async {
    try {
      final doc = await _firestore.collection('cases').doc(caseId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CaseModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'caseId': doc.id,
      });
    } catch (e) {
      print("Error in getCaseById: $e");
      return null;
    }
  }

  /// Update a case
  Future<String> updateCase({
    required String caseId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('cases').doc(caseId).update(data);
      return "success";
    } catch (e) {
      print("Error in updateCase: $e");
      return "Failed to update case: $e";
    }
  }

  /// Delete a case
  Future<String> deleteCase(String caseId, String clientId) async {
    try {
      // Delete case document
      await _firestore.collection('cases').doc(caseId).delete();

      // Remove case reference from client
      await _firestore.collection(_collection).doc(clientId).update({
        'caseIds': FieldValue.arrayRemove([caseId]),
      });

      return "success";
    } catch (e) {
      print("Error in deleteCase: $e");
      return "Failed to delete case: $e";
    }
  }
}
