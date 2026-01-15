import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/lawyer_model.dart';
import 'package:legal_sync/model/client_model.dart';
import 'package:legal_sync/model/ai_case_prediction_model.dart';
import 'package:legal_sync/model/admin_Model.dart';

class AdminService {
  AdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String lawyersCollection = 'lawyers';
  static const String clientsCollection = 'clients';
  static const String aiPredictionsCollection = 'ai_predictions';

  // =========================
  // LAWYER APPROVAL FLOW
  // =========================

  Future<void> approveLawyer(
    String lawyerId, {
    String approvedBy = 'Admin',
  }) async {
    try {
      await _firestore.collection(lawyersCollection).doc(lawyerId).update({
        'isApproved': true,
        'status': 'approved',
        'approvalStatus': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      });
    } on FirebaseException catch (e) {
      throw Exception('Approve lawyer failed: ${e.message}');
    }
  }

  Future<void> rejectLawyer(
    String lawyerId, {
    String reason = 'Documents not verified',
  }) async {
    try {
      await _firestore.collection(lawyersCollection).doc(lawyerId).update({
        'isApproved': false,
        'status': 'rejected',
        'approvalStatus': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Reject lawyer failed: ${e.message}');
    }
  }

  Future<void> markDocumentsReviewed(String lawyerId) async {
    try {
      await _firestore.collection(lawyersCollection).doc(lawyerId).update({
        'documentsReviewed': true,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Document review update failed: ${e.message}');
    }
  }

  // =========================
  // FETCH LAWYERS
  // =========================

  Stream<List<LawyerModel>> getAllLawyers() {
    return _firestore
        .collection(lawyersCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    LawyerModel.fromJson({...doc.data(), 'lawyerId': doc.id}),
              )
              .toList(),
        );
  }

  Stream<List<LawyerModel>> getPendingLawyers() {
    return _firestore
        .collection(lawyersCollection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    LawyerModel.fromJson({...doc.data(), 'lawyerId': doc.id}),
              )
              .toList(),
        );
  }

  Future<LawyerModel?> getLawyerById(String lawyerId) async {
    try {
      final doc = await _firestore
          .collection(lawyersCollection)
          .doc(lawyerId)
          .get();
      if (!doc.exists) return null;
      return LawyerModel.fromJson({...doc.data()!, 'lawyerId': doc.id});
    } on FirebaseException catch (e) {
      throw Exception('Fetch lawyer failed: ${e.message}');
    }
  }

  Future<void> deleteLawyer(String lawyerId) async {
    try {
      await _firestore.collection(lawyersCollection).doc(lawyerId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Delete lawyer failed: ${e.message}');
    }
  }

  // =========================
  // CLIENT MANAGEMENT
  // =========================

  Stream<List<ClientModel>> getAllClients() {
    return _firestore
        .collection(clientsCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ClientModel.fromJson({...doc.data(), 'clientId': doc.id}),
              )
              .toList(),
        );
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await _firestore.collection(clientsCollection).doc(clientId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Delete client failed: ${e.message}');
    }
  }

  // =========================
  // ADMIN DASHBOARD
  // =========================

  Future<Map<String, int>> getDashboardSummary() async {
    try {
      final results = await Future.wait([
        _firestore.collection(clientsCollection).get(),
        _firestore.collection(lawyersCollection).get(),
        _firestore
            .collection(lawyersCollection)
            .where('status', isEqualTo: 'pending')
            .get(),
        _firestore.collection(aiPredictionsCollection).get(),
      ]);

      return {
        'totalClients': results[0].docs.length,
        'totalLawyers': results[1].docs.length,
        'pendingLawyers': results[2].docs.length,
        'totalPredictions': results[3].docs.length,
      };
    } on FirebaseException catch (e) {
      throw Exception('Dashboard summary failed: ${e.message}');
    }
  }

  // =========================
  // AI PREDICTIONS
  // =========================

  Stream<List<AICasePredictionModel>> getAllAIPredictions() {
    return _firestore
        .collection(aiPredictionsCollection)
        .orderBy('predictedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AICasePredictionModel.fromJson({
                  ...doc.data(),
                  'caseId': doc.id,
                }),
              )
              .toList(),
        );
  }

  Future<void> deleteAIPrediction(String predictionId) async {
    try {
      await _firestore
          .collection(aiPredictionsCollection)
          .doc(predictionId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Delete AI prediction failed: ${e.message}');
    }
  }

  // =========================
  // ADMIN MANAGEMENT
  // =========================

  Future<String> createAdmin(dynamic admin) async {
    try {
      final docRef = await _firestore.collection('admins').add(admin.toJson());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Create admin failed: ${e.message}');
    }
  }

  Stream<List<AdminModel>> streamAllAdmins() {
    return _firestore.collection('admins').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminModel.fromJson(doc.data()))
          .toList();
    });
  }

  Future<AdminModel?> getAdmin(String adminId) async {
    try {
      final doc = await _firestore.collection('admins').doc(adminId).get();
      return doc.exists ? AdminModel.fromJson(doc.data()!) : null;
    } on FirebaseException catch (e) {
      throw Exception('Get admin failed: ${e.message}');
    }
  }

  Future<AdminModel?> getAdminByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty
          ? AdminModel.fromJson(snapshot.docs.first.data())
          : null;
    } on FirebaseException catch (e) {
      throw Exception('Get admin by email failed: ${e.message}');
    }
  }

  Stream<List<AdminModel>> streamActiveAdmins() {
    return _firestore
        .collection('admins')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminModel.fromJson(doc.data()))
              .toList();
        });
  }

  Stream<List<AdminModel>> streamAdminsByRole(String role) {
    return _firestore
        .collection('admins')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminModel.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> updateAdmin(dynamic admin) async {
    try {
      await _firestore
          .collection('admins')
          .doc(admin.adminId)
          .update(admin.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Update admin failed: ${e.message}');
    }
  }

  Future<void> deleteAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Delete admin failed: ${e.message}');
    }
  }

  Future<void> updateAdminRole(String adminId, String newRole) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'role': newRole,
      });
    } on FirebaseException catch (e) {
      throw Exception('Update admin role failed: ${e.message}');
    }
  }

  Future<void> activateAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'isActive': true,
      });
    } on FirebaseException catch (e) {
      throw Exception('Activate admin failed: ${e.message}');
    }
  }

  Future<void> deactivateAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'isActive': false,
      });
    } on FirebaseException catch (e) {
      throw Exception('Deactivate admin failed: ${e.message}');
    }
  }
}
