import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/app_user_model.dart';
import '../../../models/marketplace_booking_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/marketplace_service.dart';
import '../../../widgets/image_loader.dart';
import '../../equipment/presentation/equipment_form_page.dart';

class MarketplaceProfilePage extends StatelessWidget {
  const MarketplaceProfilePage({
    super.key,
    required this.currentUser,
    required this.authService,
  });

  final AppUserModel currentUser;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final service = MarketplaceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _userCard(currentUser),
          const SizedBox(height: 16),
          if (currentUser.isRenter) ...[
            _sectionTitle('My Equipments'),
            const SizedBox(height: 8),
            StreamBuilder<List<MarketplaceEquipmentModel>>(
              stream: service.watchEquipmentsByOwner(currentUser.userId),
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <MarketplaceEquipmentModel>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: [
                    if (items.isEmpty)
                      _inlineEmpty('No equipment added yet')
                    else
                      ...items.map((e) => _equipmentItem(context, e, service)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EquipmentFormPage(
                              ownerId: currentUser.userId,
                              ownerName: currentUser.name,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Equipment'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _sectionTitle('Bookings for My Equipment'),
            const SizedBox(height: 8),
            StreamBuilder<List<MarketplaceBookingModel>>(
              stream: service.watchOwnerBookings(currentUser.userId),
              builder: (context, snapshot) {
                final list = snapshot.data ?? const <MarketplaceBookingModel>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) return _inlineEmpty('No renter bookings yet');
                return Column(children: list.take(5).map(_bookingTile).toList());
              },
            ),
          ] else ...[
            _sectionTitle('My Current/Past Bookings'),
            const SizedBox(height: 8),
            StreamBuilder<List<MarketplaceBookingModel>>(
              stream: service.watchUserBookings(currentUser.userId),
              builder: (context, snapshot) {
                final list = snapshot.data ?? const <MarketplaceBookingModel>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) return _inlineEmpty('No bookings yet');
                return Column(children: list.map(_bookingTile).toList());
              },
            ),
            const SizedBox(height: 16),
            _sectionTitle('Saved Machines'),
            const SizedBox(height: 8),
            _inlineEmpty('Saved machines feature ready for integration'),
          ],
        ],
      ),
    );
  }

  Widget _userCard(AppUserModel user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE8F5E9),
            child: user.profileImage.trim().isNotEmpty
                ? ClipOval(child: buildSmartImage(user.profileImage, width: 60, height: 60))
                : const Icon(Icons.person, size: 32, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 10),
          Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(user.email),
          const SizedBox(height: 2),
          Text('Role: ${user.role.toUpperCase()}'),
        ],
      ),
    );
  }

  Widget _equipmentItem(
    BuildContext context,
    MarketplaceEquipmentModel item,
    MarketplaceService service,
  ) {
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: buildSmartImage(
              item.imageUrls.isEmpty ? 'assets/logo.jpg' : item.imageUrls.first,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(item.equipmentName),
        subtitle: Text('₹${item.pricePerDay.toStringAsFixed(0)}/day • ${item.location}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EquipmentFormPage(
                    ownerId: item.ownerId,
                    ownerName: item.ownerName,
                    existing: item,
                  ),
                ),
              );
              return;
            }
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Equipment'),
                content: const Text('Do you want to remove this equipment?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ),
            );
            if (confirm == true) {
              await service.deleteEquipment(item.equipmentId);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _bookingTile(MarketplaceBookingModel booking) {
    return Card(
      child: ListTile(
        title: Text(booking.equipmentName),
        subtitle: Text(
          '${DateFormat('dd MMM').format(booking.startDate)} - '
          '${DateFormat('dd MMM').format(booking.endDate)} • ${booking.location}',
        ),
        trailing: Text('₹${booking.totalPrice.toStringAsFixed(0)}'),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700));
  }

  Widget _inlineEmpty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
