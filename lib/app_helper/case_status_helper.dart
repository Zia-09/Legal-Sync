class CaseStatusHelper {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String closed = 'closed';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';

  static final Map<String, Set<String>> _allowedTransitions = {
    pending: {inProgress, rejected, cancelled},
    inProgress: {closed, cancelled},
    closed: const {},
    rejected: const {},
    cancelled: const {},
  };

  static String normalize(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase().replaceAll('-', '_');
    if (normalized == 'ongoing') return inProgress;
    if (normalized == 'completed') return closed;
    if (normalized == 'waiting_for_lawyer') return pending;
    return normalized;
  }

  static bool isKnownStatus(String status) {
    return _allowedTransitions.containsKey(normalize(status));
  }

  static bool canTransition({
    required String currentStatus,
    required String nextStatus,
  }) {
    final current = normalize(currentStatus);
    final next = normalize(nextStatus);
    if (current == next) return true;
    final allowed = _allowedTransitions[current];
    if (allowed == null) return false;
    return allowed.contains(next);
  }

  static List<String> allowedNextStatuses(String currentStatus) {
    final current = normalize(currentStatus);
    return (_allowedTransitions[current] ?? const <String>{}).toList();
  }

  static bool isFinalStatus(String status) {
    final normalized = normalize(status);
    return normalized == closed ||
        normalized == rejected ||
        normalized == cancelled;
  }
}
