import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 🔹 PDF Helper - Generate PDF documents (invoices, case summaries, hearing notices)
class PDFHelper {
  /// Generate invoice PDF
  static Future<Uint8List> generateInvoicePDF({
    required String invoiceId,
    required String lawyerName,
    required String clientName,
    required String clientEmail,
    required double totalHours,
    required double ratePerHour,
    required double totalAmount,
    required String caseTitle,
    required DateTime createdDate,
    required DateTime dueDate,
    String? notes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Invoice #: $invoiceId'),
                      pw.Text('Date: ${_formatDate(createdDate)}'),
                      pw.Text('Due Date: ${_formatDate(dueDate)}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Legal Sync Services'),
                      pw.Text('Professional Legal Services'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Billing Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FROM:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(lawyerName),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'BILL TO:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(clientName),
                      pw.Text(clientEmail),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Case Info
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Case: $caseTitle',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Invoice Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Hours',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Rate',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data Row
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Legal Services'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          totalHours.toStringAsFixed(2),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '\$${ratePerHour.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:'),
                            pw.Text('\$${totalAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '\$${totalAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Notes
              if (notes != null && notes.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Notes:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(notes),
                  ],
                ),

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Text(
                'Thank you for your business!',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate case summary PDF
  static Future<Uint8List> generateCaseSummaryPDF({
    required String caseId,
    required String caseTitle,
    required String caseNumber,
    required String clientName,
    required String lawyerName,
    required String status,
    required String description,
    required DateTime createdDate,
    required DateTime? closedDate,
    List<String>? documents,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'CASE SUMMARY',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              // Case Details
              _buildDetailRow('Case Title:', caseTitle),
              _buildDetailRow('Case Number:', caseNumber),
              _buildDetailRow('Case ID:', caseId),
              _buildDetailRow('Status:', status),
              _buildDetailRow('Client:', clientName),
              _buildDetailRow('Assigned Lawyer:', lawyerName),
              _buildDetailRow('Created Date:', _formatDate(createdDate)),
              if (closedDate != null)
                _buildDetailRow('Closed Date:', _formatDate(closedDate)),

              pw.SizedBox(height: 20),

              // Description
              pw.Text(
                'Case Description:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text(description),

              pw.SizedBox(height: 20),

              // Documents
              if (documents != null && documents.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Associated Documents:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    ...documents.map(
                      (doc) => pw.Row(children: [pw.Text('• '), pw.Text(doc)]),
                    ),
                  ],
                ),

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Text(
                'Generated on ${_formatDate(DateTime.now())}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate hearing notice PDF
  static Future<Uint8List> generateHearingNoticePDF({
    required String caseTitle,
    required String caseNumber,
    required String courtName,
    required DateTime hearingDate,
    required String judgeInfo,
    required String courtAddress,
    String? specialInstructions,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'COURT HEARING NOTICE',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 30),

              // Court Info
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      courtName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(courtAddress),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Case and Hearing Details
              _buildDetailRow('Case Title:', caseTitle),
              _buildDetailRow('Case Number:', caseNumber),
              _buildDetailRow('Judge/Hearing Officer:', judgeInfo),

              pw.SizedBox(height: 20),

              // Prominent hearing date
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'HEARING DATE AND TIME:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      _formatDate(hearingDate),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${hearingDate.hour}:${hearingDate.minute.toString().padLeft(2, '0')}',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Special Instructions
              if (specialInstructions != null && specialInstructions.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Special Instructions:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(specialInstructions),
                  ],
                ),

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Text(
                'Please be punctual. Failure to appear may result in default judgment.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.red),
              ),
              pw.Text(
                'Generated on ${_formatDate(DateTime.now())}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Helper to build detail rows
  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(child: pw.Text(value)),
      ],
    );
  }

  /// Format date for PDF
  static String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  /// Get month name
  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
