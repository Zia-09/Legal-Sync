import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'provider/theme_provider.dart';
import 'config/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://agzqautnshxgactnthxx.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFnenFhdXRuc2h4Z2FjdG50aHh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NDk3MTYsImV4cCI6MjA4ODEyNTcxNn0.fi_GSGQCFzP5Ki7qI_1VnJ2oPPRYMhIHIVA9krJmSrE',
  );

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    // Silently fall back to light until the provider resolves
    final themeMode = themeModeAsync.whenData((v) => v).value ?? ThemeMode.light;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LegalSync',
      themeMode: themeMode,
      theme: _buildThemeData(Brightness.light),
      darkTheme: _buildThemeData(Brightness.dark),
      home: const AuthGate(),
      onGenerateRoute: AppRouter.generateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
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

/// Auth gate — determines the initial route after app start.
///
/// KEY FIX: Uses [WidgetsBinding.addPostFrameCallback] so navigation is
/// deferred until after the first frame is fully rendered. This resolves the
/// Flutter assertion: "!_debugLocked is not true" (navigator.dart:5893).
///
/// The [_navigated] flag prevents double-navigation on provider-triggered
/// rebuilds of the parent [MyApp] widget.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame before navigating — Navigator is not available
    // during initState / build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    if (_navigated || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _navigated = true;
      Navigator.of(context).pushReplacementNamed(RouteNames.onboarding1);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted || _navigated) return;

      final isFirstTime = doc.exists
          ? (doc.data()?['isFirstTimeUser'] ?? true)
          : true;

      _navigated = true;
      if (isFirstTime) {
        Navigator.of(context).pushReplacementNamed(RouteNames.onboarding1);
      } else {
        Navigator.of(context).pushReplacementNamed(RouteNames.clientHome);
      }
    } catch (_) {
      if (!mounted || _navigated) return;
      _navigated = true;
      Navigator.of(context).pushReplacementNamed(RouteNames.clientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shown for one frame only before routing completes
    return const Scaffold(
      backgroundColor: Color(0xFFF7F9FC),
      body: SizedBox.shrink(),
    );
  }
}
