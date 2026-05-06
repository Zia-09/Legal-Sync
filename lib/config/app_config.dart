/// 🔹 Environment Configuration
///
/// This file manages environment-specific configuration
/// Use environment variables or .env files instead of hardcoding values
library;

class AppConfig {
  // Firebase Configuration - should be in google-services.json for Android
  // and GoogleService-Info.plist for iOS
  static const String firebaseProjectId = 'legal-sync-xxx';

  // Supabase Configuration
  static const String supabaseUrl =
      'https://agzqautnshxgactnthxx.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFnenFhdXRuc2h4Z2FjdG50aHh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NDk3MTYsImV4cCI6MjA4ODEyNTcxNn0.fi_GSGQCFzP5Ki7qI_1VnJ2oPPRYMhIHIVA9krJmSrE';

  // API Configuration
  static const String apiBaseUrl = 'https://api.legalsync.app';
  static const String apiTimeout = '30'; // seconds
  static const bool enableHttpCertificatePinning = true;

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // App Settings
  static const String appName = 'LegalSync';
  static const String appVersion = '1.0.0';
  static const int minSdkVersion = 21;
  static const int targetSdkVersion = 34;

  // Cache Settings
  static const int cacheExpirationMs = 3600000; // 1 hour
  static const int maxCacheSizeBytes = 52428800; // 50 MB

  // Database Settings
  static const int maxOfflineQueueSize = 1000;
  static const int syncBatchSize = 100;

  // Security Settings
  static const bool validateSSLCertificates = true;
  static const bool enableBiometricAuth = true;
  static const int passwordMinLength = 8;

  // Analytics Settings
  static const bool trackAnalytics = true;
  static const bool trackCrashes = true;
  static const int analyticsFlushIntervalSeconds = 60;
}
