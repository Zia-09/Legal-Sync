import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/model/lawyer_Model.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';
  static const String _clientsCollection = 'clients';
  static const String _lawyersCollection = 'lawyers';

  // =========================
  // GET USER ROLE FROM FIRESTORE
  // Returns "admin", "lawyer", "client", or null if not found
  // =========================
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) return null;
      return doc.data()?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // =========================
  // LOGIN
  // Returns "success" on successful sign-in, or an error message string.
  // Role-based navigation is handled by the UI after calling getUserRole().
  // =========================
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Invalid email or password.';
    } catch (e) {
      return e.toString();
    }
  }

  // =========================
  // SIGN UP
  // Creates user in Firebase Auth + Firestore (lawyers / clients).
  // Also writes a `users/{uid}` document with the role field so
  // role-based routing works at login time.
  // Admin accounts are NOT created through the app.
  // =========================
  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role, // 'client' or 'lawyer'
    String? specialization,
    double? consultationFee,
    String? location,
    String? experience,
    String? idCardDocument,
  }) async {
    try {
      if (role != 'client' && role != 'lawyer') {
        return 'Invalid role selected.';
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final String uid = userCredential.user!.uid;
      final Timestamp now = Timestamp.now();

      // Write the role document so getUserRole() works on login
      await _firestore.collection(_usersCollection).doc(uid).set({
        'role': role,
        'name': name,
        'email': email.trim(),
        'createdAt': now,
      });

      if (role == 'client') {
        final client = ClientModel(
          clientId: uid,
          name: name,
          email: email.trim(),
          phone: phone,
          joinedAt: now,
        );
        await _firestore
            .collection(_clientsCollection)
            .doc(uid)
            .set(client.toJson());
      } else {
        final lawyer = LawyerModel(
          lawyerId: uid,
          name: name,
          email: email.trim(),
          phone: phone,
          specialization: specialization ?? '',
          consultationFee: consultationFee ?? 0.0,
          location: location ?? '',
          experience: experience ?? '',
          idCardDocument: idCardDocument,
          joinedAt: now,
          isApproved: false,
          approvalStatus: 'pending',
          aiScore: 0.0,
        );
        await _firestore
            .collection(_lawyersCollection)
            .doc(uid)
            .set(lawyer.toJson());
      }

      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Something went wrong during sign-up.';
    } catch (e) {
      return e.toString();
    }
  }

  // =========================
  // FORGOT PASSWORD
  // Sends a password reset email via Firebase Auth.
  // Returns 'success' or an error message string.
  // =========================
  Future<String> forgotPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send reset email.';
    } catch (e) {
      return e.toString();
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logoutUser() async => await _auth.signOut();

  // =========================
  // CURRENT USER
  // =========================
  User? get currentUser => _auth.currentUser;

  // =========================
  // GET RAW USER DATA
  // =========================
  Future<Map<String, dynamic>?> getUserData(String uid, String role) async {
    try {
      final doc = await _firestore.collection('${role}s').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  // =========================
  // LAWYER APPROVAL
  // =========================
  Future<String> updateLawyerApproval({
    required String lawyerId,
    required bool isApproved,
    required String adminId,
    String? rejectionReason,
  }) async {
    try {
      await _firestore.collection(_lawyersCollection).doc(lawyerId).update({
        'isApproved': isApproved,
        'approvalStatus': isApproved ? 'approved' : 'rejected',
        'approvedBy': adminId,
        'rejectionReason': isApproved ? null : rejectionReason,
        'aiScore': isApproved ? 0.75 : 0.0,
      });
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> checkLawyerApproval(String uid) async {
    try {
      final doc = await _firestore
          .collection(_lawyersCollection)
          .doc(uid)
          .get();
      return doc.exists && (doc.data()?['isApproved'] == true);
    } catch (e) {
      return false;
    }
  }

  // =========================
  // DELETE USER
  // =========================
  Future<String> deleteUser(String uid, String role) async {
    try {
      await _firestore.collection('${role}s').doc(uid).delete();
      await _firestore.collection(_usersCollection).doc(uid).delete();
      if (role != 'admin') await _auth.currentUser?.delete();
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }
}
