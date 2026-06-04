import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'provider/theme_provider.dart';
import 'config/routes.dart';
import 'config/app_config.dart';
import 'utils/error_handler.dart';
import 'utils/cache_manager.dart';
import 'utils/security_manager.dart';
import 'utils/analytics_manager.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'widgets/notification_listener_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize utilities
  await CacheManager.initialize();
  await SecurityManager.initialize();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    AppLogger.info('Firebase initialized successfully', tag: 'Startup');
    // Initialize Notification Service (FCM + Local Notifications)
    await NotificationService.initialize();

    // Re-register token whenever user logs in, remove on logout
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        NotificationService.registerForCurrentUser();
      }
    });
  } catch (e) {
    AppLogger.error('Failed to initialize Firebase', tag: 'Startup', error: e);
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    AppLogger.info('Supabase initialized successfully', tag: 'Startup');
  } catch (e) {
    AppLogger.error('Failed to initialize Supabase', tag: 'Startup', error: e);
  }

  // Log app launch
  AnalyticsManager.logEvent(AnalyticsEvent.appLaunched);

  // Run app with error boundary
  runApp(
    ErrorBoundary(
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

/// Error boundary widget to catch uncaught exceptions
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({required this.child, super.key});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        'Flutter Error',
        tag: 'ErrorBoundary',
        error: details.exception,
        stackTrace: details.stack,
      );
      CrashReporter.reportCrash(
        error: details.exception.toString(),
        stackTrace: details.stack ?? StackTrace.current,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    // Silently fall back to light until the provider resolves
    final themeMode = themeModeAsync.whenData((v) => v).value ?? ThemeMode.light;

    return RealtimeNotificationListener(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'LegalSync',
        themeMode: themeMode,
        theme: _buildThemeData(Brightness.light),
        darkTheme: _buildThemeData(Brightness.dark),
        home: const SplashScreen(),
        onGenerateRoute: AppRouter.generateRoute,
        onUnknownRoute: AppRouter.onUnknownRoute,
      ),
    );
  }

  static ThemeData _buildThemeData(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6B00),
        brightness: brightness,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF7F9FC),
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        selectedItemColor: const Color(0xFFFF6B00),
        unselectedItemColor: isDark ? const Color(0xFF5A5A5A) : Colors.grey,
        elevation: 8,
      ),
      dividerColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE9ECEF),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: isDark ? Colors.white : Colors.black87),
        bodyMedium: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF9E9E9E) : Colors.grey,
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF6B6B6B) : Colors.grey[400],
        ),
        helperStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF333333) : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF333333) : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
