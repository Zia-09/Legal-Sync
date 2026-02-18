import 'dart:io';

import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/model/hearing_Model.dart';
import 'package:legal_sync/model/invoice_Model.dart';
import 'package:legal_sync/model/time_entry_Model.dart';
import 'package:legal_sync/services/case_service.dart';
import 'package:legal_sync/services/document_service.dart';
import 'package:legal_sync/services/hearing_service.dart';
import 'package:legal_sync/services/invoice_service.dart';
import 'package:legal_sync/services/notification_services.dart';
import 'package:legal_sync/services/time_tracking_service.dart';

/// Proposal-aligned orchestration service for end-to-end legal workflows.
class LegalWorkflowService {
  LegalWorkflowService({
    CaseService? caseService,
    DocumentService? documentService,
    HearingService? hearingService,
    TimeTrackingService? timeTrackingService,
    InvoiceService? invoiceService,
    NotificationService? notificationService,
  }) : _caseService = caseService ?? CaseService(),
       _documentService = documentService ?? DocumentService(),
       _hearingService = hearingService ?? HearingService(),
       _timeTrackingService = timeTrackingService ?? TimeTrackingService(),
       _invoiceService = invoiceService ?? InvoiceService(),
       _notificationService = notificationService ?? NotificationService();

  final CaseService _caseService;
  final DocumentService _documentService;
  final HearingService _hearingService;
  final TimeTrackingService _timeTrackingService;
  final InvoiceService _invoiceService;
  final NotificationService _notificationService;

  /// Step 1 from proposal: create case + optionally upload first document.
  Future<String> createCaseWithInitialDocument({
    required CaseModel caseModel,
    File? initialDocument,
    String? uploadedBy,
    String initialDocumentType = 'pdf',
  }) async {
    final caseId = caseModel.caseId.isNotEmpty
        ? caseModel.caseId
        : await _caseService.createCaseWithGeneratedId(caseModel);

    if (caseModel.caseId.isNotEmpty) {
      await _caseService.createCase(caseModel);
    }

    if (initialDocument != null) {
      await _documentService.uploadAndSaveDocument(
        file: initialDocument,
        caseId: caseId,
        uploadedBy: uploadedBy ?? caseModel.lawyerId,
        fileType: initialDocumentType,
      );
    }

    await _notificationService.createNotification(
      userId: caseModel.clientId,
      title: 'Case Created',
      message: 'Your case "${caseModel.title}" was created successfully.',
      type: 'case',
      metadata: {'caseId': caseId},
    );

    return caseId;
  }

  /// Step 2 from proposal: hearing + reminder queue.
  Future<void> addHearingAndQueueReminder({
    required HearingModel hearing,
    required List<String> recipientUserIds,
    int reminderHoursBefore = 24,
  }) async {
    await _hearingService.createHearingWithReminder(
      hearing: hearing,
      recipientUserIds: recipientUserIds,
      hoursBefore: reminderHoursBefore,
    );
  }

  /// Step 3 from proposal: start/stop timer wrappers.
  Future<TimeEntryModel> startWorkTimer({
    required String caseId,
    required String lawyerId,
    String? description,
    String? taskType,
  }) {
    return _timeTrackingService.startTimer(
      caseId: caseId,
      lawyerId: lawyerId,
      description: description,
      taskType: taskType,
    );
  }

  Future<TimeEntryModel> stopWorkTimer(String timeEntryId) {
    return _timeTrackingService.stopTimer(timeEntryId);
  }

  /// Step 4 from proposal: invoice generation from logged hours.
  Future<InvoiceModel> generateAndSaveInvoice({
    required String caseId,
    required String lawyerId,
    required String clientId,
    required double ratePerHour,
    String? notes,
    bool notifyClient = true,
  }) async {
    final invoice = await _invoiceService.generateInvoice(
      caseId: caseId,
      lawyerId: lawyerId,
      clientId: clientId,
      ratePerHour: ratePerHour,
      notes: notes,
    );
    await _invoiceService.saveInvoice(invoice);

    if (notifyClient) {
      await _notificationService.createNotification(
        userId: clientId,
        title: 'New Invoice Generated',
        message: 'A new invoice is ready for your case.',
        type: 'invoice',
        metadata: {'invoiceId': invoice.invoiceId, 'caseId': caseId},
      );
    }

    return invoice;
  }
}
