import 'package:flutter/material.dart';
import 'package:legal_sync/screens/onboarding/onboarding_screen1.dart';
import 'package:legal_sync/screens/onboarding/onboarding_screen2.dart';
import 'package:legal_sync/screens/onboarding/onboarding_screen3.dart';
import 'package:legal_sync/screens/onboarding/welcome_screen.dart';
import 'package:legal_sync/screens/client%20panel/login_screen.dart';
import 'package:legal_sync/screens/client%20panel/register_screen.dart';
import 'package:legal_sync/screens/client%20panel/forgot_password_screen.dart';
import 'package:legal_sync/screens/client%20panel/home_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_login_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_registration_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_forgot_password_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_dashboard_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_verification_pending_screen.dart';
import 'package:legal_sync/screens/admin/admin_dashboard_screen.dart';
import 'package:legal_sync/utils/animations.dart';

/// 🔹 Route names for named navigation
class RouteNames {
  // Onboarding
  static const String welcome = '/welcome';
  static const String onboarding1 = '/onboarding/1';
  static const String onboarding2 = '/onboarding/2';
  static const String onboarding3 = '/onboarding/3';

  // Client Authentication
  static const String login = '/client/login';
  static const String register = '/client/register';
  static const String forgotPassword = '/client/forgot-password';

  // Lawyer Authentication
  static const String lawyerLogin = '/lawyer/login';
  static const String lawyerRegister = '/lawyer/register';
  static const String lawyerForgotPassword = '/lawyer/forgot-password';

  // Main App
  static const String clientHome = '/client/home';
  static const String lawyerDashboard = '/lawyer/dashboard';
  static const String lawyerVerificationPending =
      '/lawyer/verification-pending';
  static const String adminDashboard = '/admin/dashboard';
}

/// 🔹 Route generator for named routes
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Onboarding
      case RouteNames.welcome:
        return _buildRoute(const WelcomeScreen(), settings);

      case RouteNames.onboarding1:
        return _buildRoute(const OnboardingPage1(), settings);

      case RouteNames.onboarding2:
        return _buildRoute(const OnboardingPage2(), settings);

      case RouteNames.onboarding3:
        return _buildRoute(const OnboardingPage3(), settings);

      // Client Authentication
      case RouteNames.login:
        return _buildRoute(const LoginScreen(), settings);

      case RouteNames.register:
        return _buildRoute(const RegisterScreen(), settings);

      case RouteNames.forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);

      // Lawyer Authentication
      case RouteNames.lawyerLogin:
        return _buildRoute(const LawyerLoginScreen(), settings);

      case RouteNames.lawyerRegister:
        return _buildRoute(const LawyerRegistrationScreen(), settings);

      case RouteNames.lawyerForgotPassword:
        return _buildRoute(const LawyerForgotPasswordScreen(), settings);

      // Main App
      case RouteNames.clientHome:
        return _buildRoute(const HomeScreen(), settings);

      case RouteNames.lawyerDashboard:
        return _buildRoute(const LawyerDashboardScreen(), settings);

      case RouteNames.lawyerVerificationPending:
        return _buildRoute(const LawyerVerificationPendingScreen(), settings);

      case RouteNames.adminDashboard:
        return _buildRoute(const AdminDashboardScreen(), settings);

      // Default - Onboarding
      default:
        return _buildRoute(const OnboardingPage1(), settings);
    }
  }

  /// Build a route with professional animations based on route type
  static PageRoute<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    // Determine animation type based on route name
    if (settings.name != null &&
        (settings.name!.contains('onboarding') ||
         settings.name == RouteNames.welcome)) {
      // Onboarding - slide from right
      return AnimationUtils.slideFromRightTransition(page, settings: settings);
    } else if (settings.name!.contains('login') ||
        settings.name!.contains('register') ||
        settings.name!.contains('forgot')) {
      // Authentication screens - scale transition
      return AnimationUtils.scaleTransition(page, settings: settings);
    } else if (settings.name == RouteNames.clientHome ||
        settings.name == RouteNames.lawyerDashboard) {
      // Main navigation - fade transition
      return AnimationUtils.fadeTransition(page, settings: settings);
    } else {
      // Default - slide from right
      return AnimationUtils.slideFromRightTransition(page, settings: settings);
    }
  }

  /// Generate route on unknown route with professional animation
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    final page = Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(child: Text('Route not found')),
    );
    return AnimationUtils.fadeTransition(page, settings: settings);
  }
}

/// 🔹 Extension methods for convenient navigation
extension NavigationExtension on BuildContext {
  /// Navigate to named route and keep history
  void navigateTo(String routeName, {Object? arguments}) {
    Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  /// Navigate and replace current route (for onboarding flows)
  void navigateAndReplace(String routeName, {Object? arguments}) {
    Navigator.of(this).pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Navigate and remove all previous routes (for login/logout flows)
  void navigateAndClearStack(String routeName, {Object? arguments}) {
    Navigator.of(this).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back to previous screen
  void goBack([Object? result]) {
    Navigator.of(this).pop(result);
  }

  /// Navigate to screen and remove until specific route
  void navigateUntil(
    String routeName, {
    required String untilRoute,
    Object? arguments,
  }) {
    Navigator.of(this).pushNamedAndRemoveUntil(
      routeName,
      ModalRoute.withName(untilRoute),
      arguments: arguments,
    );
  }
}
