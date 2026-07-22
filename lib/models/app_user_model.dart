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
    this.selectedState,
    this.locationUpdatedAt,
    this.accuracy,
    this.username,
    this.bio,
    this.preferredCategories,
    this.listingCategories,
    this.notificationsEnabled,
    @Deprecated('Use selectedState instead') String? state,
    @Deprecated('No longer used') String? district,
    @Deprecated('No longer used') String? city,
  }) : _state = state, _district = district, _city = city;

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
  final String? selectedState;
  final DateTime? locationUpdatedAt;
  final double? accuracy;
  final String? username;
  final String? bio;
  final List<String>? preferredCategories;
  final List<String>? listingCategories;
  final Map<String, bool>? notificationsEnabled;

  final String? _state;
  final String? _district;
  final String? _city;

  // Backwards compatibility getters
  String? get state => selectedState ?? _state;
  String? get district => _district;
  String? get city => _city;

  factory AppUserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    
    Map<String, bool>? parsedNotifications;
    if (data['notificationsEnabled'] is Map) {
      parsedNotifications = (data['notificationsEnabled'] as Map).map(
        (key, value) => MapEntry(key.toString(), value == true),
      );
    }

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
      selectedState: data['selectedState'] as String? ?? data['state'] as String?,
      locationUpdatedAt: data['locationUpdatedAt'] != null ? _toDate(data['locationUpdatedAt']) : null,
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      username: data['username'] as String?,
      bio: data['bio'] as String?,
      preferredCategories: (data['preferredCategories'] as List?)?.map((e) => e.toString()).toList(),
      listingCategories: (data['listingCategories'] as List?)?.map((e) => e.toString()).toList(),
      notificationsEnabled: parsedNotifications,
      state: data['state'] as String?,
      district: data['district'] as String?,
      city: data['city'] as String?,
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
      if (selectedState != null) 'selectedState': selectedState,
      if (locationUpdatedAt != null) 'locationUpdatedAt': Timestamp.fromDate(locationUpdatedAt!),
      if (accuracy != null) 'accuracy': accuracy,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (preferredCategories != null) 'preferredCategories': preferredCategories,
      if (listingCategories != null) 'listingCategories': listingCategories,
      if (notificationsEnabled != null) 'notificationsEnabled': notificationsEnabled,
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
