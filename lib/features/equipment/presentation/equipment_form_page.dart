import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/marketplace_equipment_model.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/marketplace_service.dart';
import '../../location/presentation/location_picker_page.dart';

class EquipmentFormPage extends StatefulWidget {
  const EquipmentFormPage({
    super.key,
    required this.ownerId,
    required this.ownerName,
    this.existing,
  });

  final String ownerId;
  final String ownerName;
  final MarketplaceEquipmentModel? existing;

  @override
  State<EquipmentFormPage> createState() => _EquipmentFormPageState();
}

class _EquipmentFormPageState extends State<EquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = MarketplaceService();
  final _cloudinary = CloudinaryService();

  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _priceHour;
  late final TextEditingController _priceDay;
  late final TextEditingController _specs;

  String _address = '';
  double _lat = 0;
  double _lng = 0;
  bool _availability = true;
  bool _saving = false;

  final List<File> _newImages = [];
  final List<String> _existingImages = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.equipmentName ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _priceHour = TextEditingController(text: e == null ? '' : '${e.pricePerHour}');
    _priceDay = TextEditingController(text: e == null ? '' : '${e.pricePerDay}');
    _specs = TextEditingController(text: e?.machineSpecs ?? '');
    _address = e?.location ?? '';
    _lat = e?.latitude ?? 0;
    _lng = e?.longitude ?? 0;
    _availability = e?.availability ?? true;
    if (e != null) {
      _existingImages.addAll(e.imageUrls);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _priceHour.dispose();
    _priceDay.dispose();
    _specs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Equipment' : 'Add Equipment'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Equipment Name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 2,
              maxLines: 4,
              validator: _required,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceHour,
                    decoration: const InputDecoration(labelText: 'Price / hour'),
                    keyboardType: TextInputType.number,
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceDay,
                    decoration: const InputDecoration(labelText: 'Price / day'),
                    keyboardType: TextInputType.number,
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _specs,
              decoration: const InputDecoration(labelText: 'Machine Specifications'),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_address.isEmpty ? 'Pick Location' : _address),
              subtitle: Text('Lat: ${_lat.toStringAsFixed(4)}, Lng: ${_lng.toStringAsFixed(4)}'),
              trailing: const Icon(Icons.location_on),
              onTap: _pickLocation,
            ),
            SwitchListTile(
              title: const Text('Available for booking'),
              value: _availability,
              onChanged: (v) {
                setState(() {
                  _availability = v;
                });
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._existingImages.map(
                  (url) => Stack(
                    children: [
                      Image.network(url, width: 88, height: 88, fit: BoxFit.cover),
                      Positioned(
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _existingImages.remove(url);
                            });
                          },
                          child: const CircleAvatar(radius: 10, child: Icon(Icons.close, size: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._newImages.map(
                  (file) => Stack(
                    children: [
                      Image.file(file, width: 88, height: 88, fit: BoxFit.cover),
                      Positioned(
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _newImages.remove(file);
                            });
                          },
                          child: const CircleAvatar(radius: 10, child: Icon(Icons.close, size: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Images'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_saving ? 'Saving...' : (isEdit ? 'Update' : 'Create')), 
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() {
      _newImages.addAll(picked.map((e) => File(e.path)));
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initialLatLng: (_lat == 0 && _lng == 0) ? null : null,
          initialAddress: _address,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _lat = result.latitude;
      _lng = result.longitude;
      _address = result.address;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose location')), 
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final uploaded = _newImages.isEmpty
          ? <String>[]
          : await _cloudinary.uploadImages(_newImages);
      final images = [..._existingImages, ...uploaded];

      final payload = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.ownerId,
        equipmentName: _name.text.trim(),
        category: _category.text.trim(),
        description: _description.text.trim(),
        pricePerHour: double.tryParse(_priceHour.text.trim()) ?? 0,
        pricePerDay: double.tryParse(_priceDay.text.trim()) ?? 0,
        location: _address,
        latitude: _lat,
        longitude: _lng,
        imageUrls: images,
        availability: _availability,
        rating: widget.existing?.rating ?? 0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        ownerName: widget.ownerName,
        machineSpecs: _specs.text.trim(),
      );

      if (widget.existing == null) {
        await _service.addEquipment(payload);
      } else {
        await _service.updateEquipment(
          equipmentId: widget.existing!.equipmentId,
          updates: payload.toMap(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save equipment: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
