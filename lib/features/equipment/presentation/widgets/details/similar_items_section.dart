import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'package:UzhavuSei/services/marketplace_service.dart';
import 'package:UzhavuSei/widgets/image_loader.dart';
import 'package:UzhavuSei/features/equipment/presentation/equipment_details_page.dart';
import 'details_theme.dart';

class SimilarItemsSection extends StatelessWidget {
  const SimilarItemsSection({
    super.key,
    required this.equipment,
    required this.category,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  });

  final MarketplaceEquipmentModel equipment;
  final String category;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;

  @override
  Widget build(BuildContext context) {
    final MarketplaceService service = MarketplaceService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
          child: Text(
            'Similar Listings',
            style: DetailsTheme.sectionHeadingStyle,
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 220,
          child: StreamBuilder<List<MarketplaceEquipmentModel>>(
            stream: service.watchRelatedEquipment(
              category: category,
              currentEquipmentId: equipment.equipmentId,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No similar listings found.',
                    style: DetailsTheme.captionStyle,
                  ),
                );
              }

              final items = snapshot.data!.take(10).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: DetailsTheme.outerPadding,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildSimilarItemCard(context, item);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarItemCard(
      BuildContext context, MarketplaceEquipmentModel item) {
    final image =
        item.imageUrls.isNotEmpty ? item.imageUrls.first : 'assets/logo.jpg';

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: DetailsTheme.cardSpacing),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        border: Border.all(color: DetailsTheme.border),
        boxShadow: DetailsTheme.cardShadow,
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EquipmentDetailsPage(
                equipment: item,
                userId: userId,
                userName: userName,
                userEmail: userEmail,
                userPhone: userPhone,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DetailsTheme.cardRadius),
              ),
              child: SizedBox(
                height: 105,
                width: 160,
                child: buildSmartImage(image, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.equipmentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: DetailsTheme.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        item.rating > 0
                            ? item.rating.toStringAsFixed(1)
                            : 'New',
                        style: DetailsTheme.captionStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.availability
                          ? DetailsTheme.primaryContainer
                          : const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.availability ? 'Available' : 'On Loan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: item.availability
                            ? DetailsTheme.primary
                            : Colors.orange.shade900,
                      ),
                    ),
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
