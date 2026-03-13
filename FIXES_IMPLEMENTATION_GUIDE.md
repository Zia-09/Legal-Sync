# 🔧 Code Fixes Guide - LegalSync

## Quick Reference: Issues with Code Examples and Fixes

---

## 1. 🚨 CRITICAL: BrandLogo Widget Overflow

**Location:** [lib/widgets/brand_logo.dart](lib/widgets/brand_logo.dart)

### Current Code (WRONG):
```dart
@override
Widget build(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: alignment,
    children: [
      if (showImage) ...[
        Image.asset('images/logo.png', width: imageSize, height: imageSize),
        SizedBox(width: showImage ? 12 : 0),  // ❌ WIDTH in Column = OVERFLOW!
      ],
      RichText(
        text: TextSpan(...),
      ),
    ],
  );
}
```

### Fixed Code (RIGHT):
```dart
@override
Widget build(BuildContext context) {
  if (!showImage) {
    // No image, just text
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        children: const [
          TextSpan(
            text: 'Legal',
            style: TextStyle(color: Color(0xFFDC2626)),
          ),
          TextSpan(
            text: 'Sync',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // With image - use Row for horizontal spacing
  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: alignment == MainAxisAlignment.center 
      ? MainAxisAlignment.center 
      : MainAxisAlignment.start,
    children: [
      Image.asset(
        'images/logo.png',
        width: imageSize,
        height: imageSize,
      ),
      SizedBox(width: 12),  // ✅ CORRECT: width spacing in Row
      RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          children: const [
            TextSpan(
              text: 'Legal',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
            TextSpan(
              text: 'Sync',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    ],
  );
}
```

**Why:** `SizedBox(width: x)` in a `Column` doesn't work. Use `Row` for horizontal spacing.

---

## 2. 🔐 CRITICAL: Remove Hardcoded Credentials

**Location:** [lib/main.dart](lib/main.dart) & [lib/screens/client panel/login_screen.dart](lib/screens/client%20panel/login_screen.dart)

### Current Code (INSECURE):
```dart
// main.dart
await Supabase.initialize(
  url: 'https://agzqautnshxgactnthxx.supabase.co',  // ❌ EXPOSED!
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',  // ❌ EXPOSED!
);

// login_screen.dart
const String _adminEmail = 'admin@legalsync.com';  // ❌ EXPOSED!
const String _adminPassword = 'Admin@1234';  // ❌ EXPOSED!
```

### Fixed Code (SECURE):

**Step 1:** Create `.env` file (add to .gitignore):
```
SUPABASE_URL=https://agzqautnshxgactnthxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
ADMIN_EMAIL=admin@legalsync.com
```

**Step 2:** Add to pubspec.yaml:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0  # Add this
```

**Step 3:** Update main.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  // Use environment variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}
```

**Step 4:** Update login_screen.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  // ✅ Load at runtime from secure storage
  static String get _adminEmail => dotenv.env['ADMIN_EMAIL'] ?? '';
  static String get _adminPassword => dotenv.env['ADMIN_PASSWORD'] ?? '';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
```

**Better Solution:** Use Firebase Auth properly instead of hardcoded admin:
```dart
Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  final email = _emailController.text.trim();
  final password = _passwordController.text;

  try {
    final role = await ref
        .read(authNotifierProvider.notifier)
        .login(email: email, password: password);

    if (!mounted) return;

    // Route based on role
    if (role == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (role == 'lawyer') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LawyerDashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 3. ⚠️ HIGH: Fix Theme Provider Async Issue

**Location:** [lib/provider/theme_provider.dart](lib/provider/theme_provider.dart)

### Current Code (WRONG):
```dart
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();  // ❌ Async but not awaited!
    return ThemeMode.system;  // Returns immediately
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey);
    if (isDark != null) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }
}
```

### Fixed Code (RIGHT):
```dart
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
      print('Error loading theme: $e');
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
```

**In main.dart:**
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final themeAsync = ref.watch(themeModeProvider);
  
  return themeAsync.when(
    data: (themeMode) => MaterialApp(
      themeMode: themeMode,
      // ... rest of config
    ),
    loading: () => const MaterialApp(
      home: Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    ),
    error: (e, st) => MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Error loading theme')),
      ),
    ),
  );
}
```

---

## 4. ⚠️ HIGH: Add Mounted Checks Consistently

**Location:** Multiple files (example: [lib/screens/client panel/home_screen.dart](lib/screens/client%20panel/home_screen.dart))

### Pattern to Use:
```dart
// BEFORE async operation
if (!mounted) return;
  
// Use context safely
ScaffoldMessenger.of(context).showSnackBar(...);
Navigator.push(context, ...);
```

### Example Fix:
```dart
Future<void> _uploadFile() async {
  try {
    // ... upload logic
    
    if (!mounted) return;  // ✅ Check before ScaffoldMessenger
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File uploaded!')),
    );
  } catch (e) {
    if (!mounted) return;  // ✅ Check before ScaffoldMessenger
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## 5. 🔴 MEDIUM: Proper Error Handling in Providers

**Location:** All provider watch patterns

### Current Code (POOR):
```dart
data: (cases) { ... },
loading: () => const Center(child: CircularProgressIndicator()),
error: (e, _) => Center(child: Text('Error: $e')),
```

### Fixed Code (GOOD):
```dart
data: (cases) {
  if (cases.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No cases found'),
        ],
      ),
    );
  }
  return ListView.builder(...);
},
loading: () => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Loading cases...'),
    ],
  ),
),
error: (e, st) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          'Error loading cases',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          e.toString(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: ref.refresh,
          child: const Text('Retry'),
        ),
      ],
    ),
  ),
),
```

---

## 6. 📱 MEDIUM: Fix Chat Message Overflow

**Location:** [lib/screens/client panel/chat_detail_screen.dart](lib/screens/client%20panel/chat_detail_screen.dart)

### Issue:
Messages might overflow on small screens

### Fix - Add Constraints:
```dart
// For each message bubble
Align(
  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.75,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFFFF6B00) : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(message),
    ),
  ),
)
```

---

## 7. 🎨 MEDIUM: Create Design System Constants

**New File:** Create `lib/core/constants/design_system.dart`

```dart
import 'package:flutter/material.dart';

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppColors {
  static const primary = Color(0xFFFF6B00);
  static const secondary = Color(0xFF7C3AED);
  static const success = Color(0xFF059669);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  
  // Dark theme
  static const darkBg = Color(0xFF0F0F0F);
  static const darkCard = Color(0xFF1E1E1E);
  static const darkText = Colors.white;
  
  // Light theme
  static const lightBg = Color(0xFFF8F9FA);
  static const lightCard = Colors.white;
  static const lightText = Color(0xFF1A1A1A);
}

class AppBorders {
  static const radius8 = BorderRadius.all(Radius.circular(8.0));
  static const radius12 = BorderRadius.all(Radius.circular(12.0));
  static const radius16 = BorderRadius.all(Radius.circular(16.0));
  static const radius20 = BorderRadius.all(Radius.circular(20.0));
  static const radius24 = BorderRadius.all(Radius.circular(24.0));
}
```

### Use Throughout:
```dart
// Instead of:
const SizedBox(height: 24),
backgroundColor: const Color(0xFFFF6B00),
BorderRadius.circular(20),

// Write:
SizedBox(height: AppSpacing.xl),
backgroundColor: AppColors.primary,
borderRadius: AppBorders.radius20,
```

---

## 8. 📱 MEDIUM: Make Responsive (Example: Case Status View)

**Fix GridView in case_status_view.dart:**

```dart
// BEFORE (not responsive):
GridView.count(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisCount: 2,
  childAspectRatio: 2.4,  // ❌ Fixed ratio
  children: [...],
)

// AFTER (responsive):
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
    childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2.8 : 2.4,
    crossAxisSpacing: AppSpacing.md,
    mainAxisSpacing: AppSpacing.md,
  ),
  itemCount: quickActions.length,
  itemBuilder: (context, index) => quickActions[index],
)
```

---

## 9. 🧹 LOW: Extract Inline Consumer Widgets

**Current (Hard to read):**
```dart
Consumer(
  builder: (context, ref, child) {
    final clientAsync = ref.watch(currentClientProvider);
    return clientAsync.when(
      data: (client) => SizedBox(
        width: 40,
        height: 40,
        child: ClipRRect(...),
      ),
      loading: () => SizedBox(...),
      error: (_, _) => Icon(...),
    );
  },
)
```

**Better (Extracted):**
```dart
class _ClientProfileAvatar extends ConsumerWidget {
  const _ClientProfileAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(currentClientProvider);
    
    return clientAsync.when(
      data: (client) => ... 
      loading: () => ...,
      error: (_, _) => ...,
    );
  }
}

// Use in parent:
const _ClientProfileAvatar(),
```

---

## 📋 Testing Checklist

After applying these fixes, test:

- [ ] Tap on components with long text → No overflow
- [ ] Resize window in DevTools → Layout responsive
- [ ] Load app → Theme loads correctly
- [ ] Upload file during screen transition → No crash
- [ ] Network error during data fetch → Shows error with retry
- [ ] Dark/Light mode toggle → Persists after restart
- [ ] Admin login → Uses secure method
- [ ] Message with long URL → Wraps correctly
- [ ] Small phone (320px) → All UIs fit
- [ ] Tablet (768px) → Layout adjusts

---

**Implementation Order:**
1. Fix #1 (BrandLogo overflow)
2. Fix #2 (Remove hardcoded credentials)
3. Fix #3 (Theme provider async)
4. Fix #4 (Add mounted checks)
5. Fix #5-9 (Other improvements)

