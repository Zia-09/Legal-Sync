import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/app_user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUserModel? _currentUser;
  bool _isLoading = false;

  /// ==========================
  /// Getters
  /// ==========================
  AppUserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  UserRole? get role => _currentUser?.role;

  bool get isAdmin => role == UserRole.admin;
  bool get isLawyer => role == UserRole.lawyer;
  bool get isClient => role == UserRole.client;

  /// ==========================
  /// Constructor
  /// ==========================
  AuthProvider() {
    _listenAuthChanges();
  }

  /// ==========================
  /// Listen Firebase Auth State
  /// ==========================
  void _listenAuthChanges() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentUser = null;
        notifyListeners();
      } else {
        await _loadUserFromFirestore(user.uid);
      }
    });
  }

  /// ==========================
  /// Load User from Firestore
  /// ==========================
  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        _currentUser = null;
        notifyListeners();
        return;
      }

      _currentUser = AppUserModel.fromJson(doc.data()!);
      notifyListeners();
    } catch (e) {
      debugPrint('Load user error: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  /// ==========================
  /// Login
  /// ==========================
  Future<void> login({required String email, required String password}) async {
    _setLoading(true);

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserFromFirestore(result.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    } finally {
      _setLoading(false);
    }
  }

  /// ==========================
  /// Register (Admin / Lawyer / Client)
  /// ==========================
  Future<void> register({
    required String email,
    required String password,
    required AppUserModel userModel,
  }) async {
    _setLoading(true);

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user!.uid;

      final newUser = userModel.copyWith(userId: uid);

      await _firestore.collection('users').doc(uid).set(newUser.toJson());

      _currentUser = newUser;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    } finally {
      _setLoading(false);
    }
  }

  /// ==========================
  /// Logout
  /// ==========================
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// ==========================
  /// RBAC Guards
  /// ==========================
  bool canAccessAdminPanel() {
    return role == UserRole.admin;
  }

  /// Safe lawyer access check
  /// assignments = { clientId: lawyerId }
  bool canAccessLawyerData({
    required String lawyerId,
    required String clientId,
    required Map<String, String> assignments,
  }) {
    // Only admin or assigned lawyer can access
    if (isAdmin) return true;

    final assignedLawyerId = assignments[clientId];
    if (assignedLawyerId == null) return false;

    return assignedLawyerId == lawyerId;
  }

  /// ==========================
  /// Helpers
  /// ==========================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
