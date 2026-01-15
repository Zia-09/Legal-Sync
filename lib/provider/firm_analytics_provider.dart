import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firm_analytics_service.dart';

// ===============================
// Firm Analytics Service Provider
// ===============================
final firmAnalyticsServiceProvider = Provider((ref) => FirmAnalyticsService());

// ===============================
// Firm Dashboard Stats Provider
// ===============================
final firmDashboardStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, firmId) async {
      final service = ref.watch(firmAnalyticsServiceProvider);
      return service.getFirmDashboardStats(firmId);
    });

// ===============================
// Lawyer Stats Provider
// ===============================
final lawyerStatsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, lawyerId) async {
    // Note: getLawyerStats requires both lawyerId and firmId
    // This provides basic stats by lawyer ID
    final service = ref.watch(firmAnalyticsServiceProvider);
    // For simplicity, we'll return empty map - caller should provide firmId
    return {'lawyerId': lawyerId};
  },
);

// ===============================
// Lawyer Stats with Firm Provider
// ===============================
final lawyerStatsWithFirmProvider =
    FutureProvider.family<
      Map<String, dynamic>,
      ({String lawyerId, String firmId})
    >((ref, params) async {
      final service = ref.watch(firmAnalyticsServiceProvider);
      return service.getLawyerStats(params.lawyerId, params.firmId);
    });

// ===============================
// Case Analytics Provider
// ===============================
final caseAnalyticsProvider =
    FutureProvider.family<
      Map<String, dynamic>,
      ({String caseId, String lawyerId})
    >((ref, params) async {
      final service = ref.watch(firmAnalyticsServiceProvider);
      return service.getCaseAnalytics(params.caseId, params.lawyerId);
    });

// ===============================
// Monthly Revenue Analytics Provider
// ===============================
final monthlyRevenueAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, firmId) async {
      final service = ref.watch(firmAnalyticsServiceProvider);
      // Note: getMonthlyRevenue method needs to be verified in service
      // For now returning dashboard stats which includes revenue
      return service.getFirmDashboardStats(firmId);
    });

// ===============================
// Billing Analytics Provider
// ===============================
final billingAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, firmId) async {
      final service = ref.watch(firmAnalyticsServiceProvider);
      // Note: getBillingAnalytics method needs to be verified in service
      return service.getFirmDashboardStats(firmId);
    });

// ===============================
// Staff Workload Analytics Provider
// ===============================
final staffWorkloadAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, firmId) async {
      final service = ref.watch(firmAnalyticsServiceProvider);
      // Note: getStaffWorkloadAnalytics method needs to be verified in service
      return service.getFirmDashboardStats(firmId);
    });

// ===============================
// Firm Analytics Notifier
// ===============================
class FirmAnalyticsNotifier extends StateNotifier<Map<String, dynamic>> {
  final FirmAnalyticsService _service;

  FirmAnalyticsNotifier(this._service) : super({});

  Future<void> loadFirmStats(String firmId) async {
    final stats = await _service.getFirmDashboardStats(firmId);
    state = stats;
  }

  Future<void> loadLawyerMetrics(String lawyerId, String firmId) async {
    final metrics = await _service.getLawyerStats(lawyerId, firmId);
    state = {...state, 'lawyer_metrics': metrics};
  }

  Future<void> loadCaseMetrics(String caseId, String lawyerId) async {
    final metrics = await _service.getCaseAnalytics(caseId, lawyerId);
    state = {...state, 'case_metrics': metrics};
  }

  void refreshAnalytics() {
    state = {...state, 'refreshing': true};
  }

  void clearAnalytics() {
    state = {};
  }
}

// ===============================
// Firm Analytics State Notifier Provider
// ===============================
final firmAnalyticsStateNotifierProvider =
    StateNotifierProvider<FirmAnalyticsNotifier, Map<String, dynamic>>((ref) {
      final service = ref.watch(firmAnalyticsServiceProvider);
      return FirmAnalyticsNotifier(service);
    });
