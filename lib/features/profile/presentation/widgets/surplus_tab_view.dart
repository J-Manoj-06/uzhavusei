import 'package:flutter/material.dart';
import '../../../../../models/app_user_model.dart';
import '../../../../../models/farm_surplus_exchange_model.dart';
import '../../../../../services/marketplace_service.dart';
import '../../../surplus/presentation/farm_exchange_form_page.dart';
import 'surplus_listing_card.dart';

class SurplusTabView extends StatefulWidget {
  const SurplusTabView({super.key, required this.currentUser});
  final AppUserModel currentUser;

  @override
  State<SurplusTabView> createState() => _SurplusTabViewState();
}

class _SurplusTabViewState extends State<SurplusTabView> {
  final MarketplaceService _service = MarketplaceService();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Active',
    'Sold',
    'Exchanged',
    'Community Giveaway',
    'Expired'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-filters
        Container(
          height: 50,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = filter == _selectedFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = filter);
                  },
                  selectedColor: const Color(0xFF006E1C),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF3F4A3C),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: const Color(0xFFEDEEED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                ),
              );
            },
          ),
        ),
        
        // List Stream
        Expanded(
          child: StreamBuilder<List<FarmSurplusExchangeModel>>(
            stream: _service.watchExchangesByOwner(widget.currentUser.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading surplus listings.'));
              }

              var items = snapshot.data ?? <FarmSurplusExchangeModel>[];

              // Filter logic
              if (_selectedFilter != 'All') {
                items = items.where((e) {
                  final status = e.status.toLowerCase();
                  final type = e.listingType.toLowerCase();
                  
                  switch (_selectedFilter) {
                    case 'Active': return status == 'available';
                    case 'Sold': return status == 'sold';
                    case 'Exchanged': return status == 'exchanged';
                    case 'Community Giveaway': return type == 'donate';
                    case 'Expired': return status == 'expired';
                    default: return true;
                  }
                }).toList();
              }

              if (items.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return SurplusListingCard(
                    surplus: item,
                    onTap: () {
                      // Navigate to details
                    },
                    onEdit: () => _editSurplus(item),
                    onDelete: () => _confirmDelete(item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Center(
              child: Text('🌱', style: TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No surplus resources listed.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share or exchange unused seeds, fertilizers,\nand pesticides with nearby farmers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6F7A6B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FarmExchangeFormPage(
                    ownerId: widget.currentUser.userId,
                    ownerName: widget.currentUser.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Share Surplus'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF006E1C),
              side: const BorderSide(color: Color(0xFF006E1C), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  void _editSurplus(FarmSurplusExchangeModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FarmExchangeFormPage(
          ownerId: widget.currentUser.userId,
          ownerName: widget.currentUser.name,
          existing: item,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FarmSurplusExchangeModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: const Text('Are you sure you want to delete this surplus listing? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6F7A6B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteExchange(item.exchangeId);
    }
  }
}
