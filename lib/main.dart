import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'provider/theme_provider.dart';

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

    return themeModeAsync.when(
      data: (themeMode) => _buildMaterialApp(themeMode),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LegalSync',
        theme: _buildThemeData(Brightness.light),
        darkTheme: _buildThemeData(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LegalSync',
        theme: _buildThemeData(Brightness.light),
        darkTheme: _buildThemeData(Brightness.dark),
        themeMode: ThemeMode.dark,
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
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6B00),
        brightness: brightness,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F9FC)
          : const Color(0xFF121212),
      cardColor: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF1E1E1E),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1A1A1A),
        foregroundColor: brightness == Brightness.light
            ? Colors.black87
            : Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF141414),
        selectedItemColor: const Color(0xFFFF6B00),
        unselectedItemColor: brightness == Brightness.light
            ? Colors.grey
            : const Color(0xFF5A5A5A),
        elevation: 8,
      ),
      dividerColor: brightness == Brightness.light
          ? const Color(0xFFE9ECEF)
          : const Color(0xFF2A2A2A),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: brightness == Brightness.light ? Colors.black87 : Colors.white,
        ),
        bodyMedium: TextStyle(
          color: brightness == Brightness.light
              ? Colors.black54
              : Colors.white70,
        ),
      ),
    );
  }
}
