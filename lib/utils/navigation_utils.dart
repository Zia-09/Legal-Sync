import 'package:flutter/material.dart';

/// Navigation Utilities for consistent app-wide navigation
class NavigationUtils {
  /// Navigate to a screen and allow going back
  static void navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Navigate to a screen and replace current (no back button usage)
  static void navigateAndReplace(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  /// Navigate to a screen and remove all previous screens
  static void navigateAndClear(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  /// Go back to previous screen
  static void goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Go back with a value
  static void goBackWithResult(BuildContext context, dynamic result) {
    Navigator.of(context).pop(result);
  }

  /// Build a professional back button for AppBar
  static Widget buildBackButton(
    BuildContext context, {
    Color? color,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed ?? () => NavigationUtils.goBack(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: color ?? Colors.black87,
          size: 18,
        ),
      ),
    );
  }

  /// Build a professional screen title for AppBar
  static Widget buildScreenTitle(String title, {bool isDark = false}) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }
}
