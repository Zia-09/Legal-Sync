import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/services/auth_services.dart';

// ─────────────────────────────────────────────
// Auth Service Provider (singleton)
// ─────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ─────────────────────────────────────────────
// Firebase Auth State Stream
// Emits User? whenever sign-in state changes.
// ─────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ─────────────────────────────────────────────
// Current User Role Provider
// Reads role from Firestore users/{uid} after Auth state resolves.
// Returns: "admin" | "lawyer" | "client" | null
// ─────────────────────────────────────────────
final userRoleProvider = FutureProvider<String?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return null;

  final service = ref.read(authServiceProvider);
  return service.getUserRole(authState.uid);
});

// ─────────────────────────────────────────────
// Auth Notifier — handles login / register / logout / forgotPassword
// ─────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AsyncValue.data(null));

  /// Sign in with email & password.
  /// Returns the role string ("admin"/"lawyer"/"client") on success.
  /// Throws a String error message on failure.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.loginUser(email: email, password: password);
      if (result != 'success') {
        state = const AsyncValue.data(null);
        throw result; // error message string
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'Authentication failed.';

      final role = await _service.getUserRole(uid);
      if (role == null) {
        await _service.logoutUser();
        throw 'Account not configured. Please contact support.';
      }

      state = const AsyncValue.data(null);
      return role;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Register a new client account.
  /// Throws a String error message on failure.
  Future<void> registerClient({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.signUpUser(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: 'client',
      );
      if (result != 'success') {
        state = const AsyncValue.data(null);
        throw result;
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Register a new lawyer account.
  /// Throws a String error message on failure.
  Future<void> registerLawyer({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String specialization,
    required String experience,
    required String? idCardDocument,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.signUpUser(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: 'lawyer',
        specialization: specialization,
        experience: experience,
        idCardDocument: idCardDocument,
      );
      if (result != 'success') {
        state = const AsyncValue.data(null);
        throw result;
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Send password reset email.
  /// Throws a String error message on failure.
  Future<void> forgotPassword({required String email}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.forgotPassword(email: email);
      if (result != 'success') {
        state = const AsyncValue.data(null);
        throw result;
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign out.
  Future<void> logout() async {
    await _service.logoutUser();
    state = const AsyncValue.data(null);
  }
}

// ─────────────────────────────────────────────
// Auth Notifier Provider (used by screens)
// ─────────────────────────────────────────────
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
      final service = ref.watch(authServiceProvider);
      return AuthNotifier(service);
    });
