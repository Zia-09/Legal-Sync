import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/hearing_Model.dart';
import '../services/hearing_service.dart';

// Service provider
final hearingServiceProvider = Provider((ref) {
  return HearingService();
});

// Stream providers for hearing data

/// Stream all hearings for a specific case
final streamHearingsByCaseProvider =
    StreamProvider.family<List<HearingModel>, String>((ref, caseId) {
      final service = ref.watch(hearingServiceProvider);
      return service.streamHearings(caseId);
    });

/// Stream upcoming hearings for a lawyer
final streamUpcomingHearingsProvider =
    StreamProvider.family<List<HearingModel>, String>((ref, lawyerId) {
      final service = ref.watch(hearingServiceProvider);
      return service.getUpcomingHearings(lawyerId);
    });

/// Stream upcoming hearings for a client (legacy mapping - may miss docs w/o clientId)
final streamUpcomingHearingsForClientProvider =
    StreamProvider.family<List<HearingModel>, String>((ref, clientId) {
      final service = ref.watch(hearingServiceProvider);
      return service.getUpcomingHearingsForClient(clientId);
    });

/// Robust: Stream all hearings for a given list of case IDs
final streamHearingsByCaseIdsProvider =
    StreamProvider.family<List<HearingModel>, List<String>>((ref, caseIds) {
      final service = ref.watch(hearingServiceProvider);
      return service.streamHearingsByCaseIds(caseIds);
    });

/// Get single hearing by ID (Future provider)
final getHearingByIdProvider = FutureProvider.family<HearingModel?, String>((
  ref,
  hearingId,
) async {
  final service = ref.watch(hearingServiceProvider);
  return service.getHearingById(hearingId);
});

/// State notifier for managing hearing state
class HearingStateNotifier
    extends StateNotifier<AsyncValue<List<HearingModel>>> {
  final HearingService _service;

  HearingStateNotifier(this._service) : super(const AsyncValue.loading());

  /// Add new hearing
  Future<void> addHearing(HearingModel hearing) async {
    try {
      state = const AsyncValue.loading();
      await _service.addHearing(hearing);
      state = const AsyncValue.data(<HearingModel>[]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update existing hearing
  Future<void> updateHearing(
    String hearingId,
    Map<String, dynamic> data,
  ) async {
    try {
      state = const AsyncValue.loading();
      await _service.updateHearing(hearingId, data);
      state = const AsyncValue.data(<HearingModel>[]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Delete hearing
  Future<void> deleteHearing(String hearingId) async {
    try {
      state = const AsyncValue.loading();
      await _service.deleteHearing(hearingId);
      state = const AsyncValue.data(<HearingModel>[]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Trigger reminders
  Future<void> triggerReminders() async {
    try {
      await _service.triggerReminders();
    } catch (e) {
      print('Error triggering reminders: $e');
    }
  }

  /// Load hearings for case
  Future<void> loadHearingsByCase(String caseId) async {
    try {
      state = const AsyncValue.loading();
      final hearings = await _service.streamHearings(caseId).first;
      state = AsyncValue.data(hearings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Send manual reminder to client
  Future<void> sendManualReminder({
    required HearingModel hearing,
    required String clientId,
  }) async {
    try {
      await _service.sendManualReminder(hearing: hearing, clientId: clientId);
    } catch (e) {
      print('Error sending manual reminder: $e');
    }
  }
}

/// State notifier provider for hearing management
final hearingStateNotifierProvider =
    StateNotifierProvider<HearingStateNotifier, AsyncValue<List<HearingModel>>>(
      (ref) {
        final service = ref.watch(hearingServiceProvider);
        return HearingStateNotifier(service);
      },
    );
