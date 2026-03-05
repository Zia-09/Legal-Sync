import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/services/auth_services.dart';
import 'package:legal_sync/services/notification_services.dart';
import 'package:legal_sync/services/email_service.dart';

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

      // 🔹 Trigger Professional Login Notification
      try {
        await NotificationService().createNotification(
          userId: uid,
          title: 'Login Successful',
          message:
              'YOU\'R SUCCESSFULLY LOGIN. Welcome to LegalSync professional services.',
          type: 'system',
        );

        // 🔹 Trigger Real-time Email
        final userData = await _service.getUserData(uid, role);
        final name = userData?['name'] ?? 'User';
        await emailService.sendLoginSuccessEmail(email: email, name: name);
      } catch (e) {
        // Ignore notification/email capture errors
      }

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

      // 🔹 Trigger Registration Success Email
      try {
        await emailService.sendProfessionalEmail(
          to: email,
          subject: 'Welcome to LegalSync Elite - Registration Successful',
          htmlContent:
              '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
              <h2 style="color: #FF6B00; text-align: center;">Welcome to the Elite League, $name!</h2>
              <p style="font-size: 16px; color: #333;">Your <strong>Client</strong> account has been created successfully.</p>
              <p style="color: #666;">You can now browse elite lawyers, book consultations, and manage your cases with professional ease.</p>
              <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                <p style="margin: 0; color: #666;"><strong>Login ID:</strong> $email</p>
              </div>
              <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. Your professional legal companion.</p>
            </div>
          ''',
        );
      } catch (e) {
        // Ignore email errors
      }
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

      // Notify admin
      try {
        await NotificationService().createNotification(
          userId: 'admin',
          title: 'New Lawyer Registration',
          message:
              '$name has submitted a registration request and is waiting for verification.',
          type: 'system',
        );

        // 🔹 Trigger Registration Success Email (Lawyer)
        await emailService.sendProfessionalEmail(
          to: email,
          subject: 'LegalSync Professional - Registration Received',
          htmlContent:
              '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
              <h2 style="color: #131D31; text-align: center;">Registration Received, Counselor $name!</h2>
              <p style="font-size: 16px; color: #333;">Thank you for joining <strong>LegalSync Professional</strong>.</p>
              <p style="color: #666;">Our administration team is currently verifying your credentials. You will receive a notification once your account is fully approved.</p>
              <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                <p style="margin: 0; color: #666;"><strong>Verification Status:</strong> Pending Review</p>
              </div>
              <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. Excellence in legal management.</p>
            </div>
          ''',
        );
      } catch (e) {
        // Ignore notification/email errors
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
