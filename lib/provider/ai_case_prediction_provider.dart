import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../model/ai_case_prediction_model.dart';
import '../services/ai_case_prediction_service.dart';

import 'package:flutter_riverpod/legacy.dart';

// ===============================
// AI Case Prediction Service Provider
// ===============================
final aiCasePredictionServiceProvider = Provider(
  (ref) => AICasePredictionService(),
);

// ===============================
// Get Prediction by Case Provider
// ===============================
final predictionByCaseProvider =
    FutureProvider.family<AICasePredictionModel?, String>((ref, caseId) async {
      final service = ref.watch(aiCasePredictionServiceProvider);
      return service.getPredictionByCase(caseId);
    });

// ===============================
// Predictions by Client Provider
// ===============================
final predictionsByClientProvider =
    StreamProvider.family<List<AICasePredictionModel>, String>((ref, clientId) {
      final service = ref.watch(aiCasePredictionServiceProvider);
      return service.getPredictionsByClient(clientId);
    });

// ===============================
// Predictions by Lawyer Provider
// ===============================
final predictionsByLawyerProvider =
    StreamProvider.family<List<AICasePredictionModel>, String>((ref, lawyerId) {
      final service = ref.watch(aiCasePredictionServiceProvider);
      return service.getPredictionsByLawyer(lawyerId);
    });

// ===============================
// All Predictions Provider
// ===============================
final allPredictionsProvider = StreamProvider<List<AICasePredictionModel>>((
  ref,
) {
  final service = ref.watch(aiCasePredictionServiceProvider);
  return service.getAllPredictions();
});

// ===============================
// AI Case Prediction Notifier
// ===============================
class AICasePredictionNotifier extends StateNotifier<AICasePredictionModel?> {
  final AICasePredictionService _service;

  AICasePredictionNotifier(this._service) : super(null);

  Future<void> createPrediction(AICasePredictionModel prediction) async {
    await _service.createPrediction(prediction);
    state = prediction;
  }

  Future<void> deletePrediction(String caseId) async {
    await _service.deletePrediction(caseId);
    state = null;
  }

  Future<void> reviewPrediction({
    required String caseId,
    bool? predictionConfirmed,
    String? adminNotes,
    double? updatedConfidence,
  }) async {
    await _service.reviewPrediction(
      caseId: caseId,
      predictionConfirmed: predictionConfirmed,
      adminNotes: adminNotes,
      updatedConfidence: updatedConfidence,
    );
    final prediction = await _service.getPredictionByCase(caseId);
    state = prediction;
  }

  Future<void> loadPrediction(String caseId) async {
    final prediction = await _service.getPredictionByCase(caseId);
    state = prediction;
  }
}

// ===============================
// AI Case Prediction State Notifier Provider
// ===============================
final aiCasePredictionStateNotifierProvider =
    StateNotifierProvider<AICasePredictionNotifier, AICasePredictionModel?>((
      ref,
    ) {
      final service = ref.watch(aiCasePredictionServiceProvider);
      return AICasePredictionNotifier(service);
    });

// ===============================
// Selected AI Prediction Provider
// ===============================
final selectedAIPredictionProvider = StateProvider<AICasePredictionModel?>(
  (ref) => null,
);
