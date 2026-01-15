// lib/services/firebase_services.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/model/chat_Model.dart';
import 'package:legal_sync/model/chat_thread_model.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/model/review_Model.dart';

/// =====================
/// ENUM FOR USER ROLES
/// =====================
enum UserRole { admin, lawyer, client }

/// =====================
/// CUSTOM SERVICE EXCEPTION
/// =====================
class ServiceException implements Exception {
  final String message;
  ServiceException(this.message);
}

/// =====================
/// AUTH SERVICE
/// =====================
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _adminEmail = "admin@lawconnect.com";
  static const String _adminPassword = "Admin@12345";

  // SIGN UP
  Future<String> signUpUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? specialization,
    double? consultationFee,
    String? location,
    String? experience,
  }) async {
    try {
      if (email.trim() == _adminEmail) return "Admin registration not allowed.";

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final now = Timestamp.now();

      if (role == UserRole.client) {
        final client = ClientModel(
          clientId: uid,
          name: name,
          email: email,
          phone: phone,
          joinedAt: now,
        );
        await _db.collection('clients').doc(uid).set(client.toJson());
      } else if (role == UserRole.lawyer) {
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
        await _db.collection('lawyers').doc(uid).set(lawyer.toJson());
      }

      return uid;
    } on FirebaseAuthException catch (e) {
      throw ServiceException(e.message ?? 'Authentication Error');
    }
  }

  // SIGN IN
  Future<Map<String, dynamic>> signInUser(String email, String password) async {
    try {
      if (email.trim() == _adminEmail && password == _adminPassword) {
        return {'role': UserRole.admin, 'id': 'mainAdmin'};
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      if (await _db
          .collection('clients')
          .doc(uid)
          .get()
          .then((d) => d.exists)) {
        return {'role': UserRole.client, 'id': uid};
      } else if (await _db
          .collection('lawyers')
          .doc(uid)
          .get()
          .then((d) => d.exists)) {
        final approved = await checkLawyerApproval(uid);
        if (!approved) {
          throw ServiceException("Lawyer account pending approval.");
        }
        return {'role': UserRole.lawyer, 'id': uid};
      }

      throw ServiceException("User not found.");
    } on FirebaseAuthException catch (e) {
      throw ServiceException(e.message ?? "Login failed.");
    }
  }

  Future<void> signOut() => _auth.signOut();
  User? get currentUser => _auth.currentUser;

  Future<bool> checkLawyerApproval(String uid) async {
    try {
      final doc = await _db.collection('lawyers').doc(uid).get();
      return doc.exists && (doc.data()?['isApproved'] ?? false);
    } catch (_) {
      return false;
    }
  }
}

/// =====================
/// STORAGE SERVICE
/// =====================
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({required File file, required String path}) async {
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }
}

/// =====================
/// CASE SERVICE
/// =====================
class CaseService {
  final CollectionReference casesRef = FirebaseFirestore.instance.collection(
    'cases',
  );

  Future<String> createCase(CaseModel model) async {
    final doc = casesRef.doc();
    await doc.set(model.toJson());
    return doc.id;
  }

  Future<void> updateCase(String id, Map<String, dynamic> changes) =>
      casesRef.doc(id).update(changes);
  Future<void> deleteCase(String id) => casesRef.doc(id).delete();

  Stream<List<CaseModel>> streamCasesForLawyer(String lawyerId) {
    return casesRef
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => CaseModel.fromJson({
                  ...d.data() as Map<String, dynamic>,
                  'caseId': d.id,
                }),
              )
              .toList(),
        );
  }

  Stream<CaseModel> watchCase(String caseId) {
    return casesRef
        .doc(caseId)
        .snapshots()
        .map(
          (d) => CaseModel.fromJson({
            ...d.data() as Map<String, dynamic>,
            'caseId': d.id,
          }),
        );
  }
}

/// =====================
/// CHAT SERVICE
/// =====================
class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createThread({
    required String lawyerId,
    required String clientId,
    String? caseId,
  }) async {
    final doc = _db.collection('chats').doc();
    final now = DateTime.now();
    final thread = ChatThread(
      threadId: doc.id,
      lawyerId: lawyerId,
      clientId: clientId,
      caseId: caseId,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(thread.toJson());
    return doc.id;
  }

  Stream<List<ChatThread>> streamUserThreads(String uid) {
    return _db
        .collection('chats')
        .where('lawyerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatThread.fromJson(d.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Stream<List<ChatMessage>> streamMessages(String threadId) {
    return _db
        .collection('chats')
        .doc(threadId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) =>
                    ChatMessage.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList(),
        );
  }

  Future<void> sendMessage(String threadId, ChatMessage msg) async {
    final col = _db.collection('chats').doc(threadId).collection('messages');
    await col.doc(msg.messageId).set(msg.toMap());
    await _db.collection('chats').doc(threadId).update({
      'updatedAt': Timestamp.now(),
    });
  }
}

/// =====================
/// REVIEW SERVICE
/// =====================
class ReviewService {
  final CollectionReference reviewsRef = FirebaseFirestore.instance.collection(
    'reviews',
  );

  Future<void> addReview(ReviewModel review) async =>
      reviewsRef.add(review.toMap());

  Stream<List<ReviewModel>> getReviewsForLawyer(String lawyerId) {
    return reviewsRef
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) =>
                    ReviewModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList(),
        );
  }
}

/// =====================
/// ADMIN SERVICE
/// =====================
class AdminService {
  Future<void> approveLawyer(String lawyerId) async {
    await FirebaseFirestore.instance.collection('lawyers').doc(lawyerId).update(
      {'isApproved': true, 'approvalStatus': 'approved'},
    );
  }

  Future<void> rejectLawyer(String lawyerId, String reason) async {
    await FirebaseFirestore.instance.collection('lawyers').doc(lawyerId).update(
      {
        'isApproved': false,
        'approvalStatus': 'rejected',
        'rejectionReason': reason,
      },
    );
  }

  Future<void> disableUser(String userId, UserRole role) async {
    final collection = role == UserRole.client ? 'clients' : 'lawyers';
    await FirebaseFirestore.instance.collection(collection).doc(userId).update({
      'disabled': true,
    });
  }
}
