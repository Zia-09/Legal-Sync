import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/staff_Model.dart';

class StaffService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'staff';

  // ===============================
  // CREATE STAFF MEMBER
  // ===============================
  Future<String> createStaff(StaffModel staff) async {
    final docRef = _db.collection(_collection).doc();
    await docRef.set({...staff.toJson(), 'staffId': docRef.id});
    return docRef.id;
  }

  // ===============================
  // GET STAFF BY ID
  // ===============================
  Future<StaffModel?> getStaff(String staffId) async {
    final doc = await _db.collection(_collection).doc(staffId).get();
    if (doc.exists) {
      return StaffModel.fromJson(doc.data()!);
    }
    return null;
  }

  // ===============================
  // UPDATE STAFF
  // ===============================
  Future<void> updateStaff(StaffModel staff) async {
    await _db.collection(_collection).doc(staff.staffId).update(staff.toJson());
  }

  // ===============================
  // DELETE STAFF (Soft delete by marking inactive)
  // ===============================
  Future<void> deleteStaff(String staffId) async {
    await _db.collection(_collection).doc(staffId).update({
      'isActive': false,
      'terminatedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // STREAM STAFF FOR FIRM
  // ===============================
  Stream<List<StaffModel>> streamStaffForFirm(String firmId) {
    return _db
        .collection(_collection)
        .where('firmId', isEqualTo: firmId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // GET STAFF BY ROLE
  // ===============================
  Stream<List<StaffModel>> streamStaffByRole(String firmId, String role) {
    return _db
        .collection(_collection)
        .where('firmId', isEqualTo: firmId)
        .where('role', isEqualTo: role)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // ASSIGN CASE TO STAFF
  // ===============================
  Future<void> assignCase(String staffId, String caseId) async {
    await _db.collection(_collection).doc(staffId).update({
      'assignedCases': FieldValue.arrayUnion([caseId]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // UNASSIGN CASE FROM STAFF
  // ===============================
  Future<void> unassignCase(String staffId, String caseId) async {
    await _db.collection(_collection).doc(staffId).update({
      'assignedCases': FieldValue.arrayRemove([caseId]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // GET STAFF WORKLOAD (assigned cases count)
  // ===============================
  Future<int> getStaffWorkload(String staffId) async {
    final doc = await _db.collection(_collection).doc(staffId).get();
    if (doc.exists) {
      final staff = StaffModel.fromJson(doc.data()!);
      return staff.assignedCases.length;
    }
    return 0;
  }

  // ===============================
  // UPDATE STAFF SALARY
  // ===============================
  Future<void> updateStaffSalary(String staffId, double newSalary) async {
    await _db.collection(_collection).doc(staffId).update({
      'salary': newSalary,
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // BATCH TERMINATE STAFF
  // ===============================
  Future<void> batchTerminateStaff(List<String> staffIds) async {
    final batch = _db.batch();
    final now = Timestamp.now();
    for (final id in staffIds) {
      batch.update(_db.collection(_collection).doc(id), {
        'isActive': false,
        'terminatedAt': now,
        'updatedAt': now,
      });
    }
    await batch.commit();
  }
}
