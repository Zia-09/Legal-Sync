import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/payment_method_model.dart';

/// 🔹 Professional Payment Service - Complete real-time payment handling
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _transactionsCollection = 'transactions';
  static const String _paymentMethodsCollection = 'payment_methods';
  static const String _walletCollection = 'wallets';

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSACTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Process a new payment transaction
  Future<String> createTransaction({
    required String userId,
    required String lawyerId,
    required String caseId,
    required double amount,
    required String paymentMethod,
    String currency = 'PKR',
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final transactionId = _firestore
          .collection(_transactionsCollection)
          .doc()
          .id;

      final transaction = TransactionModel(
        transactionId: transactionId,
        userId: userId,
        lawyerId: lawyerId,
        appointmentId: caseId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        status: 'pending',
        createdAt: DateTime.now(),
        metadata: {
          ...(metadata ?? {}),
          'description': description,
          'createdAt': Timestamp.now(),
        },
      );

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .set(transaction.toJson());

      return transactionId;
    } catch (e) {
      print('❌ Error creating transaction: $e');
      rethrow;
    }
  }

  /// Update transaction status (for real-time updates)
  Future<void> updateTransactionStatus({
    required String transactionId,
    required String status,
    String? paymentReference,
  }) async {
    try {
      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .update({
            'status': status,
            'paymentReference': paymentReference,
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      print('❌ Error updating transaction: $e');
      rethrow;
    }
  }

  /// Get transaction by ID
  Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      final doc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();

      if (doc.exists) {
        return TransactionModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching transaction: $e');
      return null;
    }
  }

  /// Stream transactions for a user (real-time)
  Stream<List<TransactionModel>> streamUserTransactions(String userId) {
    return _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => TransactionModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        })
        .handleError((e) {
          print('❌ Error streaming transactions: $e');
          return <TransactionModel>[];
        });
  }

  /// Stream transactions for a lawyer
  Stream<List<TransactionModel>> streamLawyerTransactions(String lawyerId) {
    return _firestore
        .collection(_transactionsCollection)
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => TransactionModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        })
        .handleError((e) {
          print('❌ Error streaming lawyer transactions: $e');
          return <TransactionModel>[];
        });
  }

  /// Stream transactions for a case
  Stream<List<TransactionModel>> streamCaseTransactions(String caseId) {
    return _firestore
        .collection(_transactionsCollection)
        .where('appointmentId', isEqualTo: caseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => TransactionModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        })
        .handleError((e) {
          print('❌ Error streaming case transactions: $e');
          return <TransactionModel>[];
        });
  }

  /// Get transaction statistics for a user
  Future<Map<String, dynamic>> getUserTransactionStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      double totalAmount = 0;
      double completedAmount = 0;
      int totalCount = 0;
      int completedCount = 0;

      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromJson(
          doc.data() as Map<String, dynamic>,
        );
        totalAmount += transaction.amount;
        totalCount += 1;

        if (transaction.isCompleted) {
          completedAmount += transaction.amount;
          completedCount += 1;
        }
      }

      return {
        'totalAmount': totalAmount,
        'completedAmount': completedAmount,
        'totalCount': totalCount,
        'completedCount': completedCount,
        'pendingCount': totalCount - completedCount,
        'averageAmount': totalCount > 0 ? totalAmount / totalCount : 0,
      };
    } catch (e) {
      print('❌ Error calculating stats: $e');
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WALLET MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize wallet for a user
  Future<void> initializeWallet({
    required String userId,
    double initialBalance = 0.0,
  }) async {
    try {
      await _firestore.collection(_walletCollection).doc(userId).set({
        'balance': initialBalance,
        'currency': 'PKR',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'transactions': [],
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error initializing wallet: $e');
      rethrow;
    }
  }

  /// Get user wallet balance
  Future<double> getWalletBalance(String userId) async {
    try {
      final doc = await _firestore
          .collection(_walletCollection)
          .doc(userId)
          .get();
      if (doc.exists) {
        return (doc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print('❌ Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  /// Stream wallet balance (real-time)
  Stream<double> streamWalletBalance(String userId) {
    return _firestore
        .collection(_walletCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          return (doc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        })
        .handleError((e) {
          print('❌ Error streaming wallet: $e');
          return 0.0;
        });
  }

  /// Update wallet balance
  Future<void> updateWalletBalance({
    required String userId,
    required double amount,
    required bool isCredit, // true for credit, false for debit
  }) async {
    try {
      final currentBalance = await getWalletBalance(userId);
      final newBalance = isCredit
          ? currentBalance + amount
          : currentBalance - amount;

      if (newBalance < 0) {
        throw Exception('Insufficient balance');
      }

      await _firestore.collection(_walletCollection).doc(userId).update({
        'balance': newBalance,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Error updating wallet: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT METHOD MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save payment method
  Future<String> savePaymentMethod({
    required String userId,
    required String methodName,
    required String methodType, // 'card', 'wallet', 'transfer'
    required Map<String, dynamic> methodDetails,
    bool isDefault = false,
  }) async {
    try {
      final methodId = _firestore
          .collection(_paymentMethodsCollection)
          .doc()
          .id;

      await _firestore.collection(_paymentMethodsCollection).doc(methodId).set({
        'methodId': methodId,
        'userId': userId,
        'methodName': methodName,
        'methodType': methodType,
        'methodDetails': methodDetails,
        'isDefault': isDefault,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });

      return methodId;
    } catch (e) {
      print('❌ Error saving payment method: $e');
      rethrow;
    }
  }

  /// Get user payment methods
  Future<List<Map<String, dynamic>>> getUserPaymentMethods(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentMethodsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error fetching payment methods: $e');
      return [];
    }
  }

  /// Delete payment method (soft delete)
  Future<void> deletePaymentMethod(String methodId) async {
    try {
      await _firestore
          .collection(_paymentMethodsCollection)
          .doc(methodId)
          .update({'isActive': false});
    } catch (e) {
      print('❌ Error deleting payment method: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPORTING & ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get monthly transaction summary
  Future<Map<String, dynamic>> getMonthlyTransactionSummary(
    String userId, {
    required int month,
    required int year,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = month == 12
          ? DateTime(year + 1, 1, 1)
          : DateTime(year, month + 1, 1);

      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
          .get();

      double totalAmount = 0;
      double completedAmount = 0;
      Map<String, int> methodCount = {};

      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromJson(
          doc.data() as Map<String, dynamic>,
        );
        totalAmount += transaction.amount;

        if (transaction.isCompleted) {
          completedAmount += transaction.amount;
        }

        methodCount[transaction.paymentMethod] =
            (methodCount[transaction.paymentMethod] ?? 0) + 1;
      }

      return {
        'month': month,
        'year': year,
        'totalAmount': totalAmount,
        'completedAmount': completedAmount,
        'transactionCount': snapshot.docs.length,
        'paymentMethods': methodCount,
      };
    } catch (e) {
      print('❌ Error generating summary: $e');
      return {};
    }
  }
}
