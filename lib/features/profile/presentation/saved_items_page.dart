import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/app_user_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../widgets/image_loader.dart';
import '../../equipment/presentation/equipment_details_page.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage> {
  final MarketplaceService _service = MarketplaceService();
  String _searchQuery = '';
  String _categoryFilter = 'all'; // all, books, farm, construction

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<MarketplaceEquipmentModel>>(
        stream: _service.watchSavedEquipments(widget.currentUser.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load saved items.'));
          }

          final items = snapshot.data ?? [];

          // Apply filters
          final filtered = items.where((item) {
            final matchQuery = item.equipmentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.description.toLowerCase().contains(_searchQuery.toLowerCase());
            if (!matchQuery) return false;

            if (_categoryFilter == 'books') {
              return item.category.toLowerCase().contains('book');
            } else if (_categoryFilter == 'farm') {
              return item.category.toLowerCase().contains('farm') || item.category.toLowerCase().contains('agri');
            } else if (_categoryFilter == 'construction') {
              return item.category.toLowerCase().contains('construct') || item.category.toLowerCase().contains('tool');
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
                        hintText: 'Search saved items',
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
                        _buildFilterChip('Books', 'books'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Farm Equipment', 'farm'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Construction', 'construction'),
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
                                      : const Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                                ),
                              ),
                              title: Text(
                                item.equipmentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '📍 ${item.location} • ${item.category}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ),
                              onTap: () {
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
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.primary),
                                    onPressed: () {
                                      // ignore: deprecated_member_use
                                      Share.share('Check out this shared item on Borrow: ${item.equipmentName}');
                                    },
                                    tooltip: 'Share',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.favorite, size: 20, color: Colors.red),
                                    onPressed: () async {
                                      final sm = ScaffoldMessenger.of(context);
                                      await _service.toggleSaveEquipment(widget.currentUser.userId, item.equipmentId);
                                      sm.showSnackBar(
                                        const SnackBar(
                                          content: Text('Removed from wishlist'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    tooltip: 'Remove',
                                  ),
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
    final active = _categoryFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
      selected: active,
      onSelected: (sel) {
        if (sel) setState(() => _categoryFilter = value);
      },
      selectedColor: AppColors.primary,
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
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No saved resources.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse available resources and tap the heart icon to save them for later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // back to profile / home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Browse Resources'),
            ),
          ],
        ),
      ),
    );
  }
}
