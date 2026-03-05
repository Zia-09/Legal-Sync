import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/payment_method_model.dart';

class TransactionService {
  final CollectionReference _transactions = FirebaseFirestore.instance
      .collection('transactions');

  /// 🔹 Add a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactions
        .doc(transaction.transactionId)
        .set(transaction.toJson());
  }

  /// 🔹 Update existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactions
        .doc(transaction.transactionId)
        .update(transaction.toJson());
  }

  /// 🔹 Delete a transaction (optional, usually keep for record)
  Future<void> deleteTransaction(String transactionId) async {
    await _transactions.doc(transactionId).delete();
  }

  /// 🔹 Get single transaction by ID
  Future<TransactionModel?> getTransaction(String transactionId) async {
    final doc = await _transactions.doc(transactionId).get();
    if (doc.exists) {
      return TransactionModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// 🔹 Stream transactions for a user (client)
  Stream<List<TransactionModel>> streamUserTransactions(String userId) {
    return _transactions.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final docs = snapshot.docs
          .map(
            (doc) =>
                TransactionModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  /// 🔹 Stream transactions for a lawyer (optional)
  Stream<List<TransactionModel>> streamLawyerTransactions(String lawyerId) {
    return _transactions.where('lawyerId', isEqualTo: lawyerId).snapshots().map(
      (snapshot) {
        final docs = snapshot.docs
            .map(
              (doc) =>
                  TransactionModel.fromJson(doc.data() as Map<String, dynamic>),
            )
            .toList();
        docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return docs;
      },
    );
  }
}
