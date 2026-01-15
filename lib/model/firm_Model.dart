import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Firm / Organization Model
/// For managing law firm information and settings
class FirmModel {
  final String firmId;
  final String ownerLawyerId; // Primary lawyer/owner
  final String firmName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String country;
  final List<String> lawyerIds; // All lawyers in firm
  final List<String> staffIds; // All staff in firm
  final String? registrationNumber;
  final DateTime? registeredAt;
  final bool isActive;
  final String? logo; // URL to firm logo
  final String? website;
  final Map<String, dynamic>? billingSettings; // Hours rate, etc
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FirmModel({
    required this.firmId,
    required this.ownerLawyerId,
    required this.firmName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    this.lawyerIds = const [],
    this.staffIds = const [],
    this.registrationNumber,
    this.registeredAt,
    this.isActive = true,
    this.logo,
    this.website,
    this.billingSettings,
    required this.createdAt,
    this.updatedAt,
  });

  /// ===============================
  /// Firestore → Model
  /// ===============================
  factory FirmModel.fromJson(Map<String, dynamic> json) {
    return FirmModel(
      firmId: json['firmId'] ?? '',
      ownerLawyerId: json['ownerLawyerId'] ?? '',
      firmName: json['firmName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      lawyerIds: List<String>.from(json['lawyerIds'] ?? []),
      staffIds: List<String>.from(json['staffIds'] ?? []),
      registrationNumber: json['registrationNumber'],
      registeredAt: json['registeredAt'] is Timestamp
          ? (json['registeredAt'] as Timestamp).toDate()
          : null,
      isActive: json['isActive'] ?? true,
      logo: json['logo'],
      website: json['website'],
      billingSettings: json['billingSettings'] != null
          ? Map<String, dynamic>.from(json['billingSettings'])
          : null,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// ===============================
  /// Model → Firestore
  /// ===============================
  Map<String, dynamic> toJson() {
    return {
      'firmId': firmId,
      'ownerLawyerId': ownerLawyerId,
      'firmName': firmName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'lawyerIds': lawyerIds,
      'staffIds': staffIds,
      'registrationNumber': registrationNumber,
      'registeredAt': registeredAt != null
          ? Timestamp.fromDate(registeredAt!)
          : null,
      'isActive': isActive,
      'logo': logo,
      'website': website,
      'billingSettings': billingSettings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// ===============================
  /// CopyWith
  /// ===============================
  FirmModel copyWith({
    String? firmName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    List<String>? lawyerIds,
    List<String>? staffIds,
    bool? isActive,
    String? logo,
    String? website,
    Map<String, dynamic>? billingSettings,
    DateTime? updatedAt,
  }) {
    return FirmModel(
      firmId: firmId,
      ownerLawyerId: ownerLawyerId,
      firmName: firmName ?? this.firmName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      lawyerIds: lawyerIds ?? this.lawyerIds,
      staffIds: staffIds ?? this.staffIds,
      registrationNumber: registrationNumber,
      registeredAt: registeredAt,
      isActive: isActive ?? this.isActive,
      logo: logo ?? this.logo,
      website: website ?? this.website,
      billingSettings: billingSettings ?? this.billingSettings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
