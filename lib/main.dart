import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'provider/theme_provider.dart';
import 'provider/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase from environment or use fallback
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
    final authStateAsync = ref.watch(authStateProvider);

    // Check if user is authenticated
    final isAuthenticated =
        authStateAsync.whenData((user) => user != null).value ?? false;

    return themeModeAsync.when(
      data: (themeMode) {
        // Use light theme for auth screens, user-selected theme after auth
        final effectiveTheme = isAuthenticated ? themeMode : ThemeMode.light;
        return _buildMaterialApp(effectiveTheme);
      },
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LegalSync',
        theme: _buildThemeData(Brightness.light),
        darkTheme: _buildThemeData(Brightness.dark),
        themeMode: ThemeMode.light,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LegalSync',
        theme: _buildThemeData(Brightness.light),
        darkTheme: _buildThemeData(Brightness.dark),
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }

  MaterialApp _buildMaterialApp(ThemeMode themeMode) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LegalSync',
      themeMode: themeMode,
      theme: _buildThemeData(Brightness.light),
      darkTheme: _buildThemeData(Brightness.dark),
      home: const SplashScreen(),
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
      // ✅ FIX: InputDecorationTheme for dark mode TextFields
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
        // ✅ FIX: Text color in TextField for dark mode
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
