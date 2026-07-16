import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  const AppUserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.profileImage,
    required this.language,
    required this.createdAt,
    required this.emailVerified,
    required this.phoneVerified,
    this.latitude,
    this.longitude,
    this.landArea,
    this.serviceRange,
    this.primaryCrops,
    this.state,
    this.district,
    this.village,
    this.landType,
    this.ownedEquipment,
    this.preferredServices,
    this.username,
    this.bio,
  });

  final String userId;
  final String name;
  final String email;
  final String role;
  final String phoneNumber;
  final String profileImage;
  final String language;
  final DateTime createdAt;
  final bool emailVerified;
  final bool phoneVerified;
  final double? latitude;
  final double? longitude;
  final String? landArea;
  final String? serviceRange;
  final String? primaryCrops;
  final String? state;
  final String? district;
  final String? village;
  final String? landType;
  final List<String>? ownedEquipment;
  final List<String>? preferredServices;
  final String? username;
  final String? bio;

  bool get isRenter =>
      role.toLowerCase() == 'renter' || role.toLowerCase() == 'owner';
  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isFarmer => role.toLowerCase() == 'farmer';

  factory AppUserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUserModel(
      userId: (data['userId'] ?? doc.id).toString(),
      name: (data['name'] ?? 'User').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? '').toString(),
      profileImage: (data['profileImage'] ?? '').toString(),
      language: (data['language'] ?? 'en').toString(),
      createdAt: _toDate(data['createdAt']),
      emailVerified: data['emailVerified'] == true,
      phoneVerified: data['phoneVerified'] == true,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      landArea: data['landArea'] as String?,
      serviceRange: data['serviceRange'] as String?,
      primaryCrops: data['primaryCrops'] as String?,
      state: data['state'] as String?,
      district: data['district'] as String?,
      village: data['village'] as String?,
      landType: data['landType'] as String?,
      ownedEquipment: (data['ownedEquipment'] as List?)?.map((e) => e.toString()).toList(),
      preferredServices: (data['preferredServices'] as List?)?.map((e) => e.toString()).toList(),
      username: data['username'] as String?,
      bio: data['bio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'language': language,
      'createdAt': Timestamp.fromDate(createdAt),
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (landArea != null) 'landArea': landArea,
      if (serviceRange != null) 'serviceRange': serviceRange,
      if (primaryCrops != null) 'primaryCrops': primaryCrops,
      if (state != null) 'state': state,
      if (district != null) 'district': district,
      if (village != null) 'village': village,
      if (landType != null) 'landType': landType,
      if (ownedEquipment != null) 'ownedEquipment': ownedEquipment,
      if (preferredServices != null) 'preferredServices': preferredServices,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
    };
  }
}

DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.now();
}
