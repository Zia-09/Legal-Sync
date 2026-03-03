import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/time_entry_Model.dart';
import '../services/time_tracking_service.dart';

final timeTrackingServiceProvider = Provider((ref) => TimeTrackingService());

final timerStateProvider = StateProvider<bool>((ref) => false);
final currentCaseIdProvider = StateProvider<String?>((ref) => null);
final currentLawyerIdProvider = StateProvider<String?>((ref) => null);

final streamTimeEntriesByCaseProvider =
    StreamProvider.family<List<TimeEntryModel>, String>((ref, caseId) {
      final service = ref.watch(timeTrackingServiceProvider);
      return service.getTimeEntriesByCase(caseId);
    });

final streamTimeEntriesByLawyerProvider =
    StreamProvider.family<List<TimeEntryModel>, String>((ref, lawyerId) {
      final service = ref.watch(timeTrackingServiceProvider);
      return service.getTimeEntriesByLawyer(lawyerId);
    });

final getTotalHoursByCaseProvider = FutureProvider.family<double, String>((
  ref,
  caseId,
) async {
  final service = ref.watch(timeTrackingServiceProvider);
  return service.getTotalHoursForCase(caseId);
});

class TimeTrackingStateNotifier
    extends StateNotifier<AsyncValue<List<TimeEntryModel>>> {
  TimeTrackingStateNotifier(this._service) : super(const AsyncValue.loading());

  final TimeTrackingService _service;

  Future<void> startTimer(String caseId, String lawyerId) async {
    try {
      state = const AsyncValue.loading();
      await _service.startTimer(caseId: caseId, lawyerId: lawyerId);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> stopTimer(String timeEntryId) async {
    try {
      state = const AsyncValue.loading();
      await _service.stopTimer(timeEntryId);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createTimeEntry(TimeEntryModel entry) async {
    try {
      state = const AsyncValue.loading();
      await _service.createTimeEntry(entry);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTimeEntry(
    String timeEntryId,
    Map<String, dynamic> data,
  ) async {
    try {
      state = const AsyncValue.loading();
      await _service.updateTimeEntry(timeEntryId, data);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTimeEntry(String timeEntryId) async {
    try {
      state = const AsyncValue.loading();
      await _service.deleteTimeEntry(timeEntryId);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<double> getTotalHours(String caseId) async {
    try {
      return await _service.getTotalHoursForCase(caseId);
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> loadTimeEntriesByCase(String caseId) async {
    try {
      state = const AsyncValue.loading();
      final entries = await _service.getTimeEntriesByCase(caseId).first;
      state = AsyncValue.data(entries);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadTimeEntriesByLawyer(String lawyerId) async {
    try {
      state = const AsyncValue.loading();
      final entries = await _service.getTimeEntriesByLawyer(lawyerId).first;
      state = AsyncValue.data(entries);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final timeTrackingStateNotifierProvider =
    StateNotifierProvider<
      TimeTrackingStateNotifier,
      AsyncValue<List<TimeEntryModel>>
    >((ref) {
      final service = ref.watch(timeTrackingServiceProvider);
      return TimeTrackingStateNotifier(service);
    });

final timerElapsedProvider = StateProvider<int>((ref) => 0);
