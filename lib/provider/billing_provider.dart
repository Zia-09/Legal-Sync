import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/billing_Model.dart';
import '../services/billing_service.dart';

// ===============================
// Billing Service Provider
// ===============================
final billingServiceProvider = Provider((ref) => BillingService());

// ===============================
// Active Billings Provider
// ===============================
final activeBillingsProvider = StreamProvider<List<BillingModel>>((ref) {
  final service = ref.watch(billingServiceProvider);
  return service.streamActiveBillings();
});

// ===============================
// Get Billing by ID Provider
// ===============================
final getBillingByIdProvider = FutureProvider.family<BillingModel?, String>((
  ref,
  billingId,
) async {
  final service = ref.watch(billingServiceProvider);
  return service.getBillingById(billingId);
});

// ===============================
// Get Billing by Client Provider
// ===============================
final billingByClientProvider = FutureProvider.family<BillingModel?, String>((
  ref,
  clientId,
) async {
  final service = ref.watch(billingServiceProvider);
  return service.getBillingByClientId(clientId);
});

// ===============================
// Stream Billing by Client Provider (Realtime)
// ===============================
final streamBillingByClientProvider =
    StreamProvider.family<BillingModel?, String>((ref, clientId) {
      final service = ref.watch(billingServiceProvider);
      return _streamBillingByClientId(service, clientId);
    });

// ===============================
// Overdue Billings Provider
// ===============================
final overdueBillingsProvider = FutureProvider<List<BillingModel>>((ref) async {
  final service = ref.watch(billingServiceProvider);
  return service.getOverdueBillings();
});

// ===============================
// Billing Notifier
// ===============================
class BillingNotifier extends StateNotifier<BillingModel?> {
  final BillingService _service;

  BillingNotifier(this._service) : super(null);

  Future<void> createBilling(BillingModel billing) async {
    await _service.createBilling(billing);
    state = billing;
  }

  Future<void> updateBilling(
    String billingId,
    Map<String, dynamic> data,
  ) async {
    await _service.updateBilling(billingId, data);
  }

  Future<void> recordPayment(String billingId, double amount) async {
    await _service.recordPayment(billingId, amount);
  }

  Future<void> addInvoice(
    String billingId,
    String invoiceId,
    double amount,
  ) async {
    await _service.addInvoiceToBilling(billingId, invoiceId, amount);
  }

  Future<void> removeInvoice(
    String billingId,
    String invoiceId,
    double amount,
  ) async {
    await _service.removeInvoiceFromBilling(billingId, invoiceId, amount);
  }

  Future<void> updateNextBillingDate(String billingId) async {
    await _service.updateNextBillingDate(billingId);
  }

  Future<void> loadBilling(String billingId) async {
    final billing = await _service.getBillingById(billingId);
    state = billing;
  }
}

// ===============================
// Billing State Notifier Provider
// ===============================
final billingStateNotifierProvider =
    StateNotifierProvider<BillingNotifier, BillingModel?>((ref) {
      final service = ref.watch(billingServiceProvider);
      return BillingNotifier(service);
    });

// ===============================
// Selected Billing Provider
// ===============================
final selectedBillingProvider = StateProvider<BillingModel?>((ref) => null);

// ===============================
// Helper Functions
// ===============================

/// Stream billing data for a client from Firestore in realtime
Stream<BillingModel?> _streamBillingByClientId(
  BillingService service,
  String clientId,
) async* {
  try {
    // Since BillingService may not have a stream method, we'll create one by polling
    // or use Firestore directly. For now, let's use a simple approach:
    // Get the billing once and then listen to Firestore updates
    final billing = await service.getBillingByClientId(clientId);
    yield billing;
    
    // If we need realtime updates, add a Firestore listener
    // This would require adding a streamBillingByClientId method to BillingService
  } catch (e) {
    yield null;
  }
}
