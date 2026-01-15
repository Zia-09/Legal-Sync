import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/invoice_Model.dart';
import 'package:legal_sync/services/time_tracking_service.dart';

class InvoiceService {
  InvoiceService({
    FirebaseFirestore? firestore,
    TimeTrackingService? timeTrackingService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _timeTrackingService = timeTrackingService ?? TimeTrackingService();

  final FirebaseFirestore _firestore;
  final TimeTrackingService _timeTrackingService;
  static const String _collection = 'invoices';

  /// 🔹 Generate invoice from time entries
  Future<InvoiceModel> generateInvoice({
    required String caseId,
    required String lawyerId,
    required String clientId,
    required double ratePerHour,
    String? notes,
  }) async {
    try {
      // Calculate total hours from time entries
      final totalHours = await _timeTrackingService.getTotalHoursForCase(
        caseId,
      );
      final totalAmount = totalHours * ratePerHour;

      final invoiceId = _firestore.collection(_collection).doc().id;

      final invoice = InvoiceModel(
        invoiceId: invoiceId,
        caseId: caseId,
        lawyerId: lawyerId,
        clientId: clientId,
        totalHours: totalHours,
        ratePerHour: ratePerHour,
        totalAmount: totalAmount,
        createdAt: DateTime.now(),
        status: 'draft',
        invoiceNumber: _generateInvoiceNumber(),
        notes: notes,
      );

      return invoice;
    } catch (e) {
      throw Exception('Failed to generate invoice: $e');
    }
  }

  /// 🔹 Save invoice
  Future<void> saveInvoice(InvoiceModel invoice) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(invoice.invoiceId)
          .set(invoice.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  /// 🔹 Get invoice by ID
  Future<InvoiceModel?> getInvoiceById(String invoiceId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(invoiceId).get();
      if (!doc.exists || doc.data() == null) return null;
      return InvoiceModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'invoiceId': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to fetch invoice: $e');
    }
  }

  /// 🔹 Get invoices for case
  Stream<List<InvoiceModel>> getInvoicesByCase(String caseId) {
    return _firestore
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => InvoiceModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'invoiceId': doc.id,
                }),
              )
              .toList();
        });
  }

  /// 🔹 Get invoices for client
  Stream<List<InvoiceModel>> getInvoicesByClient(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => InvoiceModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'invoiceId': doc.id,
                }),
              )
              .toList();
        });
  }

  /// 🔹 Get invoices for lawyer
  Stream<List<InvoiceModel>> getInvoicesByLawyer(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => InvoiceModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'invoiceId': doc.id,
                }),
              )
              .toList();
        });
  }

  /// 🔹 Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (status == 'paid') {
        data['paidAt'] = Timestamp.now();
      }
      data['updatedAt'] = Timestamp.now();

      await _firestore.collection(_collection).doc(invoiceId).update(data);
    } catch (e) {
      throw Exception('Failed to update invoice status: $e');
    }
  }

  /// 🔹 Send invoice to client
  Future<void> sendInvoice(String invoiceId, String clientEmail) async {
    try {
      // Update status to "sent"
      await updateInvoiceStatus(invoiceId, 'sent');

      // TODO: Integrate email service to send invoice
      // For now, just mark as sent
    } catch (e) {
      throw Exception('Failed to send invoice: $e');
    }
  }

  /// 🔹 Save PDF URL
  Future<void> savePDFUrl(String invoiceId, String pdfUrl) async {
    try {
      await _firestore.collection(_collection).doc(invoiceId).update({
        'pdfUrl': pdfUrl,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to save PDF URL: $e');
    }
  }

  /// 🔹 Delete invoice
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _firestore.collection(_collection).doc(invoiceId).delete();
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  /// 🔹 Get payment summary
  Future<Map<String, dynamic>> getPaymentSummary(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      double totalInvoiced = 0;
      double totalPaid = 0;
      int paidCount = 0;
      int pendingCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        totalInvoiced += amount;

        final status = data['status']?.toString() ?? '';
        if (status == 'paid') {
          totalPaid += amount;
          paidCount++;
        } else if (status != 'cancelled') {
          pendingCount++;
        }
      }

      return {
        'totalInvoiced': totalInvoiced,
        'totalPaid': totalPaid,
        'totalPending': totalInvoiced - totalPaid,
        'paidCount': paidCount,
        'pendingCount': pendingCount,
      };
    } catch (e) {
      throw Exception('Failed to get payment summary: $e');
    }
  }

  /// Helper: Generate invoice number
  String _generateInvoiceNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'INV-${timestamp.toString().substring(0, 10)}';
  }
}
