/// 🔹 Role Helper - Check permissions, manage access control
class RoleHelper {
  static const String roleAdmin = 'admin';
  static const String roleLawyer = 'lawyer';
  static const String roleClient = 'client';

  // Permission constants
  static const String permView = 'view';
  static const String permCreate = 'create';
  static const String permEdit = 'edit';
  static const String permDelete = 'delete';
  static const String permApprove = 'approve';
  static const String permManageUsers = 'manage_users';
  static const String permViewAnalytics = 'view_analytics';
  static const String permManageBilling = 'manage_billing';

  /// Check if user is admin
  static bool isAdmin(String? role) {
    return role?.toLowerCase() == roleAdmin;
  }

  /// Check if user is lawyer
  static bool isLawyer(String? role) {
    return role?.toLowerCase() == roleLawyer;
  }

  /// Check if user is client
  static bool isClient(String? role) {
    return role?.toLowerCase() == roleClient;
  }

  /// Check if user can access admin panel
  static bool canAccessAdmin(String? role) {
    return isAdmin(role);
  }

  /// Check if user can access lawyer dashboard
  static bool canAccessLawyerDashboard(String? role) {
    return isAdmin(role) || isLawyer(role);
  }

  /// Check if user can access client dashboard
  static bool canAccessClientDashboard(String? role) {
    return isClient(role);
  }

  /// Check if lawyer can edit case (own case only)
  static bool canLawyerEditCase(
    String? lawyerId,
    String? caseOwnerId,
    String? userRole,
  ) {
    if (isAdmin(userRole)) return true;
    if (!isLawyer(userRole)) return false;
    return lawyerId == caseOwnerId;
  }

  /// Check if client can edit document
  static bool canEditDocument(
    String? userId,
    String? documentOwnerId,
    String? userRole,
  ) {
    if (isAdmin(userRole)) return true;
    return userId == documentOwnerId;
  }

  /// Check if user can delete document
  static bool canDeleteDocument(
    String? userId,
    String? documentOwnerId,
    String? userRole,
  ) {
    if (isAdmin(userRole)) return true;
    if (isLawyer(userRole)) return userId == documentOwnerId;
    return false;
  }

  /// Check if user can view case
  static bool canViewCase(
    String? userId,
    String? caseOwnerId,
    String? clientId,
    String? userRole,
  ) {
    if (isAdmin(userRole)) return true;
    if (isLawyer(userRole)) return userId == caseOwnerId;
    if (isClient(userRole)) return userId == clientId;
    return false;
  }

  /// Check if user can manage billing
  static bool canManageBilling(String? role) {
    return isAdmin(role) || isLawyer(role);
  }

  /// Check if user can generate invoice
  static bool canGenerateInvoice(
    String? userId,
    String? lawyerId,
    String? userRole,
  ) {
    if (isAdmin(userRole)) return true;
    if (isLawyer(userRole)) return userId == lawyerId;
    return false;
  }

  /// Check if user can view analytics
  static bool canViewAnalytics(String? role) {
    return isAdmin(role) || isLawyer(role);
  }

  /// Check if user can approve cases
  static bool canApproveCases(String? role) {
    return isAdmin(role);
  }

  /// Check if user can manage users
  static bool canManageUsers(String? role) {
    return isAdmin(role);
  }

  /// Check if user has specific permission
  static bool hasPermission(String? userRole, String permission) {
    final role = userRole?.toLowerCase();

    if (role == roleAdmin) {
      // Admin has all permissions
      return true;
    }

    if (role == roleLawyer) {
      return switch (permission) {
        permView => true,
        permCreate => true,
        permEdit => true,
        permDelete => true,
        permViewAnalytics => true,
        permManageBilling => true,
        permApprove => false,
        permManageUsers => false,
        _ => false,
      };
    }

    if (role == roleClient) {
      return switch (permission) {
        permView => true,
        permCreate => false,
        permEdit => false,
        permDelete => false,
        _ => false,
      };
    }

    return false;
  }

  /// Get all permissions for role
  static List<String> getPermissions(String? userRole) {
    final role = userRole?.toLowerCase();

    if (role == roleAdmin) {
      return [
        permView,
        permCreate,
        permEdit,
        permDelete,
        permApprove,
        permManageUsers,
        permViewAnalytics,
        permManageBilling,
      ];
    }

    if (role == roleLawyer) {
      return [
        permView,
        permCreate,
        permEdit,
        permDelete,
        permViewAnalytics,
        permManageBilling,
      ];
    }

    if (role == roleClient) {
      return [permView];
    }

    return [];
  }

  /// Get display name for role
  static String getDisplayName(String? role) {
    return switch (role?.toLowerCase()) {
      'admin' => 'Administrator',
      'lawyer' => 'Lawyer',
      'client' => 'Client',
      _ => 'Unknown',
    };
  }

  /// Route based on role
  static String routeByRole(String? role) {
    return switch (role?.toLowerCase()) {
      'admin' => '/admin-dashboard',
      'lawyer' => '/lawyer-dashboard',
      'client' => '/client-dashboard',
      _ => '/login',
    };
  }

  /// Get list of available roles
  static List<String> getAvailableRoles() {
    return [roleAdmin, roleLawyer, roleClient];
  }

  /// Check if role is valid
  static bool isValidRole(String? role) {
    return getAvailableRoles().contains(role?.toLowerCase());
  }

  /// Check if user can assign role (only admin)
  static bool canAssignRole(String? userRole) {
    return isAdmin(userRole);
  }

  /// Check if user can change password for another user
  static bool canChangeUserPassword(
    String? userId,
    String? targetUserId,
    String? userRole,
  ) {
    if (isAdmin(userRole)) return true;
    return userId == targetUserId;
  }

  /// Get role permissions matrix
  static Map<String, List<String>> getRolePermissionsMatrix() {
    return {
      roleAdmin: getPermissions(roleAdmin),
      roleLawyer: getPermissions(roleLawyer),
      roleClient: getPermissions(roleClient),
    };
  }
}
