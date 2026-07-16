import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/app_user_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../widgets/image_loader.dart';
import '../../equipment/presentation/equipment_details_page.dart';
import '../../equipment/presentation/equipment_form_page.dart';

class MyEquipmentsPage extends StatefulWidget {
  const MyEquipmentsPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  State<MyEquipmentsPage> createState() => _MyEquipmentsPageState();
}

class _MyEquipmentsPageState extends State<MyEquipmentsPage> {
  final MarketplaceService _service = MarketplaceService();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, available, hidden, borrowed, completed

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(l10n.tr('my_equipments_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'my_equipments_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EquipmentFormPage(
              ownerId: widget.currentUser.userId,
              ownerName: widget.currentUser.name,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Share an Item', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<MarketplaceEquipmentModel>>(
        stream: _service.watchEquipmentsByOwner(widget.currentUser.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.tr('error_occurred')));
          }

          final items = snapshot.data ?? const <MarketplaceEquipmentModel>[];

          // Apply filters
          final filtered = items.where((item) {
            final matchQuery = item.equipmentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.description.toLowerCase().contains(_searchQuery.toLowerCase());
            if (!matchQuery) return false;

            if (_statusFilter == 'available') {
              return item.status.toLowerCase() == 'published' || item.status.toLowerCase() == 'available';
            } else if (_statusFilter == 'hidden') {
              return item.status.toLowerCase() == 'hidden';
            } else if (_statusFilter == 'borrowed') {
              return item.status.toLowerCase() == 'borrowed';
            } else if (_statusFilter == 'completed') {
              return item.status.toLowerCase() == 'completed';
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Search & Filter controls
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search shared items',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color(0xFFF1F3F4),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Available', 'available'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Hidden', 'hidden'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Borrowed', 'borrowed'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final image = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEBEFF0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: image.isNotEmpty
                                      ? buildSmartImage(image, fit: BoxFit.cover)
                                      : const Icon(Icons.inventory, size: 32, color: Colors.grey),
                                ),
                              ),
                              title: Text(
                                item.equipmentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A)),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '📍 ${item.location} • Status: ${item.status}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EquipmentDetailsPage(
                                    equipment: item,
                                    userId: widget.currentUser.userId,
                                    userName: widget.currentUser.name,
                                    userEmail: widget.currentUser.email,
                                    userPhone: widget.currentUser.phoneNumber,
                                  ),
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                onSelected: (value) async {
                                  if (value == 'view') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EquipmentDetailsPage(
                                          equipment: item,
                                          userId: widget.currentUser.userId,
                                          userName: widget.currentUser.name,
                                          userEmail: widget.currentUser.email,
                                          userPhone: widget.currentUser.phoneNumber,
                                        ),
                                      ),
                                    );
                                  } else if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EquipmentFormPage(
                                          ownerId: widget.currentUser.userId,
                                          ownerName: widget.currentUser.name,
                                          existing: item,
                                        ),
                                      ),
                                    );
                                  } else if (value == 'pause') {
                                    final sm = ScaffoldMessenger.of(context);
                                    final newStatus = item.status.toLowerCase() == 'hidden' ? 'published' : 'hidden';
                                    await _service.updateEquipment(equipmentId: item.equipmentId, updates: {'status': newStatus});
                                    sm.showSnackBar(
                                      SnackBar(content: Text('Item is now $newStatus.')),
                                    );
                                  } else if (value == 'share') {
                                    // ignore: deprecated_member_use
                                    Share.share('Check out this shared item on Borrow: ${item.equipmentName}');
                                  } else if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: Text(l10n.tr('delete_equipment')),
                                        content: Text(l10n.tr('delete_equipment_confirm')),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text(l10n.tr('cancel'), style: const TextStyle(color: Color(0xFF6F7A6B))),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                            child: Text(l10n.tr('delete')),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await _service.deleteEquipment(item.equipmentId);
                                    }
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(value: 'view', child: Text(l10n.tr('equipment_details'))),
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                    value: 'pause',
                                    child: Text(item.status.toLowerCase() == 'hidden' ? 'Activate' : 'Pause'),
                                  ),
                                  const PopupMenuItem(value: 'share', child: Text('Share')),
                                  PopupMenuItem(value: 'delete', child: Text(l10n.tr('delete'), style: const TextStyle(color: Colors.red))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final active = _statusFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
      selected: active,
      onSelected: (sel) {
        if (sel) setState(() => _statusFilter = value);
      },
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: const Color(0xFFF1F3F4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No shared items yet.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Start sharing your books, farm equipment, or other resources with the community.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EquipmentFormPage(
                      ownerId: widget.currentUser.userId,
                      ownerName: widget.currentUser.name,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Share an Item'),
            ),
          ],
        ),
      ),
    );
  }
}
