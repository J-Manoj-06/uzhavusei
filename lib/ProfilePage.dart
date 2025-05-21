import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'providers/user_profile_provider.dart';

void main() {
  runApp(const ProfileApp());
}

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: ProfilePage());
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().loadProfileImage();
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        await context
            .read<UserProfileProvider>()
            .updateProfileImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking image')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = context.read<UserProfileProvider>();
      await provider.updateProfile({
        'name': provider.userData['name'],
        'location': provider.userData['location'],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  void _showNotificationCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => NotificationCenter(
          notifications:
              context.read<UserProfileProvider>().userData['notifications'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettings(),
              ),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (provider.userData['notifications']
                        .any((n) => !n['read']))
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: _showNotificationCenter,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 2));
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(provider),
                    const SizedBox(height: 24),
                    _buildStatsSection(provider),
                    const SizedBox(height: 24),
                    _buildEarningsSection(provider),
                    const SizedBox(height: 24),
                    _buildAchievementsSection(provider),
                    const SizedBox(height: 24),
                    _buildSettingsSection(),
                    const SizedBox(height: 24),
                    _buildActivitySection(provider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserProfileProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: provider.isEditing ? _pickImage : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: provider.profileImage != null
                        ? FileImage(provider.profileImage!)
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  ),
                  if (provider.isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (provider.isEditing)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: provider.userData['name'],
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        provider.userData['name'] = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: provider.userData['location'],
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        provider.userData['location'] = value;
                      },
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Text(
                    provider.userData['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.userData['location'],
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (provider.isEditing)
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save Changes'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => provider.toggleEditMode(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Edit Profile'),
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to login page
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(UserProfileProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Farm Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Farm Size',
                  provider.userData['farmSize'],
                  Icons.landscape,
                ),
                _buildStatItem(
                  'Equipment',
                  provider.userData['equipmentCount'],
                  Icons.agriculture,
                ),
                _buildStatItem(
                  'Rating',
                  provider.userData['rating'],
                  Icons.star,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSection(UserProfileProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings & Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Earnings',
                  provider.userData['totalEarnings'],
                  Icons.currency_rupee,
                ),
                _buildStatItem(
                  'Total Rentals',
                  provider.userData['totalRentals'],
                  Icons.local_shipping,
                ),
                _buildStatItem(
                  'Join Date',
                  provider.userData['joinDate'],
                  Icons.calendar_today,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            const Text(
              '75% of monthly target achieved',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(UserProfileProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.userData['achievements'].length,
              itemBuilder: (context, index) {
                final achievement = provider.userData['achievements'][index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: achievement['unlocked']
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievement['icon'],
                      color:
                          achievement['unlocked'] ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text(achievement['title']),
                  subtitle: Text(achievement['description']),
                  trailing: Icon(
                    achievement['unlocked'] ? Icons.check_circle : Icons.lock,
                    color: achievement['unlocked'] ? Colors.green : Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSettingsItem(
            'Personal Info',
            Icons.person,
            () => _showPersonalInfo(),
          ),
          _buildSettingsItem(
            'Farm Details',
            Icons.agriculture,
            () => _showFarmDetails(),
          ),
          _buildSettingsItem(
            'Documents',
            Icons.description,
            () => _showDocuments(),
          ),
          _buildSettingsItem(
            'Payment Methods',
            Icons.payment,
            () => _showPaymentMethods(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildActivitySection(UserProfileProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Show all activities
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.userData['recentActivity'].length,
              itemBuilder: (context, index) {
                final activity = provider.userData['recentActivity'][index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          _getActivityColor(activity['type']).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getActivityIcon(activity['type']),
                      color: _getActivityColor(activity['type']),
                    ),
                  ),
                  title: Text(activity['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity['description']),
                      Text(
                        activity['date'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    activity['amount'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'rental':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'rental':
        return Icons.local_shipping;
      case 'maintenance':
        return Icons.build;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.history;
    }
  }

  void _showPersonalInfo() {
    final provider = context.read<UserProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Name', provider.userData['name']),
                _buildInfoRow('Email', provider.userData['email']),
                _buildInfoRow('Phone', provider.userData['phone']),
                _buildInfoRow('Location', provider.userData['location']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showFarmDetails() {
    final provider = context.read<UserProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Farm Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFarmDetailCard(
                  'Soil Type',
                  provider.userData['farmDetails']['soilType'],
                  Icons.landscape,
                ),
                _buildFarmDetailCard(
                  'Crops',
                  provider.userData['farmDetails']['crops'].join(', '),
                  Icons.grass,
                ),
                _buildFarmDetailCard(
                  'Irrigation',
                  provider.userData['farmDetails']['irrigation'],
                  Icons.water_drop,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Equipment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      provider.userData['farmDetails']['equipment'].length,
                  itemBuilder: (context, index) {
                    final equipment =
                        provider.userData['farmDetails']['equipment'][index];
                    return ListTile(
                      leading: const Icon(Icons.agriculture),
                      title: Text(equipment['name']),
                      subtitle: Text('Count: ${equipment['count']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editEquipment(equipment),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _addNewEquipment(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Equipment'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDocuments() {
    final provider = context.read<UserProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Documents',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addNewDocument(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Document'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.userData['documents'].length,
                  itemBuilder: (context, index) {
                    final document = provider.userData['documents'][index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: document['status'] == 'Verified'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description,
                            color: document['status'] == 'Verified'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        title: Text(document['type']),
                        subtitle: Text('Status: ${document['status']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewDocument(document),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteDocument(document),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentMethods() {
    final provider = context.read<UserProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addNewPaymentMethod(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Method'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.userData['paymentMethods'].length,
                  itemBuilder: (context, index) {
                    final method = provider.userData['paymentMethods'][index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: method['default']
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getPaymentMethodIcon(method['type']),
                            color:
                                method['default'] ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(method['type']),
                        subtitle: Text(method['default'] ? 'Default' : ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!method['default'])
                              IconButton(
                                icon: const Icon(Icons.star),
                                onPressed: () =>
                                    _setDefaultPaymentMethod(method),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deletePaymentMethod(method),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFarmDetailCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editFarmDetail(title, value),
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String type) {
    switch (type.toLowerCase()) {
      case 'upi':
        return Icons.phone_android;
      case 'bank transfer':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  void _addNewDocument() async {
    final provider = context.read<UserProfileProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Aadhar Card', child: Text('Aadhar Card')),
                DropdownMenuItem(value: 'PAN Card', child: Text('PAN Card')),
                DropdownMenuItem(
                    value: 'Land Documents', child: Text('Land Documents')),
                DropdownMenuItem(
                    value: 'Bank Details', child: Text('Bank Details')),
                DropdownMenuItem(value: 'Insurance', child: Text('Insurance')),
              ],
              onChanged: (value) {
                // Handle document type selection
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 85,
                );
                if (image != null) {
                  // Handle image selection
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Document'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'type': 'Aadhar Card',
                'status': 'Pending',
                'uploadDate': DateTime.now().toString(),
              });
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await provider.addDocument(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error adding document')),
          );
        }
      }
    }
  }

  void _viewDocument(Map<String, dynamic> document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document['type']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.picture_as_pdf, size: 64),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Status', document['status']),
            _buildInfoRow('Upload Date', document['uploadDate']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(Map<String, dynamic> document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete ${document['type']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<UserProfileProvider>();
      try {
        provider.userData['documents'].remove(document);
        provider.notifyListeners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting document')),
          );
        }
      }
    }
  }

  void _editEquipment(Map<String, dynamic> equipment) async {
    final provider = context.read<UserProfileProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Equipment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: equipment['name'],
              decoration: const InputDecoration(
                labelText: 'Equipment Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                equipment['name'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: equipment['count'].toString(),
              decoration: const InputDecoration(
                labelText: 'Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                equipment['count'] = int.tryParse(value) ?? 0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, equipment),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final index = provider.userData['farmDetails']['equipment']
            .indexWhere((e) => e['name'] == equipment['name']);
        if (index != -1) {
          provider.userData['farmDetails']['equipment'][index] = result;
          provider.notifyListeners();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Equipment updated successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error updating equipment')),
          );
        }
      }
    }
  }

  void _addNewEquipment() async {
    final provider = context.read<UserProfileProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Equipment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Equipment Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': 'New Equipment',
                'count': 1,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        provider.userData['farmDetails']['equipment'].add(result);
        provider.notifyListeners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error adding equipment')),
          );
        }
      }
    }
  }

  void _editFarmDetail(String title, String value) async {
    final provider = context.read<UserProfileProvider>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        switch (title) {
          case 'Soil Type':
            provider.userData['farmDetails']['soilType'] = result;
            break;
          case 'Crops':
            provider.userData['farmDetails']['crops'] = result.split(', ');
            break;
          case 'Irrigation':
            provider.userData['farmDetails']['irrigation'] = result;
            break;
        }
        provider.notifyListeners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Farm detail updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error updating farm detail')),
          );
        }
      }
    }
  }

  void _addNewPaymentMethod() async {
    final provider = context.read<UserProfileProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Payment Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(
                    value: 'Bank Transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              ],
              onChanged: (value) {
                // Handle payment type selection
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Account Details',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'type': 'UPI',
                'default': false,
                'details': 'UPI ID: example@upi',
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await provider.addPaymentMethod(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment method added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error adding payment method')),
          );
        }
      }
    }
  }

  void _setDefaultPaymentMethod(Map<String, dynamic> method) async {
    final provider = context.read<UserProfileProvider>();
    try {
      for (var pm in provider.userData['paymentMethods']) {
        pm['default'] = pm['type'] == method['type'];
      }
      provider.notifyListeners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default payment method updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error updating default payment method')),
        );
      }
    }
  }

  void _deletePaymentMethod(Map<String, dynamic> method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete ${method['type']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<UserProfileProvider>();
      try {
        provider.userData['paymentMethods'].remove(method);
        provider.notifyListeners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Payment method deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting payment method')),
          );
        }
      }
    }
  }

  void _showSettings() {
    final provider = context.read<UserProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: Text(provider.selectedLanguage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageSelector(),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: provider.darkMode,
                    onChanged: (value) => provider.toggleDarkMode(),
                  ),
                ),
                const Divider(),
                const Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Privacy Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrivacySettings(),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notification Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showNotificationSettings(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final provider = context.read<UserProfileProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Language',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('English'),
            trailing: provider.selectedLanguage == 'English'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              provider.updateLanguage('English');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('हिंदी'),
            trailing: provider.selectedLanguage == 'हिंदी'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              provider.updateLanguage('हिंदी');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('தமிழ்'),
            trailing: provider.selectedLanguage == 'தமிழ்'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              provider.updateLanguage('தமிழ்');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('বাংলা'),
            trailing: provider.selectedLanguage == 'বাংলা'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              provider.updateLanguage('বাংলা');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('తెలుగు'),
            trailing: provider.selectedLanguage == 'తెలుగు'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              provider.updateLanguage('తెలుగు');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('मराठी'),
            trailing: provider.selectedLanguage == 'मराठी'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              provider.updateLanguage('मराठी');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('ગુજરાતી'),
            trailing: provider.selectedLanguage == 'ગુજરાતી'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              provider.updateLanguage('ગુજરાતી');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    final provider = context.read<UserProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Profile Visibility'),
                  subtitle: const Text('Control who can see your profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showProfileVisibilitySettings(),
                ),
                ListTile(
                  title: const Text('Location Sharing'),
                  subtitle: const Text('Manage location sharing preferences'),
                  trailing: Switch(
                    value: provider.userData['locationSharing'] ?? false,
                    onChanged: (value) {
                      provider.updateProfile({'locationSharing': value});
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Contact Information'),
                  subtitle:
                      const Text('Control who can see your contact details'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showContactPrivacySettings(),
                ),
                const Divider(),
                const Text(
                  'Data & Security',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ListTile(
                  title: const Text('Two-Factor Authentication'),
                  subtitle: const Text('Add an extra layer of security'),
                  trailing: Switch(
                    value: provider.userData['twoFactorAuth'] ?? false,
                    onChanged: (value) {
                      provider.updateProfile({'twoFactorAuth': value});
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Data Backup'),
                  subtitle: const Text('Backup your farm data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDataBackupSettings(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    final provider = context.read<UserProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Rental Requests'),
                  subtitle:
                      const Text('Get notified about new rental requests'),
                  trailing: Switch(
                    value: provider.userData['rentalNotifications'] ?? true,
                    onChanged: (value) {
                      provider.updateProfile({'rentalNotifications': value});
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Payment Updates'),
                  subtitle: const Text('Receive payment status updates'),
                  trailing: Switch(
                    value: provider.userData['paymentNotifications'] ?? true,
                    onChanged: (value) {
                      provider.updateProfile({'paymentNotifications': value});
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Maintenance Alerts'),
                  subtitle: const Text('Get maintenance reminders'),
                  trailing: Switch(
                    value:
                        provider.userData['maintenanceNotifications'] ?? true,
                    onChanged: (value) {
                      provider
                          .updateProfile({'maintenanceNotifications': value});
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Weather Updates'),
                  subtitle: const Text('Receive weather alerts for your farm'),
                  trailing: Switch(
                    value: provider.userData['weatherNotifications'] ?? true,
                    onChanged: (value) {
                      provider.updateProfile({'weatherNotifications': value});
                    },
                  ),
                ),
                const Divider(),
                const Text(
                  'Notification Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ListTile(
                  title: const Text('Sound'),
                  subtitle: const Text('Play sound for notifications'),
                  trailing: Switch(
                    value: provider.userData['notificationSound'] ?? true,
                    onChanged: (value) {
                      provider.updateProfile({'notificationSound': value});
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate for notifications'),
                  trailing: Switch(
                    value: provider.userData['notificationVibration'] ?? true,
                    onChanged: (value) {
                      provider.updateProfile({'notificationVibration': value});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileVisibilitySettings() {
    // Implement profile visibility settings
  }

  void _showContactPrivacySettings() {
    // Implement contact privacy settings
  }

  void _showDataBackupSettings() {
    // Implement data backup settings
  }
}

class NotificationCenter extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  const NotificationCenter({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context
                      .read<UserProfileProvider>()
                      .markAllNotificationsAsRead();
                },
                child: const Text('Mark all as read'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notification['read']
                        ? Colors.grey[200]
                        : Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications,
                    color:
                        notification['read'] ? Colors.grey[400] : Colors.green,
                  ),
                ),
                title: Text(notification['title']),
                subtitle: Text(notification['message']),
                trailing: Text(
                  notification['time'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  // Handle notification tap
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
