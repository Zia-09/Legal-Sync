import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/billing_Model.dart';
import '../model/payment_transaction_Model.dart';
import 'email_service.dart';

/// 🔹 Billing Service - Manage client billing and payment tracking
class BillingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'billings';

  /// Create billing record
  Future<void> createBilling(BillingModel billing) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(billing.billingId)
          .set(billing.toJson());
    } catch (e) {
      print('Error creating billing: $e');
      rethrow;
    }
  }

  /// Get billing by ID
  Future<BillingModel?> getBillingById(String billingId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(billingId).get();
      if (doc.exists) {
        return BillingModel.fromJson(doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error getting billing: $e');
      return null;
    }
  }

  /// Get billing by client ID
  Future<BillingModel?> getBillingByClientId(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return BillingModel.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting client billing: $e');
      return null;
    }
  }

  /// Update billing record
  Future<void> updateBilling(
    String billingId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(_collection).doc(billingId).update(data);
    } catch (e) {
      print('Error updating billing: $e');
      rethrow;
    }
  }

  /// Record payment
  Future<void> recordPayment(String billingId, double amount) async {
    try {
      final billing = await getBillingById(billingId);
      if (billing == null) throw Exception('Billing not found');

      final newTotalPaid = billing.totalPaid + amount;
      final newBalance = billing.balance - amount;

      await updateBilling(billingId, {
        'totalPaid': newTotalPaid,
        'balance': newBalance,
        'status': newBalance <= 0 ? 'paid' : 'active',
      });
    } catch (e) {
      print('Error recording payment: $e');
      rethrow;
    }
  }

  /// Add invoice to billing
  Future<void> addInvoiceToBilling(
    String billingId,
    String invoiceId,
    double amount,
  ) async {
    try {
      final billing = await getBillingById(billingId);
      if (billing == null) throw Exception('Billing not found');

      final updatedInvoiceIds = [...billing.invoiceIds, invoiceId];

      await updateBilling(billingId, {
        'invoiceIds': updatedInvoiceIds,
        'totalBilled': billing.totalBilled + amount,
        'balance': (billing.totalBilled + amount) - billing.totalPaid,
      });
    } catch (e) {
      print('Error adding invoice: $e');
      rethrow;
    }
  }

  /// Remove invoice from billing
  Future<void> removeInvoiceFromBilling(
    String billingId,
    String invoiceId,
    double amount,
  ) async {
    try {
      final billing = await getBillingById(billingId);
      if (billing == null) throw Exception('Billing not found');

      final updatedInvoiceIds = billing.invoiceIds
          .where((id) => id != invoiceId)
          .toList();

      await updateBilling(billingId, {
        'invoiceIds': updatedInvoiceIds,
        'totalBilled': billing.totalBilled - amount,
        'balance': (billing.totalBilled - amount) - billing.totalPaid,
      });
    } catch (e) {
      print('Error removing invoice: $e');
      rethrow;
    }
  }

  /// Get all active billings
  Future<List<BillingModel>> getActiveBillings() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .get();

      final docs = snapshot.docs
          .map((doc) => BillingModel.fromJson(doc.data()))
          .toList();
      docs.sort(
        (a, b) => (a.nextBillingDate ?? DateTime.now()).compareTo(
          b.nextBillingDate ?? DateTime.now(),
        ),
      );
      return docs;
    } catch (e) {
      print('Error getting active billings: $e');
      return [];
    }
  }

  /// Stream active billings
  Stream<List<BillingModel>> streamActiveBillings() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => BillingModel.fromJson(doc.data()))
              .toList();
          docs.sort(
            (a, b) => (a.nextBillingDate ?? DateTime.now()).compareTo(
              b.nextBillingDate ?? DateTime.now(),
            ),
          );
          return docs;
        });
  }

  /// Get overdue billings
  Future<List<BillingModel>> getOverdueBillings() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .get();

      final docs = snapshot.docs
          .map((doc) => BillingModel.fromJson(doc.data()))
          .toList();

      final overdue = docs
          .where(
            (b) =>
                b.nextBillingDate != null &&
                b.nextBillingDate!.isBefore(now.toDate()),
          )
          .toList();
      overdue.sort((a, b) => a.nextBillingDate!.compareTo(b.nextBillingDate!));
      return overdue;
    } catch (e) {
      print('Error getting overdue billings: $e');
      return [];
    }
  }

  /// Update next billing date
  Future<void> updateNextBillingDate(String billingId) async {
    try {
      final billing = await getBillingById(billingId);
      if (billing == null) throw Exception('Billing not found');

      final nextDate = _calculateNextBillingDate(billing.billingFrequency);

      await updateBilling(billingId, {
        'nextBillingDate': Timestamp.fromDate(nextDate),
        'lastBilledAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating next billing date: $e');
      rethrow;
    }
  }

  /// Get billing summary
  Future<BillingSummary> getBillingSummary() async {
    try {
      final activeBillings = await getActiveBillings();
      final overdueBillings = await getOverdueBillings();

      double totalBilled = 0;
      double totalPaid = 0;
      double totalBalance = 0;

      for (final billing in activeBillings) {
        totalBilled += billing.totalBilled;
        totalPaid += billing.totalPaid;
        totalBalance += billing.balance;
      }

      return BillingSummary(
        totalBilled: totalBilled,
        totalPaid: totalPaid,
        totalBalance: totalBalance,
        activeBillingCount: activeBillings.length,
        overdueBillingCount: overdueBillings.length,
      );
    } catch (e) {
      print('Error getting billing summary: $e');
      return BillingSummary(
        totalBilled: 0,
        totalPaid: 0,
        totalBalance: 0,
        activeBillingCount: 0,
        overdueBillingCount: 0,
      );
    }
  }

  /// Send payment reminder (implement notification email sending)
  Future<void> sendPaymentReminder(String billingId, String clientEmail, {String? clientName}) async {
    try {
      final billing = await getBillingById(billingId);
      if (billing == null) throw Exception('Billing not found');

      // Send email notification for payment reminder
      await EmailService().sendBillingNotificationEmail(
        toEmail: clientEmail,
        clientName: clientName ?? 'Valued Client',
        notificationType: 'payment_reminder',
        billingDetails: {
          'amount': billing.balance.toStringAsFixed(2),
          'dueDate': billing.nextBillingDate?.toString() ?? 'Soon',
          'billingId': billingId,
        },
      );

      print('✅ Payment reminder sent to $clientEmail for billing: $billingId');
    } catch (e) {
      print('❌ Error sending payment reminder: $e');
      rethrow;
    }
  }

  /// Send payment confirmation email
  Future<void> sendPaymentConfirmation(
    String billingId,
    String clientEmail,
    double amountPaid, {
    String? clientName,
  }) async {
    try {
      final billing = await getBillingById(billingId);
      if (billing == null) throw Exception('Billing not found');

      // Send email notification for successful payment
      await EmailService().sendBillingNotificationEmail(
        toEmail: clientEmail,
        clientName: clientName ?? 'Valued Client',
        notificationType: 'payment_received',
        billingDetails: {
          'amount': amountPaid.toStringAsFixed(2),
          'billingId': billingId,
          'date': DateTime.now().toString(),
          'remainingBalance': billing.balance.toStringAsFixed(2),
        },
      );

      print('✅ Payment confirmation sent to $clientEmail');
    } catch (e) {
      print('❌ Error sending payment confirmation: $e');
      rethrow;
    }
  }

  /// Send billing ready notification
  Future<void> sendBillingReadyNotification(
    String billingId,
    String clientEmail,
    double totalAmount, {
    String? clientName,
  }) async {
    try {
      // Send email notification when billing is ready
      await EmailService().sendBillingNotificationEmail(
        toEmail: clientEmail,
        clientName: clientName ?? 'Valued Client',
        notificationType: 'billing_ready',
        billingDetails: {
          'amount': totalAmount.toStringAsFixed(2),
          'billingId': billingId,
          'date': DateTime.now().toString(),
        },
      );

      print('✅ Billing ready notification sent to $clientEmail');
    } catch (e) {
      print('❌ Error sending billing ready notification: $e');
      rethrow;
    }
  }

  /// Send subscription update notification
  Future<void> sendSubscriptionUpdateNotification(
    String billingId,
    String clientEmail,
    String action, {
    String? clientName,
    String? newFrequency,
    double? newAmount,
  }) async {
    try {
      // Send email notification for subscription changes
      await EmailService().sendBillingNotificationEmail(
        toEmail: clientEmail,
        clientName: clientName ?? 'Valued Client',
        notificationType: 'subscription_update',
        billingDetails: {
          'action': action,
          'billingId': billingId,
          'newFrequency': newFrequency ?? 'unchanged',
          'newAmount': newAmount?.toStringAsFixed(2) ?? 'unchanged',
          'date': DateTime.now().toString(),
        },
      );

      print('✅ Subscription update notification sent to $clientEmail');
    } catch (e) {
      print('❌ Error sending subscription update notification: $e');
      rethrow;
    }
  }

  /// Send payment failure notification
  Future<void> sendPaymentFailureNotification(
    String billingId,
    String clientEmail,
    String failureReason, {
    String? clientName,
  }) async {
    try {
      // Send email notification for payment failures
      await EmailService().sendBillingNotificationEmail(
        toEmail: clientEmail,
        clientName: clientName ?? 'Valued Client',
        notificationType: 'payment_failed',
        billingDetails: {
          'billingId': billingId,
          'reason': failureReason,
          'date': DateTime.now().toString(),
        },
      );

      print('✅ Payment failure notification sent to $clientEmail');
    } catch (e) {
      print('❌ Error sending payment failure notification: $e');
      rethrow;
    }
  }

  /// Calculate next billing date based on frequency
  DateTime _calculateNextBillingDate(String frequency) {
    final now = DateTime.now();
    return switch (frequency) {
      'monthly' => DateTime(now.year, now.month + 1, now.day),
      'quarterly' => DateTime(now.year, now.month + 3, now.day),
      'yearly' => DateTime(now.year + 1, now.month, now.day),
      _ => DateTime(now.year, now.month + 1, now.day),
    };
  }

  /// Delete billing record
  Future<void> deleteBilling(String billingId) async {
    try {
      await _firestore.collection(_collection).doc(billingId).delete();
    } catch (e) {
      print('Error deleting billing: $e');
      rethrow;
    }
  }

  // ==================== PAYMENT TRANSACTION METHODS ====================

  /// Create payment transaction
  Future<PaymentTransactionModel> createPaymentTransaction({
    required String clientId,
    required String lawyerId,
    required String caseId,
    required double amount,
    required String paymentMethod,
    String? description,
  }) async {
    try {
      final transactionId = _firestore.collection('transactions').doc().id;
      final transaction = PaymentTransactionModel(
        transactionId: transactionId,
        clientId: clientId,
        lawyerId: lawyerId,
        caseId: caseId,
        amount: amount,
        paymentMethod: paymentMethod,
        status: 'pending',
        transactionType: 'payment',
        transactionDate: DateTime.now(),
        description: description ?? 'Payment to lawyer for case',
      );

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .set(transaction.toJson());

      return transaction;
    } catch (e) {
      print('Error creating payment transaction: $e');
      rethrow;
    }
  }

  /// Complete payment transaction
  Future<void> completePaymentTransaction(
    String transactionId,
    String? transactionRef,
  ) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'completed',
        'completedDate': Timestamp.now(),
        'transactionRef': transactionRef,
      });
    } catch (e) {
      print('Error completing payment transaction: $e');
      rethrow;
    }
  }

  /// Fail payment transaction
  Future<void> failPaymentTransaction(
    String transactionId,
    String failureReason,
  ) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'failed',
        'failureReason': failureReason,
      });
    } catch (e) {
      print('Error failing payment transaction: $e');
      rethrow;
    }
  }

  /// Get transaction by ID
  Future<PaymentTransactionModel?> getTransactionById(
    String transactionId,
  ) async {
    try {
      final doc =
          await _firestore.collection('transactions').doc(transactionId).get();
      if (doc.exists) {
        return PaymentTransactionModel.fromJson(doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  /// Get transactions by client
  Stream<List<PaymentTransactionModel>> getTransactionsByClient(
    String clientId,
  ) {
    return _firestore
        .collection('transactions')
        .where('clientId', isEqualTo: clientId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) =>
                  PaymentTransactionModel.fromJson(doc.data()))
              .toList();
        });
  }

  /// Get transactions by lawyer
  Stream<List<PaymentTransactionModel>> getTransactionsByLawyer(
    String lawyerId,
  ) {
    return _firestore
        .collection('transactions')
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) =>
                  PaymentTransactionModel.fromJson(doc.data()))
              .toList();
        });
  }

  /// Get transactions by case
  Stream<List<PaymentTransactionModel>> getTransactionsByCase(
    String caseId,
  ) {
    return _firestore
        .collection('transactions')
        .where('caseId', isEqualTo: caseId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) =>
                  PaymentTransactionModel.fromJson(doc.data()))
              .toList();
        });
  }

  /// Send payment confirmation to client
  Future<void> sendPaymentConfirmationToClient(
    PaymentTransactionModel transaction,
    String clientEmail,
    String lawyerName, {
    String? clientName,
  }) async {
    try {
      await EmailService().sendBillingNotificationEmail(
        toEmail: clientEmail,
        clientName: clientName ?? 'Valued Client',
        notificationType: 'payment_received',
        billingDetails: {
          'amount': transaction.amount.toStringAsFixed(2),
          'lawyerName': lawyerName,
          'transactionId': transaction.transactionId,
          'date': transaction.transactionDate.toString(),
          'status': transaction.status,
        },
      );

      print('✅ Payment confirmation sent to $clientEmail');
    } catch (e) {
      print('❌ Error sending payment confirmation: $e');
    }
  }
}

/// Helper class for billing summary
class BillingSummary {
  final double totalBilled;
  final double totalPaid;
  final double totalBalance;
  final int activeBillingCount;
  final int overdueBillingCount;

  BillingSummary({
    required this.totalBilled,
    required this.totalPaid,
    required this.totalBalance,
    required this.activeBillingCount,
    required this.overdueBillingCount,
  });
}
