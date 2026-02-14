import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/time_entry_Model.dart';
import '../services/time_tracking_service.dart';

// Service provider
final timeTrackingServiceProvider = Provider((ref) {
  return TimeTrackingService();
});

// Timer state
final timerStateProvider = StateProvider<bool>((ref) {
  return false; // false = stopped, true = running
});

final currentCaseIdProvider = StateProvider<String?>((ref) {
  return null;
});

final currentLawyerIdProvider = StateProvider<String?>((ref) {
  return null;
});

// Stream providers for time entry data

/// Stream all time entries for a specific case
final streamTimeEntriesByCaseProvider =
    StreamProvider.family<List<TimeEntryModel>, String>((ref, caseId) {
      final service = ref.watch(timeTrackingServiceProvider);
      return service.streamTimeEntriesByCase(caseId);
    });

/// Stream all time entries for a specific lawyer
final streamTimeEntriesByLawyerProvider =
    StreamProvider.family<List<TimeEntryModel>, String>((ref, lawyerId) {
      final service = ref.watch(timeTrackingServiceProvider);
      return service.getTimeEntriesByLawyer(lawyerId).asStream();
    });

/// Get total hours for a case (Future provider)
final getTotalHoursByCaseProvider = FutureProvider.family<double, String>((
  ref,
  caseId,
) async {
  final service = ref.watch(timeTrackingServiceProvider);
  return service.getTotalHoursByCase(caseId);
});

/// State notifier for managing time tracking state
class TimeTrackingStateNotifier
    extends StateNotifier<AsyncValue<List<TimeEntryModel>>> {
  final TimeTrackingService _service;

  TimeTrackingStateNotifier(this._service) : super(const AsyncValue.loading());

  /// Start timer
  Future<void> startTimer(String caseId, String lawyerId) async {
    try {
      state = const AsyncValue.loading();
      await _service.startTimer(caseId, lawyerId);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Stop timer and save time entry
  Future<void> stopTimer(String timeEntryId) async {
    try {
      state = const AsyncValue.loading();
      await _service.stopTimer(timeEntryId);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create manual time entry
  Future<void> createTimeEntry(TimeEntryModel entry) async {
    try {
      state = const AsyncValue.loading();
      await _service.createTimeEntry(entry);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update time entry
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

  /// Delete time entry
  Future<void> deleteTimeEntry(String timeEntryId) async {
    try {
      state = const AsyncValue.loading();
      await _service.deleteTimeEntry(timeEntryId);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Get total hours for case
  Future<double> getTotalHours(String caseId) async {
    try {
      return await _service.getTotalHoursByCase(caseId);
    } catch (e) {
      print('Error getting total hours: $e');
      return 0.0;
    }
  }

  /// Load time entries for case
  Future<void> loadTimeEntriesByCase(String caseId) async {
    try {
      state = const AsyncValue.loading();
      final entries = await _service.streamTimeEntriesByCase(caseId).first;
      state = AsyncValue.data(entries);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load time entries for lawyer
  Future<void> loadTimeEntriesByLawyer(String lawyerId) async {
    try {
      state = const AsyncValue.loading();
      final entries = _service.getTimeEntriesByLawyer(lawyerId);
      state = AsyncValue.data(entries);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// State notifier provider for time tracking management
final timeTrackingStateNotifierProvider =
    StateNotifierProvider<
      TimeTrackingStateNotifier,
      AsyncValue<List<TimeEntryModel>>
    >((ref) {
      final service = ref.watch(timeTrackingServiceProvider);
      return TimeTrackingStateNotifier(service);
    });

/// Timer elapsed time provider (in seconds)
final timerElapsedProvider = StateProvider<int>((ref) {
  return 0; // seconds
});
