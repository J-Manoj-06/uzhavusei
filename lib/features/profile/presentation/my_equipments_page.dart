import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/app_user_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../widgets/image_loader.dart';
import '../../equipment/presentation/equipment_details_page.dart';
import '../../equipment/presentation/equipment_form_page.dart';

class MyEquipmentsPage extends StatelessWidget {
  const MyEquipmentsPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = MarketplaceService();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('my_equipments_title')),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EquipmentFormPage(
              ownerId: currentUser.userId,
              ownerName: currentUser.name,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.tr('my_equipments')),
      ),
      body: StreamBuilder<List<MarketplaceEquipmentModel>>(
        stream: service.watchEquipmentsByOwner(currentUser.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.tr('error_occurred')));
          }

          final items = snapshot.data ?? const <MarketplaceEquipmentModel>[];
          if (items.isEmpty) {
            return Center(child: Text(l10n.tr('no_equipments')));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final item = items[index];
              final image = item.imageUrls.isNotEmpty
                  ? item.imageUrls.first
                  : 'assets/logo.jpg';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: buildSmartImage(image, fit: BoxFit.cover),
                    ),
                  ),
                  title: Text(item.equipmentName),
                  subtitle: Text(
                    '₹${item.pricePerDay.toStringAsFixed(0)} • ${item.location} • ${item.status}',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EquipmentDetailsPage(
                        equipment: item,
                        userId: currentUser.userId,
                        userName: currentUser.name,
                        userEmail: currentUser.email,
                        userPhone: currentUser.phoneNumber,
                      ),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EquipmentDetailsPage(
                              equipment: item,
                              userId: currentUser.userId,
                              userName: currentUser.name,
                              userEmail: currentUser.email,
                              userPhone: currentUser.phoneNumber,
                            ),
                          ),
                        );
                        return;
                      }

                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EquipmentFormPage(
                              ownerId: currentUser.userId,
                              ownerName: currentUser.name,
                              existing: item,
                            ),
                          ),
                        );
                        return;
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.tr('delete_equipment')),
                          content: Text(l10n.tr('delete_equipment_confirm')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.tr('cancel')),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(l10n.tr('delete')),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await service.deleteEquipment(item.equipmentId);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'view',
                          child: Text(l10n.tr('equipment_details'))),
                      PopupMenuItem(
                          value: 'edit', child: Text(l10n.tr('edit'))),
                      PopupMenuItem(
                          value: 'delete', child: Text(l10n.tr('delete'))),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}
