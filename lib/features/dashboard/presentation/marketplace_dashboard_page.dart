import 'package:flutter/material.dart';

import '../../../models/app_user_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../widgets/image_loader.dart';
import '../../equipment/presentation/equipment_details_page.dart';
import '../../equipment/presentation/equipment_form_page.dart';

class MarketplaceDashboardPage extends StatefulWidget {
  const MarketplaceDashboardPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  State<MarketplaceDashboardPage> createState() => _MarketplaceDashboardPageState();
}

class _MarketplaceDashboardPageState extends State<MarketplaceDashboardPage> {
  final _service = MarketplaceService();
  String _search = '';
  MarketplaceFilter _filter = const MarketplaceFilter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openFilter,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEquipmentForm,
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Equipment'),
      ),
      body: StreamBuilder<List<MarketplaceEquipmentModel>>(
        stream: _service.watchEquipments(
          category: _filter.category,
          onlyAvailable: _filter.onlyAvailable,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load equipment: ${snapshot.error}'));
          }

          final items = _applyFilter(snapshot.data ?? const []);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, category, location',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _search = value.trim();
                    });
                  },
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final equipment = items[index];
                          return _EquipmentCard(
                            equipment: equipment,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EquipmentDetailsPage(
                                    equipment: equipment,
                                    userId: widget.currentUser.userId,
                                    userName: widget.currentUser.name,
                                    userEmail: widget.currentUser.email,
                                    userPhone: widget.currentUser.phoneNumber,
                                  ),
                                ),
                              );
                            },
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.agriculture_rounded, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No equipment found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing search or filters.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  List<MarketplaceEquipmentModel> _applyFilter(List<MarketplaceEquipmentModel> src) {
    final query = _search.toLowerCase();
    return src.where((item) {
      final matchSearch = query.isEmpty ||
          item.equipmentName.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query);

      final matchPrice = item.pricePerDay >= _filter.minPrice &&
          item.pricePerDay <= _filter.maxPrice;

      final matchRating = item.rating >= _filter.minRating;

      return matchSearch && matchPrice && matchRating;
    }).toList(growable: false);
  }

  Future<void> _openFilter() async {
    final result = await showModalBottomSheet<MarketplaceFilter>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _FilterSheet(initial: _filter),
    );

    if (result == null) return;
    setState(() {
      _filter = result;
    });
  }

  Future<void> _openAddEquipmentForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentFormPage(
          ownerId: widget.currentUser.userId,
          ownerName: widget.currentUser.name,
        ),
      ),
    );

    if (!mounted || created != true) return;
    setState(() {});
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.equipment, required this.onTap});

  final MarketplaceEquipmentModel equipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: buildSmartImage(
                  equipment.imageUrls.isEmpty ? 'assets/logo.jpg' : equipment.imageUrls.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.equipmentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    equipment.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${equipment.pricePerHour.toStringAsFixed(0)}/hr',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          equipment.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                        ),
                      ),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      Text(
                        equipment.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketplaceFilter {
  const MarketplaceFilter({
    this.category = 'All',
    this.minPrice = 0,
    this.maxPrice = 100000,
    this.minRating = 0,
    this.onlyAvailable = true,
  });

  final String category;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final bool onlyAvailable;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final MarketplaceFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const _categories = [
    'All',
    'Tractor',
    'Harvester',
    'Rotavator',
    'Sprayer',
    'Tiller',
  ];

  late String _category;
  late RangeValues _price;
  late double _rating;
  late bool _onlyAvailable;

  @override
  void initState() {
    super.initState();
    _category = widget.initial.category;
    _price = RangeValues(widget.initial.minPrice, widget.initial.maxPrice);
    _rating = widget.initial.minRating;
    _onlyAvailable = widget.initial.onlyAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _category = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Text('Price range: ₹${_price.start.toStringAsFixed(0)} - ₹${_price.end.toStringAsFixed(0)}'),
            RangeSlider(
              values: _price,
              min: 0,
              max: 100000,
              divisions: 100,
              labels: RangeLabels(
                _price.start.toStringAsFixed(0),
                _price.end.toStringAsFixed(0),
              ),
              onChanged: (v) {
                setState(() {
                  _price = v;
                });
              },
            ),
            const SizedBox(height: 6),
            Text('Minimum rating: ${_rating.toStringAsFixed(1)}'),
            Slider(
              value: _rating,
              min: 0,
              max: 5,
              divisions: 10,
              label: _rating.toStringAsFixed(1),
              onChanged: (v) {
                setState(() {
                  _rating = v;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Only available equipment'),
              value: _onlyAvailable,
              onChanged: (v) {
                setState(() {
                  _onlyAvailable = v;
                });
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    MarketplaceFilter(
                      category: _category,
                      minPrice: _price.start,
                      maxPrice: _price.end,
                      minRating: _rating,
                      onlyAvailable: _onlyAvailable,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
