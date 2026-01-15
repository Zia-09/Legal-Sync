import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_sync/model/admin_model.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/model/lawyer_Model.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // 🔒 Hardcoded Admin Credentials
  static const String _adminEmail = "admin@lawconnect.com";
  static const String _adminPassword = "Admin@12345";

  static const String _adminsCollection = "admins";
  static const String _clientsCollection = "clients";
  static const String _lawyersCollection = "lawyers";

  // =========================
  // ADMIN INITIALIZATION
  // =========================
  Future<void> ensureAdminExists() async {
    try {
      final adminDoc = await _firestore
          .collection(_adminsCollection)
          .doc('mainAdmin')
          .get();

      if (!adminDoc.exists) {
        final admin = AdminModel(
          adminId: 'mainAdmin',
          name: 'Super Admin',
          email: _adminEmail,
          phone: '+923000000000',
          profileImage: null,
          approvedLawyers: const [],
          rejectedLawyers: const [],
          suspendedAccounts: const [],
          role: 'super_admin',
          isActive: true,
          joinedAt: Timestamp.now(),
          lastActive: null,
        );

        await _firestore
            .collection(_adminsCollection)
            .doc('mainAdmin')
            .set(admin.toJson());
        print("✅ Default Admin created in Firestore");
      }
    } catch (e) {
      print("⚠️ Error creating admin: $e");
    }
  }

  // =========================
  // SIGN UP
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
  }) async {
    try {
      if (email.trim() == _adminEmail) {
        return "Admin registration not allowed through app.";
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;
      final Timestamp now = Timestamp.now();

      if (role == 'client') {
        final client = ClientModel(
          clientId: uid,
          name: name,
          email: email,
          phone: phone,
          joinedAt: now,
        );
        await _firestore
            .collection(_clientsCollection)
            .doc(uid)
            .set(client.toJson());
      } else if (role == 'lawyer') {
        final lawyer = LawyerModel(
          lawyerId: uid,
          name: name,
          email: email,
          phone: phone,
          specialization: specialization ?? '',
          consultationFee: consultationFee ?? 0.0,
          location: location ?? '',
          experience: experience ?? '',
          joinedAt: now,
          isApproved: false,
          approvalStatus: "pending",
          aiScore: 0.0,
        );
        await _firestore
            .collection(_lawyersCollection)
            .doc(uid)
            .set(lawyer.toJson());
      } else {
        return "Invalid role selected.";
      }

      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Something went wrong during sign-up.";
    } catch (e) {
      return e.toString();
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      if (email.trim() == _adminEmail && password == _adminPassword) {
        await ensureAdminExists();
        return "admin_success";
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return "Login failed. Please try again.";

      final role = await _detectUserRole(user.uid);

      if (role == 'lawyer') {
        final approved = await checkLawyerApproval(user.uid);
        if (!approved) {
          await _auth.signOut();
          return "Your lawyer account is pending admin approval.";
        }
      }

      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Invalid email or password.";
    } catch (e) {
      return e.toString();
    }
  }

  // =========================
  // ROLE DETECTION
  // =========================
  Future<String?> _detectUserRole(String uid) async {
    final client = await _firestore
        .collection(_clientsCollection)
        .doc(uid)
        .get();
    if (client.exists) return 'client';

    final lawyer = await _firestore
        .collection(_lawyersCollection)
        .doc(uid)
        .get();
    if (lawyer.exists) return 'lawyer';

    final admin = await _firestore.collection(_adminsCollection).doc(uid).get();
    if (admin.exists) return 'admin';

    return null;
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logoutUser() async => await _auth.signOut();

  // =========================
  // GET CURRENT USER
  // =========================
  User? get currentUser => _auth.currentUser;

  Future<Map<String, dynamic>?> getUserData(String uid, String role) async {
    try {
      final doc = await _firestore.collection('${role}s').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching user data: $e");
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

      final adminRef = _firestore.collection(_adminsCollection).doc(adminId);
      await adminRef.update({
        isApproved ? 'approvedLawyers' : 'rejectedLawyers':
            FieldValue.arrayUnion([lawyerId]),
      });

      return "success";
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
      print("Approval check error: $e");
      return false;
    }
  }

  // =========================
  // DELETE USER
  // =========================
  Future<String> deleteUser(String uid, String role) async {
    try {
      await _firestore.collection('${role}s').doc(uid).delete();
      if (role != 'admin') await _auth.currentUser?.delete();
      return "success";
    } catch (e) {
      return e.toString();
    }
  }
}
