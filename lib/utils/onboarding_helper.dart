import 'package:shared_preferences/shared_preferences.dart';

/// Helper to manage onboarding completion state.
///
/// Once the user completes (or skips through) the onboarding flow and
/// taps "Get Started", [markSeen] is called. Thereafter [hasSeen] returns
/// true, so the AuthGate routes to the Login screen on cold start instead
/// of replaying onboarding.
class OnboardingHelper {
  static const _key = 'has_seen_onboarding';

  /// Returns true if the user has already seen the onboarding flow.
  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  /// Marks onboarding as completed. Call this once when the user
  /// taps "Get Started" on the final onboarding screen.
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
