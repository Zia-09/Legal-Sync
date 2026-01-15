import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/firm_Model.dart';

class FirmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'firms';

  // ===============================
  // CREATE FIRM
  // ===============================
  Future<String> createFirm(FirmModel firm) async {
    final docRef = _db.collection(_collection).doc();
    await docRef.set({...firm.toJson(), 'firmId': docRef.id});
    return docRef.id;
  }

  // ===============================
  // GET FIRM BY ID
  // ===============================
  Future<FirmModel?> getFirm(String firmId) async {
    final doc = await _db.collection(_collection).doc(firmId).get();
    if (doc.exists) {
      return FirmModel.fromJson(doc.data()!);
    }
    return null;
  }

  // ===============================
  // UPDATE FIRM
  // ===============================
  Future<void> updateFirm(FirmModel firm) async {
    await _db.collection(_collection).doc(firm.firmId).update(firm.toJson());
  }

  // ===============================
  // GET FIRM BY OWNER
  // ===============================
  Stream<FirmModel?> streamFirmByOwner(String ownerLawyerId) {
    return _db
        .collection(_collection)
        .where('ownerLawyerId', isEqualTo: ownerLawyerId)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty
              ? FirmModel.fromJson(snapshot.docs.first.data())
              : null,
        );
  }

  // ===============================
  // ADD LAWYER TO FIRM
  // ===============================
  Future<void> addLawyerToFirm(String firmId, String lawyerId) async {
    await _db.collection(_collection).doc(firmId).update({
      'lawyerIds': FieldValue.arrayUnion([lawyerId]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // REMOVE LAWYER FROM FIRM
  // ===============================
  Future<void> removeLawyerFromFirm(String firmId, String lawyerId) async {
    await _db.collection(_collection).doc(firmId).update({
      'lawyerIds': FieldValue.arrayRemove([lawyerId]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // ADD STAFF TO FIRM
  // ===============================
  Future<void> addStaffToFirm(String firmId, String staffId) async {
    await _db.collection(_collection).doc(firmId).update({
      'staffIds': FieldValue.arrayUnion([staffId]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // REMOVE STAFF FROM FIRM
  // ===============================
  Future<void> removeStaffFromFirm(String firmId, String staffId) async {
    await _db.collection(_collection).doc(firmId).update({
      'staffIds': FieldValue.arrayRemove([staffId]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // UPDATE BILLING SETTINGS
  // ===============================
  Future<void> updateBillingSettings(
    String firmId,
    Map<String, dynamic> settings,
  ) async {
    await _db.collection(_collection).doc(firmId).update({
      'billingSettings': settings,
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // GET FIRM STATS
  // ===============================
  Future<Map<String, dynamic>> getFirmStats(String firmId) async {
    final firm = await getFirm(firmId);
    if (firm == null) return {};

    return {
      'totalLawyers': firm.lawyerIds.length,
      'totalStaff': firm.staffIds.length,
      'isActive': firm.isActive,
      'lawyerIds': firm.lawyerIds,
      'staffIds': firm.staffIds,
    };
  }

  // ===============================
  // DEACTIVATE FIRM
  // ===============================
  Future<void> deactivateFirm(String firmId) async {
    await _db.collection(_collection).doc(firmId).update({
      'isActive': false,
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // ACTIVATE FIRM
  // ===============================
  Future<void> activateFirm(String firmId) async {
    await _db.collection(_collection).doc(firmId).update({
      'isActive': true,
      'updatedAt': Timestamp.now(),
    });
  }
}
