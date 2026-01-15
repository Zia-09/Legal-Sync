import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/invoice_Model.dart';
import '../services/invoice_service.dart';

// Service provider
final invoiceServiceProvider = Provider((ref) {
  return InvoiceService();
});

// Stream providers for invoice data

/// Stream all invoices for a specific case
final streamInvoicesByCaseProvider =
    StreamProvider.family<List<InvoiceModel>, String>((ref, caseId) {
      final service = ref.watch(invoiceServiceProvider);
      return service.getInvoicesByCaseId(caseId);
    });

/// Stream all invoices for a specific lawyer
final streamInvoicesByLawyerProvider =
    StreamProvider.family<List<InvoiceModel>, String>((ref, lawyerId) {
      final service = ref.watch(invoiceServiceProvider);
      return service.getInvoicesByLawyer(lawyerId);
    });

/// Get single invoice by ID (Future provider)
final getInvoiceByIdProvider = FutureProvider.family<InvoiceModel?, String>((
  ref,
  invoiceId,
) async {
  final service = ref.watch(invoiceServiceProvider);
  return service.getInvoiceById(invoiceId);
});

/// State notifier for managing invoice state
class InvoiceStateNotifier
    extends StateNotifier<AsyncValue<List<InvoiceModel>>> {
  final InvoiceService _service;

  InvoiceStateNotifier(this._service) : super(const AsyncValue.loading());

  /// Generate invoice from time entries
  Future<void> generateInvoice({
    required String caseId,
    required String lawyerId,
    required String clientId,
    double? customRatePerHour,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _service.generateInvoice(
        caseId: caseId,
        lawyerId: lawyerId,
        clientId: clientId,
        customRatePerHour: customRatePerHour,
      );
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Save invoice
  Future<void> saveInvoice(InvoiceModel invoice) async {
    try {
      state = const AsyncValue.loading();
      await _service.saveInvoice(invoice);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update invoice status (paid/overdue/draft/sent)
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      state = const AsyncValue.loading();
      await _service.updateInvoiceStatus(invoiceId, status);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Delete invoice
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      state = const AsyncValue.loading();
      await _service.deleteInvoice(invoiceId);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Mark invoice as paid
  Future<void> markAsPaid(String invoiceId) async {
    try {
      await _service.updateInvoiceStatus(invoiceId, 'paid');
    } catch (e) {
      print('Error marking invoice as paid: $e');
    }
  }

  /// Load invoices for case
  Future<void> loadInvoicesByCase(String caseId) async {
    try {
      state = const AsyncValue.loading();
      final invoices = await _service.getInvoicesByCaseId(caseId).first;
      state = AsyncValue.data(invoices);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load invoices for lawyer
  Future<void> loadInvoicesByLawyer(String lawyerId) async {
    try {
      state = const AsyncValue.loading();
      final invoices = await _service.getInvoicesByLawyer(lawyerId).first;
      state = AsyncValue.data(invoices);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Get invoice PDF URL
  Future<String?> getInvoicePDF(String invoiceId) async {
    try {
      final invoice = await _service.getInvoiceById(invoiceId);
      return invoice?.pdfUrl;
    } catch (e) {
      print('Error getting invoice PDF: $e');
      return null;
    }
  }
}

/// State notifier provider for invoice management
final invoiceStateNotifierProvider =
    StateNotifierProvider<InvoiceStateNotifier, AsyncValue<List<InvoiceModel>>>(
      (ref) {
        final service = ref.watch(invoiceServiceProvider);
        return InvoiceStateNotifier(service);
      },
    );
