import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/case_Model.dart';
import '../services/case_service.dart';

// ===============================
// Case Service Provider
// ===============================
final caseServiceProvider = Provider((ref) => CaseService());

// ===============================
// All Cases Provider
// ===============================
final allCasesProvider = StreamProvider<List<CaseModel>>((ref) {
  final service = ref.watch(caseServiceProvider);
  return service.streamAllCases();
});

// ===============================
// Cases by Lawyer Provider
// ===============================
final casesByLawyerProvider = StreamProvider.family<List<CaseModel>, String>((
  ref,
  lawyerId,
) {
  final service = ref.watch(caseServiceProvider);
  return service.streamCasesByLawyer(lawyerId);
});

// ===============================
// Cases by Client Provider
// ===============================
final casesByClientProvider = StreamProvider.family<List<CaseModel>, String>((
  ref,
  clientId,
) {
  final service = ref.watch(caseServiceProvider);
  return service.streamCasesByClient(clientId);
});

// ===============================
// Get Case by ID Provider
// ===============================
final getCaseByIdProvider = FutureProvider.family<CaseModel?, String>((
  ref,
  caseId,
) async {
  final service = ref.watch(caseServiceProvider);
  return service.getCase(caseId);
});

// ===============================
// Active Cases Provider
// ===============================
final activeCasesProvider = StreamProvider<List<CaseModel>>((ref) {
  final service = ref.watch(caseServiceProvider);
  return service.streamActiveCases();
});

// ===============================
// Closed Cases Provider
// ===============================
final closedCasesProvider = StreamProvider<List<CaseModel>>((ref) {
  final service = ref.watch(caseServiceProvider);
  return service.streamClosedCases();
});

// ===============================
// Case Notifier
// ===============================
class CaseNotifier extends StateNotifier<CaseModel?> {
  final CaseService _service;

  CaseNotifier(this._service) : super(null);

  Future<String> createCase(CaseModel caseModel) async {
    final id = await _service.createCase(caseModel);
    state = caseModel;
    return id;
  }

  Future<void> updateCase(CaseModel caseModel) async {
    await _service.updateCase(caseModel);
    state = caseModel;
  }

  Future<void> deleteCase(String caseId) async {
    await _service.deleteCase(caseId);
    state = null;
  }

  Future<void> updateCaseStatus(String caseId, String newStatus) async {
    await _service.updateCaseStatus(caseId, newStatus);
  }

  Future<void> loadCase(String caseId) async {
    final caseModel = await _service.getCase(caseId);
    state = caseModel;
  }

  Future<void> archiveCase(String caseId) async {
    await _service.archiveCase(caseId);
  }

  Future<void> unarchiveCase(String caseId) async {
    await _service.unarchiveCase(caseId);
  }
}

// ===============================
// Case State Notifier Provider
// ===============================
final caseStateNotifierProvider =
    StateNotifierProvider<CaseNotifier, CaseModel?>((ref) {
      final service = ref.watch(caseServiceProvider);
      return CaseNotifier(service);
    });

// ===============================
// Selected Case Provider
// ===============================
final selectedCaseProvider = StateProvider<CaseModel?>((ref) => null);
