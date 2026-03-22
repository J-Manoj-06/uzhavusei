import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  static const List<String> _categories = <String>[
    'Seeder',
    'Tractor',
    'Harvester',
    'Sprayer',
    'Rotavator',
    'Cultivator',
    'Plough',
    'Pump',
    'Other',
  ];

  static const List<String> _conditions = <String>[
    'New',
    'Good',
    'Used',
  ];

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _minDuration;
  late final TextEditingController _tagInput;

  String? _selectedCategory;
  String _selectedCondition = 'Good';
  String _priceType = 'hour';
  String _minDurationType = 'hours';
  String _status = 'published';

  DateTime? _availabilityFrom;
  DateTime? _availabilityTo;

  String _location = '';
  double _lat = 0;
  double _lng = 0;

  final List<String> _tags = <String>[];
  bool _saving = false;

  final List<File> _newImages = [];
  final List<String> _existingImages = [];
  final List<String> _existingImagePublicIds = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.equipmentName ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    final initialPriceType =
        (e?.priceType ?? 'hour').toLowerCase() == 'day' ? 'day' : 'hour';
    final initialPrice = initialPriceType == 'day'
        ? (e?.pricePerDay ?? 0)
        : (e?.pricePerHour ?? 0);
    _price = TextEditingController(
      text: initialPrice > 0 ? initialPrice.toString() : '',
    );
    _minDuration = TextEditingController(
      text: (e?.minRentalDuration ?? 0) > 0
          ? e!.minRentalDuration.toStringAsFixed(
              e.minRentalDuration.truncateToDouble() == e.minRentalDuration
                  ? 0
                  : 1,
            )
          : '',
    );
    _tagInput = TextEditingController();
    _selectedCategory = _categories.contains(e?.category) ? e!.category : null;
    _selectedCondition =
        _conditions.contains(e?.condition) ? e!.condition : 'Good';
    _priceType = initialPriceType;
    _minDurationType =
        (e?.minRentalDurationType ?? 'hours').toLowerCase() == 'days'
            ? 'days'
            : 'hours';
    _status = (e?.status ?? 'published').toLowerCase() == 'draft'
        ? 'draft'
        : 'published';
    _availabilityFrom = e?.availabilityFrom;
    _availabilityTo = e?.availabilityTo;
    _location = e?.location ?? '';
    _lat = e?.latitude ?? 0;
    _lng = e?.longitude ?? 0;
    if (e != null) {
      _existingImages.addAll(e.imageUrls);
      _existingImagePublicIds.addAll(e.imagePublicIds);
      _tags.addAll(e.tags);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _minDuration.dispose();
    _tagInput.dispose();
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
            _sectionCard(
              title: 'Equipment Title',
              icon: Icons.title_rounded,
              child: TextFormField(
                controller: _title,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration('Enter equipment title'),
                validator: _required,
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Equipment Details',
              icon: Icons.category_rounded,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: _fieldDecoration('Select category'),
                    items: _categories
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(growable: false),
                    validator: (value) =>
                        value == null ? 'Category is required' : null,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCondition,
                    decoration: _fieldDecoration('Select condition'),
                    items: _conditions
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCondition = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 5,
                    decoration:
                        _fieldDecoration('Describe condition and usage'),
                    validator: _required,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Pricing',
              icon: Icons.currency_rupee_rounded,
              child: Column(
                children: [
                  TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _fieldDecoration('Enter price'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Price should be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'hour',
                        label: Text('Hour'),
                      ),
                      ButtonSegment<String>(
                        value: 'day',
                        label: Text('Day'),
                      ),
                    ],
                    selected: <String>{_priceType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _priceType = selection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Minimum Rental Duration',
              icon: Icons.timelapse_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minDuration,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration('Duration'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _minDurationType,
                      decoration: _fieldDecoration('Unit'),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'hours',
                          child: Text('Hours'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'days',
                          child: Text('Days'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _minDurationType = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Availability Window',
              icon: Icons.calendar_today_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAvailabilityFrom,
                          icon: const Icon(Icons.date_range_rounded),
                          label: Text(_availabilityFrom == null
                              ? 'From Date'
                              : _formatDate(_availabilityFrom!)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAvailabilityTo,
                          icon: const Icon(Icons.event_available_rounded),
                          label: Text(_availabilityTo == null
                              ? 'To Date'
                              : _formatDate(_availabilityTo!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _availabilityFrom != null && _availabilityTo != null
                        ? 'Available from ${_formatDate(_availabilityFrom!)} to ${_formatDate(_availabilityTo!)}'
                        : 'Select both dates',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Location',
              icon: Icons.location_on_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _location.isEmpty ? 'No location selected' : _location,
                      style: TextStyle(
                        color: _location.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Pick on Map'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Images',
              icon: Icons.image_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _existingImages.length; i++)
                        _imageTile(
                          child: Image.network(
                            _existingImages[i],
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                          onRemove: () {
                            setState(() {
                              _existingImages.removeAt(i);
                              if (i < _existingImagePublicIds.length) {
                                _existingImagePublicIds.removeAt(i);
                              }
                            });
                          },
                        ),
                      for (var i = 0; i < _newImages.length; i++)
                        _imageTile(
                          child: Image.file(
                            _newImages[i],
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                          onRemove: () {
                            setState(() {
                              _newImages.removeAt(i);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Upload Images'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'At least one image is required.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Tags (Optional)',
              icon: Icons.sell_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagInput,
                          decoration: _fieldDecoration(
                            'Add tags e.g. seeder, farming',
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _addTag,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map(
                            (tag) => InputChip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  _tags.remove(tag);
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Listing Status',
              icon: Icons.publish_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Published'),
                      selected: _status == 'published',
                      onSelected: (_) {
                        setState(() {
                          _status = 'published';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Draft'),
                      selected: _status == 'draft',
                      onSelected: (_) {
                        setState(() {
                          _status = 'draft';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _saving
                    ? 'Saving...'
                    : (isEdit ? 'Update Equipment' : 'Create Equipment'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _imageTile({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          initialLatLng: (_lat == 0 && _lng == 0) ? null : LatLng(_lat, _lng),
          initialAddress: _location,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _lat = result.latitude;
      _lng = result.longitude;
      _location = _extractCity(result.address);
    });
  }

  Future<void> _pickAvailabilityFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _availabilityFrom ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      _availabilityFrom = DateTime(picked.year, picked.month, picked.day);
      if (_availabilityTo != null &&
          _availabilityTo!.isBefore(_availabilityFrom!)) {
        _availabilityTo = _availabilityFrom;
      }
    });
  }

  Future<void> _pickAvailabilityTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _availabilityTo ?? _availabilityFrom ?? now,
      firstDate: _availabilityFrom ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      _availabilityTo = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _addTag() {
    final raw = _tagInput.text.trim();
    if (raw.isEmpty) return;
    final normalized = raw.toLowerCase();
    if (_tags.any((tag) => tag.toLowerCase() == normalized)) {
      _tagInput.clear();
      return;
    }
    setState(() {
      _tags.add(raw);
      _tagInput.clear();
    });
  }

  bool _validateExtraRules() {
    if (_location.trim().isEmpty) {
      _showSnack('Location is required');
      return false;
    }
    if (_availabilityFrom == null || _availabilityTo == null) {
      _showSnack('Availability from/to dates are required');
      return false;
    }
    if (_availabilityTo!.isBefore(_availabilityFrom!)) {
      _showSnack('Availability end date should be after start date');
      return false;
    }
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      _showSnack('Please upload at least one image');
      return false;
    }
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _extractCity(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '';
    final city = trimmed.split(',').first.trim();
    return city.isEmpty ? trimmed : city;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateExtraRules()) return;

    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || authUid.trim().isEmpty) {
      _showSnack('Please login again to add equipment');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final uploaded = _newImages.isEmpty
          ? const <CloudinaryUploadResult>[]
          : await _cloudinary.uploadImagesWithMetadata(_newImages);
      final images = [
        ..._existingImages,
        ...uploaded.map((e) => e.secureUrl),
      ];
      final imagePublicIds = [
        ..._existingImagePublicIds,
        ...uploaded.map((e) => e.publicId),
      ];
      final nowUtc = DateTime.now().toUtc();
      final createdAtUtc = (widget.existing?.createdAt ?? nowUtc).toUtc();
      final parsedPrice = double.parse(_price.text.trim());
      final parsedMinDuration = double.parse(_minDuration.text.trim());

      final payload = <String, dynamic>{
        'title': _title.text.trim(),
        'category': _selectedCategory!,
        'description': _description.text.trim(),
        'condition': _selectedCondition,
        'price': parsedPrice,
        'price_type': _priceType,
        'min_rental_duration': parsedMinDuration,
        'min_rental_duration_type': _minDurationType,
        'location': _location.trim(),
        'availability': {
          'from': _availabilityFrom!.toUtc().toIso8601String(),
          'to': _availabilityTo!.toUtc().toIso8601String(),
        },
        'images': images,
        'image_public_ids': imagePublicIds,
        'documents': const <String>[],
        'owner_user_id': authUid,
        'status': _status,
        'tags': _tags,
        'created_at': Timestamp.fromDate(createdAtUtc),
        'updated_at': Timestamp.fromDate(nowUtc),
      };

      if (widget.existing == null) {
        await _service.addEquipmentRecord(payload);
      } else {
        await _service.updateEquipment(
          equipmentId: widget.existing!.equipmentId,
          updates: payload,
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
