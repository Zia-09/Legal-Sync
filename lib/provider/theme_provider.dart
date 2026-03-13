import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  static const _themeKey = 'theme_preference';

  @override
  Future<ThemeMode> build() async {
    return await _loadTheme();
  }

  Future<ThemeMode> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? true;
      return isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      return ThemeMode.dark;
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    state = AsyncValue.data(isDark ? ThemeMode.dark : ThemeMode.light);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
