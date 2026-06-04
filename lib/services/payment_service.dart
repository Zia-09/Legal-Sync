import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/payment_transaction_Model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> recordPayment(PaymentTransactionModel payment) async {
    try {
      // 1. Add payment transaction to 'payment_transactions' collection
      await _firestore
          .collection('payment_transactions')
          .doc(payment.transactionId)
          .set(payment.toJson());

      // 2. Update case totals
      if (payment.status == 'completed' && payment.transactionType != 'refund') {
        final caseRef = _firestore.collection('cases').doc(payment.caseId);
        
        await _firestore.runTransaction((transaction) async {
          final caseDoc = await transaction.get(caseRef);
          
          if (caseDoc.exists) {
            double currentPaid = 0.0;
            if (caseDoc.data()!.containsKey('totalPaid')) {
              var tp = caseDoc.data()!['totalPaid'];
              currentPaid = tp is num ? tp.toDouble() : 0.0;
            }
            
            double caseFee = 0.0;
            if (caseDoc.data()!.containsKey('caseFee')) {
              var cf = caseDoc.data()!['caseFee'];
              caseFee = cf is num ? cf.toDouble() : 0.0;
            }

            final newTotalPaid = currentPaid + payment.amount;
            final newStatus = newTotalPaid >= caseFee ? 'paid' : 'partial';

            transaction.update(caseRef, {
              'totalPaid': newTotalPaid,
              'paymentStatus': newStatus,
            });
          }
        });
      }
    } catch (e) {
      print('Error recording payment: $e');
      rethrow;
    }
  }

  Stream<List<PaymentTransactionModel>> streamPaymentsByCase(String caseId) {
    return _firestore
        .collection('payment_transactions')
        .where('caseId', isEqualTo: caseId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentTransactionModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<PaymentTransactionModel>> streamPaymentsByClient(String clientId) {
    return _firestore
        .collection('payment_transactions')
        .where('clientId', isEqualTo: clientId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentTransactionModel.fromJson(doc.data()))
            .toList());
  }

  Stream<double> streamWalletBalance(String userId) {
    return Stream.value(0.0); // Stub
  }

  Future<Map<String, dynamic>> getUserTransactionStats(String userId) async {
    return {}; // Stub
  }

  Future<Map<String, dynamic>> getMonthlyTransactionSummary(String userId, {required int month, required int year}) async {
    return {}; // Stub
  }

  Future<List<Map<String, dynamic>>> getUserPaymentMethods(String userId) async {
    return []; // Stub
  }
}
