import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/lawyer_availability_Model.dart';

class LawyerAvailabilityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'lawyer_availability';

  // ===============================
  // CREATE AVAILABILITY SLOT
  // ===============================
  Future<String> createAvailability(
    LawyerAvailabilityModel availability,
  ) async {
    final docRef = _db.collection(_collection).doc();
    await docRef.set({...availability.toJson(), 'availabilityId': docRef.id});
    return docRef.id;
  }

  // ===============================
  // GET AVAILABILITY BY ID
  // ===============================
  Future<LawyerAvailabilityModel?> getAvailability(
    String availabilityId,
  ) async {
    final doc = await _db.collection(_collection).doc(availabilityId).get();
    if (doc.exists) {
      return LawyerAvailabilityModel.fromJson(doc.data()!);
    }
    return null;
  }

  // ===============================
  // UPDATE AVAILABILITY
  // ===============================
  Future<void> updateAvailability(LawyerAvailabilityModel availability) async {
    await _db
        .collection(_collection)
        .doc(availability.availabilityId)
        .update(availability.toJson());
  }

  // ===============================
  // DELETE AVAILABILITY
  // ===============================
  Future<void> deleteAvailability(String availabilityId) async {
    await _db.collection(_collection).doc(availabilityId).delete();
  }

  // ===============================
  // GET AVAILABILITY FOR LAWYER
  // ===============================
  Stream<List<LawyerAvailabilityModel>> streamAvailabilityForLawyer(
    String lawyerId,
  ) {
    return _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LawyerAvailabilityModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // GET AVAILABILITY FOR SPECIFIC DAY
  // ===============================
  Future<LawyerAvailabilityModel?> getAvailabilityForDay(
    String lawyerId,
    String dayOfWeek,
  ) async {
    final snapshot = await _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('dayOfWeek', isEqualTo: dayOfWeek)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return LawyerAvailabilityModel.fromJson(snapshot.docs.first.data());
    }
    return null;
  }

  // ===============================
  // BOOK APPOINTMENT SLOT
  // ===============================
  Future<void> bookSlot(String availabilityId, String appointmentId) async {
    await _db.collection(_collection).doc(availabilityId).update({
      'bookedSlots': FieldValue.arrayUnion([appointmentId]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // CANCEL APPOINTMENT SLOT
  // ===============================
  Future<void> cancelSlot(String availabilityId, String appointmentId) async {
    await _db.collection(_collection).doc(availabilityId).update({
      'bookedSlots': FieldValue.arrayRemove([appointmentId]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // GET AVAILABLE SLOTS FOR LAWYER (count)
  // ===============================
  Future<int> getAvailableSlots(String lawyerId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('isActive', isEqualTo: true)
        .get();

    int totalAvailable = 0;
    for (final doc in snapshot.docs) {
      final availability = LawyerAvailabilityModel.fromJson(doc.data());
      totalAvailable += availability.availableSlots;
    }
    return totalAvailable;
  }

  // ===============================
  // TOGGLE AVAILABILITY STATUS
  // ===============================
  Future<void> toggleAvailabilityStatus(
    String availabilityId,
    bool isActive,
  ) async {
    await _db.collection(_collection).doc(availabilityId).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // BULK CREATE AVAILABILITY FOR WEEK
  // ===============================
  Future<List<String>> createWeeklyAvailability({
    required String lawyerId,
    required String startTime,
    required String endTime,
    required int slotDuration,
    String? breakStart,
    String? breakEnd,
  }) async {
    const daysOfWeek = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    final ids = <String>[];

    for (final day in daysOfWeek) {
      final availability = LawyerAvailabilityModel(
        availabilityId: '', // Will be set
        lawyerId: lawyerId,
        dayOfWeek: day,
        startTime: startTime,
        endTime: endTime,
        slotDurationMinutes: slotDuration,
        breakStartTime: breakStart,
        breakEndTime: breakEnd,
        createdAt: DateTime.now(),
      );
      final id = await createAvailability(availability);
      ids.add(id);
    }
    return ids;
  }
}
