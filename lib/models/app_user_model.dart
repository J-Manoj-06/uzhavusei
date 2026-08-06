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
    String? fullNameStr,
    String? registerNumberStr,
    String? departmentStr,
    String? yearStr,
    String? collegeEmailStr,
    String? phoneStr,
    String? photoUrlStr,
    bool? profileCompletedBool,
    @Deprecated('Use selectedState instead') String? state,
    @Deprecated('No longer used') String? district,
    @Deprecated('No longer used') String? city,
  })  : _fullName = fullNameStr,
        _registerNumber = registerNumberStr,
        _department = departmentStr,
        _year = yearStr,
        _collegeEmail = collegeEmailStr,
        _phone = phoneStr,
        _photoUrl = photoUrlStr,
        _profileCompleted = profileCompletedBool,
        _state = state,
        _district = district,
        _city = city;

  final String userId;
  String get uid => userId;
  final String name;
  final String email;

  factory AppUserModel.empty(String uid, [String? email]) {
    return AppUserModel(
      userId: uid,
      name: 'User',
      email: email ?? '',
      role: 'user',
      phoneNumber: '',
      profileImage: '',
      language: 'en',
      createdAt: DateTime.now(),
      emailVerified: false,
      phoneVerified: false,
    );
  }
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

  final String? _fullName;
  final String? _registerNumber;
  final String? _department;
  final String? _year;
  final String? _collegeEmail;
  final String? _phone;
  final String? _photoUrl;
  final bool? _profileCompleted;

  final String? _state;
  final String? _district;
  final String? _city;

  // Student Profile Getters
  String get fullName {
    final fn = _fullName?.trim();
    if (fn != null && fn.isNotEmpty) return fn;
    final n = name.trim();
    return n.isNotEmpty ? n : 'Student';
  }

  String get registerNumber => _registerNumber ?? '';
  String get department => _department ?? '';
  String get year => _year ?? '';

  String get collegeEmail {
    final ce = _collegeEmail?.trim();
    if (ce != null && ce.isNotEmpty) return ce;
    return email;
  }

  String get phone {
    final ph = _phone?.trim();
    if (ph != null && ph.isNotEmpty) return ph;
    return phoneNumber;
  }

  String get photoUrl {
    final pu = _photoUrl?.trim();
    if (pu != null && pu.isNotEmpty) return pu;
    return profileImage;
  }

  bool get profileCompleted => _profileCompleted == true;

  bool get isProfileComplete =>
      profileCompleted &&
      fullName.trim().isNotEmpty &&
      registerNumber.trim().isNotEmpty &&
      department.trim().isNotEmpty &&
      year.trim().isNotEmpty &&
      collegeEmail.trim().isNotEmpty &&
      phone.trim().replaceAll(RegExp(r'\D'), '').length >= 10;

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
      userId: (data['uid'] ?? data['userId'] ?? doc.id).toString(),
      name: (data['fullName'] ?? data['name'] ?? 'User').toString(),
      email: (data['collegeEmail'] ?? data['email'] ?? '').toString(),
      role: (data['role'] ?? '').toString(),
      phoneNumber: (data['phone'] ?? data['phoneNumber'] ?? '').toString(),
      profileImage: (data['photoUrl'] ?? data['profileImage'] ?? '').toString(),
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
      fullNameStr: (data['fullName'] ?? data['name']) as String?,
      registerNumberStr: (data['registerNumber'] ?? data['regNo']) as String?,
      departmentStr: data['department'] as String?,
      yearStr: data['year'] as String?,
      collegeEmailStr: (data['collegeEmail'] ?? data['email']) as String?,
      phoneStr: (data['phone'] ?? data['phoneNumber']) as String?,
      photoUrlStr: (data['photoUrl'] ?? data['profileImage']) as String?,
      profileCompletedBool: data['profileCompleted'] == true,
      state: data['state'] as String?,
      district: data['district'] as String?,
      city: data['city'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': userId,
      'userId': userId,
      'fullName': fullName,
      'name': fullName,
      'registerNumber': registerNumber,
      'department': department,
      'year': year,
      'collegeEmail': collegeEmail,
      'email': collegeEmail,
      'phone': phone,
      'phoneNumber': phone,
      'photoUrl': photoUrl,
      'profileImage': photoUrl,
      'profileCompleted': profileCompleted,
      'role': role,
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
