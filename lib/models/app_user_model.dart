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
    this.latitude,
    this.longitude,
  });

  final String userId;
  final String name;
  final String email;
  final String role;
  final String phoneNumber;
  final String profileImage;
  final String language;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

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
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
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
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
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
