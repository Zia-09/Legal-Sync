import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/admin_Model.dart';
import '../services/admin_service.dart';

// ===============================
// Admin Service Provider
// ===============================
final adminServiceProvider = Provider((ref) => AdminService());

// ===============================
// All Admins Provider
// ===============================
final allAdminsProvider = StreamProvider<List<AdminModel>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamAllAdmins();
});

// ===============================
// Get Admin by ID Provider
// ===============================
final getAdminByIdProvider = FutureProvider.family<AdminModel?, String>((
  ref,
  adminId,
) async {
  final service = ref.watch(adminServiceProvider);
  return service.getAdmin(adminId);
});

// ===============================
// Admin by Email Provider
// ===============================
final getAdminByEmailProvider = FutureProvider.family<AdminModel?, String>((
  ref,
  email,
) async {
  final service = ref.watch(adminServiceProvider);
  return service.getAdminByEmail(email);
});

// ===============================
// Active Admins Provider
// ===============================
final activeAdminsProvider = StreamProvider<List<AdminModel>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamActiveAdmins();
});

// ===============================
// Admin by Role Provider
// ===============================
final adminsByRoleProvider = StreamProvider.family<List<AdminModel>, String>((
  ref,
  role,
) {
  final service = ref.watch(adminServiceProvider);
  return service.streamAdminsByRole(role);
});

// ===============================
// Admin Notifier
// ===============================
class AdminNotifier extends StateNotifier<AdminModel?> {
  final AdminService _service;

  AdminNotifier(this._service) : super(null);

  Future<String> createAdmin(AdminModel admin) async {
    final id = await _service.createAdmin(admin);
    state = admin;
    return id;
  }

  Future<void> updateAdmin(AdminModel admin) async {
    await _service.updateAdmin(admin);
    state = admin;
  }

  Future<void> deleteAdmin(String adminId) async {
    await _service.deleteAdmin(adminId);
    state = null;
  }

  Future<void> loadAdmin(String adminId) async {
    final admin = await _service.getAdmin(adminId);
    state = admin;
  }

  Future<void> updateRole(String adminId, String newRole) async {
    await _service.updateAdminRole(adminId, newRole);
  }

  Future<void> deactivateAdmin(String adminId) async {
    await _service.deactivateAdmin(adminId);
  }

  Future<void> activateAdmin(String adminId) async {
    await _service.activateAdmin(adminId);
  }
}

// ===============================
// Admin State Notifier Provider
// ===============================
final adminStateNotifierProvider =
    StateNotifierProvider<AdminNotifier, AdminModel?>((ref) {
      final service = ref.watch(adminServiceProvider);
      return AdminNotifier(service);
    });

// ===============================
// Selected Admin Provider
// ===============================
final selectedAdminProvider = StateProvider<AdminModel?>((ref) => null);
