import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserProfileProvider extends ChangeNotifier {
  Map<String, dynamic> _userData = {
    'name': 'Rajesh Kumar',
    'location': 'Chennai, Tamil Nadu',
    'phone': '+91 98765 43210',
    'email': 'rajesh.kumar@example.com',
    'farmSize': '25 acres',
    'equipmentCount': '5 machines',
    'rating': '4.8',
    'totalRentals': '89',
    'totalEarnings': '₹2,45,000',
    'verificationStatus': 'Verified',
    'joinDate': '2023-01-15',
    'farmDetails': {
      'soilType': 'Alluvial',
      'crops': ['Rice', 'Wheat', 'Sugarcane'],
      'irrigation': 'Drip Irrigation',
      'equipment': [
        {'name': 'Tractor', 'count': 2},
        {'name': 'Harvester', 'count': 1},
        {'name': 'Seeder', 'count': 2},
      ],
    },
    'documents': [
      {'type': 'Aadhar Card', 'status': 'Verified'},
      {'type': 'Land Documents', 'status': 'Verified'},
      {'type': 'Bank Details', 'status': 'Verified'},
    ],
    'paymentMethods': [
      {'type': 'UPI', 'default': true},
      {'type': 'Bank Transfer', 'default': false},
    ],
    'notifications': [
      {
        'title': 'Payment Received',
        'message': '₹4,500 received for John Deere Tractor rental',
        'time': '2 hours ago',
        'read': false,
        'type': 'payment',
      },
      {
        'title': 'New Rental Request',
        'message': 'Suresh requested your Mahindra Harvester',
        'time': '1 day ago',
        'read': true,
        'type': 'rental',
      },
      {
        'title': 'Rating Updated',
        'message': 'You received a 5-star rating from Amit',
        'time': '2 days ago',
        'read': true,
        'type': 'rating',
      },
    ],
    'recentActivity': [
      {
        'type': 'rental',
        'title': 'Tractor Rented',
        'description': 'John Deere 5050D rented to Ramesh',
        'date': '2024-03-15',
        'amount': '₹2,500',
      },
      {
        'type': 'maintenance',
        'title': 'Maintenance Completed',
        'description': 'Regular service completed for Mahindra Harvester',
        'date': '2024-03-14',
        'amount': '₹1,200',
      },
      {
        'type': 'payment',
        'title': 'Payment Received',
        'description': 'Received payment for tractor rental',
        'date': '2024-03-13',
        'amount': '₹3,000',
      },
    ],
    'achievements': [
      {
        'title': 'First Rental',
        'description': 'Completed your first equipment rental',
        'icon': Icons.star,
        'unlocked': true,
      },
      {
        'title': 'Top Rated',
        'description': 'Maintained 4.5+ rating for 3 months',
        'icon': Icons.emoji_events,
        'unlocked': true,
      },
      {
        'title': 'Equipment Master',
        'description': 'Listed 5 different types of equipment',
        'icon': Icons.construction,
        'unlocked': false,
      },
    ],
  };

  bool _isLoading = false;
  bool _isEditing = false;
  File? _profileImage;
  String _selectedLanguage = 'English';
  bool _darkMode = false;

  Map<String, dynamic> get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  File? get profileImage => _profileImage;
  String get selectedLanguage => _selectedLanguage;
  bool get darkMode => _darkMode;

  Future<void> updateProfile(Map<String, dynamic> newData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      _userData = {..._userData, ...newData};
      _isEditing = false;
    } catch (e) {
      debugPrint('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleEditMode() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  Future<void> updateProfileImage(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profile_image.jpg');
      await file.writeAsBytes(await image.readAsBytes());
      _profileImage = file;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile image: $e');
    }
  }

  Future<void> loadProfileImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profile_image.jpg');
      if (await file.exists()) {
        _profileImage = file;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  void markAllNotificationsAsRead() {
    for (var notification in _userData['notifications']) {
      notification['read'] = true;
    }
    notifyListeners();
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  void updateLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  Future<void> addDocument(Map<String, dynamic> document) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _userData['documents'].add(document);
    } catch (e) {
      debugPrint('Error adding document: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPaymentMethod(Map<String, dynamic> paymentMethod) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _userData['paymentMethods'].add(paymentMethod);
    } catch (e) {
      debugPrint('Error adding payment method: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFarmDetails(Map<String, dynamic> details) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _userData['farmDetails'] = {..._userData['farmDetails'], ...details};
    } catch (e) {
      debugPrint('Error updating farm details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
