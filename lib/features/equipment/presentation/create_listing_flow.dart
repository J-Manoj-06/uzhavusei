import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/app_user_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/location_service.dart';
import '../../../services/logger_service.dart';
import '../../../widgets/image_loader.dart';

// ── CATEGORY SELECTION PAGE ──────────────────────────────────────────────────

class CategorySelectionPage extends StatelessWidget {
  const CategorySelectionPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Share Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What would you like to share?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a category to create a listing.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildCategoryCard(
              context,
              emoji: '📚',
              title: 'Books',
              desc: 'Share books with your community.',
              examples: 'Academic, Novels, Reference Books, competitive exams...',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookListingFormPage(currentUser: currentUser),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryCard(
              context,
              emoji: '🚜',
              title: 'Farm Equipment',
              desc: 'Share farming tools and machinery.',
              examples: 'Tractor, Rotavator, Sprayer, Cultivator...',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FarmEquipmentFormPage(currentUser: currentUser),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryCard(
              context,
              emoji: '🏗️',
              title: 'Construction Equipment',
              desc: 'Share construction tools and equipment.',
              examples: 'Drill Machine, Ladder, Concrete Mixer, safety tools...',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConstructionEquipmentFormPage(currentUser: currentUser),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String desc,
    required String examples,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEFF0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Examples: $examples',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── BOOK LISTING FORM ────────────────────────────────────────────────────────

class BookListingFormPage extends StatefulWidget {
  const BookListingFormPage({super.key, required this.currentUser, this.existing});
  final AppUserModel currentUser;
  final MarketplaceEquipmentModel? existing;

  @override
  State<BookListingFormPage> createState() => _BookListingFormPageState();
}

class _BookListingFormPageState extends State<BookListingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _languageCtrl;
  late TextEditingController _editionCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _qtyCtrl;

  String _condition = 'Good';
  bool _availability = true;
  bool _submitting = false;
  final List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    final specsStr = widget.existing?.machineSpecs ?? '';
    final author = specsStr.split(', ').firstWhere((s) => s.startsWith('Author: '), orElse: () => 'Author: ').replaceAll('Author: ', '');
    _titleCtrl = TextEditingController(text: widget.existing?.equipmentName ?? '');
    _authorCtrl = TextEditingController(text: author);
    _languageCtrl = TextEditingController(text: specsStr.split(', ').firstWhere((s) => s.startsWith('Language: '), orElse: () => 'Language: English').replaceAll('Language: ', ''));
    _editionCtrl = TextEditingController(text: specsStr.split(', ').firstWhere((s) => s.startsWith('Edition: '), orElse: () => 'Edition: ').replaceAll('Edition: ', ''));
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _qtyCtrl = TextEditingController(text: widget.existing?.minRentalDuration.toInt().toString() ?? '1');
    _condition = widget.existing?.condition ?? 'Good';
    _availability = widget.existing?.availability ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _languageCtrl.dispose();
    _editionCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _images.add(img));
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final locResult = await LocationService.instance.getCurrentLocation();
      if (locResult is LocationFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location Verification Failed: ${locResult.reason}'), backgroundColor: Colors.red),
          );
        }
        setState(() => _submitting = false);
        return;
      }

      final loc = (locResult as LocationSuccess).location;
      final specs = 'Language: ${_languageCtrl.text.trim()}, Edition: ${_editionCtrl.text.trim()}';

      final List<String> urls = widget.existing?.imageUrls ?? [
        'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=400&q=80'
      ];

      final model = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        equipmentName: _titleCtrl.text.trim(),
        category: 'Books',
        description: _descCtrl.text.trim(),
        titleLocalized: {'en': _titleCtrl.text.trim()},
        categoryLocalized: {'en': 'Books'},
        descriptionLocalized: {'en': _descCtrl.text.trim()},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: [loc.area, loc.city].where((e) => e != null && e.isNotEmpty).join(', '),
        latitude: loc.latitude,
        longitude: loc.longitude,
        area: loc.area ?? '',
        city: loc.city ?? '',
        state: loc.state ?? '',
        country: loc.country ?? '',
        locationAccuracy: loc.accuracy ?? 0.0,
        locationCapturedAt: loc.timestamp,
        imageUrls: urls,
        availability: _availability,
        rating: 5.0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        machineSpecs: specs,
        condition: _condition,
        minRentalDuration: double.tryParse(_qtyCtrl.text.trim()) ?? 1.0,
        priceType: 'day',
        status: 'published',
        views: widget.existing?.views ?? 0,
        savedBy: widget.existing?.savedBy ?? [],
        bookingsCount: widget.existing?.bookingsCount ?? 0,
      );

      if (widget.existing != null) {
        await _service.updateEquipment(equipmentId: widget.existing!.equipmentId, updates: model.toMap());
      } else {
        await _service.addEquipment(model);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Book listing published successfully!'), backgroundColor: Color(0xFF2E7D32)),
        );
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      LoggerService.error('Error publishing book listing', e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(title: const Text('Share a Book')),
      body: _submitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildImageSelector(),
                  const SizedBox(height: 24),
                  _buildTextField('Book Title', _titleCtrl, validator: (v) => v!.isEmpty ? 'Enter book title' : null),
                  const SizedBox(height: 16),
                  _buildTextField('Author', _authorCtrl, validator: (v) => v!.isEmpty ? 'Enter author name' : null),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Language', _languageCtrl)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Edition (Optional)', _editionCtrl)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildConditionDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Available Quantity', _qtyCtrl, isNumeric: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Description', _descCtrl, maxLines: 4, validator: (v) => v!.isEmpty ? 'Enter description' : null),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Available for Borrowing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    activeColor: const Color(0xFF2E7D32),
                    value: _availability,
                    onChanged: (val) => setState(() => _availability = val),
                  ),
                  const SizedBox(height: 24),
                  _buildPublishButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEFF0)),
        ),
        child: _images.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Color(0xFF2E7D32), size: 36),
                  SizedBox(height: 8),
                  Text('Upload Cover Images', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: _images.length,
                itemBuilder: (ctx, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_images[index].path), width: 104, height: 104, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: CircleAvatar(radius: 12, backgroundColor: Colors.black.withOpacity(0.6), child: const Icon(Icons.close, size: 14, color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumeric = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
      value: _condition,
      decoration: InputDecoration(
        labelText: 'Condition',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Like New', 'Excellent', 'Good', 'Fair']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) => setState(() => _condition = val!),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Publish Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

// ── FARM EQUIPMENT FORM ──────────────────────────────────────────────────────

class FarmEquipmentFormPage extends StatefulWidget {
  const FarmEquipmentFormPage({super.key, required this.currentUser, this.existing});
  final AppUserModel currentUser;
  final MarketplaceEquipmentModel? existing;

  @override
  State<FarmEquipmentFormPage> createState() => _FarmEquipmentFormPageState();
}

class _FarmEquipmentFormPageState extends State<FarmEquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _instructionsCtrl;
  late TextEditingController _descCtrl;

  String _condition = 'Good';
  bool _availability = true;
  bool _submitting = false;
  final List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    final specsStr = widget.existing?.machineSpecs ?? '';
    final brand = specsStr.split(', ').firstWhere((s) => s.startsWith('Brand: '), orElse: () => 'Brand: ').replaceAll('Brand: ', '');
    _nameCtrl = TextEditingController(text: widget.existing?.equipmentName ?? '');
    _typeCtrl = TextEditingController(text: specsStr.split(', ').firstWhere((s) => s.startsWith('Type: '), orElse: () => 'Type: Tractor').replaceAll('Type: ', ''));
    _brandCtrl = TextEditingController(text: brand);
    _instructionsCtrl = TextEditingController(text: specsStr.split(', ').firstWhere((s) => s.startsWith('Instructions: '), orElse: () => 'Instructions: ').replaceAll('Instructions: ', ''));
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _condition = widget.existing?.condition ?? 'Good';
    _availability = widget.existing?.availability ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _brandCtrl.dispose();
    _instructionsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _images.add(img));
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final locResult = await LocationService.instance.getCurrentLocation();
      if (locResult is LocationFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location Verification Failed: ${locResult.reason}'), backgroundColor: Colors.red),
          );
        }
        setState(() => _submitting = false);
        return;
      }

      final loc = (locResult as LocationSuccess).location;
      final specs = 'Type: ${_typeCtrl.text.trim()}, Instructions: ${_instructionsCtrl.text.trim()}';

      final List<String> urls = widget.existing?.imageUrls ?? [
        'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=400&q=80'
      ];

      final model = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        equipmentName: _nameCtrl.text.trim(),
        category: 'Farm Equipment',
        description: _descCtrl.text.trim(),
        titleLocalized: {'en': _nameCtrl.text.trim()},
        categoryLocalized: {'en': 'Farm Equipment'},
        descriptionLocalized: {'en': _descCtrl.text.trim()},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: [loc.area, loc.city].where((e) => e != null && e.isNotEmpty).join(', '),
        latitude: loc.latitude,
        longitude: loc.longitude,
        area: loc.area ?? '',
        city: loc.city ?? '',
        state: loc.state ?? '',
        country: loc.country ?? '',
        locationAccuracy: loc.accuracy ?? 0.0,
        locationCapturedAt: loc.timestamp,
        imageUrls: urls,
        availability: _availability,
        rating: 5.0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        machineSpecs: specs,
        condition: _condition,
        minRentalDuration: 1.0,
        priceType: 'day',
        status: 'published',
        views: widget.existing?.views ?? 0,
        savedBy: widget.existing?.savedBy ?? [],
        bookingsCount: widget.existing?.bookingsCount ?? 0,
      );

      if (widget.existing != null) {
        await _service.updateEquipment(equipmentId: widget.existing!.equipmentId, updates: model.toMap());
      } else {
        await _service.addEquipment(model);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Farm equipment listing published successfully!'), backgroundColor: Color(0xFF2E7D32)),
        );
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      LoggerService.error('Error publishing farm listing', e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(title: const Text('Share Farm Equipment')),
      body: _submitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildImageSelector(),
                  const SizedBox(height: 24),
                  _buildTextField('Equipment Name', _nameCtrl, validator: (v) => v!.isEmpty ? 'Enter equipment name' : null),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Equipment Type', _typeCtrl)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Brand', _brandCtrl)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildConditionDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField('Usage Instructions (Optional)', _instructionsCtrl, maxLines: 2),
                  const SizedBox(height: 16),
                  _buildTextField('Description', _descCtrl, maxLines: 4, validator: (v) => v!.isEmpty ? 'Enter description' : null),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Available for Borrowing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    activeColor: const Color(0xFF2E7D32),
                    value: _availability,
                    onChanged: (val) => setState(() => _availability = val),
                  ),
                  const SizedBox(height: 24),
                  _buildPublishButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEFF0)),
        ),
        child: _images.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Color(0xFF2E7D32), size: 36),
                  SizedBox(height: 8),
                  Text('Upload Equipment Images', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: _images.length,
                itemBuilder: (ctx, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_images[index].path), width: 104, height: 104, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: CircleAvatar(radius: 12, backgroundColor: Colors.black.withOpacity(0.6), child: const Icon(Icons.close, size: 14, color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
      value: _condition,
      decoration: InputDecoration(
        labelText: 'Condition',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Like New', 'Excellent', 'Good', 'Fair']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) => setState(() => _condition = val!),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Publish Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

// ── CONSTRUCTION EQUIPMENT FORM ──────────────────────────────────────────────

class ConstructionEquipmentFormPage extends StatefulWidget {
  const ConstructionEquipmentFormPage({super.key, required this.currentUser, this.existing});
  final AppUserModel currentUser;
  final MarketplaceEquipmentModel? existing;

  @override
  State<ConstructionEquipmentFormPage> createState() => _ConstructionEquipmentFormPageState();
}

class _ConstructionEquipmentFormPageState extends State<ConstructionEquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _safetyCtrl;
  late TextEditingController _descCtrl;

  String _condition = 'Good';
  bool _availability = true;
  bool _submitting = false;
  final List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    final specsStr = widget.existing?.machineSpecs ?? '';
    final brand = specsStr.split(', ').firstWhere((s) => s.startsWith('Brand: '), orElse: () => 'Brand: ').replaceAll('Brand: ', '');
    _nameCtrl = TextEditingController(text: widget.existing?.equipmentName ?? '');
    _typeCtrl = TextEditingController(text: specsStr.split(', ').firstWhere((s) => s.startsWith('Type: '), orElse: () => 'Type: Power Tool').replaceAll('Type: ', ''));
    _brandCtrl = TextEditingController(text: brand);
    _safetyCtrl = TextEditingController(text: specsStr.split(', ').firstWhere((s) => s.startsWith('Safety: '), orElse: () => 'Safety: ').replaceAll('Safety: ', ''));
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _condition = widget.existing?.condition ?? 'Good';
    _availability = widget.existing?.availability ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _brandCtrl.dispose();
    _safetyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _images.add(img));
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final locResult = await LocationService.instance.getCurrentLocation();
      if (locResult is LocationFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location Verification Failed: ${locResult.reason}'), backgroundColor: Colors.red),
          );
        }
        setState(() => _submitting = false);
        return;
      }

      final loc = (locResult as LocationSuccess).location;
      final specs = 'Type: ${_typeCtrl.text.trim()}, Safety: ${_safetyCtrl.text.trim()}';

      final List<String> urls = widget.existing?.imageUrls ?? [
        'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80'
      ];

      final model = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        equipmentName: _nameCtrl.text.trim(),
        category: 'Construction Equipment',
        description: _descCtrl.text.trim(),
        titleLocalized: {'en': _nameCtrl.text.trim()},
        categoryLocalized: {'en': 'Construction Equipment'},
        descriptionLocalized: {'en': _descCtrl.text.trim()},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: [loc.area, loc.city].where((e) => e != null && e.isNotEmpty).join(', '),
        latitude: loc.latitude,
        longitude: loc.longitude,
        area: loc.area ?? '',
        city: loc.city ?? '',
        state: loc.state ?? '',
        country: loc.country ?? '',
        locationAccuracy: loc.accuracy ?? 0.0,
        locationCapturedAt: loc.timestamp,
        imageUrls: urls,
        availability: _availability,
        rating: 5.0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        machineSpecs: specs,
        condition: _condition,
        minRentalDuration: 1.0,
        priceType: 'day',
        status: 'published',
        views: widget.existing?.views ?? 0,
        savedBy: widget.existing?.savedBy ?? [],
        bookingsCount: widget.existing?.bookingsCount ?? 0,
      );

      if (widget.existing != null) {
        await _service.updateEquipment(equipmentId: widget.existing!.equipmentId, updates: model.toMap());
      } else {
        await _service.addEquipment(model);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Construction listing published successfully!'), backgroundColor: Color(0xFF2E7D32)),
        );
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      LoggerService.error('Error publishing construction listing', e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(title: const Text('Share Construction Equipment')),
      body: _submitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildImageSelector(),
                  const SizedBox(height: 24),
                  _buildTextField('Equipment Name', _nameCtrl, validator: (v) => v!.isEmpty ? 'Enter equipment name' : null),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Equipment Type', _typeCtrl)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Brand', _brandCtrl)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildConditionDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField('Safety Notes (Optional)', _safetyCtrl, maxLines: 2),
                  const SizedBox(height: 16),
                  _buildTextField('Description', _descCtrl, maxLines: 4, validator: (v) => v!.isEmpty ? 'Enter description' : null),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Available for Borrowing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    activeColor: const Color(0xFF2E7D32),
                    value: _availability,
                    onChanged: (val) => setState(() => _availability = val),
                  ),
                  const SizedBox(height: 24),
                  _buildPublishButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEFF0)),
        ),
        child: _images.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Color(0xFF2E7D32), size: 36),
                  SizedBox(height: 8),
                  Text('Upload Equipment Images', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: _images.length,
                itemBuilder: (ctx, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_images[index].path), width: 104, height: 104, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: CircleAvatar(radius: 12, backgroundColor: Colors.black.withOpacity(0.6), child: const Icon(Icons.close, size: 14, color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
      value: _condition,
      decoration: InputDecoration(
        labelText: 'Condition',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Like New', 'Excellent', 'Good', 'Fair']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) => setState(() => _condition = val!),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Publish Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
