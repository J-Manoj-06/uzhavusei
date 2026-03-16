import 'package:cloud_firestore/cloud_firestore.dart';

class MachineryModel {
  const MachineryModel({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.isActive,
  });

  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final double pricePerHour;
  final double pricePerDay;
  final bool isActive;

  factory MachineryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return MachineryModel(
      id: (data['machineryId'] ?? data['id'] ?? doc.id).toString(),
      name: (data['name'] ?? '').toString().trim().isEmpty
          ? 'Unnamed Machinery'
          : data['name'].toString(),
      category: (data['category'] ?? 'General').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      pricePerHour: _toDouble(data['pricePerHour']),
      pricePerDay: _toDouble(data['pricePerDay']),
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
