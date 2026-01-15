import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/billing_Model.dart';

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
          .orderBy('nextBillingDate')
          .get();

      return snapshot.docs
          .map((doc) => BillingModel.fromJson(doc.data()))
          .toList();
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
        .orderBy('nextBillingDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BillingModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get overdue billings
  Future<List<BillingModel>> getOverdueBillings() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .where('nextBillingDate', isLessThan: now)
          .orderBy('nextBillingDate')
          .get();

      return snapshot.docs
          .map((doc) => BillingModel.fromJson(doc.data()))
          .toList();
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

  /// Send payment reminder
  Future<void> sendPaymentReminder(String billingId) async {
    try {
      final billing = await getBillingById(billingId);
      if (billing == null) throw Exception('Billing not found');

      // TODO: Implement notification/email sending
      print('Payment reminder sent for billing: $billingId');
    } catch (e) {
      print('Error sending payment reminder: $e');
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
