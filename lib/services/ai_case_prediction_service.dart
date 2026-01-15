import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/ai_case_prediction_model.dart';

class AICasePredictionService {
  final FirebaseFirestore _firestore;

  AICasePredictionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'ai_case_predictions';

  /// ✅ Create ONE AI prediction per case
  Future<void> createPrediction(AICasePredictionModel model) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(model.caseId) // caseId = document ID
          .set(model.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Create prediction failed: ${e.message}');
    }
  }

  /// ✅ Fetch prediction by case
  Future<AICasePredictionModel?> getPredictionByCase(String caseId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(caseId).get();

      if (!doc.exists) return null;

      return AICasePredictionModel.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw Exception('Fetch prediction failed: ${e.message}');
    }
  }

  /// ✅ Client predictions
  Stream<List<AICasePredictionModel>> getPredictionsByClient(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((e) => AICasePredictionModel.fromJson(e.data()))
              .toList(),
        );
  }

  /// ✅ Lawyer predictions
  Stream<List<AICasePredictionModel>> getPredictionsByLawyer(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((e) => AICasePredictionModel.fromJson(e.data()))
              .toList(),
        );
  }

  /// ✅ Admin dashboard
  Stream<List<AICasePredictionModel>> getAllPredictions() {
    return _firestore
        .collection(_collection)
        .orderBy('predictedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((e) => AICasePredictionModel.fromJson(e.data()))
              .toList(),
        );
  }

  /// ✅ Review / update (SAFE fields only)
  Future<void> reviewPrediction({
    required String caseId,
    bool? predictionConfirmed,
    String? adminNotes,
    double? updatedConfidence,
  }) async {
    final data = <String, dynamic>{
      if (predictionConfirmed != null)
        'predictionConfirmed': predictionConfirmed,
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (updatedConfidence != null) 'updatedConfidence': updatedConfidence,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection(_collection).doc(caseId).update(data);
    } on FirebaseException catch (e) {
      throw Exception('Update prediction failed: ${e.message}');
    }
  }

  /// ✅ Delete (admin only)
  Future<void> deletePrediction(String caseId) async {
    try {
      await _firestore.collection(_collection).doc(caseId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Delete prediction failed: ${e.message}');
    }
  }
}
