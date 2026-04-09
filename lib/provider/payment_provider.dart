import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/payment_transaction_Model.dart';
import 'package:legal_sync/services/billing_service.dart';
import 'package:legal_sync/services/payment_service.dart';

class PaymentMethod {
  final String id;
  final String title;
  final String subtitle;
  final String iconPath;
  final bool isEnabled;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    this.isEnabled = false,
    this.isDefault = false,
  });

  PaymentMethod copyWith({bool? isEnabled, bool? isDefault}) {
    return PaymentMethod(
      id: id,
      title: title,
      subtitle: subtitle,
      iconPath: iconPath,
      isEnabled: isEnabled ?? this.isEnabled,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class PaymentNotifier extends StateNotifier<List<PaymentMethod>> {
  PaymentNotifier()
    : super([
        PaymentMethod(
          id: 'easypaisa',
          title: 'EasyPaisa',
          subtitle: 'Fast & Secure',
          iconPath: 'images/easypaisa.png',
          isEnabled: true,
        ),
        PaymentMethod(
          id: 'jazzcash',
          title: 'JazzCash',
          subtitle: 'Instant Transfer',
          iconPath: 'images/jazzcash.png',
          isEnabled: true,
        ),
        PaymentMethod(
          id: 'nayapay',
          title: 'NayaPay',
          subtitle: 'Digital Payments',
          iconPath: 'images/nayapay.png',
          isEnabled: true,
        ),
      ]);

  void toggleMethod(String id, bool enabled) {
    state = [
      for (final method in state)
        if (method.id == id) method.copyWith(isEnabled: enabled) else method,
    ];
  }

  void addCard(PaymentMethod card) {
    state = [...state, card];
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, List<PaymentMethod>>((ref) {
      return PaymentNotifier();
    });

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENT SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Payment Service Provider - singleton instance
final paymentServiceProvider = Provider((ref) => PaymentService());

/// Billing Service Provider - singleton instance
final billingServiceProvider = Provider((ref) => BillingService());

// ═══════════════════════════════════════════════════════════════════════════
// REAL-TIME TRANSACTION STREAMS
// ═══════════════════════════════════════════════════════════════════════════

/// Stream transactions for a client (real-time)
final transactionsByClientProvider =
    StreamProvider.family<List<PaymentTransactionModel>, String>((
      ref,
      clientId,
    ) {
      final service = ref.watch(billingServiceProvider);
      return service.getTransactionsByClient(clientId);
    });

/// Stream transactions for a lawyer (real-time)
final transactionsByLawyerProvider =
    StreamProvider.family<List<PaymentTransactionModel>, String>((
      ref,
      lawyerId,
    ) {
      final service = ref.watch(billingServiceProvider);
      return service.getTransactionsByLawyer(lawyerId);
    });

/// Stream transactions for a case (real-time)
final transactionsByCaseProvider =
    StreamProvider.family<List<PaymentTransactionModel>, String>((ref, caseId) {
      final service = ref.watch(billingServiceProvider);
      return service.getTransactionsByCase(caseId);
    });

// ===============================
// Transaction Notifier
// ===============================
class TransactionNotifier
    extends StateNotifier<AsyncValue<PaymentTransactionModel?>> {
  final BillingService _service;

  TransactionNotifier(this._service) : super(const AsyncValue.data(null));

  /// Create a new payment transaction
  Future<PaymentTransactionModel> createTransaction({
    required String clientId,
    required String lawyerId,
    required String caseId,
    required double amount,
    required String paymentMethod,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final transaction = await _service.createPaymentTransaction(
        clientId: clientId,
        lawyerId: lawyerId,
        caseId: caseId,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
      );
      state = AsyncValue.data(transaction);
      return transaction;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Complete payment transaction
  Future<void> completeTransaction(
    String transactionId,
    String? transactionRef,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _service.completePaymentTransaction(transactionId, transactionRef);
      final transaction = await _service.getTransactionById(transactionId);
      state = AsyncValue.data(transaction);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Fail payment transaction
  Future<void> failTransaction(
    String transactionId,
    String failureReason,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _service.failPaymentTransaction(transactionId, failureReason);
      final transaction = await _service.getTransactionById(transactionId);
      state = AsyncValue.data(transaction);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<
      TransactionNotifier,
      AsyncValue<PaymentTransactionModel?>
    >((ref) {
      final service = ref.watch(billingServiceProvider);
      return TransactionNotifier(service);
    });

// ═══════════════════════════════════════════════════════════════════════════
// REAL-TIME WALLET STREAMS
// ═══════════════════════════════════════════════════════════════════════════

/// Stream user wallet balance (real-time)
final walletBalanceProvider = StreamProvider.family<double, String>((
  ref,
  userId,
) {
  final service = ref.watch(paymentServiceProvider);
  return service.streamWalletBalance(userId);
});

// ═══════════════════════════════════════════════════════════════════════════
// TRANSACTION STATISTICS PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Get user transaction statistics (async)
final userTransactionStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
      final service = ref.watch(paymentServiceProvider);
      return service.getUserTransactionStats(userId);
    });

/// Get monthly transaction summary
final monthlyTransactionSummaryProvider =
    FutureProvider.family<
      Map<String, dynamic>,
      (String userId, int month, int year)
    >((ref, params) {
      final service = ref.watch(paymentServiceProvider);
      return service.getMonthlyTransactionSummary(
        params.$1,
        month: params.$2,
        year: params.$3,
      );
    });

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENT METHODS PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Get user payment methods (async)
final userPaymentMethodsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
      final service = ref.watch(paymentServiceProvider);
      return service.getUserPaymentMethods(userId);
    });
