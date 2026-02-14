import 'package:cloud_firestore/cloud_firestore.dart';

class FirmAnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Proposal-aligned admin dashboard metrics:
  // active cases, upcoming deadlines, time billed, invoices issued.
  Future<Map<String, dynamic>> getMvpDashboardMetrics({
    required String firmId,
    Duration upcomingWindow = const Duration(days: 7),
  }) async {
    final now = DateTime.now();
    final until = now.add(upcomingWindow);

    final results = await Future.wait([
      _db
          .collection('cases')
          .where('firmId', isEqualTo: firmId)
          .where('status', whereIn: const ['pending', 'in_progress'])
          .get(),
      _db
          .collection('deadlines')
          .where('firmId', isEqualTo: firmId)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(until))
          .where('status', isNotEqualTo: 'completed')
          .get(),
      _db.collection('time_entries').where('firmId', isEqualTo: firmId).get(),
      _db.collection('invoices').where('firmId', isEqualTo: firmId).get(),
    ]);

    final activeCases = results[0].docs.length;
    final upcomingDeadlines = results[1].docs.length;
    final timeEntries = results[2].docs;
    final invoices = results[3].docs;

    double totalMinutes = 0;
    for (final doc in timeEntries) {
      totalMinutes += ((doc.data()['duration'] ?? 0) as num).toDouble();
    }

    return {
      'activeCases': activeCases,
      'upcomingDeadlines': upcomingDeadlines,
      'timeBilledHours': totalMinutes / 60.0,
      'invoicesIssued': invoices.length,
      'windowDays': upcomingWindow.inDays,
    };
  }

  // ===============================
  // GET FIRM DASHBOARD STATS
  // ===============================
  Future<Map<String, dynamic>> getFirmDashboardStats(String firmId) async {
    try {
      final firmLawyers = await _db
          .collection('lawyers')
          .where('firmId', isEqualTo: firmId)
          .get();

      final cases = await _db
          .collection('cases')
          .where('firmId', isEqualTo: firmId)
          .get();

      final invoices = await _db
          .collection('invoices')
          .where('firmId', isEqualTo: firmId)
          .get();

      final appointments = await _db.collection('appointments').get();

      // Calculate metrics
      int activeCases = 0;
      int completedCases = 0;
      double totalRevenue = 0.0;

      for (final caseDoc in cases.docs) {
        final caseData = caseDoc.data();
        if (caseData['status'] == 'closed') {
          completedCases++;
        } else {
          activeCases++;
        }
      }

      for (final invoiceDoc in invoices.docs) {
        final invoiceData = invoiceDoc.data();
        if (invoiceData['status'] == 'paid') {
          totalRevenue +=
              (invoiceData['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return {
        'totalLawyers': firmLawyers.size,
        'activeCases': activeCases,
        'completedCases': completedCases,
        'totalCases': cases.size,
        'totalRevenue': totalRevenue,
        'totalAppointments': appointments.size,
        'upcomingDeadlines': await _getUpcomingDeadlinesCount(firmId),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ===============================
  // GET UPCOMING DEADLINES COUNT
  // ===============================
  Future<int> _getUpcomingDeadlinesCount(String firmId) async {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    final snapshot = await _db
        .collection('deadlines')
        .where('firmId', isEqualTo: firmId)
        .where('dueDate', isGreaterThan: Timestamp.fromDate(now))
        .where('dueDate', isLessThan: Timestamp.fromDate(nextWeek))
        .get();

    return snapshot.size;
  }

  // ===============================
  // GET LAWYER PERFORMANCE STATS
  // ===============================
  Future<Map<String, dynamic>> getLawyerStats(
    String lawyerId,
    String firmId,
  ) async {
    try {
      final cases = await _db
          .collection('cases')
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      final timeEntries = await _db
          .collection('time_entries')
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      final invoices = await _db
          .collection('invoices')
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      double totalHours = 0.0;
      double totalEarnings = 0.0;

      for (final entry in timeEntries.docs) {
        final data = entry.data();
        totalHours += (data['durationHours'] as num?)?.toDouble() ?? 0.0;
      }

      for (final invoice in invoices.docs) {
        final data = invoice.data();
        if (data['status'] == 'paid') {
          totalEarnings += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return {
        'lawyerId': lawyerId,
        'totalCases': cases.size,
        'totalHoursBilled': totalHours,
        'totalEarnings': totalEarnings,
        'averageHourlyRate': totalHours > 0 ? totalEarnings / totalHours : 0.0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ===============================
  // GET CASE ANALYTICS
  // ===============================
  Future<Map<String, dynamic>> getCaseAnalytics(
    String caseId,
    String lawyerId,
  ) async {
    try {
      final caseDoc = await _db.collection('cases').doc(caseId).get();
      if (!caseDoc.exists) return {'error': 'Case not found'};

      final timeEntries = await _db
          .collection('time_entries')
          .where('caseId', isEqualTo: caseId)
          .get();

      final invoices = await _db
          .collection('invoices')
          .where('caseId', isEqualTo: caseId)
          .get();

      final documents = await _db
          .collection('documents')
          .where('caseId', isEqualTo: caseId)
          .get();

      double totalHours = 0.0;
      double estimatedValue = 0.0;

      for (final entry in timeEntries.docs) {
        final data = entry.data();
        totalHours += (data['durationHours'] as num?)?.toDouble() ?? 0.0;
      }

      for (final invoice in invoices.docs) {
        final data = invoice.data();
        estimatedValue += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }

      return {
        'caseId': caseId,
        'status': caseDoc.data()?['status'] ?? 'pending',
        'totalTimeLogged': totalHours,
        'totalDocuments': documents.size,
        'estimatedValue': estimatedValue,
        'invoiceCount': invoices.size,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ===============================
  // GET REVENUE SUMMARY
  // ===============================
  Future<Map<String, dynamic>> getRevenueSummary(
    String firmId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final invoices = await _db
          .collection('invoices')
          .where('firmId', isEqualTo: firmId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalInvoiced = 0.0;
      double totalPaid = 0.0;
      double totalPending = 0.0;

      for (final invoice in invoices.docs) {
        final data = invoice.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

        totalInvoiced += amount;
        if (data['status'] == 'paid') {
          totalPaid += amount;
        } else if (data['status'] == 'pending') {
          totalPending += amount;
        }
      }

      return {
        'periodStart': startDate.toIso8601String(),
        'periodEnd': endDate.toIso8601String(),
        'totalInvoiced': totalInvoiced,
        'totalPaid': totalPaid,
        'totalPending': totalPending,
        'invoiceCount': invoices.size,
        'collectionRate': totalInvoiced > 0
            ? (totalPaid / totalInvoiced) * 100
            : 0.0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
