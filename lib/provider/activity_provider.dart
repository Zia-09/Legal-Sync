import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/activity_model.dart';
import 'package:legal_sync/services/activity_service.dart';

final activityServiceProvider = Provider((ref) => ActivityService());

final caseActivitiesProvider =
    StreamProvider.family<List<ActivityModel>, String>((ref, caseId) {
      final service = ref.watch(activityServiceProvider);
      return service.streamCaseActivities(caseId);
    });

/// 🔹 ActivityProvider handles state and fetching for the Case Activity Log
class ActivityProvider extends ChangeNotifier {
  final ActivityService _activityService = ActivityService();

  List<ActivityModel> _activities = [];
  List<ActivityModel> get activities => _activities;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Stream case activities
  Stream<List<ActivityModel>> streamActivities(String caseId) {
    return _activityService.streamCaseActivities(caseId);
  }

  /// Helper to manually log an activity via Provider
  Future<void> logActivity({
    required String caseId,
    required String userId,
    required String userName,
    required String userRole,
    required String actionType,
    required String actionDescription,
  }) async {
    await _activityService.logActivity(
      caseId: caseId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      actionType: actionType,
      actionDescription: actionDescription,
    );
  }
}
