import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, lawyer, client }

class AppUserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final Timestamp createdAt;

  const AppUserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  /// --------------------------
  /// From Firestore
  /// --------------------------
  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: _mapRole(json['role']),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? json['createdAt']
          : Timestamp.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
    );
  }

  /// --------------------------
  /// To Firestore
  /// --------------------------
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name, // admin / lawyer / client
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  /// --------------------------
  /// CopyWith
  /// --------------------------
  AppUserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    bool? isActive,
    Timestamp? createdAt,
  }) {
    return AppUserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// --------------------------
  /// Helpers
  /// --------------------------
  static UserRole _mapRole(dynamic value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'lawyer':
        return UserRole.lawyer;
      default:
        return UserRole.client;
    }
  }
}
